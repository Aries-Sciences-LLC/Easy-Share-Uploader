/*
 * Copyright 2017 Google
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import "Firestore/Source/Remote/FSTDatastore.h"

#import <GRPCClient/GRPCCall+OAuth2.h>
#import <ProtoRPC/ProtoRPC.h>

#import "FIRFirestoreErrors.h"
#import "Firestore/Source/API/FIRFirestore+Internal.h"
#import "Firestore/Source/API/FIRFirestoreVersion.h"
#import "Firestore/Source/Auth/FSTCredentialsProvider.h"
#import "Firestore/Source/Core/FSTDatabaseInfo.h"
#import "Firestore/Source/Local/FSTLocalStore.h"
#import "Firestore/Source/Model/FSTDatabaseID.h"
#import "Firestore/Source/Model/FSTDocument.h"
#import "Firestore/Source/Model/FSTDocumentKey.h"
#import "Firestore/Source/Model/FSTMutation.h"
#import "Firestore/Source/Remote/FSTSerializerBeta.h"
#import "Firestore/Source/Remote/FSTStream.h"
#import "Firestore/Source/Util/FSTAssert.h"
#import "Firestore/Source/Util/FSTDispatchQueue.h"
#import "Firestore/Source/Util/FSTLogger.h"

#import "Firestore/Protos/objc/google/firestore/v1beta1/Firestore.pbrpc.h"

NS_ASSUME_NONNULL_BEGIN

// GRPC does not publicly declare a means of disabling SSL, which we need for testing. Firestore
// directly exposes an sslEnabled setting so this is required to plumb that through. Note that our
// own tests depend on this working so we'll know if this changes upstream.
@interface GRPCHost
+ (nullable instancetype)hostWithAddress:(NSString *)address;
@property(nonatomic, getter=isSecure) BOOL secure;
@end

static NSString *const kXGoogAPIClientHeader = @"x-goog-api-client";
static NSString *const kGoogleCloudResourcePrefix = @"google-cloud-resource-prefix";

/** Function typedef used to create RPCs. */
typedef GRPCProtoCall * (^RPCFactory)(void);

#pragma mark - FSTDatastore

@interface FSTDatastore ()

/** The GRPC service for Firestore. */
@property(nonatomic, strong, readonly) GCFSFirestore *service;

@property(nonatomic, strong, readonly) FSTDispatchQueue *workerDispatchQueue;

/** An object for getting an auth token before each request. */
@property(nonatomic, strong, readonly) id<FSTCredentialsProvider> credentials;

@property(nonatomic, strong, readonly) FSTSerializerBeta *serializer;

@end

@implementation FSTDatastore

+ (instancetype)datastoreWithDatabase:(FSTDatabaseInfo *)databaseInfo
                  workerDispatchQueue:(FSTDispatchQueue *)workerDispatchQueue
                          credentials:(id<FSTCredentialsProvider>)credentials {
  return [[FSTDatastore alloc] initWithDatabaseInfo:databaseInfo
                                workerDispatchQueue:workerDispatchQueue
                                        credentials:credentials];
}

- (instancetype)initWithDatabaseInfo:(FSTDatabaseInfo *)databaseInfo
                 workerDispatchQueue:(FSTDispatchQueue *)workerDispatchQueue
                         credentials:(id<FSTCredentialsProvider>)credentials {
  if (self = [super init]) {
    _databaseInfo = databaseInfo;
    if (!databaseInfo.isSSLEnabled) {
      GRPCHost *hostConfig = [GRPCHost hostWithAddress:databaseInfo.host];
      hostConfig.secure = NO;
    }
    _service = [GCFSFirestore serviceWithHost:databaseInfo.host];
    _workerDispatchQueue = workerDispatchQueue;
    _credentials = credentials;
    _serializer = [[FSTSerializerBeta alloc] initWithDatabaseID:databaseInfo.databaseID];
  }
  return self;
}

- (NSString *)description {
  return [NSString stringWithFormat:@"<FSTDatastore: %@>", self.databaseInfo];
}

/**
 * Converts the error to an error within the domain FIRFirestoreErrorDomain.
 */
+ (NSError *)firestoreErrorForError:(NSError *)error {
  if (!error) {
    return error;
  } else if ([error.domain isEqualToString:FIRFirestoreErrorDomain]) {
    return error;
  } else if ([error.domain isEqualToString:kGRPCErrorDomain]) {
    FSTAssert(error.code >= GRPCErrorCodeCancelled && error.code <= GRPCErrorCodeUnauthenticated,
              @"Unknown GRPC error code: %ld", (long)error.code);
    return
        [NSError errorWithDomain:FIRFirestoreErrorDomain code:error.code userInfo:error.userInfo];
  } else {
    return [NSError errorWithDomain:FIRFirestoreErrorDomain
                               code:FIRFirestoreErrorCodeUnknown
                           userInfo:@{NSUnderlyingErrorKey : error}];
  }
}

