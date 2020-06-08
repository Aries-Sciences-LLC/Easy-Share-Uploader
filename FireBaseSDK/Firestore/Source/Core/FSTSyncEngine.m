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

#import "Firestore/Source/Core/FSTSyncEngine.h"

#import <GRPCClient/GRPCCall.h>

#import "FIRFirestoreErrors.h"
#import "Firestore/Source/Auth/FSTUser.h"
#import "Firestore/Source/Core/FSTQuery.h"
#import "Firestore/Source/Core/FSTSnapshotVersion.h"
#import "Firestore/Source/Core/FSTTargetIDGenerator.h"
#import "Firestore/Source/Core/FSTTransaction.h"
#import "Firestore/Source/Core/FSTView.h"
#import "Firestore/Source/Core/FSTViewSnapshot.h"
#import "Firestore/Source/Local/FSTEagerGarbageCollector.h"
#import "Firestore/Source/Local/FSTLocalStore.h"
#import "Firestore/Source/Local/FSTLocalViewChanges.h"
#import "Firestore/Source/Local/FSTLocalWriteResult.h"
#import "Firestore/Source/Local/FSTQueryData.h"
#import "Firestore/Source/Local/FSTReferenceSet.h"
#import "Firestore/Source/Model/FSTDocument.h"
#import "Firestore/Source/Model/FSTDocumentKey.h"
#import "Firestore/Source/Model/FSTDocumentSet.h"
#import "Firestore/Source/Model/FSTMutationBatch.h"
#import "Firestore/Source/Remote/FSTRemoteEvent.h"
#import "Firestore/Source/Util/FSTAssert.h"
#import "Firestore/Source/Util/FSTDispatchQueue.h"
#import "Firestore/Source/Util/FSTLogger.h"

NS_ASSUME_NONNULL_BEGIN

#pragma mark - FSTQueryView

/**
 * FSTQueryView contains all of the info that FSTSyncEngine needs to track for a particular
 * query and view.
 */
@interface FSTQueryView : NSObject

- (instancetype)initWithQuery:(FSTQuery *)query
                     targetID:(FSTTargetID)targetID
                  resumeToken:(NSData *)resumeToken
                         view:(FSTView *)view NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;

/** The query itself. */
@property(nonatomic, strong, readonly) FSTQuery *query;

/** The targetID created by the client that is used in the watch stream to identify this query. */
@property(nonatomic, assign, readonly) FSTTargetID targetID;

/**
 * An identifier from the datastore backend that indicates the last state of the results that
 * was received. This can be used to indicate where to continue receiving new doc changes for the
 * query.
 */
@property(nonatomic, copy, readonly) NSData *resumeToken;

/**
 * The view is responsible for computing the final merged truth of what docs are in the query.
 * It gets notified of local and remote changes, and applies the query filters and limits to
 * determine the most correct possible results.
 */
@property(nonatomic, strong, readonly) FSTView *view;

@end

@implementation FSTQueryView

- (instancetype)initWithQuery:(FSTQuery *)query
                     targetID:(FSTTargetID)targetID
                  resumeToken:(NSData *)resumeToken
                         view:(FSTView *)view {
  if (self = [super init]) {
    _query = query;
    _targetID = targetID;
    _resumeToken = resumeToken;
    _view = view;
  }
  return self;
}

@end

#pragma mark - FSTSyncEngine

@interface FSTSyncEngine ()

/** The local store, used to persist mutations and cached documents. */
@property(nonatomic, strong, readonly) FSTLocalStore *localStore;

/** The remote store for sending writes, watches, etc. to the backend. */
@property(nonatomic, strong, readonly) FSTRemoteStore *remoteStore;

/** FSTQueryViews for all active queries, indexed by query. */
@property(nonatomic, strong, readonly)
    NSMutableDictionary<FSTQuery *, FSTQueryView *> *queryViewsByQuery;

