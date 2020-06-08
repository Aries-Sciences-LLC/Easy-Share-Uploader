//
//  DragDropView.swift
//  Image Uploader
//
//  Created by Ozan Mirza on 3/10/19.
//  Copyright © 2019 Ozan Mirza. All rights reserved.
//

import Cocoa

class DropView: NSView {
    
    var filePath: String?
    let expectedExt = ["jpg" ,"png", "jpeg", "bmp"]  //file extensions allowed for Drag&Drop (example: "jpg","png","docx", etc..)
    var callback : (String) -> Void = { file in }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        self.wantsLayer = true
        self.layer?.backgroundColor = NSColor.gray.cgColor
        
        registerForDraggedTypes([NSPasteboard.PasteboardType.URL, NSPasteboard.PasteboardType.fileURL])
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        // Drawing code here.
    }
    
    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        NSCursor.dragCopy.set()
        self.layer?.borderColor = NSColor(red: (66 / 255), green: (244 / 255), blue: (178 / 255), alpha: 1).cgColor
        self.layer?.borderWidth = 5
        self.layer?.backgroundColor = NSColor(red: (66 / 255), green: (244 / 255), blue: (178 / 255), alpha: 0.5).cgColor
        if checkExtension(sender) == true {
            return .copy
        } else {
            self.displayError()
            return NSDragOperation()
        }
    }
    
    fileprivate func checkExtension(_ drag: NSDraggingInfo) -> Bool {
        guard let board = drag.draggingPasteboard.propertyList(forType: NSPasteboard.PasteboardType(rawValue: "NSFilenamesPboardType")) as? NSArray,
            let path = board[0] as? String
            else { return false }
        
        let suffix = URL(fileURLWithPath: path).pathExtension
        for ext in self.expectedExt {
            if ext.lowercased() == suffix {
                return true
            }
        }
        return false
    }
    
    override func draggingExited(_ sender: NSDraggingInfo?) {
        self.layer?.backgroundColor = NSColor.darkGray.cgColor
        self.layer?.borderWidth = 2
        self.layer?.borderColor = NSColor.lightGray.cgColor
    }
    
    override func draggingEnded(_ sender: NSDraggingInfo) {
        self.layer?.backgroundColor = NSColor.darkGray.cgColor
        self.layer?.borderWidth = 2
        self.layer?.borderColor = NSColor.lightGray.cgColor
    }
    
    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        guard let pasteboard = sender.draggingPasteboard.propertyList(forType: NSPasteboard.PasteboardType(rawValue: "NSFilenamesPboardType")) as? NSArray,
            let path = pasteboard[0] as? String
            else { return false }
        
        //GET YOUR FILE PATH !!!
        self.filePath = path
        self.callback(path)
        
        return true
    }
    
    fileprivate func displayError() {
        self.shake()
        self.layer!.borderWidth = 5
        let color = CABasicAnimation(keyPath: "borderColor")
        color.fromValue = self.layer!.borderColor!
        color.toValue = NSColor(red: (244 / 255), green: (66 / 255), blue: (66 / 255), alpha: 0.5).cgColor
        color.duration = 1.0
        self.layer!.add(color, forKey: "borderColor")
        let colourAnim = CABasicAnimation(keyPath: "backgroundColor")
        colourAnim.fromValue = self.layer!.backgroundColor
        colourAnim.toValue = NSColor(red: (244 / 255), green: (66 / 255), blue: (66 / 255), alpha: 0.5).cgColor
        colourAnim.duration = 1.0
        self.layer!.add(colourAnim, forKey: "colorAnimation")
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1.0) {
            self.layer!.borderWidth = 5
            self.layer!.borderColor = NSColor(red: (244 / 255), green: (66 / 255), blue: (66 / 255), alpha: 0.5).cgColor
            self.layer!.backgroundColor = NSColor(red: (244 / 255), green: (66 / 255), blue: (66 / 255), alpha: 0.5).cgColor
            
            let txt = NSTextField(frame: NSRect(x: 20, y: self.frame.size.height - 110, width: self.frame.size.width - 40, height: 75))
            txt.textColor = NSColor.white
            txt.stringValue = "Uh-Oh, looks like that file isn't an image."
            txt.font = NSFont.systemFont(ofSize: 15)
            txt.isEditable = false
            txt.drawsBackground = false
            txt.isBezeled = false
            txt.isBordered = false
            txt.alignment = NSTextAlignment.center
            txt.alphaValue = 0.0
            self.addSubview(txt)
            
            NSAnimationContext.beginGrouping()
            NSAnimationContext.current.duration = 1.0
            txt.animator().alphaValue = 1.0
            NSAnimationContext.endGrouping()
        }
    }
}

extension NSView {
    
    func shake(with intensity : CGFloat = 0.05, duration : Double = 0.5 ){
        let numberOfShakes      = 3
        let frame : CGRect = self.frame
        let shakeAnimation :CAKeyframeAnimation  = CAKeyframeAnimation()
        
        let shakePath = CGMutablePath()
        shakePath.move(to: CGPoint(x:NSMinX(frame),y:NSMinY(frame)))
        
        for _ in 0...numberOfShakes-1 {
            shakePath.addLine(to: CGPoint(x:NSMinX(frame) - frame.size.width * intensity,y:NSMinY(frame)))
            shakePath.addLine(to: CGPoint(x:NSMinX(frame) + frame.size.width * intensity,y:NSMinY(frame)))
        }
        
        shakePath.closeSubpath()
        shakeAnimation.path = shakePath
        shakeAnimation.duration = duration
        
        self.animations = ["frameOrigin":shakeAnimation]
        self.animator().setFrameOrigin(self.frame.origin)
    }
}
