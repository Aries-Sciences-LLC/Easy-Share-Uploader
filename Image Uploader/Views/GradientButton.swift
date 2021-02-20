//
//  GradientButton.swift
//  Image Uploader
//
//  Created by Ozan Mirza on 1/7/21.
//  Copyright © 2021 Ozan Mirza. All rights reserved.
//

import Cocoa

class GradientButton: NSButton {
    let gradientLayer = CAGradientLayer()
    
    @IBInspectable var topGradientColor: NSColor?
    @IBInspectable var bottomGradientColor: NSColor?
    
    override func awakeFromNib() {
        
    }
    
    public func setGradient(topGradientColor: NSColor?, bottomGradientColor: NSColor?) {
        if let topGradientColor = topGradientColor, let bottomGradientColor = bottomGradientColor {
            gradientLayer.frame = CGRect(x: 3, y: 3, width: bounds.width - 7, height: bounds.height - 7)
            gradientLayer.locations = [0.0, 1.0]
            gradientLayer.colors = [topGradientColor.cgColor, bottomGradientColor.cgColor]
            gradientLayer.cornerRadius = 4
            self.layer!.insertSublayer(gradientLayer, at: 0)
        } else {
            gradientLayer.removeFromSuperlayer()
        }
    }
}