/** FSTQueryViews for all active queries, indexed by target ID. */
@property(nonatomic, strong, readonly)
    NSMutableDictionary<NSNumber *, FSTQueryView *> *queryViewsByTarget;

/**
 * When a document is in limbo, we create a special listen to resolve it. This maps the
 * FSTDocumentKey of each limbo document to the FSTTargetID of the listen resolving it.
 */
@property(nonatomic, strong, readonly)
    NSMutableDictionary<FSTDocumentKey *, FSTBoxedTargetID *> *limboTargetsByKey;

/** The inverse of limboTargetsByKey, a map of FSTTargetID to the key of the limbo doc. */
@property(nonatomic, strong, readonly)
    NSMutableDictionary<FSTBoxedTargetID *, FSTDocumentKey *> *limboKeysByTarget;

/** Used to track any documents that are currently in limbo. */
@property(nonatomic, strong, readonly) FSTReferenceSet *limboDocumentRefs;

/** The garbage collector used to collect documents that are no longer in limbo. */
@property(nonatomic, strong, readonly) FSTEagerGarbageCollector *limboCollector;

/** Stores user completion blocks, indexed by user and FSTBatchID. */
@property(nonatomic, strong)
    NSMutableDictionary<FSTUser *, NSMutableDictionary<NSNumber *, FSTVoidErrorBlock> *>
        *mutationCompletionBlocks;

/** Used for creating the FSTTargetIDs for the listens used to resolve limbo documents. */
@property(nonatomic, strong, readonly) FSTTargetIDGenerator *targetIdGenerator;

@property(nonatomic, strong) FSTUser *currentUser;

@end

@implementation FSTSyncEngine

- (instancetype)initWithLocalStore:(FSTLocalStore *)localStore
                       remoteStore:(FSTRemoteStore *)remoteStore
                       initialUser:(FSTUser *)initialUser {
  if (self = [super init]) {
    _localStore = localStore;
    _remoteStore = remoteStore;

    _queryViewsByQuery = [NSMutableDictionary dictionary];
    _queryViewsByTarget = [NSMutableDictionary dictionary];

    _limboTargetsByKey = [NSMutableDictionary dictionary];
    _limboKeysByTarget = [NSMutableDictionary dictionary];
    _limboCollector = [[FSTEagerGarbageCollector alloc] init];
    _limboDocumentRefs = [[FSTReferenceSet alloc] init];
    [_limboCollector addGarbageSource:_limboDocumentRefs];

    _mutationCompletionBlocks = [NSMutableDictionary dictionary];
    _targetIdGenerator = [FSTTargetIDGenerator generatorForSyncEngineStartingAfterID:0];
    _currentUser = initialUser;
  }
  return self;
}

- (FSTTargetID)listenToQuery:(FSTQuery *)query {
  [self assertDelegateExistsForSelector:_cmd];
  FSTAssert(self.queryViewsByQuery[query] == nil, @"We already listen to query: %@", query);

  FSTQueryData *queryData = [self.localStore allocateQuery:query];
  FSTDocumentDictionary *docs = [self.localStore executeQuery:query];
  FSTDocumentKeySet *remoteKeys = [self.localStore remoteDocumentKeysForTarget:queryData.targetID];

  FSTView *view = [[FSTView alloc] initWithQuery:query remoteDocuments:remoteKeys];
  FSTViewDocumentChanges *viewDocChanges = [view computeChangesWithDocuments:docs];
  FSTViewChange *viewChange = [view applyChangesToDocuments:viewDocChanges];
  FSTAssert(viewChange.limboChanges.count == 0,
            @"View returned limbo docs before target ack from the server.");

  FSTQueryView *queryView = [[FSTQueryView alloc] initWithQuery:query
                                                       targetID:queryData.targetID
                                                    resumeToken:queryData.resumeToken
                                                           view:view];
  self.queryViewsByQuery[query] = queryView;
  self.queryViewsByTarget[@(queryData.targetID)] = queryView;
  [self.delegate handleViewSnapshots:@[ viewChange.snapshot ]];

  [self.remoteStore listenToTargetWithQueryData:queryData];
  return queryData.targetID;
}