+ (BOOL)isAbortedError:(NSError *)error {
  FSTAssert([error.domain isEqualToString:FIRFirestoreErrorDomain],
            @"isAbortedError: only works with errors emitted by FSTDatastore.");
  return error.code == FIRFirestoreErrorCodeAborted;
}

+ (BOOL)isPermanentWriteError:(NSError *)error {
  FSTAssert([error.domain isEqualToString:FIRFirestoreErrorDomain],
            @"isPerminanteWriteError: only works with errors emitted by FSTDatastore.");
  switch (error.code) {
    case FIRFirestoreErrorCodeCancelled:
    case FIRFirestoreErrorCodeUnknown:
    case FIRFirestoreErrorCodeDeadlineExceeded:
    case FIRFirestoreErrorCodeResourceExhausted:
    case FIRFirestoreErrorCodeInternal:
    case FIRFirestoreErrorCodeUnavailable:
    case FIRFirestoreErrorCodeUnauthenticated:
      // Unauthenticated means something went wrong with our token and we need
      // to retry with new credentials which will happen automatically.
      // TODO(b/37325376): Give up after second unauthenticated error.
      return NO;
    case FIRFirestoreErrorCodeInvalidArgument:
    case FIRFirestoreErrorCodeNotFound:
    case FIRFirestoreErrorCodeAlreadyExists:
    case FIRFirestoreErrorCodePermissionDenied:
    case FIRFirestoreErrorCodeFailedPrecondition:
    case FIRFirestoreErrorCodeAborted:
    // Aborted might be retried in some scenarios, but that is dependant on
    // the context and should handled individually by the calling code.
    // See https://cloud.google.com/apis/design/errors
    case FIRFirestoreErrorCodeOutOfRange:
    case FIRFirestoreErrorCodeUnimplemented:
    case FIRFirestoreErrorCodeDataLoss:
    default:
      return YES;
  }
}

/** Returns the string to be used as x-goog-api-client header value. */
+ (NSString *)googAPIClientHeaderValue {
  // TODO(dimond): This should ideally also include the grpc version, however, gRPC defines the
  // version as a macro, so it would be hardcoded based on version we have at compile time of
  // the Firestore library, rather than the version available at runtime/at compile time by the
  // user of the library.
  return [NSString stringWithFormat:@"gl-objc/ fire/%s grpc/", FirebaseFirestoreVersionString];
}

/** Returns the string to be used as google-cloud-resource-prefix header value. */
+ (NSString *)googleCloudResourcePrefixForDatabaseID:(FSTDatabaseID *)databaseID {
  return [NSString
      stringWithFormat:@"projects/%@/databases/%@", databaseID.projectID, databaseID.databaseID];
}
/**
 * Takes a dictionary of (HTTP) response headers and returns the set of whitelisted headers
 * (for logging purposes).
 */
+ (NSDictionary<NSString *, NSString *> *)extractWhiteListedHeaders:
    (NSDictionary<NSString *, NSString *> *)headers {
  NSMutableDictionary<NSString *, NSString *> *whiteListedHeaders =
      [NSMutableDictionary dictionary];
  NSArray<NSString *> *whiteList = @[
    @"date", @"x-google-backends", @"x-google-netmon-label", @"x-google-service",
    @"x-google-gfe-request-trace"
  ];
  [headers
      enumerateKeysAndObjectsUsingBlock:^(NSString *headerName, NSString *headerValue, BOOL *stop) {
        if ([whiteList containsObject:[headerName lowercaseString]]) {
          whiteListedHeaders[headerName] = headerValue;
        }
      }];
  return whiteListedHeaders;
}

/** Logs the (whitelisted) headers returned for an GRPCProtoCall RPC. */
+ (void)logHeadersForRPC:(GRPCProtoCall *)rpc RPCName:(NSString *)rpcName {
  if ([FIRFirestore isLoggingEnabled]) {
    FSTLog(@"RPC %@ returned headers (whitelisted): %@", rpcName,
           [FSTDatastore extractWhiteListedHeaders:rpc.responseHeaders]);
  }
}

- (void)commitMutations:(NSArray<FSTMutation *> *)mutations
             completion:(FSTVoidErrorBlock)completion {
  GCFSCommitRequest *request = [GCFSCommitRequest message];
  request.database = [self.serializer encodedDatabaseID];

  NSMutableArray<GCFSWrite *> *mutationProtos = [NSMutableArray array];
  for (FSTMutation *mutation in mutations) {
    [mutationProtos addObject:[self.serializer encodedMutation:mutation]];
  }
  request.writesArray = mutationProtos;

  RPCFactory rpcFactory = ^GRPCProtoCall * {
    __block GRPCProtoCall *rpc = [self.service
        RPCToCommitWithRequest:request
                       handler:^(GCFSCommitResponse *response, NSError *_Nullable error) {
                         error = [FSTDatastore firestoreErrorForError:error];
                         [self.workerDispatchQueue dispatchAsync:^{
                           FSTLog(@"RPC CommitRequest completed. Error: %@", error);
                           [FSTDatastore logHeadersForRPC:rpc RPCName:@"CommitRequest"];
                           completion(error);
                         }];
                       }];
    return rpc;
  };

  [self invokeRPCWithFactory:rpcFactory errorHandler:completion];
}

