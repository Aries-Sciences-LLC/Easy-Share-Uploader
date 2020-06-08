//
//  NSDictionary+UrlEncoding.h
//  Riders
//
//  Created by Yury Nechaev on 31.03.16.
//  Copyright © 2016 Whitescape. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDictionary (UrlEncoding)

- (NSString *)uc_urlEncodedString;
- (NSString *)uc_urlOriginalString;

@end
