//
//  SaveState.swift
//  Easy Share Uploader
//
//  Created by Ozan Mirza on 2/19/21.
//  Copyright © 2021 Aries Sciences LLC. All rights reserved.
//

import Foundation

struct SaveState {
    private(set) var saved: Bool
    private(set) var destination: URL?
    
    init(destination: URL) {
        self.destination = destination
        saved = true
    }
    
    init() {
        destination = nil
        saved = false
    }
}