- (void)stopListeningToQuery:(FSTQuery *)query {
  [self assertDelegateExistsForSelector:_cmd];

  FSTQueryView *queryView = self.queryViewsByQuery[query];
  FSTAssert(queryView, @"Trying to stop listening to a query not found");

  [self.localStore releaseQuery:query];
  [self.remoteStore stopListeningToTargetID:queryView.targetID];
  [self removeAndCleanupQuery:queryView];
  [self.localStore collectGarbage];
}

- (void)writeMutations:(NSArray<FSTMutation *> *)mutations
            completion:(FSTVoidErrorBlock)completion {
  [self assertDelegateExistsForSelector:_cmd];

  FSTLocalWriteResult *result = [self.localStore locallyWriteMutations:mutations];
  [self addMutationCompletionBlock:completion batchID:result.batchID];

  [self emitNewSnapshotsWithChanges:result.changes remoteEvent:nil];
  [self.remoteStore fillWritePipeline];
}

- (void)addMutationCompletionBlock:(FSTVoidErrorBlock)completion batchID:(FSTBatchID)batchID {
  NSMutableDictionary<NSNumber *, FSTVoidErrorBlock> *completionBlocks =
      self.mutationCompletionBlocks[self.currentUser];
  if (!completionBlocks) {
    completionBlocks = [NSMutableDictionary dictionary];
    self.mutationCompletionBlocks[self.currentUser] = completionBlocks;
  }
  [completionBlocks setObject:completion forKey:@(batchID)];
}

/**
 * Takes an updateBlock in which a set of reads and writes can be performed atomically. In the
 * updateBlock, user code can read and write values using a transaction object. After the
 * updateBlock, all changes will be committed. If someone else has changed any of the data
 * referenced, then the updateBlock will be called again. If the updateBlock still fails after the
 * given number of retries, then the transaction will be rejected.
 *
 * The transaction object passed to the updateBlock contains methods for accessing documents
 * and collections. Unlike other firestore access, data accessed with the transaction will not
 * reflect local changes that have not been committed. For this reason, it is required that all
 * reads are performed before any writes. Transactions must be performed while online.
 */
- (void)transactionWithRetries:(int)retries
           workerDispatchQueue:(FSTDispatchQueue *)workerDispatchQueue
                   updateBlock:(FSTTransactionBlock)updateBlock
                    completion:(FSTVoidIDErrorBlock)completion {
  [workerDispatchQueue verifyIsCurrentQueue];
  FSTAssert(retries >= 0, @"Got negative number of retries for transaction");
  FSTTransaction *transaction = [self.remoteStore transaction];
  updateBlock(transaction, ^(id _Nullable result, NSError *_Nullable error) {
    [workerDispatchQueue dispatchAsync:^{
      if (error) {
        completion(nil, error);
        return;
      }
      [transaction commitWithCompletion:^(NSError *_Nullable transactionError) {
        if (!transactionError) {
          completion(result, nil);
          return;
        }
        // TODO(b/35201829): Only retry on real transaction failures.
        if (retries == 0) {
          NSError *wrappedError =
              [NSError errorWithDomain:FIRFirestoreErrorDomain
                                  code:FIRFirestoreErrorCodeFailedPrecondition
                              userInfo:@{
                                NSLocalizedDescriptionKey : @"Transaction failed all retries.",
                                NSUnderlyingErrorKey : transactionError
                              }];
          completion(nil, wrappedError);
          return;
        }
        [workerDispatchQueue verifyIsCurrentQueue];
        return [self transactionWithRetries:(retries - 1)
                        workerDispatchQueue:workerDispatchQueue
                                updateBlock:updateBlock
                                 completion:completion];
      }];
    }];
  });
}

