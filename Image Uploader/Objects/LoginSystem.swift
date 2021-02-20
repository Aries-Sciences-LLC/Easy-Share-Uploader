//
//  LoginSystem.swift
//  Image Uploader
//
//  Created by Ozan Mirza on 1/8/21.
//  Copyright © 2021 Ozan Mirza. All rights reserved.
//

import Foundation

public class LoginSystem: NSObject {
    private var username: String!
    private var password: String!
    
    public init(username: String, password: String) {
        self.username = username
        self.password = password
    }
    
    public func getUsername() -> String {
        return self.username
    }
    
    public func getPassword() -> String {
        return self.password
    }
    
    public func setUsername(username: String) {
        self.username = username
    }
    
    public func setPassword(password: String) {
        self.password = password
    }
}
