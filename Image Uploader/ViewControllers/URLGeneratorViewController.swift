//
//  URLGeneratorViewController.swift
//  Image Uploader
//
//  Created by Ozan Mirza on 1/8/21.
//  Copyright © 2021 Ozan Mirza. All rights reserved.
//

import Cocoa
import anim

protocol URLGeneratorViewControllerDelegate {
    func linkWasSelected(_ link: URL)
    func imageToUpload() -> NSImage
}

class URLGeneratorViewController: NSViewController {

    @IBOutlet weak var URLDisplay: NSTextField!
    @IBOutlet weak var actionSpinner: NSProgressIndicator!
    
    private var service: UploadService!
    
    var delegate: URLGeneratorViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        service = UploadService() { url in
            DispatchQueue.main.async {
                if url == "Error Making URL" {
                    self.refreshLink(self)
                } else {
                    self.view.fade(to: 1.0)
                    self.actionSpinner.stopAnimation(nil)
                    self.URLDisplay.stringValue = url
                }
            }
        }
        
        refreshLink(self)
    }
    
    @IBAction func copyToClipboard(_ sender: Any) {
        guard URLDisplay.stringValue.count > 0 && URLDisplay.stringValue != "Error Making URL" else { return }
        
        addToClipboard(URLDisplay.stringValue)
    }
    
    @IBAction func refreshLink(_ sender: Any) {
        guard let delegate = delegate else { return }
        
        view.fade(to: 0.0)
        actionSpinner.startAnimation(nil)
        service.mainImage = delegate.imageToUpload()
    }
    
    @IBAction func saveLink(_ sender: Any) {
        guard let delegate = delegate else { return }
        guard URLDisplay.stringValue.count > 0 && URLDisplay.stringValue != "Error Making URL" else { return }
        
        delegate.linkWasSelected(URL(string: URLDisplay.stringValue)!)
        dismiss(self)
    }
    
    @IBAction func openLinkinDefaultBrowser(_ sender: Any) {
        guard URLDisplay.stringValue.count > 0 && URLDisplay.stringValue != "Error Making URL" else { return }
        
        NSWorkspace.shared.open(URL(string: URLDisplay.stringValue)!)
    }
    
    @IBAction func tbCopyToClipboard(_ sender: Any) {
        copyToClipboard(sender)
    }
    
    @IBAction func tbRefreshLink(_ sender: Any) {
        refreshLink(sender)
    }
    
    @IBAction func tbSaveLink(_ sender: Any) {
        saveLink(sender)
    }
    
    @IBAction func tbOpenLinkinDefaultBrowser(_ sender: Any) {
        openLinkinDefaultBrowser(sender)
    }
}