- (void)applyRemoteEvent:(FSTRemoteEvent *)remoteEvent {
  [self assertDelegateExistsForSelector:_cmd];

  // Make sure limbo documents are deleted if there were no results
  [remoteEvent.targetChanges enumerateKeysAndObjectsUsingBlock:^(
                                 FSTBoxedTargetID *_Nonnull targetID,
                                 FSTTargetChange *_Nonnull targetChange, BOOL *_Nonnull stop) {
    FSTDocumentKey *limboKey = self.limboKeysByTarget[targetID];
    if (limboKey && targetChange.currentStatusUpdate == FSTCurrentStatusUpdateMarkCurrent &&
        remoteEvent.documentUpdates[limboKey] == nil) {
      // When listening to a query the server responds with a snapshot containing documents
      // matching the query and a current marker telling us we're now in sync. It's possible for
      // these to arrive as separate remote events or as a single remote event. For a document
      // query, there will be no documents sent in the response if the document doesn't exist.
      //
      // If the snapshot arrives separately from the current marker, we handle it normally and
      // updateTrackedLimboDocumentsWithChanges:targetID: will resolve the limbo status of the
      // document, removing it from limboDocumentRefs. This works because clients only initiate
      // limbo resolution when a target is current and because all current targets are always at a
      // consistent snapshot.
      //
      // However, if the document doesn't exist and the current marker arrives, the document is
      // not present in the snapshot and our normal view handling would consider the document to
      // remain in limbo indefinitely because there are no updates to the document. To avoid this,
      // we specially handle this just this case here: synthesizing a delete.
      //
      // TODO(dimond): Ideally we would have an explicit lookup query instead resulting in an
      // explicit delete message and we could remove this special logic.
      [remoteEvent
          addDocumentUpdate:[FSTDeletedDocument documentWithKey:limboKey
                                                        version:remoteEvent.snapshotVersion]];
    }
  }];

  FSTMaybeDocumentDictionary *changes = [self.localStore applyRemoteEvent:remoteEvent];
  [self emitNewSnapshotsWithChanges:changes remoteEvent:remoteEvent];
}

- (void)rejectListenWithTargetID:(FSTBoxedTargetID *)targetID error:(NSError *)error {
  [self assertDelegateExistsForSelector:_cmd];

  FSTDocumentKey *limboKey = self.limboKeysByTarget[targetID];
  if (limboKey) {
    // Since this query failed, we won't want to manually unlisten to it.
    // So go ahead and remove it from bookkeeping.
    [self.limboTargetsByKey removeObjectForKey:limboKey];
    [self.limboKeysByTarget removeObjectForKey:targetID];

    // TODO(dimond): Retry on transient errors?

    // It's a limbo doc. Create a synthetic event saying it was deleted. This is kind of a hack.
    // Ideally, we would have a method in the local store to purge a document. However, it would
    // be tricky to keep all of the local store's invariants with another method.
    NSMutableDictionary<NSNumber *, FSTTargetChange *> *targetChanges =
        [NSMutableDictionary dictionary];
    FSTDeletedDocument *doc =
        [FSTDeletedDocument documentWithKey:limboKey version:[FSTSnapshotVersion noVersion]];
    NSMutableDictionary<FSTDocumentKey *, FSTMaybeDocument *> *docUpdate =
        [NSMutableDictionary dictionaryWithObject:doc forKey:limboKey];
    FSTRemoteEvent *event = [FSTRemoteEvent eventWithSnapshotVersion:[FSTSnapshotVersion noVersion]
                                                       targetChanges:targetChanges
                                                     documentUpdates:docUpdate];
    [self applyRemoteEvent:event];
  } else {
    FSTQueryView *queryView = self.queryViewsByTarget[targetID];
    FSTAssert(queryView, @"Unknown targetId: %@", targetID);
    [self.localStore releaseQuery:queryView.query];
    [self removeAndCleanupQuery:queryView];
    [self.delegate handleError:error forQuery:queryView.query];
  }
}

