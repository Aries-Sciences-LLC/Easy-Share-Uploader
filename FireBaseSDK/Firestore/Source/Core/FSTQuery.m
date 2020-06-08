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

#import "Firestore/Source/Core/FSTQuery.h"

#import "Firestore/Source/API/FIRFirestore+Internal.h"
#import "Firestore/Source/Model/FSTDocument.h"
#import "Firestore/Source/Model/FSTDocumentKey.h"
#import "Firestore/Source/Model/FSTFieldValue.h"
#import "Firestore/Source/Model/FSTPath.h"
#import "Firestore/Source/Util/FSTAssert.h"

NS_ASSUME_NONNULL_BEGIN

#pragma mark - FSTRelationFilterOperator functions

NSString *FSTStringFromQueryRelationOperator(FSTRelationFilterOperator filterOperator) {
  switch (filterOperator) {
    case FSTRelationFilterOperatorLessThan:
      return @"<";
    case FSTRelationFilterOperatorLessThanOrEqual:
      return @"<=";
    case FSTRelationFilterOperatorEqual:
      return @"==";
    case FSTRelationFilterOperatorGreaterThanOrEqual:
      return @">=";
    case FSTRelationFilterOperatorGreaterThan:
      return @">";
    default:
      FSTCFail(@"Unknown FSTRelationFilterOperator %lu", (unsigned long)filterOperator);
  }
}

#pragma mark - FSTRelationFilter

@interface FSTRelationFilter ()

/**
 * Initializes the receiver relation filter.
 *
 * @param field A path to a field in the document to filter on. The LHS of the expression.
 * @param filterOperator The binary operator to apply.
 * @param value A constant value to compare @a field to. The RHS of the expression.
 */
- (instancetype)initWithField:(FSTFieldPath *)field
               filterOperator:(FSTRelationFilterOperator)filterOperator
                        value:(FSTFieldValue *)value NS_DESIGNATED_INITIALIZER;

/** Returns YES if @a document matches the receiver's constraint. */
- (BOOL)matchesDocument:(FSTDocument *)document;

/**
 * A canonical string identifying the filter. Two different instances of equivalent filters will
 * return the same canonicalID.
 */
- (NSString *)canonicalID;

@end

@implementation FSTRelationFilter

#pragma mark - Constructor methods

+ (instancetype)filterWithField:(FSTFieldPath *)field
                 filterOperator:(FSTRelationFilterOperator)filterOperator
                          value:(FSTFieldValue *)value {
  return [[FSTRelationFilter alloc] initWithField:field filterOperator:filterOperator value:value];
}

- (instancetype)initWithField:(FSTFieldPath *)field
               filterOperator:(FSTRelationFilterOperator)filterOperator
                        value:(FSTFieldValue *)value {
  self = [super init];
  if (self) {
    _field = field;
    _filterOperator = filterOperator;
    _value = value;
  }
  return self;
}

#pragma mark - Public Methods

- (BOOL)isInequality {
  return self.filterOperator != FSTRelationFilterOperatorEqual;
}

#pragma mark - NSObject methods

- (NSString *)description {
  return [NSString stringWithFormat:@"%@ %@ %@", [self.field canonicalString],
                                    FSTStringFromQueryRelationOperator(self.filterOperator),
                                    self.value];
}

- (BOOL)isEqual:(id)other {
  if (self == other) {
    return YES;
  }
  if (![other isKindOfClass:[FSTRelationFilter class]]) {
    return NO;
  }
  return [self isEqualToFilter:(FSTRelationFilter *)other];
}

#pragma mark - Private methods

- (BOOL)matchesDocument:(FSTDocument *)document {
  if ([self.field isKeyFieldPath]) {
    FSTAssert([self.value isKindOfClass:[FSTReferenceValue class]],
              @"Comparing on key, but filter value not a FSTReferenceValue.");
    FSTReferenceValue *refValue = (FSTReferenceValue *)self.value;
    NSComparisonResult comparison = FSTDocumentKeyComparator(document.key, refValue.value);
    return [self matchesComparison:comparison];
  } else {
    return [self matchesValue:[document fieldForPath:self.field]];
  }
}

