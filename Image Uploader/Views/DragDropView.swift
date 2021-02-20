//
//  DragDropView.swift
//  Image Uploader
//
//  Created by Ozan Mirza on 3/10/19.
//  Copyright © 2019 Ozan Mirza. All rights reserved.
//

import Cocoa

protocol DropViewDelegate {
    func fileWasCopied(_ dropView: DropView)
}

class DropView: LayerBackedView {
    
    var filePath: String?
    let expectedExt = ["jpg" ,"png", "jpeg", "bmp", "pdf", "docx", "gif", "pct"]
    
    var delegate: DropViewDelegate?
    
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
        
        scale(size: 20)
        fade()
        
        if checkExtension(sender) == true {
            return .copy
        } else {
            shake()
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
        backToNormal()
    }
    
    override func draggingEnded(_ sender: NSDraggingInfo) {
        backToNormal()
    }
    
    func backToNormal() {
        scale(size: -20)
        fade(to: 1.0)
    }
    
    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        guard let pasteboard = sender.draggingPasteboard.propertyList(forType: NSPasteboard.PasteboardType(rawValue: "NSFilenamesPboardType")) as? NSArray,
            let path = pasteboard[0] as? String
            else { return false }
        
        self.filePath = path
        
        guard let delegate = delegate else {
            return true
        }
        
        delegate.fileWasCopied(self)
        
        return true
    }
}
