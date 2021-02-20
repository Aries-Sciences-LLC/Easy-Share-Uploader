//
//  NSView.swift
//  Image Uploader
//
//  Created by Ozan Mirza on 1/10/21.
//  Copyright © 2021 Ozan Mirza. All rights reserved.
//

import Cocoa
import anim

extension NSView {
    func applyGradient(with colors: [NSColor]) {
        let gradient = CAGradientLayer()
        gradient.frame = bounds
        gradient.colors = colors.map({ return $0.cgColor })
        gradient.startPoint = .zero
        gradient.endPoint = CGPoint(x: 1, y: 1)
        gradient.masksToBounds = true
        gradient.shadowPath = layer?.shadowPath
        gradient.shadowColor = layer?.shadowColor
        gradient.shadowRadius = layer?.shadowRadius ?? 0
        gradient.shadowOpacity = layer?.shadowOpacity ?? 0
        
        wantsLayer = true
        layerContentsRedrawPolicy = .duringViewResize
        layer = gradient
    }
    
    func applyCornerRadius(to radius: CGFloat) {
        layer?.sublayers?.forEach({
            $0.cornerCurve = .continuous
            $0.cornerRadius = radius
        })
        
        layer?.cornerCurve = .continuous
        layer?.cornerRadius = radius
    }
    
    func shake(with intensity: CGFloat = 0.05, duration: Double = 0.5){
        let numberOfShakes = 3
        let shakeAnimation = CAKeyframeAnimation()
        
        let shakePath = CGMutablePath()
        shakePath.move(to: CGPoint(x: NSMinX(frame), y: NSMinY(frame)))
        
        for _ in 0...(numberOfShakes - 1) {
            shakePath.addLine(to: CGPoint(x: NSMinX(frame) - frame.size.width * intensity, y: NSMinY(frame)))
            shakePath.addLine(to: CGPoint(x: NSMinX(frame) + frame.size.width * intensity, y: NSMinY(frame)))
        }
        
        shakePath.closeSubpath()
        shakeAnimation.path = shakePath
        shakeAnimation.duration = duration
        
        animations = ["frameOrigin": shakeAnimation]
        animator().setFrameOrigin(self.frame.origin)
    }
    
    func scale(size: CGFloat = 1) {
//        anim(constraintParent: superview!) { (settings) -> animClosure in
//            settings.duration = 0.3
//            return {
//                self.layer?.sublayerTransform = CATransform3DMakeScale(size, size, 1)
//            }
//        }
        
        constraints.forEach {
            if ($0.firstItem as! NSObject) == self.widthAnchor {
                $0.constant += size
            }
        }
        
        superview?.constraints.forEach({
            if ($0.firstItem as! NSObject) == self.widthAnchor {
                $0.constant += size
            }
        })
    }
    
    func fade(to alpha: CGFloat = 0.7) {
        NSAnimationContext.beginGrouping()
        NSAnimationContext.current.duration = 0.3
        animator().alphaValue = alphaValue
        NSAnimationContext.endGrouping()
    }
    
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