- (NSString *)canonicalID {
  // TODO(b/37283291): This should be collision robust and avoid relying on |description| methods.
  return [NSString stringWithFormat:@"%@%@%@", [self.field canonicalString],
                                    FSTStringFromQueryRelationOperator(self.filterOperator),
                                    [self.value value]];
}

- (BOOL)isEqualToFilter:(FSTRelationFilter *)other {
  if (self.filterOperator != other.filterOperator) {
    return NO;
  }
  if (![self.field isEqual:other.field]) {
    return NO;
  }
  if (![self.value isEqual:other.value]) {
    return NO;
  }
  return YES;
}

/** Returns YES if receiver is true with the given value as its LHS. */
- (BOOL)matchesValue:(FSTFieldValue *)other {
  // Only compare types with matching backend order (such as double and int).
  return self.value.typeOrder == other.typeOrder &&
         [self matchesComparison:[other compare:self.value]];
}

- (BOOL)matchesComparison:(NSComparisonResult)comparison {
  switch (self.filterOperator) {
    case FSTRelationFilterOperatorLessThan:
      return comparison == NSOrderedAscending;
    case FSTRelationFilterOperatorLessThanOrEqual:
      return comparison == NSOrderedAscending || comparison == NSOrderedSame;
    case FSTRelationFilterOperatorEqual:
      return comparison == NSOrderedSame;
    case FSTRelationFilterOperatorGreaterThanOrEqual:
      return comparison == NSOrderedDescending || comparison == NSOrderedSame;
    case FSTRelationFilterOperatorGreaterThan:
      return comparison == NSOrderedDescending;
    default:
      FSTFail(@"Unknown operator: %ld", (long)self.filterOperator);
  }
}

@end

#pragma mark - FSTNullFilter

@interface FSTNullFilter ()
@property(nonatomic, strong, readonly) FSTFieldPath *field;
@end

@implementation FSTNullFilter
- (instancetype)initWithField:(FSTFieldPath *)field {
  if (self = [super init]) {
    _field = field;
  }
  return self;
}

- (BOOL)matchesDocument:(FSTDocument *)document {
  FSTFieldValue *fieldValue = [document fieldForPath:self.field];
  return fieldValue != nil && [fieldValue isEqual:[FSTNullValue nullValue]];
}

- (NSString *)canonicalID {
  return [NSString stringWithFormat:@"%@ IS NULL", [self.field canonicalString]];
}

- (NSString *)description {
  return [self canonicalID];
}

- (BOOL)isEqual:(id)other {
  if (other == self) return YES;
  if (!other || ![[other class] isEqual:[self class]]) return NO;

  return [self.field isEqual:((FSTNullFilter *)other).field];
}

- (NSUInteger)hash {
  return [self.field hash];
}

@end

#pragma mark - FSTNanFilter

@interface FSTNanFilter ()
@property(nonatomic, strong, readonly) FSTFieldPath *field;
@end

@implementation FSTNanFilter

- (instancetype)initWithField:(FSTFieldPath *)field {
  if (self = [super init]) {
    _field = field;
  }
  return self;
}

- (BOOL)matchesDocument:(FSTDocument *)document {
  FSTFieldValue *fieldValue = [document fieldForPath:self.field];
  return fieldValue != nil && [fieldValue isEqual:[FSTDoubleValue nanValue]];
}

- (NSString *)canonicalID {
  return [NSString stringWithFormat:@"%@ IS NaN", [self.field canonicalString]];
}

- (NSString *)description {
  return [self canonicalID];
}

- (BOOL)isEqual:(id)other {
  if (other == self) return YES;
  if (!other || ![[other class] isEqual:[self class]]) return NO;

  return [self.field isEqual:((FSTNanFilter *)other).field];
}

- (NSUInteger)hash {
  return [self.field hash];
}
@end

#pragma mark - FSTSortOrder

@interface FSTSortOrder ()

/** Creates a new sort order with the given field and direction. */
- (instancetype)initWithFieldPath:(FSTFieldPath *)fieldPath ascending:(BOOL)ascending;

- (NSString *)canonicalID;

@end

@implementation FSTSortOrder

#pragma mark - Constructor methods

+ (instancetype)sortOrderWithFieldPath:(FSTFieldPath *)fieldPath ascending:(BOOL)ascending {
  return [[FSTSortOrder alloc] initWithFieldPath:fieldPath ascending:ascending];
}

