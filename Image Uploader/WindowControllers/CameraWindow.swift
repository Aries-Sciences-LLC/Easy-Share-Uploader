//
//  CameraWindpow.swift
//  Image Uploader
//
//  Created by Ozan Mirza on 1/7/21.
//  Copyright © 2021 Ozan Mirza. All rights reserved.
//

import Cocoa

class CameraWindow: NSWindowController {
    
    override func windowDidLoad() {
        super.windowDidLoad()
        
        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
        
        //        [WAYTheDarkSide welcomeApplicationWithBlock:^{
        //            [weakSelf.window setAppearance:[NSAppearance appearanceNamed:NSAppearanceNameVibrantDark]];
        //            [weakSelf.contentView setMaterial:NSVisualEffectMaterialDark];
        //            [self.label setStringValue:@"Dark!"];
        //        } immediately:YES];
        
//        window?.styleMask.insert(.fullSizeContentView)
//        window?.isMovableByWindowBackground = true
//        window?.appearance = NSAppearance(named: NSAppearance.Name.vibrantDark)
//        window?.hasShadow = false
//        window?.invalidateShadow()
        
        let toolbar = NSToolbar()
        toolbar.showsBaselineSeparator = false
        window?.toolbar = toolbar
    }
}
