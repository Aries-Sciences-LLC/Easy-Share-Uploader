#ifdef __OBJC__
#import <Cocoa/Cocoa.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "NSDictionary+UrlEncoding.h"
#import "NSString+EncodeRFC3986.h"
#import "UCAPIRequest.h"
#import "UCClient.h"
#import "UCConstantsHeader.h"
#import "UCFileInfoRequest.h"
#import "UCFileUploadRequest.h"
#import "UCGroupInfoRequest.h"
#import "UCGroupPostRequest.h"
#import "UCRemoteFileUploadRequest.h"
#import "UploadcareKit.h"

FOUNDATION_EXPORT double UploadcareVersionNumber;
FOUNDATION_EXPORT const unsigned char UploadcareVersionString[];

