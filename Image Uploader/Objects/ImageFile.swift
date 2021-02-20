//
//  File.swift
//  Image Uploader
//
//  Created by Ozan Mirza on 1/8/21.
//  Copyright © 2021 Ozan Mirza. All rights reserved.
//

import Cocoa

public struct ImageFile: Codable {
    var name: String
    var description: String
    var data: Data
    var link: URL
    var date: Date
    
    var image: NSImage {
        return NSImage(data: data)!
    }
}

