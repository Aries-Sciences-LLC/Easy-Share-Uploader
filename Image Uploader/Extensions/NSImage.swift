//
//  NSImage.swift
//  Image Uploader
//
//  Created by Ozan Mirza on 1/7/21.
//  Copyright © 2021 Ozan Mirza. All rights reserved.
//

import Cocoa

extension NSImage {
    var png: Data? {
        return tiffRepresentation?.bitmap?.png
    }
    var jpeg: Data? {
        return tiffRepresentation?.bitmap?.jpeg
    }
    
    func savePNG(to url: URL?) -> Bool {
        guard let url = url else { return false }
        do {
            try png?.write(to: url)
            return true
        } catch {
            print(error)
            return false
        }
    }
    
    func write(to path: URL, atomically: Bool, usingType type: NSBitmapImageRep.FileType) -> SaveState {
        let properties = [NSBitmapImageRep.PropertyKey.compressionFactor: 1.0]
        
        guard
            let imageData = tiffRepresentation,
            let imageRep = NSBitmapImageRep(data: imageData),
            let data = imageRep.representation(using: type, properties: properties)
        else { return SaveState() }
        
        let path = path.appendingPathExtension("png")
        
        do {
            try data.write(to: path, options: .atomic)
            return SaveState(destination: path)
        } catch {
            print(error)
            return SaveState()
        }
    }
    
    func resizeImage(_ newSize: CGSize) -> NSImage {
        let targetFrame = CGRect(origin: CGPoint.zero, size: newSize);
        let targetImage = NSImage.init(size: newSize)
        
        let ratioH = newSize.height / newSize.height;
        let ratioW = newSize.width / newSize.width;

        var cropRect = CGRect.zero;
        if (ratioH >= ratioW) {
            cropRect.size.width = floor(newSize.width / ratioH);
            cropRect.size.height = newSize.height;
        } else {
            cropRect.size.height = floor(newSize.height / ratioW);
            cropRect.size.width = newSize.width;
        }

        cropRect.origin.x = floor((newSize.width - cropRect.size.width) / 2);
        cropRect.origin.y = floor((newSize.height - cropRect.size.height) / 2);
        
        targetImage.lockFocus()
        draw(in: targetFrame, from: cropRect, operation: .copy, fraction: 1.0, respectFlipped: true, hints: nil )
        targetImage.unlockFocus()
        
        return targetImage;
    }
}
