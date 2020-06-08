//
//  ViewController.swift
//  Image Uploader
//
//  Created by Ozan Mirza on 3/9/19.
//  Copyright © 2019 Ozan Mirza. All rights reserved.
//

import Cocoa
import SwiftyDropbox

var mainImage = NSImage()

class ViewController: NSViewController, CameraViewControllerDelegate, NSSharingServicePickerDelegate, NSTextFieldDelegate {
    
    @IBOutlet weak var imageSelector: DropView!
    @IBOutlet weak var errorMessage: NSVisualEffectView!
    @IBOutlet weak var imageReview: NSView!
    @IBOutlet weak var startButton: GradientButton!
    @IBOutlet weak var finishedLink: NSView!
    @IBOutlet weak var loadingIndicator: NSView!
    @IBOutlet weak var loadingWidget: NSProgressIndicator!
    @IBOutlet weak var cameraSelector: NSView!
    @IBOutlet weak var connectionErrorView: NSVisualEffectView!
    @IBOutlet weak var history: GradientButton!
    @IBOutlet weak var copiedSuccess: NSVisualEffectView!
    @IBOutlet weak var helpBtn: NSButton!
    
    var state = false
    var loginState = 0
    let popover = NSPopover()
    var proccess: UploadType = .Google
    var animatedStage: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        cameraSelector.subviews[0].appearance = NSAppearance(named: .darkAqua)
        
        uploadService.callback = { imageURL in
            DispatchQueue.main.async {
                (self.finishedLink.subviews[1] as? NSTextField)!.stringValue = imageURL
                NSAnimationContext.beginGrouping()
                NSAnimationContext.current.duration = 1
                self.loadingIndicator.animator().alphaValue = 0
                self.loadingWidget.animator().alphaValue = 0
                self.loadingWidget.animator().frame.origin.y -= 25
                self.loadingIndicator.animator().frame.origin.y -= 25
                self.finishedLink.animator().alphaValue = 1
                NSAnimationContext.endGrouping()
                history_data.append(History(image: mainImage, link: imageURL))
                self.startButton.title = "Create Another"
                self.state = false
                NSWorkspace.shared.open(URL(string: imageURL)!)
                NSApp.keyWindow?.orderFront(self)
            }
        }
        
        NetworkManager.isReachable { _ in
            self.renderWidgets(resize: false)
        }
        
        NetworkManager.isUnreachable { _ in
            self.displayInternetProblems()
        }
        
        NetworkManager.sharedInstance.reachability.whenUnreachable = { _ in
            self.displayInternetProblems()
        }
        
