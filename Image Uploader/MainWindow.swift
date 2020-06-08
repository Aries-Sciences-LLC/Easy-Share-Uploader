//
//  MainWindow.swift
//  Image Uploader
//
//  Created by Ozan Mirza on 3/9/19.
//  Copyright © 2019 Ozan Mirza. All rights reserved.
//

import Cocoa

var loadCount : Int = 0

class MainWindow: NSWindowController, NSWindowDelegate {
    
    override func windowDidLoad() {
        super.windowDidLoad()
        
        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
        
        //        [WAYTheDarkSide welcomeApplicationWithBlock:^{
        //            [weakSelf.window setAppearance:[NSAppearance appearanceNamed:NSAppearanceNameVibrantDark]];
        //            [weakSelf.contentView setMaterial:NSVisualEffectMaterialDark];
        //            [self.label setStringValue:@"Dark!"];
        //        } immediately:YES];
        
        window?.styleMask.insert(.fullSizeContentView)
        window?.appearance = NSAppearance(named: NSAppearance.Name.accessibilityHighContrastVibrantDark)
        window?.isMovableByWindowBackground = true
        window?.hasShadow = false
        window?.invalidateShadow()
        
        window?.minSize = (window?.contentViewController?.view.frame.size)!
        
        window!.delegate = self
    }
    
    func windowDidResize(_ notification: Notification) {
        if loadCount > 0 {
            (self.contentViewController! as? ViewController)!.resizeSubviews()
        } else {
            loadCount += 1
        }
    }
}

class CameraWindow: NSWindowController {
    
    override func windowDidLoad() {
        super.windowDidLoad()
        
        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
        
        //        [WAYTheDarkSide welcomeApplicationWithBlock:^{
        //            [weakSelf.window setAppearance:[NSAppearance appearanceNamed:NSAppearanceNameVibrantDark]];
        //            [weakSelf.contentView setMaterial:NSVisualEffectMaterialDark];
        //            [self.label setStringValue:@"Dark!"];
        //        } immediately:YES];
        
        window?.styleMask.insert(.fullSizeContentView)
        window?.isMovableByWindowBackground = true
        window?.appearance = NSAppearance(named: NSAppearance.Name.vibrantDark)
        window?.hasShadow = false
        window?.invalidateShadow()
    }
}

class HistoryWindow: NSWindowController {
    
    override func windowDidLoad() {
        super.windowDidLoad()
        
        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
        
        //        [WAYTheDarkSide welcomeApplicationWithBlock:^{
        //            [weakSelf.window setAppearance:[NSAppearance appearanceNamed:NSAppearanceNameVibrantDark]];
        //            [weakSelf.contentView setMaterial:NSVisualEffectMaterialDark];
        //            [self.label setStringValue:@"Dark!"];
        //        } immediately:YES];
        
        window?.styleMask.insert(.fullSizeContentView)
        window?.isMovableByWindowBackground = true
        window?.appearance = NSAppearance(named: NSAppearance.Name.vibrantDark)
        window?.hasShadow = false
        window?.invalidateShadow()
    }
}

extension NSBitmapImageRep {
    var png: Data? {
        return representation(using: .png, properties: [:])
    }
    var jpeg: Data? {
        return representation(using: .jpeg, properties: [:])
    }
}
extension Data {
    var bitmap: NSBitmapImageRep? {
        return NSBitmapImageRep(data: self)
    }
}
extension NSImage {
    var png: Data? {
        return tiffRepresentation?.bitmap?.png
    }
    var jpeg: Data? {
        return tiffRepresentation?.bitmap?.jpeg
    }
    func savePNG(to url: URL) -> Bool {
        do {
            try png?.write(to: url)
            return true
        } catch {
            print(error)
            return false
        }
        
    }
}

class GradientButton: NSButton {
    let gradientLayer = CAGradientLayer()
    
    @IBInspectable var topGradientColor: NSColor?
    @IBInspectable var bottomGradientColor: NSColor?
    
    public func setGradient(topGradientColor: NSColor?, bottomGradientColor: NSColor?) {
        if let topGradientColor = topGradientColor, let bottomGradientColor = bottomGradientColor {
            gradientLayer.frame = NSRect(x: 0, y: 0, width: NSScreen.main!.frame.size.width, height: self.bounds.size.height)
            gradientLayer.locations = [0.0, 1.0]
            gradientLayer.colors = [topGradientColor.cgColor, bottomGradientColor.cgColor]
            gradientLayer.borderColor = self.layer!.borderColor
            gradientLayer.borderWidth = self.layer!.borderWidth
            gradientLayer.cornerRadius = self.layer!.cornerRadius
            self.layer!.insertSublayer(gradientLayer, at: 0)
        } else {
            gradientLayer.removeFromSuperlayer()
        }
    }
}
