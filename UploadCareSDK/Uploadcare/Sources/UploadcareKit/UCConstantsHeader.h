//
//  UCConstantsHeader.h
//  Riders
//
//  Created by Yury Nechaev on 31.03.16.
//  Copyright © 2016 Uploadcare. All rights reserved.
//

#pragma mark - root paths

static NSString * const UCAPIProtocol				= @"https";
static NSString * const UCApiRoot   				= @"upload.uploadcare.com";

#pragma mark - api paths

static NSString * const UCFileUploadingPath 		= @"/base/";
static NSString * const UCFileInfoPath				= @"/info/";
static NSString * const UCRemoteFileUploadingPath 	= @"/from_url/";
static NSString * const UCRemoteObservingPath	 	= @"/from_url/status/";
static NSString * const UCGroupUploadingPath		= @"/group/";
static NSString * const UCGroupInfoPath				= @"/group/info/";

#pragma mark - domains

static NSString * const UCRootDomain				= @"com.uploadcare.upload";
static NSString * const UCLocalFileUploadDomain		= @"local";
static NSString * const UCRemoteFileUploadDomain	= @"remote";

#pragma mark - error codes

static NSUInteger const UCErrorUnknown = 1001;
static NSUInteger const UCErrorUploadcare = 1002;