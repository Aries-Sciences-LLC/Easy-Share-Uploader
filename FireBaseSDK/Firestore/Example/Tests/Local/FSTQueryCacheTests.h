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

#import "Firestore/Source/Local/FSTQueryCache.h"

#import <XCTest/XCTest.h>

@protocol FSTPersistence;

NS_ASSUME_NONNULL_BEGIN

/**
 * These are tests for any implementation of the FSTQueryCache protocol.
 *
 * To test a specific implementation of FSTQueryCache:
 *
 * + Subclass FSTQueryCacheTests
 * + override -setUp, assigning to queryCache and persistence
 * + override -tearDown, cleaning up queryCache and persistence
 */
@interface FSTQueryCacheTests : XCTestCase

/** The implementation of the query cache to test. */
@property(nonatomic, strong, nullable) id<FSTQueryCache> queryCache;

/**
 * The persistence implementation to use while testing the queryCache (e.g. for committing write
 * groups).
 */
@property(nonatomic, strong, nullable) id<FSTPersistence> persistence;

@end

NS_ASSUME_NONNULL_END