        NetworkManager.sharedInstance.reachability.whenReachable = { _ in
            self.renderWidgets(resize: true)
        }
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    override func viewDidAppear() {
        if !animatedStage {
            helpBtn.appearance = NSAppearance(named: NSAppearance.Name.darkAqua)
            NSAnimationContext.beginGrouping()
            NSAnimationContext.current.duration = 1.0
            imageSelector.animator().frame.origin.x = 10
            helpBtn.animator().frame.origin.y = 515
            NSAnimationContext.endGrouping()
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.25) {
                NSAnimationContext.beginGrouping()
                NSAnimationContext.current.duration = 1.0
                self.cameraSelector.animator().frame.origin.x = 30
                NSAnimationContext.endGrouping()
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.25) {
                    NSAnimationContext.beginGrouping()
                    NSAnimationContext.current.duration = 1.0
                    self.startButton.animator().frame.origin.y = 30
                    NSAnimationContext.endGrouping()
                    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.25) {
                        self.history.alphaValue = 1.0
                        NSAnimationContext.beginGrouping()
                        NSAnimationContext.current.duration = 1.0
                        self.history.animator().frame.origin.y = 10
                        NSAnimationContext.endGrouping()
                        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.25) {
                            NSAnimationContext.beginGrouping()
                            NSAnimationContext.current.duration = 0.25
                            self.imageSelector.animator().frame.origin.x = 20
                            NSAnimationContext.endGrouping()
                            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.25) {
                                NSAnimationContext.beginGrouping()
                                NSAnimationContext.current.duration = 0.25
                                self.cameraSelector.animator().frame.origin.x = 20
                                NSAnimationContext.endGrouping()
                                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.25) {
                                    NSAnimationContext.beginGrouping()
                                    NSAnimationContext.current.duration = 0.25
                                    self.startButton.animator().frame.origin.y = 20
                                    NSAnimationContext.endGrouping()
                                    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.25) {
                                        NSAnimationContext.beginGrouping()
                                        NSAnimationContext.current.duration = 0.25
                                        self.history.animator().frame.origin.y = 20
                                        NSAnimationContext.endGrouping()
                                        self.animatedStage = true
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    func renderWidgets(resize: Bool) {
        self.connectionErrorView.alphaValue = 0
        self.errorMessage.alphaValue = 0
        
        self.imageSelector.wantsLayer = true
        self.imageSelector.layer?.cornerRadius = 25
        self.imageSelector.layer?.borderColor = NSColor.darkGray.cgColor
        self.imageSelector.layer?.backgroundColor = NSColor.lightGray.cgColor
        self.imageSelector.layer?.borderWidth = 5
        
        self.imageReview.wantsLayer = true
        self.imageReview.layer?.cornerRadius = 15
        self.imageReview.layer?.borderColor = NSColor.lightGray.cgColor
        self.imageReview.layer?.backgroundColor = NSColor.darkGray.cgColor
        self.imageReview.layer?.borderWidth = 5
        self.imageReview.subviews.last!.appearance = NSAppearance(named: NSAppearance.Name.aqua)
        
        self.startButton.wantsLayer = true
        self.startButton.layer?.cornerRadius = 20
        self.startButton.layer?.borderColor = NSColor.lightGray.withAlphaComponent(0.75).cgColor
        self.startButton.layer?.borderWidth = 5
        self.startButton.setGradient(topGradientColor: self.startButton.topGradientColor, bottomGradientColor: self.startButton.bottomGradientColor)
        self.startButton.appearance = NSAppearance(named: NSAppearance.Name.darkAqua)
        
        self.history.wantsLayer = true
        self.history.layer?.cornerRadius = 20
        self.history.layer?.borderColor = NSColor.lightGray.withAlphaComponent(0.75).cgColor
        self.history.layer?.borderWidth = 5
        self.history.setGradient(topGradientColor: self.history.topGradientColor, bottomGradientColor: self.history.bottomGradientColor)
        self.history.appearance = NSAppearance(named: NSAppearance.Name.darkAqua)
        
        self.cameraSelector.wantsLayer = true
        self.cameraSelector.layer?.cornerRadius = 25
        self.cameraSelector.layer?.borderColor = NSColor.lightGray.cgColor
        self.cameraSelector.layer?.backgroundColor = NSColor.darkGray.cgColor
        self.cameraSelector.layer?.borderWidth = 5
        
        self.errorMessage.alphaValue = 0
        self.finishedLink.alphaValue = 0
        self.imageReview.alphaValue = 0
        self.loadingIndicator.alphaValue = 0
        self.loadingWidget.alphaValue = 0
        
        (self.imageSelector.subviews[1] as? NSProgressIndicator)?.maxValue = 100
        (self.imageSelector.subviews[1] as? NSProgressIndicator)?.minValue = 0
        (self.imageSelector.subviews[1] as? NSProgressIndicator)?.appearance = NSAppearance(named: NSAppearance.Name.aqua)
        
        (self.imageSelector.subviews[2] as? NSTextField)?.appearance = NSAppearance(named: .aqua)
        
        self.imageSelector.callback = { file in
            self.convertImage(for: URL(fileURLWithPath: file))
        }
        
        self.copiedSuccess.wantsLayer = true
        self.copiedSuccess.layer!.cornerRadius = 25
        self.copiedSuccess.layer!.masksToBounds = true
        
        self.imageSelector.frame.origin.x = self.view.frame.size.width
        self.cameraSelector.frame.origin.x = 0 - self.cameraSelector.frame.size.width
        self.startButton.frame.origin.y = 0 - self.startButton.frame.size.height
        self.history.alphaValue = 0.0
        self.history.frame.origin.y = self.cameraSelector.frame.origin.y
        self.helpBtn.frame.origin.y = self.view.frame.size.height + 25
        
        self.loadingIndicator.wantsLayer = true
        self.loadingIndicator.layer!.cornerRadius = 15
        self.loadingIndicator.layer!.borderColor = NSColor.darkGray.cgColor
        self.loadingIndicator.layer!.borderWidth = 5
        self.loadingIndicator.layer!.backgroundColor = NSColor.lightGray.cgColor
        
        self.loadingWidget.appearance = NSAppearance(named: NSAppearance.Name.aqua)
        
        if resize {
            self.resizeSubviews()
        }
    }
    
    func displayInternetProblems() {
        self.connectionErrorView.removeFromSuperview()
        self.view.addSubview(self.connectionErrorView)
        NSAnimationContext.beginGrouping()
        NSAnimationContext.current.duration = 1
        self.connectionErrorView.animator().alphaValue = 1
        NSAnimationContext.endGrouping()
    }
    
    func removeInternetPopUp() {
        self.connectionErrorView.removeFromSuperview()
        NSAnimationContext.beginGrouping()
        NSAnimationContext.current.duration = 1.0
        self.connectionErrorView.animator().alphaValue = 0
        NSAnimationContext.endGrouping()
    }
    
    @IBAction func activateCamera(_ sender: NSButton) {
        if sender.alphaValue != 0.0 {
            let cameraVC = self.storyboard?.instantiateController(withIdentifier: "CameraController") as! CameraViewController
            cameraVC.delegate = self
            present(cameraVC, asPopoverRelativeTo: sender.frame, of: self.view, preferredEdge: NSRectEdge.maxX, behavior: .applicationDefined)
        }
    }
    
    @IBAction func displayHelp(_ sender: NSButton!) {
        showLittlePopoverWithMessage(sender: sender, message: "All it takes is three simple clicks. You can choose to either drag your image onto the big view, hold ⌘⌥ while dragging the file onto the app icon, or you can click the upload button Then after it starts, you'll be presented with a link, and the button to share it.", height: 275, txtHeight: 170)
    }
    
    func showLittlePopoverWithMessage(sender: AnyObject, message: String, height: Int, txtHeight: Int) {
        let controller = NSViewController()
        controller.view = NSView(frame: CGRect(x: 100, y: 50, width: 200, height: height))
        
        let popover = NSPopover()
        popover.contentViewController = controller
        popover.contentSize = controller.view.frame.size
        
        popover.behavior = .transient
        popover.animates = true
        popover.appearance = NSAppearance(named: .vibrantDark)
        
        let ttl = NSImageView(frame: NSRect(x: Int(62.5), y: height - 85, width: 75, height: 75))
        ttl.image = NSImage(named: "AppIcon")
        controller.view.addSubview(ttl)
        
        let txt = NSTextField(frame: NSRect(x: 20, y: 20, width: 160, height: txtHeight))
        txt.stringValue = message
        txt.textColor = NSColor.white.withAlphaComponent(0.95)
        txt.isBezeled = false
        txt.isEditable = false
        txt.drawsBackground = false
        txt.alignment = .center
        controller.view.addSubview(txt)
        
        popover.show(relativeTo: sender.bounds, of: sender as! NSView, preferredEdge: NSRectEdge.maxX)
    }

    @IBAction func uploadPicture(_ sender: NSButton) {
        if (self.imageSelector.subviews[0] as? NSButton)!.image != NSImage(named: "success_icon") {
            if sender.image == NSImage(named: "NormalStateIcon") {
                sender.image = NSImage(named: "DraggingStateIcon")
            } else {
                sender.image = NSImage(named: "NormalStateIcon")
            }
            
            let panel = NSOpenPanel()
            panel.allowsMultipleSelection = false
            panel.canChooseDirectories = false
            panel.canCreateDirectories = false
            panel.canChooseFiles = true
            panel.allowedFileTypes = ["png", "jpeg", "jpg", "bmp"]
            
            let verification = panel.runModal()
            
            if verification == NSApplication.ModalResponse.OK {
                self.convertImage(for: panel.urls[0])
                NSAnimationContext.beginGrouping()
                NSAnimationContext.current.duration = 0.5
                self.startButton.animator().alphaValue = 0.0
                NSAnimationContext.endGrouping()
                self.startButton.title = "Start"
                NSAnimationContext.beginGrouping()
                NSAnimationContext.current.duration = 0.5
                self.startButton.animator().alphaValue = 1.0
                NSAnimationContext.endGrouping()
            } else {
                sender.image = NSImage(named: "NormalStateIcon")
            }
        }
    }
    
    func convertImage(for url: URL) {
        var alreadyNotified = false
        (imageSelector.subviews.last! as? NSTextField)!.stringValue = "Uploading..."
        for i in 0...100 {
            (self.imageSelector.subviews[1] as? NSProgressIndicator)?.usesThreadedAnimation = true
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + (Double(i) / 10)) {
                if !alreadyNotified {
                    (self.imageSelector.subviews[1] as? NSProgressIndicator)?.increment(by: Double(i))
                    if (self.imageSelector.subviews[1] as? NSProgressIndicator)?.doubleValue == 100 {
                        (self.imageSelector.subviews.last! as? NSTextField)!.stringValue = "Success"
                        (self.imageSelector.subviews[0] as? NSButton)!.image = NSImage(named: "success_icon")
                        alreadyNotified = true
                    }
                }
            }
        }
        
        if let image = NSImage(contentsOf: url) {
            NSAnimationContext.beginGrouping()
            NSAnimationContext.current.duration = 1
            cameraSelector.animator().alphaValue = 0
            NSAnimationContext.endGrouping()
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1) {
                self.imageReview.alphaValue = 1
                mainImage = image
                (self.imageReview.subviews[0] as? NSImageView)?.image = image
                (self.imageReview.subviews[1] as? NSTextField)?.stringValue = url.lastPathComponent
                self.imageReview.subviews.last!.animator().alphaValue = 1.0
                NSAnimationContext.beginGrouping()
                NSAnimationContext.current.duration = 1
                self.imageReview.animator().frame.origin.y -= 70
                NSAnimationContext.endGrouping()
                self.state = true
            }
        } else {
            errorMessage.removeFromSuperview()
            self.view.addSubview(errorMessage)
            NSAnimationContext.beginGrouping()
            NSAnimationContext.current.duration = 1
            errorMessage.animator().alphaValue = 1
            NSAnimationContext.endGrouping()
        }
    }
    
