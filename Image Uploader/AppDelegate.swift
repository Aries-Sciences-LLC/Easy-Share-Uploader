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
import Backendless

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    lazy var windows = MainWindow()
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        
        FirebaseApp.configure()
        DropboxClientsManager.setupWithAppKeyDesktop("alzhwtp0a8xg6xv")
        Backendless.shared.initApp(applicationId: "4FC0B105-33FD-21C5-FFD2-D4BDD2D64300", apiKey: "5A61560E-C220-3385-FFA7-C29CF05B4A00")
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
//        UserDefaults.standard.set(history_data, forKey: "History_Data")
        
        UserImages.standard.save()
    }
    
    func application(_ sender: NSApplication, openFile filename: String) -> Bool {
        _ = applicationShouldHandleReopen(sender, hasVisibleWindows: sender.keyWindow != nil)
//        (sender.keyWindow!.contentViewController as? ViewController)!.quickUpload(with: filename)
        
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
}
