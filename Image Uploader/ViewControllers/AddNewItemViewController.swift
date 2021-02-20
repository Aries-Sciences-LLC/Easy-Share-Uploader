//
//  AddNewItemViewController.swift
//  Image Uploader
//
//  Created by Ozan Mirza on 1/8/21.
//  Copyright © 2021 Ozan Mirza. All rights reserved.
//

import Cocoa

protocol AddNewItemControllerDelegate {
    func getImage() -> NSImage
    func getFileName() -> String
    func finishedWriting(with fileName: String, and fileDescription: String)
}

class AddNewItemViewController: NSViewController {
    
    @IBOutlet weak var imageBackground: NSImageView!
    @IBOutlet weak var itemTitle: NSTextField!
    @IBOutlet weak var itemDescription: NSTextField!
    
    var delegate: AddNewItemControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        resigner(self)
        guard let delegate = delegate else { return }
        imageBackground.image = delegate.getImage()
        itemTitle.placeholderString = "\(delegate.getFileName()) (optional)"
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
    }
    
    @IBAction func done(_ sender: Any) {
        guard let delegate = delegate else { return }
        if itemTitle.stringValue == "" {
            delegate.finishedWriting(with: String(delegate.getFileName().prefix(delegate.getFileName().count - 4)), and: itemDescription.stringValue)
        } else {
            delegate.finishedWriting(with: itemTitle.stringValue, and: itemDescription.stringValue)
        }
        
        cancel(sender)
    }
    
    @IBAction func tbDone(_ sender: Any) {
        done(sender)
    }
    
    @IBAction func cancel(_ sender: Any) {
        dismiss(sender)
    }
    
    @IBAction func tbCancel(_ sender: Any) {
        cancel(sender)
    }
    
    @IBAction func resigner(_ sender: Any) {
        DispatchQueue.main.async {
            self.view.window?.makeFirstResponder(nil)
        }
    }
}