- (instancetype)initWithFieldPath:(FSTFieldPath *)fieldPath ascending:(BOOL)ascending {
  self = [super init];
  if (self) {
    _field = fieldPath;
    _ascending = ascending;
  }
  return self;
}

#pragma mark - Public methods

- (NSComparisonResult)compareDocument:(FSTDocument *)document1 toDocument:(FSTDocument *)document2 {
  int modifier = self.isAscending ? 1 : -1;
  if ([self.field isEqual:[FSTFieldPath keyFieldPath]]) {
    return (NSComparisonResult)(modifier * FSTDocumentKeyComparator(document1.key, document2.key));
  } else {
    FSTFieldValue *value1 = [document1 fieldForPath:self.field];
    FSTFieldValue *value2 = [document2 fieldForPath:self.field];
    FSTAssert(value1 != nil && value2 != nil,
              @"Trying to compare documents on fields that don't exist.");
    return modifier * [value1 compare:value2];
  }
}

- (NSString *)canonicalID {
  return [NSString
      stringWithFormat:@"%@%@", self.field.canonicalString, self.isAscending ? @"asc" : @"desc"];
}

- (BOOL)isEqualToSortOrder:(FSTSortOrder *)other {
  return [self.field isEqual:other.field] && self.isAscending == other.isAscending;
}

#pragma mark - NSObject methods

- (NSString *)description {
  return [NSString stringWithFormat:@"<FSTSortOrder: path:%@ dir:%@>", self.field,
                                    self.ascending ? @"asc" : @"desc"];
}

- (BOOL)isEqual:(NSObject *)other {
  if (self == other) {
    return YES;
  }
  if (![other isKindOfClass:[FSTSortOrder class]]) {
    return NO;
  }
  return [self isEqualToSortOrder:(FSTSortOrder *)other];
}

- (NSUInteger)hash {
  return [self.canonicalID hash];
}

- (instancetype)copyWithZone:(nullable NSZone *)zone {
  return self;
}

@end

#pragma mark - FSTBound

@implementation FSTBound

- (instancetype)initWithPosition:(NSArray<FSTFieldValue *> *)position isBefore:(BOOL)isBefore {
  if (self = [super init]) {
    _position = position;
    _before = isBefore;
  }
  return self;
}

+ (instancetype)boundWithPosition:(NSArray<FSTFieldValue *> *)position isBefore:(BOOL)isBefore {
  return [[FSTBound alloc] initWithPosition:position isBefore:isBefore];
}

- (NSString *)canonicalString {
  // TODO(b/29183165): Make this collision robust.
  NSMutableString *string = [NSMutableString string];
  if (self.isBefore) {
    [string appendString:@"b:"];
  } else {
    [string appendString:@"a:"];
  }
  for (FSTFieldValue *component in self.position) {
    [string appendFormat:@"%@", component];
  }
  return string;
}

- (BOOL)sortsBeforeDocument:(FSTDocument *)document
             usingSortOrder:(NSArray<FSTSortOrder *> *)sortOrder {
  FSTAssert(self.position.count <= sortOrder.count,
            @"FSTIndexPosition has more components than provided sort order.");
  __block NSComparisonResult result = NSOrderedSame;
  [self.position enumerateObjectsUsingBlock:^(FSTFieldValue *fieldValue, NSUInteger idx,
                                              BOOL *stop) {
    FSTSortOrder *sortOrderComponent = sortOrder[idx];
    NSComparisonResult comparison;
    if ([sortOrderComponent.field isEqual:[FSTFieldPath keyFieldPath]]) {
      FSTAssert([fieldValue isKindOfClass:[FSTReferenceValue class]],
                @"FSTBound has a non-key value where the key path is being used %@", fieldValue);
      comparison = [fieldValue.value compare:document.key];
    } else {
      FSTFieldValue *docValue = [document fieldForPath:sortOrderComponent.field];
      FSTAssert(docValue != nil, @"Field should exist since document matched the orderBy already.");
      comparison = [fieldValue compare:docValue];
    }

    if (!sortOrderComponent.isAscending) {
      comparison = comparison * -1;
    }

    if (comparison != 0) {
      result = comparison;
      *stop = YES;
    }
  }];

  return self.isBefore ? result <= NSOrderedSame : result < NSOrderedSame;
}

