//
//  NSColor.swift
//  Image Uploader
//
//  Created by Ozan Mirza on 1/10/21.
//  Copyright © 2021 Ozan Mirza. All rights reserved.
//

import Cocoa

extension String  {
    func conformsTo(_ pattern: String) -> Bool {
        return NSPredicate(format:"SELF MATCHES %@", pattern).evaluate(with: self)
    }
}

extension NSColor {
    convenience init(hex: Int, alpha: Float) {
        self.init(
            calibratedRed: CGFloat((hex & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((hex & 0xFF00) >> 8) / 255.0,
            blue: CGFloat((hex & 0xFF)) / 255.0,
            alpha: 1.0
        )
    }
    
    convenience init(hex: String, alpha: Float) {
        // Handle two types of literals: 0x and # prefixed
        var cleanedString = ""
        if hex.hasPrefix("0x") {
            cleanedString = String(hex[hex.index(cleanedString.startIndex, offsetBy: 2)..<hex.endIndex])
        } else if hex.hasPrefix("#") {
            cleanedString = String(hex[hex.index(cleanedString.startIndex, offsetBy: 1)..<hex.endIndex])
        }
        
        // Ensure it only contains valid hex characters 0
        let validHexPattern = "[a-fA-F0-9]+"
        if cleanedString.conformsTo(validHexPattern) {
            var value: UInt64 = 0
            Scanner(string: cleanedString).scanHexInt64(&value)
            self.init(hex: Int(value), alpha: 1)
        } else {
            fatalError("Unable to parse color?")
        }
    }
}
