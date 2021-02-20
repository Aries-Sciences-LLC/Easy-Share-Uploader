//
//  NSBitmapImageRep.swift
//  Image Uploader
//
//  Created by Ozan Mirza on 1/7/21.
//  Copyright © 2021 Ozan Mirza. All rights reserved.
//

import Cocoa

extension NSBitmapImageRep {
    var png: Data? {
        return representation(using: .png, properties: [:])
    }
    var jpeg: Data? {
        return representation(using: .jpeg, properties: [:])
    }
}
