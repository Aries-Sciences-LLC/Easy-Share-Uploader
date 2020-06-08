//
//  UCGroupPostRequest.m
//  Cloudkit test
//
//  Created by Yury Nechaev on 04.04.16.
//  Copyright © 2016 Uploadcare. All rights reserved.
//

#import "UCGroupPostRequest.h"
#import "UCConstantsHeader.h"

@implementation UCGroupPostRequest

+ (instancetype)requestWithFileIDs:(NSArray<NSString *> *)fileIDs {
    UCGroupPostRequest *request = [[UCGroupPostRequest alloc] initWithFileIDs:fileIDs];
    return request;
}

- (id)initWithFileIDs:(NSArray *)fileIDs {
    NSParameterAssert(fileIDs);
    self = [super init];
    if (self) {
        self.path = UCGroupUploadingPath;
        self.parameters = [self filesDictionaryFromIDs:fileIDs];
    }
    return self;
}

- (NSDictionary *)filesDictionaryFromIDs:(NSArray *)fileIDs {
    NSMutableDictionary *returnedValue = @{}.mutableCopy;
    [fileIDs enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *key = [NSString stringWithFormat:@"files[%lu]", (unsigned long)idx];
        [returnedValue setObject:obj forKey:key];
    }];
    return returnedValue.copy;
}

@end
