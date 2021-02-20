//
//  Date.swift
//  Image Uploader
//
//  Created by Ozan Mirza on 1/7/21.
//  Copyright © 2021 Ozan Mirza. All rights reserved.
//

import Cocoa

extension Data {
    var bitmap: NSBitmapImageRep? {
        return NSBitmapImageRep(data: self)
    }
}
