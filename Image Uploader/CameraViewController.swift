//
//  CameraViewController.swift
//  Image Uploader
//
//  Created by Ozan Mirza on 3/14/19.
//  Copyright © 2019 Ozan Mirza. All rights reserved.
//

import Cocoa
import AVFoundation

protocol CameraViewControllerDelegate {
    func cameraViewControllerDidFinish()
}

class CameraViewController: NSViewController {
    
    @IBOutlet var preview: NSView!
    @IBOutlet var select: GradientButton!
    @IBOutlet var cancel: GradientButton!
    @IBOutlet weak var photobooth: GradientButton!
    @IBOutlet weak var error_message: NSTextField!
    
    let captureSession = AVCaptureSession()
    let device_output = AVCaptureStillImageOutput()
    var captureDevice : AVCaptureDevice?
    var previewLayer : AVCaptureVideoPreviewLayer?
    
    var delegate: CameraViewControllerDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.preferredContentSize = self.view.frame.size
        
        error_message.alphaValue = 0
        
        select.wantsLayer = true
        cancel.wantsLayer = true
        photobooth.wantsLayer = true
        select.appearance = NSAppearance(named: .darkAqua)
        cancel.appearance = NSAppearance(named: .darkAqua)
        photobooth.appearance = NSAppearance(named: .darkAqua)
        select.setGradient(topGradientColor: select.topGradientColor, bottomGradientColor: select.bottomGradientColor)
        cancel.setGradient(topGradientColor: cancel.topGradientColor, bottomGradientColor: cancel.bottomGradientColor)
        photobooth.setGradient(topGradientColor: photobooth.topGradientColor, bottomGradientColor: photobooth.bottomGradientColor)
        select.layer?.cornerRadius = 20
        cancel.layer?.cornerRadius = 20
        photobooth.layer?.cornerRadius = 20
        select.layer?.borderColor = NSColor.lightGray.withAlphaComponent(0.75).cgColor
        cancel.layer?.borderColor = NSColor.lightGray.withAlphaComponent(0.75).cgColor
        photobooth.layer?.borderColor = NSColor.lightGray.withAlphaComponent(0.75).cgColor
        select.layer?.borderWidth = 5
        cancel.layer?.borderWidth = 5
        photobooth.layer?.borderWidth = 5
        select.layer?.masksToBounds = true
        cancel.layer?.masksToBounds = true
        photobooth.layer?.masksToBounds = true
        
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            self.setUpCameraSettings()
            break // The user has previously granted access to the camera.
        case .notDetermined: // The user has not yet been asked for camera access.
            AVCaptureDevice.requestAccess(for: .video) { granted in
                if granted {
                    self.setUpCameraSettings()
                }
            }
            