#pragma mark - NSObject methods

- (NSString *)description {
  return [NSString stringWithFormat:@"<FSTBound: position:%@ before:%@>", self.position,
                                    self.isBefore ? @"YES" : @"NO"];
}

- (BOOL)isEqual:(NSObject *)other {
  if (self == other) {
    return YES;
  }
  if (![other isKindOfClass:[FSTBound class]]) {
    return NO;
  }

  FSTBound *otherBound = (FSTBound *)other;

  return [self.position isEqualToArray:otherBound.position] && self.isBefore == otherBound.isBefore;
}

- (NSUInteger)hash {
  return 31 * self.position.hash + (self.isBefore ? 0 : 1);
}

- (instancetype)copyWithZone:(nullable NSZone *)zone {
  return self;
}

@end

#pragma mark - FSTQuery

@interface FSTQuery () {
  // Cached value of the canonicalID property.
  NSString *_canonicalID;
}

/**
 * Initializes the receiver with the given query constraints.
 *
 * @param path The base path of the query.
 * @param filters Filters specify which documents to include in the results.
 * @param sortOrders The fields and directions to sort the results.
 * @param limit If not NSNotFound, only this many results will be returned.
 */
- (instancetype)initWithPath:(FSTResourcePath *)path
                    filterBy:(NSArray<id<FSTFilter>> *)filters
                     orderBy:(NSArray<FSTSortOrder *> *)sortOrders
                       limit:(NSInteger)limit
                     startAt:(nullable FSTBound *)startAtBound
                       endAt:(nullable FSTBound *)endAtBound NS_DESIGNATED_INITIALIZER;

/** A list of fields given to sort by. This does not include the implicit key sort at the end. */
@property(nonatomic, strong, readonly) NSArray<FSTSortOrder *> *explicitSortOrders;

/** The memoized list of sort orders */
@property(nonatomic, nullable, strong, readwrite) NSArray<FSTSortOrder *> *memoizedSortOrders;

@end

@implementation FSTQuery

#pragma mark - Constructors

+ (instancetype)queryWithPath:(FSTResourcePath *)path {
  return [[FSTQuery alloc] initWithPath:path
                               filterBy:@[]
                                orderBy:@[]
                                  limit:NSNotFound
                                startAt:nil
                                  endAt:nil];
}

- (instancetype)initWithPath:(FSTResourcePath *)path
                    filterBy:(NSArray<id<FSTFilter>> *)filters
                     orderBy:(NSArray<FSTSortOrder *> *)sortOrders
                       limit:(NSInteger)limit
                     startAt:(nullable FSTBound *)startAtBound
                       endAt:(nullable FSTBound *)endAtBound {
  if (self = [super init]) {
    _path = path;
    _filters = filters;
    _explicitSortOrders = sortOrders;
    _limit = limit;
    _startAt = startAtBound;
    _endAt = endAtBound;
  }
  return self;
}

#pragma mark - NSObject methods

- (NSString *)description {
  return [NSString stringWithFormat:@"<FSTQuery: canonicalID:%@>", self.canonicalID];
}

- (BOOL)isEqual:(id)object {
  if (self == object) {
    return YES;
  }
  if (![object isKindOfClass:[FSTQuery class]]) {
    return NO;
  }
  return [self isEqualToQuery:(FSTQuery *)object];
}

- (NSUInteger)hash {
  return [self.canonicalID hash];
}

- (instancetype)copyWithZone:(nullable NSZone *)zone {
  return self;
}

#pragma mark - Public methods

