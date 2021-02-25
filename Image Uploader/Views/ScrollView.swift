//
//  ScrollView.swift
//  Easy Share Uploader
//
//  Created by Ozan Mirza on 1/12/21.
//  Copyright © 2021 Aries Sciences LLC. All rights reserved.
//

import Cocoa
import anim

protocol ScrollViewDelegate {
    func updatedScroll(_ visibleItem: ImageFile?)
}

class ScrollView: NSScrollView {
    
    var currentPage: CGFloat = 0
    var maxPageIndex: Int!
    var minPageIndex: Int!
    var spacing: CGFloat!
    var proportion: CGFloat!
    
    var inSession = false
    
    var delegate: ScrollViewDelegate?
    
    override var acceptsFirstResponder: Bool {
        return true
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Drawing code here.
    }
    
    override func keyDown(with event: NSEvent) {
        switch event.keyCode {
        case Keycode.upArrow:
            scrollPageUp(nil)
        case Keycode.downArrow:
            scrollPageDown(nil)
        case Keycode.returnKey:
            guard let vc = window?.contentViewController as? ViewController else { return }
            if currentPage == 0 {
                vc.openFileBrowser(self)
            } else {
                vc.copyFileLink(self)
            }
        default:
            return
        }
    }
    
    override func scrollWheel(with event: NSEvent) {
        if event.deltaY != 0 {
            if !inSession {
                if event.deltaY < 0 {
                    scrollPageDown(self)
                } else {
                    scrollPageUp(self)
                }
                
                inSession = true
                Timer.scheduledTimer(withTimeInterval: 1, repeats: false) { _ in
                    self.inSession = false
                }
            }
        }
    }
    
    override func scrollPageUp(_ sender: Any?) {
        if currentPage > CGFloat(minPageIndex ?? 0) {
            currentPage -= 1
            updateVisibleBounds()
        }
    }
    
    override func scrollPageDown(_ sender: Any?) {
        if currentPage < CGFloat(maxPageIndex - 1) {
            currentPage += 1
            updateVisibleBounds()
        }
    }
    
    override func scrollToBeginningOfDocument(_ sender: Any?) {
        currentPage = CGFloat(minPageIndex ?? 0)
        updateVisibleBounds()
    }
    
    override func scrollToEndOfDocument(_ sender: Any?) {
        currentPage = CGFloat(maxPageIndex - 1)
        updateVisibleBounds()
    }
    
    func manualScroll(to index: Int) {
        guard index > minPageIndex && index < maxPageIndex else { return }
        currentPage = CGFloat(index)
        updateVisibleBounds()
    }
    
    func updateVisibleBounds() {
        let offset = ((currentPage * (0.5 * contentView.bounds.height)) + (37.5 * currentPage)) + (75 * (currentPage / 10))
            .clamped(to: 0...documentView!.bounds.height)
        anim { (settings) -> (animClosure) in
            settings.duration = 0.35
            return {
                self.documentView?.animator().frame.origin.y = offset
            }
        }.callback {
            guard let delegate = self.delegate else { return }
            guard let item = self.documentView?.subviews[safe: Int(self.currentPage)] else { return }
            delegate.updatedScroll((item as? ImageFileItem)?.data)
        }
    }
    
    // I know, it definetly could've done way better with being more modular and stuff, but could you blame me? Why waste the time?
    // Actually that was a stupid question of course there is a huge reason to try to make code perfect no matter what. I'll focus on it later I'm on a schedule.
    func loadImageFiles() {
        let count = UserImages.standard.images.count
        
        maxPageIndex = count + 1
        minPageIndex = 0
        spacing = 50
        proportion = 0.65
        
        documentView?.frame.size.height = contentView.bounds.height * CGFloat(count)
        documentView?.subviews.forEach({ if $0 is ImageFileItem { $0.removeFromSuperview() } })
        documentView?.scroll(CGPoint(x: 0, y: documentView?.bounds.height ?? 0))
        
        for (index, item) in UserImages.standard.images.enumerated() {
            let itemView = ImageFileItem(count: index, proportion: proportion, contents: item)
            
            let superview = documentView!
            let prevItem = documentView!.subviews.last!
            superview.addSubview(itemView)
            
            NSLayoutConstraint.activate([
                itemView.widthAnchor.constraint(equalTo: prevItem.widthAnchor),
                itemView.heightAnchor.constraint(equalTo: prevItem.heightAnchor),
                itemView.centerXAnchor.constraint(equalTo: superview.centerXAnchor),
//                itemView.topAnchor.constraint(equalTo: prevItem.bottomAnchor, constant: filesView.spacing)
            ])
        }
        
        if count == 0 {
            documentView?.frame.size.height = 1.75 * (contentView.bounds.width * proportion)
        }
    }
    
//    override func resizeSubviews(withOldSize oldSize: NSSize) {
//        super.resizeSubviews(withOldSize: oldSize)
//
//        documentView?.subviews.forEach {
//            if $0 is ImageFileItem {
//                ($0 as! ImageFileItem).resize()
//                ($0 as! ImageFileItem).configure()
//            }
//        }
//    }
}