- (void)lookupDocuments:(NSArray<FSTDocumentKey *> *)keys
             completion:(FSTVoidMaybeDocumentArrayErrorBlock)completion {
  GCFSBatchGetDocumentsRequest *request = [GCFSBatchGetDocumentsRequest message];
  request.database = [self.serializer encodedDatabaseID];
  for (FSTDocumentKey *key in keys) {
    [request.documentsArray addObject:[self.serializer encodedDocumentKey:key]];
  }

  __block FSTMaybeDocumentDictionary *results =
      [FSTMaybeDocumentDictionary maybeDocumentDictionary];

  RPCFactory rpcFactory = ^GRPCProtoCall * {
    __block GRPCProtoCall *rpc = [self.service
        RPCToBatchGetDocumentsWithRequest:request
                             eventHandler:^(BOOL done,
                                            GCFSBatchGetDocumentsResponse *_Nullable response,
                                            NSError *_Nullable error) {
                               error = [FSTDatastore firestoreErrorForError:error];
                               [self.workerDispatchQueue dispatchAsync:^{
                                 if (error) {
                                   FSTLog(@"RPC BatchGetDocuments completed. Error: %@", error);
                                   [FSTDatastore logHeadersForRPC:rpc RPCName:@"BatchGetDocuments"];
                                   completion(nil, error);
                                   return;
                                 }

                                 if (!done) {
                                   // Streaming response, accumulate result
                                   FSTMaybeDocument *doc =
                                       [self.serializer decodedMaybeDocumentFromBatch:response];
                                   results = [results dictionaryBySettingObject:doc forKey:doc.key];
                                 } else {
                                   // Streaming response is done, call completion
                                   FSTLog(@"RPC BatchGetDocuments completed successfully.");
                                   [FSTDatastore logHeadersForRPC:rpc RPCName:@"BatchGetDocuments"];
                                   FSTAssert(!response, @"Got response after done.");
                                   NSMutableArray<FSTMaybeDocument *> *docs =
                                       [NSMutableArray arrayWithCapacity:keys.count];
                                   for (FSTDocumentKey *key in keys) {
                                     [docs addObject:results[key]];
                                   }
                                   completion(docs, nil);
                                 }
                               }];
                             }];
    return rpc;
  };

  [self invokeRPCWithFactory:rpcFactory
                errorHandler:^(NSError *_Nonnull error) {
                  error = [FSTDatastore firestoreErrorForError:error];
                  completion(nil, error);
                }];
}

- (void)invokeRPCWithFactory:(GRPCProtoCall * (^)(void))rpcFactory
                errorHandler:(FSTVoidErrorBlock)errorHandler {
  // TODO(mikelehen): We should force a refresh if the previous RPC failed due to an expired token,
  // but I'm not sure how to detect that right now. http://b/32762461
  [self.credentials
      getTokenForcingRefresh:NO
                  completion:^(FSTGetTokenResult *_Nullable result, NSError *_Nullable error) {
                    error = [FSTDatastore firestoreErrorForError:error];
                    [self.workerDispatchQueue dispatchAsyncAllowingSameQueue:^{
                      if (error) {
                        errorHandler(error);
                      } else {
                        GRPCProtoCall *rpc = rpcFactory();
                        [FSTDatastore prepareHeadersForRPC:rpc
                                                databaseID:self.databaseInfo.databaseID
                                                     token:result.token];
                        [rpc start];
                      }
                    }];
                  }];
}

- (FSTWatchStream *)createWatchStream {
  return [[FSTWatchStream alloc] initWithDatabase:_databaseInfo
                              workerDispatchQueue:_workerDispatchQueue
                                      credentials:_credentials
                                       serializer:_serializer];
}

- (FSTWriteStream *)createWriteStream {
  return [[FSTWriteStream alloc] initWithDatabase:_databaseInfo
                              workerDispatchQueue:_workerDispatchQueue
                                      credentials:_credentials
                                       serializer:_serializer];
}

/** Adds headers to the RPC including any OAuth access token if provided .*/
+ (void)prepareHeadersForRPC:(GRPCCall *)rpc
                  databaseID:(FSTDatabaseID *)databaseID
                       token:(nullable NSString *)token {
  rpc.oauth2AccessToken = token;
  rpc.requestHeaders[kXGoogAPIClientHeader] = [FSTDatastore googAPIClientHeaderValue];
  // This header is used to improve routing and project isolation by the backend.
  rpc.requestHeaders[kGoogleCloudResourcePrefix] =
      [FSTDatastore googleCloudResourcePrefixForDatabaseID:databaseID];
}

@end

NS_ASSUME_NONNULL_END
