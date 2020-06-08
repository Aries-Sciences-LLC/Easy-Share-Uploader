//
//  HistoryViewController.swift
//  Image Uploader
//
//  Created by Ozan Mirza on 4/1/19.
//  Copyright © 2019 Ozan Mirza. All rights reserved.
//

import Cocoa

var history_data : [History]!

public class History : NSObject {
    public var image: NSImage!
    public var link: String
    
    public init(image: NSImage, link: String) {
        self.image = image
        self.link = link
    }
}

class HistoryViewController: NSViewController, NSSharingServicePickerDelegate {
    
    @IBOutlet weak var cancel: GradientButton!
    @IBOutlet weak var cell: NSView!
    @IBOutlet weak var listView: NSScrollView!
    @IBOutlet weak var copiedSuccess: NSImageView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        self.preferredContentSize = self.view.frame.size
        cancel.wantsLayer = true
        cancel.appearance = NSAppearance(named: .darkAqua)
        cancel.setGradient(topGradientColor: cancel.topGradientColor, bottomGradientColor: cancel.bottomGradientColor)
        cancel.layer?.cornerRadius = 20
        cancel.layer?.borderColor = NSColor.lightGray.withAlphaComponent(0.75).cgColor
        cancel.layer?.borderWidth = 5
        cancel.layer?.masksToBounds = true
        
        if history_data!.count == 0 {
            listView.alphaValue = 0
        } else {
            
            cell.wantsLayer = true
            cell.layer!.cornerRadius = 25
            cell.layer!.backgroundColor = NSColor.lightGray.withAlphaComponent(0.6).cgColor
            cell.layer!.borderWidth = 5
            cell.layer!.borderColor = NSColor.darkGray.cgColor
            
            (cell.subviews[1] as? NSTextField)!.wantsLayer = true
            (cell.subviews[1] as? NSTextField)!.layer!.backgroundColor = NSColor.clear.cgColor
            cell.subviews[1].appearance = NSAppearance(named: NSAppearance.Name.darkAqua)
            
            self.view.subviews[1].alphaValue = 0.0
            listView.hasVerticalScroller = true
            (cell.subviews[0] as? NSImageView)?.image = history_data[0].image
            (cell.subviews[1] as? NSTextField)?.stringValue = history_data[0].link
            for i in 1..<history_data.count {
                let temp = NSKeyedUnarchiver.unarchiveObject(with: NSKeyedArchiver.archivedData(withRootObject: cell)) as? NSView
                temp!.frame.origin.y = listView.documentView!.frame.size.height - (temp!.frame.size.height * CGFloat(i)) - temp!.frame.size.height - 17.5
                listView.documentView!.addSubview(temp!)
                if temp!.frame.origin.y < 0 {
                    listView.documentView!.frame.size.height += temp!.frame.size.height
                }
                (temp!.subviews[0] as? NSImageView)!.image = history_data[i].image
                (temp!.subviews[1] as? NSTextField)!.stringValue = history_data[i].link
            }
            
            listView.scroll(NSPoint(x: 0, y: listView.frame.size.height))
        }
    }
    
    @IBAction func cancel(_ sender: NSButton!) {
        dismiss(self)
    }
    
    @IBAction func remove(_ sender: NSButton!) {
        for i in 0..<history_data!.count {
            let current_history = History(image: (sender.superview!.subviews[0] as? NSImageView)!.image!, link: (sender.superview!.subviews[1] as? NSTextField)!.stringValue)
            if history_data[i].image == current_history.image && history_data[i].link == current_history.link {
                history_data.remove(at: i)
                break
            }
        }
        
        NSAnimationContext.beginGrouping()
        NSAnimationContext.current.duration = 1.0
        sender.superview!.animator().frame.origin.x = self.view.frame.size.width
        NSAnimationContext.endGrouping()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            if history_data!.count == 0 {
                NSAnimationContext.beginGrouping()
                NSAnimationContext.current.duration = 1.0
                self.view.subviews[1].animator().alphaValue = 1.0
                NSAnimationContext.endGrouping()
            }
            
            var passed = false
            for subview in self.listView.documentView!.subviews {
                if passed {
                    NSAnimationContext.beginGrouping()
                    NSAnimationContext.current.duration = 1.0
                    subview.animator().frame.origin.y += 125
                    NSAnimationContext.endGrouping()
                }
                
                if subview == sender.superview! {
                    passed = true
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: {
                if self.listView.documentView!.frame.size.height > 462 {
                    self.listView.documentView!.frame.size.height -= sender.superview!.frame.size.height
                }
            })
        }
    }
    
    @IBAction func copy(_ sender: NSButton!) {
        let sharingPicker = NSSharingServicePicker(items: [(sender.superview!.subviews[1] as? NSTextField)!.stringValue, (sender.superview!.subviews[0] as? NSImageView)!.image!])
        sharingPicker.delegate = self
        sharingPicker.show(relativeTo: NSZeroRect, of: sender, preferredEdge: .minY)
    }
    
    func setClipboard(text: String) {
        let clipboard = NSPasteboard.general
        clipboard.clearContents()
        clipboard.setString(text, forType: .string)
    }
    
    func sharingServicePicker(_ sharingServicePicker: NSSharingServicePicker, sharingServicesForItems items: [Any], proposedSharingServices proposedServices: [NSSharingService]) -> [NSSharingService] {
        guard let image = NSImage(named: NSImage.Name("copy")) else {
            return proposedServices
        }
        
        var share = proposedServices
        let customService = NSSharingService(title: "Copy Text", image: image, alternateImage: image, handler: {
            if let text = items.first as? String {
                self.setClipboard(text: text)
            }
        })
        share.insert(customService, at: 0)
        
        return share
    }
}
