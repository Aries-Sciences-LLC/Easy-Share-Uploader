//
//  NSAlert.swift
//  Easy Share Uploader
//
//  Created by Ozan Mirza on 2/5/21.
//  Copyright © 2021 Aries Sciences LLC. All rights reserved.
//

import Cocoa

extension NSAlert {
    static func informative(_ title: String? = nil, _ message: String? = nil, _ callback: ((NSApplication.ModalResponse) -> Void)? = nil) {
        let alert = NSAlert()
        alert.messageText = title ?? ""
        alert.informativeText = message ?? ""
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.beginSheetModal(for: NSApp.windows.first!) {
            callback?($0)
        }
    }
    
    static func warning(_ title: String? = nil, _ message: String? = nil, _ callback: ((NSApplication.ModalResponse) -> Void)? = nil) {
        let alert = NSAlert()
        alert.messageText = title ?? ""
        alert.informativeText = message ?? ""
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        alert.addButton(withTitle: "Cancel")
        alert.beginSheetModal(for: NSApp.windows.first!) {
            callback?($0)
        }
    }
}
