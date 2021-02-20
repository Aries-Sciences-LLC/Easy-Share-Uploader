//
//  UserImages.swift
//  Image Uploader
//
//  Created by Ozan Mirza on 1/8/21.
//  Copyright © 2021 Ozan Mirza. All rights reserved.
//

import Foundation

class UserImages {
    static let standard = UserImages()
    
    private let key = "Image-Uploader.ImageFile"
    
    private(set) var images: [ImageFile]
    
    init() {
        images = []
        load()
    }
    
    func load() {
        do {
            guard let data = UserDefaults.standard.data(forKey: key) else { return }
            images = try JSONDecoder().decode([ImageFile].self, from: data)
        } catch {
            print(error)
        }
    }
    
    func save() {
        do {
            let data = try JSONEncoder().encode(images)
            UserDefaults.standard.setValue(data, forKey: key)
        } catch {
            print(error)
        }
    }
    
    func add(_ name: String, _ description: String,_ data: Data, _ link: URL) {
        images.append(
            ImageFile(
                name: name,
                description: description,
                data: data,
                link: link,
                date: Date()
            )
        )
    }
    
    func remove(at index: Int) {
        images.remove(at: index)
    }
}
