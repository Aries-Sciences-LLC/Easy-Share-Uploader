//
//  HelpWindow.swift
//  Image Uploader
//
//  Created by Ozan Mirza on 7/13/19.
//  Copyright © 2019 Ozan Mirza. All rights reserved.
//

import Cocoa
import WebKit

class OpenHelpWindowController: NSWindowController, NSWindowDelegate {
    convenience init() {
        // Creating Standard window
        self.init(window: NSWindow(contentRect: NSRect(x: 0, y: 0, width: 650, height: 600), styleMask: [.titled, .fullSizeContentView, .closable, .miniaturizable, .resizable], backing: .buffered, defer: false))
        window!.delegate = self // Manipulating the window
        window!.contentViewController = OpeningHelpViewController() // Content inside window
        // Styling the window
        window!.titleVisibility = .hidden
        window!.titlebarAppearsTransparent = true
        window!.hasShadow = false
        window!.invalidateShadow()
        
        // Customizing properties for interation
        window!.center()
        window!.isMovableByWindowBackground = true
        window!.isOpaque = false
        window!.backgroundColor = NSColor.clear
        
        // Lowering buttons
        let customToolbar = NSToolbar()
        customToolbar.showsBaselineSeparator = false
        window!.toolbar = customToolbar
    }
}

class OpeningHelpViewController: NSViewController {
    override func loadView() {
        self.view = NSView(frame: NSRect(x: 0, y: 0, width: 650, height: 600))
        self.view.wantsLayer = true
        self.view.layer!.backgroundColor = NSColor.white.cgColor
    }
    
    override func viewDidLoad() {
        let mainView = WKWebView(frame: NSRect(x: 20, y: 20, width: 610, height: 540))
        mainView.load(URLRequest(url: URL(fileURLWithPath: Bundle.main.path(forResource: "index", ofType: "html")!)))
        mainView.wantsLayer = true
        mainView.layer!.cornerRadius = 20
        
        self.view.addSubview(mainView)
    }
}
