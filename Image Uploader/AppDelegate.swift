//
//  AppDelegate.swift
//  Image Uploader
//
//  Created by Ozan Mirza on 3/9/19.
//  Copyright © 2019 Ozan Mirza. All rights reserved.
//

import Cocoa
import FirebaseCore
import SwiftyDropbox

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    lazy var windows = MainWindow()
    
    let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    
    @objc func handleGetURLEvent(_ event: NSAppleEventDescriptor?, replyEvent: NSAppleEventDescriptor?) {
        if let aeEventDescriptor = event?.paramDescriptor(forKeyword: AEKeyword(keyDirectObject)) {
            if let urlStr = aeEventDescriptor.stringValue {
                let url = URL(string: urlStr)!
                if let authResult = DropboxClientsManager.handleRedirectURL(url) {
                    switch authResult {
                    case .success:
                        uploadService.upload(uploadType: .Dropbox, credentials: nil)
                    case .cancel:
                        print("Authorization flow was manually canceled by user!")
                    case .error(_, let description):
                        print("Error: \(description)")
                    }
                }
                // this brings your application back the foreground on redirect
                NSApp.activate(ignoringOtherApps: true)
            }
        }
    }
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        
        let icon = NSImage(named: "StatusIcon")
        icon?.isTemplate = true // best for dark mode
        // statusItem.button!.image = icon
        // statusItem.button!.action = #selector(openWindow(_:))
        
        if !UserDefaults.standard.bool(forKey: "InitialRun") {
            showHelp(self)
            UserDefaults.standard.set(true, forKey: "InitialRun")
        }
        
        FirebaseApp.configure()
        DropboxClientsManager.setupWithAppKeyDesktop("cykaqpqkndira6x")
        Backendless.sharedInstance()?.initApp("4FC0B105-33FD-21C5-FFD2-D4BDD2D64300", apiKey: "5A61560E-C220-3385-FFA7-C29CF05B4A00")
        
        history_data = UserDefaults.standard.value(forKey: "History_Data") as? [History]
        if history_data == nil {
            history_data = []
        }
        
        NSAppleEventManager.shared().setEventHandler(self,
                                                     andSelector: #selector(handleGetURLEvent),
                                                     forEventClass: AEEventClass(kInternetEventClass),
                                                     andEventID: AEEventID(kAEGetURL))
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
        UserDefaults.standard.set(history_data, forKey: "History_Data")
    }
    
    func application(_ sender: NSApplication, openFile filename: String) -> Bool {
        _ = applicationShouldHandleReopen(sender, hasVisibleWindows: sender.keyWindow != nil)
        (sender.keyWindow!.contentViewController as? ViewController)!.quickUpload(with: filename)
        
        return true
    }
    
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            for window in sender.windows {
                window.makeKeyAndOrderFront(self)
            }
        }
        
        return true
    }
    
    @IBAction func showHelp(_ sender: Any!) {
        OpenHelpWindowController().showWindow(self)
    }
    
    @IBAction func openFile(_ sender: Any!) {
        (NSApp.keyWindow!.contentViewController as? ViewController)!.uploadPicture(NSButton())
    }
    
    @objc func openWindow(_ sender: NSButton) {
        _ = applicationShouldHandleReopen(NSApp, hasVisibleWindows: NSApp!.keyWindow != nil)
        openFile(sender)
    }
    
    @IBAction func openSettingsPanel(_ sender: Any!) {
        NSApp.keyWindow?.contentViewController!.presentAsSheet(NSApp.keyWindow?.contentViewController!.storyboard!.instantiateController(withIdentifier: "SettingsPanel") as! NSViewController)
    }
}
