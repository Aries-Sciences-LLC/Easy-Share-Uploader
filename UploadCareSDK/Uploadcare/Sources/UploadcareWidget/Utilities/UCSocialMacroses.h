//
//  UCSocialMacroses.h
//  ExampleProject
//
//  Created by Yury Nechaev on 06.04.16.
//  Copyright © 2016 Uploadcare. All rights reserved.
//

#define SetIfNotNull(a,b) {a = [b isKindOfClass:[NSNull class]] ? nil : b;}

#define UCAbstractAssert {NSAssert(NO, @"You should override %@ method", NSStringFromSelector(_cmd));}