//
//  UploadService.swift
//  Image Uploader
//
//  Created by Ozan Mirza on 6/24/19.
//  Copyright © 2019 Ozan Mirza. All rights reserved.
//

import Cocoa
import Alamofire
import FirebaseStorage
import FirebaseCore
import FirebaseAuth
import SwiftyDropbox
import Uploadcare
import Backendless

public enum UploadType: Int, CaseIterable {
    case Google = 0
    case Imgur = 1
    case Dropbox = 2
    case CatBox = 3
    case UploadCare = 4
    case Backendless = 5
}

public class UploadService: NSObject {
    
    private var urls: NSDictionary = [
        "Google": "gs://image-uploader-63693.appspot.com",
        "Imgur": "https://api.imgur.com/3/image",
        "Dropbox": "https://api.dropboxapi.com/2/file_requests/create",
        "CatBox": "https://catbox.moe/user/api.php",
        "UploadCare": "https://upload.uploadcare.com/",
        "Backendless": "https://backendlessappcontent.com/<application id>/<REST-API-key>/files/<path>/<file name>"
    ]
    
    public var callback : (String) -> Void = { urlString in }
    
    public var server: UploadType!
    public var credentials: LoginSystem!
    public var mainImage: NSImage! {
        didSet {
            upload(uploadType: UploadType(rawValue: Int.random(in: 0..<6)) ?? .Google, credentials: credentials)
        }
    }
    
    public override init() {}
    
    public init(callback : @escaping (String) -> Void = { urlString in }) {
        self.callback = callback
    }
    
    public func upload(uploadType: UploadType, credentials: LoginSystem?) {
        switch uploadType {
        case .UploadCare:
            let uploadRequest = UCFileUploadRequest(fileData: mainImage.png!, fileName: randomWord(wordLength: Int.random(in: 0...20)), mimeType: "image/png")
            UCClient.default()?.setPublicKey("aa76e54886cf7f99d6c8")
            UCClient.default().performUCRequest(uploadRequest, progress: { (_, _) in }, completion: { (response, error) in
                if error != nil {
                    self.callback("Error Making URL")
                    fatalError(error!.localizedDescription)
                } else {
                    self.callback("https://ucarecdn.com/\((response! as? NSDictionary)!["file"]!)/i")
                }
            })
        case .CatBox:
            let boundary = UUID().uuidString
            
            let fieldName = "reqtype"
            let fieldValue = "fileupload"
            
            let session = URLSession(configuration: URLSessionConfiguration.default)
            
            // Set the URLRequest to POST and to the specified URL
            var urlRequest = URLRequest(url: URL(string: "https://catbox.moe/user/api.php")!)
            urlRequest.httpMethod = "POST"
            
            // Set Content-Type Header to multipart/form-data, this is equivalent to submitting form data with file upload in a web browser
            // And the boundary is also set here
            urlRequest.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
            
            var data = Data()
            
            // Add the reqtype field and its value to the raw http request data
            data.append("\r\n--\(boundary)\r\n".data(using: .utf8)!)
            data.append("Content-Disposition: form-data; name=\"\(fieldName)\"\r\n\r\n".data(using: .utf8)!)
            data.append("\(fieldValue)".data(using: .utf8)!)
            
            // Add the image data to the raw http request data
            data.append("\r\n--\(boundary)\r\n".data(using: .utf8)!)
            data.append("Content-Disposition: form-data; name=\"fileToUpload\"; filename=\"\(randomWord(wordLength: Int.random(in: 1...20)))\"\r\n".data(using: .utf8)!)
            data.append("Content-Type: image/png\r\n\r\n".data(using: .utf8)!)
            data.append(mainImage.png!)
            
            // End the raw http request data, note that there is 2 extra dash ("-") at the end, this is to indicate the end of the data
            // According to the HTTP 1.1 specification https://tools.ietf.org/html/rfc7230
            data.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
            
            // Send a POST request to the URL, with the data we created earlier
            session.uploadTask(with: urlRequest, from: data, completionHandler: { responseData, response, error in
                
                if(error != nil){
                    self.callback("Error Making URL")
                    fatalError(error!.localizedDescription)
                }
                
                guard let responseData = responseData else {
                    self.callback("Error Making URL")
                    fatalError(error!.localizedDescription)
                }
                
                if let responseString = String(data: responseData, encoding: .utf8) {
                    self.callback(responseString)
                }
            }).resume()
        case .Dropbox:
            let client = DropboxClientsManager.authorizedClient!
            let fileData = mainImage.png!
            
            client.files.upload(path: "/\(randomWord(wordLength: Int.random(in: 0...20))).png", input: fileData).response { response, error in
                if let response = response {
                    client.sharing.createSharedLinkWithSettings(path: response.pathLower!).response { response, error in
                        if let link = response {
                            self.callback(link.url)
                        } else if error != nil {
                            self.callback("Error Making URL")
                            print(error!.description)
                        }
                    }
                } else if error != nil {
                    if ((error?.description.contains("insufficient_space")) != nil) {
                        self.callback("Your Dropbox account has insufficient space. Please retry!")
                    } else {
                        self.callback("Error Making URL")
                    }
                    print(error!.description)
                }
            }
        case .Backendless:
            Backendless.shared.file.uploadFile(fileName: self.randomWord(wordLength: Int.random(in: 1...20)), filePath: ".", content: mainImage.png!) { fileURL in
                self.callback(fileURL.fileUrl!)
            } errorHandler: { error in
                self.callback("Error Making URL")
            }
        case .Google:
            Auth.auth().signInAnonymously { (user, error) in
                if error == nil {
                    let storageRef = Storage.storage().reference().child("images\(self.randomWord(wordLength: Int.random(in: 1...20))).png")
                    let imgData = self.mainImage.png
                    let metaData = StorageMetadata()
                    metaData.contentType = "image/png"
                    storageRef.putData(imgData!, metadata: metaData) { (metadata, error) in
                        if error == nil {
                            storageRef.downloadURL(completion: { (url, error) in
                                self.callback(url!.absoluteString)
                            })
                        } else {
                            self.callback("Error Making URL")
                            fatalError(error!.localizedDescription)
                        }
                    }
                } else {
                    self.callback("Error Making URL")
                    fatalError(error!.localizedDescription)
                }
            }
        case .Imgur:
            let base64Image = mainImage.png!.base64EncodedString(options: .lineLength64Characters)
            let url = "https://api.imgur.com/3/image"
            let parameters = [ "image": base64Image ]
            let username = self.randomWord()
            Alamofire.upload(multipartFormData: { multipartFormData in
                if let imageData = self.mainImage.jpeg {
                    multipartFormData.append(imageData, withName: username, fileName: "\(username).png", mimeType: "image/png")
                }
                
                for (key, value) in parameters {
                    multipartFormData.append((value.data(using: .utf8))!, withName: key)
                }}, to: url, method: .post, headers: ["Authorization": "Client-ID 06cc7376c70aee5"],
                    encodingCompletion: { encodingResult in
                        switch encodingResult {
                        case .success(let upload, _, _):
                            upload.response { response in
                                let json = try? JSONSerialization.jsonObject(with: response.data!, options: .allowFragments) as? [String:Any]
                                self.callback((json?["data"] as? [String:Any])!["link"] as! String)
                            }
                        case .failure(let encodingError):
                            print("error:\(encodingError)")
                        }
            })
        }
    }
    
