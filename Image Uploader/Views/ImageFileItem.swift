//
//  ImageFileItem.swift
//  Easy Share Uploader
//
//  Created by Ozan Mirza on 1/13/21.
//  Copyright © 2021 Aries Sciences LLC. All rights reserved.
//

import Cocoa

class ImageFileItem: NSView {
    var item: CGFloat
    var scale: CGFloat
    var data: ImageFile
    
    init(count: Int, proportion: CGFloat, contents: ImageFile) {
        item = CGFloat(count)
        scale = proportion
        data = contents
        
        super.init(frame: .zero)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidMoveToSuperview() {
        super.viewDidMoveToSuperview()
        
        shadow = NSShadow()
        shadow?.shadowColor = NSColor.black
        shadow?.shadowOffset = NSMakeSize(3, 3)
        shadow?.shadowBlurRadius = 16
        
        resize()
        configure()
        applyCornerRadius(to: 50)
        layer?.borderWidth = 10
        layer?.borderColor = NSColor.gray.withSystemEffect(.disabled).cgColor
    }
    
    override func mouseDown(with event: NSEvent) {
        NSWorkspace.shared.open(data.link)
    }
    
    func configure() {
        wantsLayer = true
        
        let imageLayer = CALayer()
        imageLayer.frame = bounds
        imageLayer.contents = data.image
        imageLayer.contentsGravity = .resizeAspectFill
        imageLayer.cornerRadius = 50
        imageLayer.masksToBounds = true
        layer?.addSublayer(imageLayer)
    }
    
    func resize() {
        guard let parent = superview?.superview?.superview as? ScrollView else { return }
        let size = parent.contentView.bounds.width * scale
        let x = parent.contentView.bounds.width * 0.175
        let temp = ((parent.spacing + size) * (item + 1))
        let y = parent.documentView!.bounds.height - 300 - temp
        frame = CGRect(x: x, y: y, width: size, height: size)
    }
}