        case .denied: // The user has previously denied access.
            error_message.alphaValue = 1
            return
        case .restricted: // The user can't grant access due to restrictions.
            error_message.alphaValue = 1
            return
        }
    }
    
    override var representedObject: Any? {
        didSet {
            // Update the view, if already loaded.
        }
    }
    
    @IBAction func cancel(_ sender: NSButton) {
        captureSession.stopRunning()
        dismiss(self)
    }
    
    @IBAction func select(_ sender: NSButton) {
        sender.isEnabled = false
        if let videoConnection = device_output.connection(with: AVMediaType.video) {
            device_output.captureStillImageAsynchronously(from: videoConnection) { (imageDataSampler, error) in
                let imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(imageDataSampler!)
                DispatchQueue.main.async {
                    
                    let pic = NSImageView(frame: NSRect(x: 0, y: 0, width: 510, height: 462))
                    pic.image = NSImage(data: imageData!)!
                    pic.imageScaling = NSImageScaling.scaleAxesIndependently
                    pic.alphaValue = 0.0
                    self.preview.addSubview(pic)
                    
                    let checkmarkBtn = NSButton(frame: NSRect(x: (pic.frame.size.width / 2) + 50, y: 20, width: 75, height: 75))
                    checkmarkBtn.image = NSImage(named: NSImage.Name("checkmark"))
                    checkmarkBtn.target = self
                    checkmarkBtn.action = #selector(self.setPicture(_:))
                    checkmarkBtn.isBordered = false
                    checkmarkBtn.wantsLayer = true
                    checkmarkBtn.layer!.cornerRadius = 15
                    checkmarkBtn.layer!.backgroundColor = NSColor(red: (66 / 255), green: (244 / 255), blue: (178 / 255), alpha: 1).cgColor
                    checkmarkBtn.layer!.borderColor = NSColor.darkGray.cgColor
                    checkmarkBtn.layer!.borderWidth = 5
                    checkmarkBtn.alphaValue = 0.0
                    pic.addSubview(checkmarkBtn)
                    
                    let x = NSButton(frame: NSRect(x: (pic.frame.size.width / 2) - 125, y: 20, width: 75, height: 75))
                    x.image = NSImage(named: NSImage.Name("x"))
                    x.target = self
                    x.action = #selector(self.removePicture(_:))
                    x.isBordered = false
                    x.wantsLayer = true
                    x.layer!.cornerRadius = 15
                    x.layer!.backgroundColor = NSColor(red: (244 / 255), green: (66 / 255), blue: (66 / 255), alpha: 1).cgColor
                    x.layer!.borderColor = NSColor.darkGray.cgColor
                    x.layer!.borderWidth = 5
                    x.alphaValue = 0.0
                    pic.addSubview(x)
                    
                    NSAnimationContext.beginGrouping()
                    NSAnimationContext.current.duration = 1.0
                    pic.animator().alphaValue = 1.0
                    NSAnimationContext.endGrouping()
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {
                        NSAnimationContext.beginGrouping()
                        NSAnimationContext.current.duration = 0.4
                        checkmarkBtn.animator().alphaValue = 1.0
                        x.animator().alphaValue = 1.0
                        NSAnimationContext.endGrouping()
                    })
                }
            }
        }
    }
    
    func setUpCameraSettings() {
        preview.wantsLayer = true
        captureSession.sessionPreset = AVCaptureSession.Preset.high
        captureDevice = AVCaptureDevice.default(for: .video)
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer!.frame = preview.bounds
        previewLayer!.videoGravity = AVLayerVideoGravity.resizeAspectFill
        preview.layer?.addSublayer(previewLayer!)
        let device_input : AVCaptureDeviceInput = try! AVCaptureDeviceInput(device: captureDevice!)
        if captureSession.canAddInput(device_input)
        {
            captureSession.addInput(device_input)
        }
        device_output.outputSettings = [AVVideoCodecKey: AVVideoCodecType.jpeg]
        if captureSession.canAddOutput(device_output) {
            captureSession.addOutput(device_output)
        }
        captureSession.startRunning()
    }
    
    @objc func setPicture(_ sender: NSButton!) {
        mainImage = (sender.superview! as? NSImageView)!.image!
        if self.delegate != nil {
            self.delegate?.cameraViewControllerDidFinish()
        }
        self.captureSession.stopRunning()
        self.view.window?.close()
    }
    
    @objc func removePicture(_ sender: NSButton!) {
        select.isEnabled = true
        NSAnimationContext.beginGrouping()
        NSAnimationContext.current.duration = 1.0
        sender.superview!.animator().alphaValue = 0.0
        NSAnimationContext.endGrouping()
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1.0) {
            sender.superview!.removeFromSuperview()
        }
    }
    
    @IBAction func openPhotoBooth(_ sender: NSButton!) {
        NSWorkspace.shared.launchApplication("Photo Booth")
        cancel(cancel)
    }
}

extension CALayer {
    
    /// Get `NSImage` representation of the layer.
    ///
    /// - Returns: `NSImage` of the layer.
    
    func image() -> NSImage {
        let width = Int(bounds.width * self.contentsScale)
        let height = Int(bounds.height * self.contentsScale)
        let imageRepresentation = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: width, pixelsHigh: height, bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: NSColorSpaceName.deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
        imageRepresentation.size = bounds.size
        
        let context = NSGraphicsContext(bitmapImageRep: imageRepresentation)!
        
        render(in: context.cgContext)
        
        return NSImage(cgImage: imageRepresentation.cgImage!, size: bounds.size)
    }
    
}

extension NSView {
    var snapshot: NSImage {
        guard let bitmapRep = bitmapImageRepForCachingDisplay(in: bounds) else { return NSImage() }
        bitmapRep.size = bounds.size
        cacheDisplay(in: bounds, to: bitmapRep)
        let image = NSImage(size: bounds.size)
        image.addRepresentation(bitmapRep)
        return image
    }
    
    /// Get `Data` representation of the view.
    ///
    /// - Parameters:
    ///   - fileType: The format of file. Defaults to PNG.
    ///   - properties: A dictionary that contains key-value pairs specifying image properties.
    /// - Returns: `Data` for image.
    
    func data(using fileType: NSBitmapImageRep.FileType = .png, properties: [NSBitmapImageRep.PropertyKey : Any] = [:]) -> Data {
        let imageRepresentation = bitmapImageRepForCachingDisplay(in: bounds)!
        cacheDisplay(in: bounds, to: imageRepresentation)
        return imageRepresentation.representation(using: fileType, properties: properties)!
    }
    
    func imageRepresentation() -> NSImage {
        let viewToCapture = self.window!.contentView!
        let rep = viewToCapture.bitmapImageRepForCachingDisplay(in: viewToCapture.bounds)!
        viewToCapture.cacheDisplay(in: viewToCapture.bounds, to: rep)
        
        let img = NSImage(size: viewToCapture.bounds.size)
        img.addRepresentation(rep)
        
        return img
    }
}