    private func randomWord(wordLength: Int=6) -> String {
        
        let kCons = 1
        let kVows = 2
        
        var cons: [String] = [
            // single consonants. Beware of Q, it"s often awkward in words
            "b", "c", "d", "f", "g", "h", "j", "k", "l", "m",
            "n", "p", "r", "s", "t", "v", "w", "x", "z",
            // possible combinations excluding those which cannot start a word
            "pt", "gl", "gr", "ch", "ph", "ps", "sh", "st", "th", "wh"
        ]
        
        // consonant combinations that cannot start a word
        let cons_cant_start: [String] = [
            "ck", "cm",
            "dr", "ds",
            "ft",
            "gh", "gn",
            "kr", "ks",
            "ls", "lt", "lr",
            "mp", "mt", "ms",
            "ng", "ns",
            "rd", "rg", "rs", "rt",
            "ss",
            "ts", "tch"
        ]
        
        let vows : [String] = [
            // single vowels
            "a", "e", "i", "o", "u", "y",
            // vowel combinations your language allows
            "ee", "oa", "oo",
            ]
        
        // start by vowel or consonant ?
        var current = (Int(arc4random_uniform(2)) == 1 ? kCons : kVows )
        
        var word: String = ""
        while ( word.count < wordLength ) {
            // After first letter, use all consonant combos
            if word.count == 2 {
                cons += cons_cant_start
            }
            
            // random sign from either $cons or $vows
            var rnd: String = ""
            var index: Int
            if current == kCons {
                index = Int(arc4random_uniform(UInt32(cons.count)))
                rnd = cons[index]
            } else if current == kVows {
                index = Int(arc4random_uniform(UInt32(vows.count)))
                rnd = vows[index]
            }
            
            // check if random sign fits in word length
            let tempWord = "\(word)\(rnd)"
            if tempWord.count <= wordLength {
                word = "\(word)\(rnd)"
                // alternate sounds
                current = (current == kCons) ? kVows : kCons;
            }
        }
        
        return word
    }
}
