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
    func cameraViewControllerDidFinish(_ cameraViewController: CameraViewController)
}

class CameraViewController: NSViewController {
    
    @IBOutlet weak var preview: NSView!
    @IBOutlet weak var error_message: NSTextField!
    
    @IBOutlet weak var select: GradientButton!
    @IBOutlet weak var cancel: GradientButton!
    @IBOutlet weak var photobooth: GradientButton!
    @IBOutlet weak var tbSelect: NSButton!
    
    @IBOutlet weak var keep: GradientButton!
    @IBOutlet weak var discard: GradientButton!
    
    @IBOutlet var firstStepX: NSLayoutConstraint!
    @IBOutlet var secondStepX: NSLayoutConstraint!
    
    let captureSession = AVCaptureSession()
    let output = AVCaptureStillImageOutput()
    var captureDevice : AVCaptureDevice?
    var previewLayer : AVCaptureVideoPreviewLayer?
    
    var snappedImage: NSImage!
    
    var delegate: CameraViewControllerDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.preferredContentSize = self.view.frame.size
        
        error_message.alphaValue = 0
        
        select.appearance = NSAppearance(named: .darkAqua)
        cancel.appearance = NSAppearance(named: .darkAqua)
        photobooth.appearance = NSAppearance(named: .darkAqua)
        select.setGradient(topGradientColor: select.topGradientColor, bottomGradientColor: select.bottomGradientColor)
        cancel.setGradient(topGradientColor: cancel.topGradientColor, bottomGradientColor: cancel.bottomGradientColor)
        photobooth.setGradient(topGradientColor: photobooth.topGradientColor, bottomGradientColor: photobooth.bottomGradientColor)
        keep.setGradient(topGradientColor: keep.topGradientColor, bottomGradientColor: keep.bottomGradientColor)
        discard.setGradient(topGradientColor: discard.topGradientColor, bottomGradientColor: discard.bottomGradientColor)
        
        preview.wantsLayer = true
        preview.layer?.borderWidth = 5
        preview.layer?.borderColor = NSColor.gray.withSystemEffect(.pressed).cgColor
        
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            setUpCameraSettings()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                if granted {
                    self.setUpCameraSettings()
                }
            }
        case .denied:
            error_message.alphaValue = 1
        case .restricted:
            error_message.alphaValue = 1
        @unknown default:
            break
        }
    }
    
    override var representedObject: Any? {
        didSet {
            // Update the view, if already loaded.
        }
    }
    
    @IBAction func cancel(_ sender: Any) {
        captureSession.stopRunning()
        dismiss(self)
    }
    
    @IBAction func tbCancel(_ sender: Any) {
        cancel(sender)
    }
    
    @IBAction func select(_ sender: Any) {
        if let videoConnection = output.connection(with: AVMediaType.video) {
            output.captureStillImageAsynchronously(from: videoConnection, completionHandler: { (sampleBuffer, error) -> Void in
                guard let sampleBuffer = sampleBuffer else { return }
                guard let imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(sampleBuffer) else { return }
                guard let dataProvider = CGDataProvider(data: imageData as CFData) else { return }
                guard let cgImageRef = CGImage(jpegDataProviderSource: dataProvider, decode: nil, shouldInterpolate: true, intent: CGColorRenderingIntent.defaultIntent) else { return }
                
                DispatchQueue.main.async {
                    
                    let flash = CALayer()
                    flash.frame = self.preview.bounds
                    flash.backgroundColor = NSColor.white.cgColor
                    self.preview.layer?.addSublayer(flash)
                    flash.opacity = 0

                    let anim = CABasicAnimation(keyPath: "opacity")
                    anim.fromValue = 0
                    anim.toValue = 1
                    anim.duration = 0.1
                    anim.autoreverses = true
                    anim.isRemovedOnCompletion = true

                    flash.add(anim, forKey: "flashAnimation")
                    
                    self.snappedImage = NSImage(cgImage: cgImageRef, size: self.preview.bounds.size)
                    self.previewLayer?.connection?.isEnabled = false
                    
                    NSAnimationContext.beginGrouping()
                    NSAnimationContext.current.duration = 0.3
                    self.firstStepX.animator().constant = -self.view.bounds.width
                    self.secondStepX.animator().constant = 20
                    NSAnimationContext.endGrouping()
                    
                    self.tbSelect.isEnabled = false
                }
            })
        }
    }
    
    @IBAction func tbSelect(_ sender: Any) {
        select(sender)
    }
    
    @IBAction func setPicture(_ sender: NSButton!) {
        captureSession.stopRunning()
        guard let delegate = delegate else { return }
        delegate.cameraViewControllerDidFinish(self)
    }
    
    @IBAction func removePicture(_ sender: NSButton!) {
        previewLayer?.connection?.isEnabled = true
        
        NSAnimationContext.beginGrouping()
        NSAnimationContext.current.duration = 0.3
        self.firstStepX.animator().constant = 20
        self.secondStepX.animator().constant = self.view.frame.size.width
        NSAnimationContext.endGrouping()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.preview.subviews.forEach({ $0.removeFromSuperview() })
            
            self.tbSelect.isEnabled = true
        }
    }
    
    @IBAction func openPhotoBooth(_ sender: Any!) {
        NSWorkspace.shared.launchApplication("Photo Booth")
        cancel(cancel)
    }
    
    @IBAction func tbOpenPhotoBooth(_ sender: Any!) {
        openPhotoBooth(sender)
    }
    
    func setUpCameraSettings() {
        preview.wantsLayer = true
        captureSession.sessionPreset = .high
        captureDevice = .default(for: .video)
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer!.frame = preview.bounds
        previewLayer!.videoGravity = .resizeAspectFill
        preview.layer?.addSublayer(previewLayer!)
        let input = try! AVCaptureDeviceInput(device: captureDevice!)
        if captureSession.canAddInput(input) {
            captureSession.addInput(input)
        }
        if captureSession.canAddOutput(output) {
            captureSession.addOutput(output)
        }
        output.outputSettings = [AVVideoCodecKey: AVVideoCodecType.jpeg]
        captureSession.commitConfiguration()
        captureSession.startRunning()
    }
}
