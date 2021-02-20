//
//  HoverableButton.swift
//  Image Uploader
//
//  Created by Ozan Mirza on 1/10/21.
//  Copyright © 2021 Ozan Mirza. All rights reserved.
//

import Cocoa

class HoverableButton: NSButton {
    
    override func awakeFromNib() {
        addTrackingArea(NSTrackingArea(rect: bounds, options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect], owner: self, userInfo: nil))
    }

    override func mouseEntered(with event: NSEvent) {
        scale(size: 10)
        fade()
    }
    
    override func mouseExited(with event: NSEvent) {
        scale(size: -10)
        fade(to: 1.0)
    }
}