- (NSArray *)sortOrders {
  if (self.memoizedSortOrders == nil) {
    FSTFieldPath *_Nullable inequalityField = [self inequalityFilterField];
    FSTFieldPath *_Nullable firstSortOrderField = [self firstSortOrderField];
    if (inequalityField && !firstSortOrderField) {
      // In order to implicitly add key ordering, we must also add the inequality filter field for
      // it to be a valid query. Note that the default inequality field and key ordering is
      // ascending.
      if ([inequalityField isKeyFieldPath]) {
        self.memoizedSortOrders =
            @[ [FSTSortOrder sortOrderWithFieldPath:[FSTFieldPath keyFieldPath] ascending:YES] ];
      } else {
        self.memoizedSortOrders = @[
          [FSTSortOrder sortOrderWithFieldPath:inequalityField ascending:YES],
          [FSTSortOrder sortOrderWithFieldPath:[FSTFieldPath keyFieldPath] ascending:YES]
        ];
      }
    } else {
      FSTAssert(!inequalityField || [inequalityField isEqual:firstSortOrderField],
                @"First orderBy %@ should match inequality field %@.", firstSortOrderField,
                inequalityField);

      __block BOOL foundKeyOrder = NO;

      NSMutableArray *result = [NSMutableArray array];
      for (FSTSortOrder *sortOrder in self.explicitSortOrders) {
        [result addObject:sortOrder];
        if ([sortOrder.field isEqual:[FSTFieldPath keyFieldPath]]) {
          foundKeyOrder = YES;
        }
      }

      if (!foundKeyOrder) {
        // The direction of the implicit key ordering always matches the direction of the last
        // explicit sort order
        BOOL lastIsAscending =
            self.explicitSortOrders.count > 0 ? self.explicitSortOrders.lastObject.ascending : YES;
        [result addObject:[FSTSortOrder sortOrderWithFieldPath:[FSTFieldPath keyFieldPath]
                                                     ascending:lastIsAscending]];
      }

      self.memoizedSortOrders = result;
    }
  }
  return self.memoizedSortOrders;
}

- (instancetype)queryByAddingFilter:(id<FSTFilter>)filter {
  FSTAssert(![FSTDocumentKey isDocumentKey:self.path], @"No filtering allowed for document query");

  FSTFieldPath *_Nullable newInequalityField = nil;
  if ([filter isKindOfClass:[FSTRelationFilter class]] &&
      [((FSTRelationFilter *)filter)isInequality]) {
    newInequalityField = filter.field;
  }
  FSTFieldPath *_Nullable queryInequalityField = [self inequalityFilterField];
  FSTAssert(!queryInequalityField || !newInequalityField ||
                [queryInequalityField isEqual:newInequalityField],
            @"Query must only have one inequality field.");

  return [[FSTQuery alloc] initWithPath:self.path
                               filterBy:[self.filters arrayByAddingObject:filter]
                                orderBy:self.explicitSortOrders
                                  limit:self.limit
                                startAt:self.startAt
                                  endAt:self.endAt];
}

- (instancetype)queryByAddingSortOrder:(FSTSortOrder *)sortOrder {
  FSTAssert(![FSTDocumentKey isDocumentKey:self.path],
            @"No ordering is allowed for a document query.");

  // TODO(klimt): Validate that the same key isn't added twice.
  return [[FSTQuery alloc] initWithPath:self.path
                               filterBy:self.filters
                                orderBy:[self.explicitSortOrders arrayByAddingObject:sortOrder]
                                  limit:self.limit
                                startAt:self.startAt
                                  endAt:self.endAt];
}

- (instancetype)queryBySettingLimit:(NSInteger)limit {
  return [[FSTQuery alloc] initWithPath:self.path
                               filterBy:self.filters
                                orderBy:self.explicitSortOrders
                                  limit:limit
                                startAt:self.startAt
                                  endAt:self.endAt];
}

- (instancetype)queryByAddingStartAt:(FSTBound *)bound {
  return [[FSTQuery alloc] initWithPath:self.path
                               filterBy:self.filters
                                orderBy:self.explicitSortOrders
                                  limit:self.limit
                                startAt:bound
                                  endAt:self.endAt];
}

- (instancetype)queryByAddingEndAt:(FSTBound *)bound {
  return [[FSTQuery alloc] initWithPath:self.path
                               filterBy:self.filters
                                orderBy:self.explicitSortOrders
                                  limit:self.limit
                                startAt:self.startAt
                                  endAt:bound];
}

- (BOOL)isDocumentQuery {
  return [FSTDocumentKey isDocumentKey:self.path] && self.filters.count == 0;
}

- (BOOL)matchesDocument:(FSTDocument *)document {
  return [self pathMatchesDocument:document] && [self orderByMatchesDocument:document] &&
         [self filtersMatchDocument:document] && [self boundsMatchDocument:document];
}