    @IBAction func start(_ sender: NSButton) {
        if state {
            if sender.title == "Start" {
                let controller = NSViewController()
                controller.view = NSView(frame: CGRect(x: 0, y: 0, width: 400, height: 400))
                
                popover.contentViewController = controller
                popover.contentSize = controller.view.frame.size
                
                popover.behavior = .transient
                popover.animates = true
                popover.appearance = NSAppearance(named: .vibrantDark)
                
                let favicon = NSImageView(frame: NSRect(x: 20, y: 315, width: 360, height: 75))
                favicon.image = NSImage(named: NSImage.Name("AppIcon"))
                controller.view.addSubview(favicon)
                
                let ttl = NSTextField(frame: NSRect(x: 20, y: 290, width: 360, height: 20))
                ttl.font = NSFont.systemFont(ofSize: 15)
                ttl.textColor = NSColor.white
                ttl.drawsBackground = false
                ttl.isBezeled = false
                ttl.isBordered = false
                ttl.isEditable = false
                ttl.stringValue = "Please select the service to use."
                ttl.alignment = .center
                controller.view.addSubview(ttl)
                
                var count = 0
                var timer: Double = 0
                UploadType.allCases.forEach { uploadType in
                    let x_pos = count < 3 ? ((50 * count) * 2) + 75 : ((50 * (count - 3)) * 2) + 75
                    let y_pos = count < 3 ? 200 : 100
                    
                    let btn = NSButton(frame: NSRect(x: x_pos, y: y_pos - 25, width: 50, height: 50))
                    btn.isBordered = false
                    btn.title = ""
                    btn.image = NSImage(named: NSImage.Name(String(describing: uploadType) + "-1"))
                    btn.wantsLayer = true
                    btn.layer!.backgroundColor = NSColor.white.cgColor
                    btn.layer!.cornerRadius = 10
                    btn.alphaValue = 0.0
                    btn.action = #selector(self.beginUploadProcess(_:))
                    controller.view.addSubview(btn)
                    
                    let lbl = NSTextField(frame: NSRect(x: CGFloat(x_pos) - 12.5, y: CGFloat(y_pos - 17), width: CGFloat(75), height: CGFloat(15)))
                    lbl.isBordered = false
                    lbl.isBezeled = false
                    lbl.isEditable = false
                    lbl.drawsBackground = false
                    lbl.textColor = NSColor.white
                    lbl.font = NSFont.systemFont(ofSize: 10)
                    lbl.alignment = .center
                    lbl.stringValue = String(describing: uploadType)
                    lbl.alphaValue = 0.0
                    controller.view.addSubview(lbl)
                    
                    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.25 + timer, execute: {
                        NSAnimationContext.beginGrouping()
                        NSAnimationContext.current.duration = 0.5
                        btn.animator().alphaValue = 1.0
                        btn.animator().frame.origin.y = CGFloat(y_pos)
                        self.imageReview.subviews.last!.animator().alphaValue = 0.0
                        NSAnimationContext.endGrouping()
                        
                        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.25, execute: {
                            NSAnimationContext.beginGrouping()
                            NSAnimationContext.current.duration = 0.5
                            lbl.animator().alphaValue = 1.0
                            NSAnimationContext.endGrouping()
                        })
                    })
                    
                    timer += 0.15
                    count += 1
                }
                
                popover.show(relativeTo: sender.bounds, of: sender, preferredEdge: NSRectEdge.maxY)
            }
        } else {
            if sender.title != "Start" {
                self.removeFile(sender)
                loadingIndicator.frame.origin.y = 70
                loadingWidget.frame.origin.y = 84
                NSAnimationContext.beginGrouping()
                NSAnimationContext.current.duration = 1
                finishedLink.animator().frame.origin.y -= 25
                finishedLink.animator().alphaValue = 0
                cameraSelector.animator().alphaValue = 1
                imageReview.animator().frame = NSRect(x: 20, y: imageSelector.frame.origin.y + 20, width: self.view.frame.size.width - 40, height: 50)
                NSAnimationContext.endGrouping()
                sender.title = "Start"
            } else {
                showLittlePopoverWithMessage(sender: self.startButton, message: "You first need to select an image or take a picture of it.", height: 160, txtHeight: 50)
            }
        }
    }
    
    @objc func beginUploadProcess(_ sender: NSButton!) {
        self.setProccess(with: sender.image!.name()!)
        var timer: Double = 0
        for subview in sender.superview!.subviews {
            DispatchQueue.main.asyncAfter(deadline: .now() + timer) {
                NSAnimationContext.beginGrouping()
                NSAnimationContext.current.duration = 0.5
                subview.animator().frame.origin.x = -subview.frame.size.width
                NSAnimationContext.endGrouping()
            }
            timer += 0.15
        }
        
        if proccess == .Dropbox {
            DropboxClientsManager.authorizeFromController(sharedWorkspace: NSWorkspace.shared, controller: self, openURL: { (url: URL) -> Void in
                NSWorkspace.shared.open(url)
            })
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.9) {
            if sender.image?.name() == "Google-1" {
                let usernameField = NSView(frame: NSRect(x: 400, y: 200, width: 360, height: 50))
                usernameField.wantsLayer = true
                usernameField.layer!.cornerRadius = 7.5
                usernameField.layer!.backgroundColor = NSColor.lightGray.withAlphaComponent(0.7).cgColor
                usernameField.addSubview(NSTextField(frame: NSRect(x: 0, y: 10, width: 360, height: 30)))
                (usernameField.subviews[0] as? NSTextField)!.isBordered = false
                (usernameField.subviews[0] as? NSTextField)!.isBezeled = false
                (usernameField.subviews[0] as? NSTextField)!.drawsBackground = false
                (usernameField.subviews[0] as? NSTextField)!.focusRingType = .none
                (usernameField.subviews[0] as? NSTextField)!.textColor = NSColor.white
                (usernameField.subviews[0] as? NSTextField)!.font = NSFont.systemFont(ofSize: 25)
                (usernameField.subviews[0] as? NSTextField)!.placeholderString = "Username"
                (usernameField.subviews[0] as? NSTextField)!.alignment = .center
                (usernameField.subviews[0] as? NSTextField)!.usesSingleLineMode = true
                (usernameField.subviews[0] as? NSTextField)!.delegate = self
                sender.superview!.addSubview(usernameField)
                
                let passwordField = NSView(frame: NSRect(x: 400, y: 125, width: 360, height: 50))
                passwordField.wantsLayer = true
                passwordField.layer!.cornerRadius = 7.5
                passwordField.layer!.backgroundColor = NSColor.lightGray.withAlphaComponent(0.7).cgColor
                passwordField.addSubview(NSSecureTextField(frame: NSRect(x: 0, y: 10, width: 360, height: 30)))
                (passwordField.subviews[0] as? NSTextField)!.isBordered = false
                (passwordField.subviews[0] as? NSTextField)!.isBezeled = false
                (passwordField.subviews[0] as? NSTextField)!.drawsBackground = false
                (passwordField.subviews[0] as? NSTextField)!.focusRingType = .none
                (passwordField.subviews[0] as? NSTextField)!.textColor = NSColor.white
                (passwordField.subviews[0] as? NSTextField)!.font = NSFont.systemFont(ofSize: 25)
                (passwordField.subviews[0] as? NSTextField)!.placeholderString = "Password"
                (passwordField.subviews[0] as? NSTextField)!.alignment = .center
                (passwordField.subviews[0] as? NSTextField)!.usesSingleLineMode = true
                (passwordField.subviews[0] as? NSTextField)!.delegate = self
                sender.superview!.addSubview(passwordField)
                
                let consent = NSTextField(frame: NSRect(x: 20, y: 75, width: 360, height: 50))
                consent.isBezeled = false
                consent.isBordered = false
                consent.isEditable = false
                consent.drawsBackground = false
                consent.textColor = NSColor.lightGray
                consent.font = NSFont.systemFont(ofSize: 11)
                consent.stringValue = "* Please note that we do not and will not save any account information entered on this app, the data goes straight to the main websites."
                consent.alphaValue = 0.0
                sender.superview!.addSubview(consent)
                
                NSAnimationContext.beginGrouping()
                NSAnimationContext.current.duration = 0.5
                sender.superview!.subviews[0].animator().frame.origin.x = 20
                NSAnimationContext.endGrouping()
                (sender.superview!.subviews[1] as? NSTextField)!.stringValue = "Please enter your \(String(describing: self.proccess)) account info below"
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15, execute: {
                    NSAnimationContext.beginGrouping()
                    NSAnimationContext.current.duration = 0.5
                    sender.superview!.subviews[1].animator().frame.origin.x = 20
                    NSAnimationContext.endGrouping()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
                        NSAnimationContext.beginGrouping()
                        NSAnimationContext.current.duration = 0.5
                        usernameField.animator().frame.origin.x = 20
                        NSAnimationContext.endGrouping()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15, execute: {
                            NSAnimationContext.beginGrouping()
                            NSAnimationContext.current.duration = 0.5
                            passwordField.animator().frame.origin.x = 20
                            NSAnimationContext.endGrouping()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35, execute: {
                                NSAnimationContext.beginGrouping()
                                NSAnimationContext.current.duration = 0.5
                                consent.animator().alphaValue = 1.0
                                NSAnimationContext.endGrouping()
                            })
                        })
                    })
                })
            } else {
                uploadService.upload(uploadType: self.proccess, credentials: nil)
                self.popover.performClose(self)
            }
            
            self.loadingWidget.startAnimation(self)
            NSAnimationContext.beginGrouping()
            NSAnimationContext.current.duration = 0.5
            self.loadingWidget.animator().alphaValue = 1.0
            self.loadingIndicator.animator().alphaValue = 1.0
            self.loadingIndicator.animator().frame.origin.y = self.imageReview.frame.origin.y - self.loadingIndicator.frame.size.height - 8
            self.loadingWidget.animator().frame.origin.y = self.loadingIndicator.frame.origin.y + ((self.loadingIndicator.frame.size.height - self.loadingWidget.frame.size.height) / 2)
            NSAnimationContext.endGrouping()
        }
    }
    
    func controlTextDidBeginEditing(_ obj: Notification) {
        loginState += 1
        
        if loginState == 2 {
            let loginBtn = NSButton(frame: NSRect(x: 75, y: -50, width: 250, height: 50))
            loginBtn.isBordered = false
            loginBtn.title = "Login"
            loginBtn.wantsLayer = true
            loginBtn.layer!.cornerRadius = 10
            loginBtn.layer!.backgroundColor = NSColor(red: (66 / 255), green: (244 / 255), blue: (178 / 255), alpha: 1).cgColor
            loginBtn.contentTintColor = NSColor.white
            loginBtn.font = NSFont.systemFont(ofSize: 20)
            loginBtn.alignment = .center
            loginBtn.action = #selector(self.uploadToSpecialParties(_:))
            popover.contentViewController?.view.addSubview(loginBtn)
            
            self.loadingWidget.startAnimation(self)
            NSAnimationContext.beginGrouping()
            NSAnimationContext.current.duration = 0.5
            loginBtn.animator().frame.origin.y = 20
            NSAnimationContext.endGrouping()
        }
    }
    
    @objc func uploadToSpecialParties(_ sender: NSButton!) {
        popover.performClose(self)
        let username = ((self.popover.contentViewController?.view.subviews[14].subviews[0] as? NSTextField)?.stringValue)!
        let password = ((self.popover.contentViewController?.view.subviews[15].subviews[0] as? NSTextField)?.stringValue)!
        uploadService.upload(uploadType: proccess, credentials: LoginSystem(username: username, password: password))
        
        self.loadingWidget.startAnimation(self)
        NSAnimationContext.beginGrouping()
        NSAnimationContext.current.duration = 0.5
        self.loadingWidget.animator().alphaValue = 1.0
        self.loadingIndicator.animator().alphaValue = 1.0
        self.loadingWidget.animator().frame.origin.y += 25
        self.loadingIndicator.animator().frame.origin.y += 25
        NSAnimationContext.endGrouping()
    }
    
    func setProccess(with name: String) {
        if name == "Google-1" {
            proccess = .Google
        } else if name == "Imgur-1" {
            proccess = .Imgur
        } else if name == "UploadCare-1" {
            proccess = .UploadCare
        } else if name == "CatBox-1" {
            proccess = .CatBox
        } else if name == "Backendless-1" {
            proccess = .Backendless
        } else if name == "Dropbox-1" {
            proccess = .Dropbox
        }
    }
    
    @IBAction func history(_ sender: NSButton) {
        let historyVC = self.storyboard?.instantiateController(withIdentifier: "HistoryController") as! HistoryViewController
        present(historyVC, asPopoverRelativeTo: sender.frame, of: self.view, preferredEdge: NSRectEdge.maxY, behavior: .applicationDefined)
    }
    
    @IBAction func removeFile(_ sender: NSButton) {
        (self.imageSelector.subviews[0] as? NSButton)!.image = NSImage(named: "NormalStateIcon")
        (self.imageSelector.subviews[2] as? NSTextField)!.stringValue = "Drag Or Select Image"
        startButton.layer!.backgroundColor = NSColor.clear.cgColor
        NSAnimationContext.beginGrouping()
        NSAnimationContext.current.duration = 1
        cameraSelector.animator().alphaValue = 1
        finishedLink.animator().alphaValue = 0
        imageReview.animator().frame.origin.y += 70
        loadingIndicator.animator().frame.origin.y -= 25
        loadingWidget.animator().frame.origin.y -= 25
        loadingIndicator.animator().alphaValue = 0
        loadingWidget.animator().alphaValue = 0
        NSAnimationContext.endGrouping()
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1) {
            self.imageReview.alphaValue = 0
            (self.imageSelector.subviews[1] as? NSProgressIndicator)!.doubleValue = 0
            self.state = false
        }
    }
    
    @IBAction func copyToClipboard(_ sender: NSButton) {
        let sharingPicker = NSSharingServicePicker(items: [(self.finishedLink.subviews[1] as? NSTextField)!.stringValue, mainImage])
        
        sharingPicker.delegate = self
        sharingPicker.show(relativeTo: NSZeroRect, of: sender, preferredEdge: .minY)
    }
    
    func cameraViewControllerDidFinish() {
        state = true
        NSAnimationContext.beginGrouping()
        NSAnimationContext.current.duration = 1
        self.cameraSelector.animator().alphaValue = 0
        NSAnimationContext.endGrouping()
        (self.imageSelector.subviews[1] as? NSProgressIndicator)?.doubleValue = 100
        (self.imageSelector.subviews.last! as? NSTextField)!.stringValue = "Success"
        (self.imageSelector.subviews[0] as? NSButton)!.image = NSImage(named: "success_icon")
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1) {
            self.imageReview.alphaValue = 1
            (self.imageReview.subviews[0] as? NSImageView)?.image = mainImage
            (self.imageReview.subviews[1] as? NSTextField)?.stringValue = "Camera Picture"
            if self.imageReview.frame.origin.y > self.imageSelector.frame.origin.y {
                NSAnimationContext.beginGrouping()
                NSAnimationContext.current.duration = 1
                self.imageReview.animator().frame.origin.y -= 70
                NSAnimationContext.endGrouping()
            }
        }
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
    
    func resizeSubviews() {
        imageSelector.frame = NSRect(x: 20, y: 215, width: self.view.frame.size.width - 40, height: self.view.frame.size.height - 240)
        if imageReview.frame.origin.y > imageSelector.frame.origin.y {
            imageReview.frame = NSRect(x: 20, y: imageSelector.frame.origin.y + 20, width: self.view.frame.size.width - 40, height: 50)
        } else {
            imageReview.frame = NSRect(x: 20, y: imageSelector.frame.origin.y - 50, width: self.view.frame.size.width - 40, height: 50)
        }
        finishedLink.frame = NSRect(x: 20, y: 100, width: self.view.frame.size.width - 40, height: 35)
        loadingIndicator.frame = NSRect(x: (self.view.frame.size.width / 2) - 30, y: 70, width: 60, height: 60)
        loadingWidget.frame = NSRect(x: (self.view.frame.size.width / 2) - 16, y: 84, width: 32, height: 32)
        startButton.frame = NSRect(x: 20, y: 20, width: self.view.frame.size.width - 151, height: 40)
        history.frame = NSRect(x: self.view.frame.size.width - 123, y: 20, width: 103, height: 40)
        cameraSelector.frame = NSRect(x: 20, y: 95, width: self.view.frame.size.width - 40, height: 105)
        copiedSuccess.frame = NSRect(x: (self.view.frame.size.width / 2) - 100, y: -200, width: 200, height: 200)
        helpBtn.frame = NSRect(x: self.view.frame.size.width - 30, y: self.view.frame.size.height - 30, width: 24, height: 25)
        connectionErrorView.frame = self.view.bounds
        errorMessage.subviews[0].frame = NSRect(x: 20, y: (self.view.frame.size.height / 2) + 44, width: self.view.frame.size.width - 40, height: 35)
        errorMessage.subviews[1].frame = NSRect(x: 20, y: (self.view.frame.size.height / 2) - 18, width: self.view.frame.size.width - 40, height: 72)
        connectionErrorView.subviews[0].frame = NSRect(x: (self.view.frame.size.width / 2) - 87.5, y: (self.view.frame.size.height / 2) - 87.5, width: 175, height: 175)
        connectionErrorView.subviews[1].frame = NSRect(x: 20, y: (self.view.frame.size.height / 2) - 130.5, width: self.view.frame.size.width - 40, height: 35)
        connectionErrorView.subviews[2].frame = NSRect(x: 20, y: (self.view.frame.size.height / 2) - 238.5, width: self.view.frame.size.width - 40, height: 100)
        imageReview.subviews[0].frame = NSRect(x: 0, y: 0, width: 50, height: 50)
        imageReview.subviews[1].frame = NSRect(x: 58, y: 13, width: imageReview.frame.size.width - 112, height: 25)
        imageReview.subviews[2].frame = NSRect(x: imageReview.frame.size.width - 50, y: 0, width: 50, height: 50)
        imageSelector.subviews[0].frame = NSRect(x: (imageSelector.frame.size.width / 2) - 50, y: (imageSelector.frame.size.height / 2) - 50, width: 100, height: 100)
        imageSelector.subviews[1].frame = NSRect(x: 20, y: 78, width: imageSelector.frame.size.width - 40, height: 20)
        imageSelector.subviews[2].frame = NSRect(x: 18, y: 36, width: imageSelector.frame.size.width - 36, height: 35)
        finishedLink.subviews[0].frame = NSRect(x: finishedLink.frame.size.width - 35, y: 0, width: 35, height: 35)
        finishedLink.subviews[1].frame = NSRect(x: 0, y: 5, width: finishedLink.frame.size.width - 43, height: 25)
        cameraSelector.subviews[0].frame = NSRect(x: (cameraSelector.frame.size.width / 2) - 27, y: 13, width: 54, height: 54)
        cameraSelector.subviews[1].frame = NSRect(x: 18, y: 50, width: cameraSelector.frame.size.width - 36, height: 35)
    }
    
    func quickUpload(with filename: String) {
        if mainImage.png != nil {
            removeFile(imageReview.subviews.last! as! NSButton)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.convertImage(for: URL(fileURLWithPath: filename))
            }
        } else {
            convertImage(for: URL(fileURLWithPath: filename))
        }
    }
    
    @IBAction func openSettingsPanel(_ sender: Any!) {
        self.presentAsSheet(self.storyboard?.instantiateController(withIdentifier: "SettingsPanel") as! NSViewController)
    }
}
