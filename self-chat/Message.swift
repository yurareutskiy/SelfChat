//
//  Message.swift
//  self-chat
//
//  Created by Yura Reutskiy on 06/11/2016.
//  Copyright © 2016 Yura Reutskiy. All rights reserved.
//

import UIKit


enum MessageType: String {
    case text
    case image
    case location
}

class Message: NSObject {
    var date: Date = Date()
    var text: String?
    var image: Data?
    var type: MessageType
    
    init(messageText text:String) {
        self.text = text
        self.type = .text
    }
    
    init(messageImage data:Data) {
        self.image = data
        self.type = .image
    }
    
    init(urlImage urlString:String) {
        type = .image
        let url = URL(string: ServerTask.baseUrl + "images/" + urlString)
        do {
            image = try Data(contentsOf: url!)
        } catch {
            image = UIImageJPEGRepresentation(UIImage.init(named: "default")!, 1)
        }
    }
    
    func serialize() -> [String:Any] {
        var dictionary: [String:Any] = [:]
    
        dictionary.updateValue(date.toString(), forKey: "date")
        dictionary.updateValue(type.rawValue, forKey: "type")
        dictionary.updateValue("", forKey: "image")
        
        dictionary.updateValue("", forKey: "text")
        if text != nil {
            dictionary.updateValue(text!, forKey: "text")
        }
        
        return ["message": dictionary]
    }
    
}
extension Date {
    func toString() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMMM dd yyyy hh:mm:ss +zzzz"
        return dateFormatter.string(from: self)
    }
}

