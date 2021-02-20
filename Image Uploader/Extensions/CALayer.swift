//
//  CALayer.swift
//  Easy Share Uploader
//
//  Created by Ozan Mirza on 1/10/21.
//  Copyright © 2021 Aries Sciences LLC. All rights reserved.
//

import Cocoa

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