- (NSComparator)comparator {
  return ^NSComparisonResult(id document1, id document2) {
    BOOL didCompareOnKeyField = NO;
    for (FSTSortOrder *orderBy in self.sortOrders) {
      NSComparisonResult comp = [orderBy compareDocument:document1 toDocument:document2];
      if (comp != NSOrderedSame) {
        return comp;
      }
      didCompareOnKeyField =
          didCompareOnKeyField || [orderBy.field isEqual:[FSTFieldPath keyFieldPath]];
    }
    FSTAssert(didCompareOnKeyField, @"sortOrder of query did not include key ordering");
    return NSOrderedSame;
  };
}

- (FSTFieldPath *_Nullable)inequalityFilterField {
  for (id<FSTFilter> filter in self.filters) {
    if ([filter isKindOfClass:[FSTRelationFilter class]] &&
        ((FSTRelationFilter *)filter).filterOperator != FSTRelationFilterOperatorEqual) {
      return filter.field;
    }
  }
  return nil;
}

- (FSTFieldPath *_Nullable)firstSortOrderField {
  return self.explicitSortOrders.firstObject.field;
}

#pragma mark - Private properties

- (NSString *)canonicalID {
  if (_canonicalID) {
    return _canonicalID;
  }

  NSMutableString *canonicalID = [[self.path canonicalString] mutableCopy];

  // Add filters.
  [canonicalID appendString:@"|f:"];
  for (id<FSTFilter> predicate in self.filters) {
    [canonicalID appendFormat:@"%@", [predicate canonicalID]];
  }

  // Add order by.
  [canonicalID appendString:@"|ob:"];
  for (FSTSortOrder *orderBy in self.sortOrders) {
    [canonicalID appendString:orderBy.canonicalID];
  }

  // Add limit.
  if (self.limit != NSNotFound) {
    [canonicalID appendFormat:@"|l:%ld", (long)self.limit];
  }

  if (self.startAt) {
    [canonicalID appendFormat:@"|lb:%@", self.startAt.canonicalString];
  }

  if (self.endAt) {
    [canonicalID appendFormat:@"|ub:%@", self.endAt.canonicalString];
  }

  _canonicalID = canonicalID;
  return canonicalID;
}

#pragma mark - Private methods

- (BOOL)isEqualToQuery:(FSTQuery *)other {
  return [self.path isEqual:other.path] && self.limit == other.limit &&
         [self.filters isEqual:other.filters] && [self.sortOrders isEqual:other.sortOrders] &&
         (self.startAt == other.startAt || [self.startAt isEqual:other.startAt]) &&
         (self.endAt == other.endAt || [self.endAt isEqual:other.endAt]);
}

/* Returns YES if the document matches the path for the receiver. */
- (BOOL)pathMatchesDocument:(FSTDocument *)document {
  FSTResourcePath *documentPath = document.key.path;
  if ([FSTDocumentKey isDocumentKey:self.path]) {
    // Exact match for document queries.
    return [self.path isEqual:documentPath];
  } else {
    // Shallow ancestor queries by default.
    return [self.path isPrefixOfPath:documentPath] && self.path.length == documentPath.length - 1;
  }
}

/**
 * A document must have a value for every ordering clause in order to show up in the results.
 */
- (BOOL)orderByMatchesDocument:(FSTDocument *)document {
  for (FSTSortOrder *orderBy in self.explicitSortOrders) {
    FSTFieldPath *fieldPath = orderBy.field;
    // order by key always matches
    if (![fieldPath isEqual:[FSTFieldPath keyFieldPath]] &&
        [document fieldForPath:fieldPath] == nil) {
      return NO;
    }
  }
  return YES;
}

/** Returns YES if the document matches all of the filters in the receiver. */
- (BOOL)filtersMatchDocument:(FSTDocument *)document {
  for (id<FSTFilter> filter in self.filters) {
    if (![filter matchesDocument:document]) {
      return NO;
    }
  }
  return YES;
}

- (BOOL)boundsMatchDocument:(FSTDocument *)document {
  if (self.startAt && ![self.startAt sortsBeforeDocument:document usingSortOrder:self.sortOrders]) {
    return NO;
  }
  if (self.endAt && [self.endAt sortsBeforeDocument:document usingSortOrder:self.sortOrders]) {
    return NO;
  }
  return YES;
}

@end

NS_ASSUME_NONNULL_END