- (void)applySuccessfulWriteWithResult:(FSTMutationBatchResult *)batchResult {
  [self assertDelegateExistsForSelector:_cmd];

  // The local store may or may not be able to apply the write result and raise events immediately
  // (depending on whether the watcher is caught up), so we raise user callbacks first so that they
  // consistently happen before listen events.
  [self processUserCallbacksForBatchID:batchResult.batch.batchID error:nil];

  FSTMaybeDocumentDictionary *changes = [self.localStore acknowledgeBatchWithResult:batchResult];
  [self emitNewSnapshotsWithChanges:changes remoteEvent:nil];
}

- (void)rejectFailedWriteWithBatchID:(FSTBatchID)batchID error:(NSError *)error {
  [self assertDelegateExistsForSelector:_cmd];

  // The local store may or may not be able to apply the write result and raise events immediately
  // (depending on whether the watcher is caught up), so we raise user callbacks first so that they
  // consistently happen before listen events.
  [self processUserCallbacksForBatchID:batchID error:error];

  FSTMaybeDocumentDictionary *changes = [self.localStore rejectBatchID:batchID];
  [self emitNewSnapshotsWithChanges:changes remoteEvent:nil];
}

- (void)processUserCallbacksForBatchID:(FSTBatchID)batchID error:(NSError *_Nullable)error {
  NSMutableDictionary<NSNumber *, FSTVoidErrorBlock> *completionBlocks =
      self.mutationCompletionBlocks[self.currentUser];

  // NOTE: Mutations restored from persistence won't have completion blocks, so it's okay for
  // this (or the completion below) to be nil.
  if (completionBlocks) {
    NSNumber *boxedBatchID = @(batchID);
    FSTVoidErrorBlock completion = completionBlocks[boxedBatchID];
    if (completion) {
      completion(error);
      [completionBlocks removeObjectForKey:boxedBatchID];
    }
  }
}

- (void)assertDelegateExistsForSelector:(SEL)methodSelector {
  FSTAssert(self.delegate, @"Tried to call '%@' before delegate was registered.",
            NSStringFromSelector(methodSelector));
}

- (void)removeAndCleanupQuery:(FSTQueryView *)queryView {
  [self.queryViewsByQuery removeObjectForKey:queryView.query];
  [self.queryViewsByTarget removeObjectForKey:@(queryView.targetID)];

  [self.limboDocumentRefs removeReferencesForID:queryView.targetID];
  [self garbageCollectLimboDocuments];
}

/**
 * Computes a new snapshot from the changes and calls the registered callback with the new snapshot.
 */
- (void)emitNewSnapshotsWithChanges:(FSTMaybeDocumentDictionary *)changes
                        remoteEvent:(FSTRemoteEvent *_Nullable)remoteEvent {
  NSMutableArray<FSTViewSnapshot *> *newSnapshots = [NSMutableArray array];
  NSMutableArray<FSTLocalViewChanges *> *documentChangesInAllViews = [NSMutableArray array];

  [self.queryViewsByQuery
      enumerateKeysAndObjectsUsingBlock:^(FSTQuery *query, FSTQueryView *queryView, BOOL *stop) {
        FSTView *view = queryView.view;
        FSTViewDocumentChanges *viewDocChanges = [view computeChangesWithDocuments:changes];
        if (viewDocChanges.needsRefill) {
          // The query has a limit and some docs were removed/updated, so we need to re-run the
          // query against the local store to make sure we didn't lose any good docs that had been
          // past the limit.
          FSTDocumentDictionary *docs = [self.localStore executeQuery:queryView.query];
          viewDocChanges = [view computeChangesWithDocuments:docs previousChanges:viewDocChanges];
        }
        FSTTargetChange *_Nullable targetChange = remoteEvent.targetChanges[@(queryView.targetID)];
        FSTViewChange *viewChange =
            [queryView.view applyChangesToDocuments:viewDocChanges targetChange:targetChange];

        [self updateTrackedLimboDocumentsWithChanges:viewChange.limboChanges
                                            targetID:queryView.targetID];

        if (viewChange.snapshot) {
          [newSnapshots addObject:viewChange.snapshot];
          FSTLocalViewChanges *docChanges =
              [FSTLocalViewChanges changesForViewSnapshot:viewChange.snapshot];
          [documentChangesInAllViews addObject:docChanges];
        }
      }];

  [self.delegate handleViewSnapshots:newSnapshots];
  [self.localStore notifyLocalViewChanges:documentChangesInAllViews];
  [self.localStore collectGarbage];
}

