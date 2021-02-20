//
//  Collection.swift
//  Easy Share Uploader
//
//  Created by Ozan Mirza on 2/2/21.
//  Copyright © 2021 Aries Sciences LLC. All rights reserved.
//

import Foundation

extension Collection where Indices.Iterator.Element == Index {
    subscript (safe index: Index) -> Iterator.Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
