//
//  LayerBackedView.swift
//  Easy Share Uploader
//
//  Created by Ozan Mirza on 2/2/21.
//  Copyright © 2021 Aries Sciences LLC. All rights reserved.
//

import Cocoa

class LayerBackedView: NSView {

    override func viewDidMoveToSuperview() {
        super.viewDidMoveToSuperview()
        postsBoundsChangedNotifications = true
        NotificationCenter.default.addObserver(forName: NSView.boundsDidChangeNotification, object: self, queue: nil) { notification in
            guard let view = notification.object as? NSView else { return }
            view.layer?.sublayers?.forEach {
                $0.frame = view.bounds
            }
        }
    }
}