/** Updates the limbo document state for the given targetID. */
- (void)updateTrackedLimboDocumentsWithChanges:(NSArray<FSTLimboDocumentChange *> *)limboChanges
                                      targetID:(FSTTargetID)targetID {
  for (FSTLimboDocumentChange *limboChange in limboChanges) {
    switch (limboChange.type) {
      case FSTLimboDocumentChangeTypeAdded:
        [self.limboDocumentRefs addReferenceToKey:limboChange.key forID:targetID];
        [self trackLimboChange:limboChange];
        break;

      case FSTLimboDocumentChangeTypeRemoved:
        FSTLog(@"Document no longer in limbo: %@", limboChange.key);
        [self.limboDocumentRefs removeReferenceToKey:limboChange.key forID:targetID];
        break;

      default:
        FSTFail(@"Unknown limbo change type: %ld", (long)limboChange.type);
    }
  }
  [self garbageCollectLimboDocuments];
}

- (void)trackLimboChange:(FSTLimboDocumentChange *)limboChange {
  FSTDocumentKey *key = limboChange.key;

  if (!self.limboTargetsByKey[key]) {
    FSTLog(@"New document in limbo: %@", key);
    FSTTargetID limboTargetID = [self.targetIdGenerator nextID];
    FSTQuery *query = [FSTQuery queryWithPath:key.path];
    FSTQueryData *queryData = [[FSTQueryData alloc] initWithQuery:query
                                                         targetID:limboTargetID
                                                          purpose:FSTQueryPurposeLimboResolution];
    self.limboKeysByTarget[@(limboTargetID)] = key;
    [self.remoteStore listenToTargetWithQueryData:queryData];
    self.limboTargetsByKey[key] = @(limboTargetID);
  }
}

/** Garbage collect the limbo documents that we no longer need to track. */
- (void)garbageCollectLimboDocuments {
  NSSet<FSTDocumentKey *> *garbage = [self.limboCollector collectGarbage];
  for (FSTDocumentKey *key in garbage) {
    FSTBoxedTargetID *limboTarget = self.limboTargetsByKey[key];
    if (!limboTarget) {
      // This target already got removed, because the query failed.
      return;
    }
    FSTTargetID limboTargetID = limboTarget.intValue;
    [self.remoteStore stopListeningToTargetID:limboTargetID];
    [self.limboTargetsByKey removeObjectForKey:key];
    [self.limboKeysByTarget removeObjectForKey:limboTarget];
  }
}

// Used for testing
- (NSDictionary<FSTDocumentKey *, FSTBoxedTargetID *> *)currentLimboDocuments {
  // Return defensive copy
  return [self.limboTargetsByKey copy];
}

- (void)userDidChange:(FSTUser *)user {
  self.currentUser = user;

  // Notify local store and emit any resulting events from swapping out the mutation queue.
  FSTMaybeDocumentDictionary *changes = [self.localStore userDidChange:user];
  [self emitNewSnapshotsWithChanges:changes remoteEvent:nil];

  // Notify remote store so it can restart its streams.
  [self.remoteStore userDidChange:user];
}

@end

NS_ASSUME_NONNULL_END
