//
//  Math.swift
//  Easy Share Uploader
//
//  Created by Ozan Mirza on 1/12/21.
//  Copyright © 2021 Aries Sciences LLC. All rights reserved.
//

import Foundation

extension Comparable {
    func clamped(to limits: ClosedRange<Self>) -> Self {
        return min(max(self, limits.lowerBound), limits.upperBound)
    }
}

// Swift < 5.1
extension Strideable where Stride: SignedInteger {
    func clamped(to limits: CountableClosedRange<Self>) -> Self {
        return min(max(self, limits.lowerBound), limits.upperBound)
    }
}
