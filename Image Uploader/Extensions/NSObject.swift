//
//  NSObject.swift
//  Easy Share Uploader
//
//  Created by Ozan Mirza on 1/12/21.
//  Copyright © 2021 Aries Sciences LLC. All rights reserved.
//

import Cocoa

extension NSObject {
    func addToClipboard(_ item: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.declareTypes([.string], owner: nil)
        pasteboard.setString(item, forType: .string)
    }
}
