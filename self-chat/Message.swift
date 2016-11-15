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

enum MessageSenderType: String {
    case income
    case outcome
}

enum MessagePositionInBlockType {
    case first
    case middle
    case last
}

class Message: NSObject {
    var date: Date = Date()
    var text: String?
    var image: Data?
    var type: MessageType
    var sender: MessageSenderType = .outcome
    var latitude: String?
    var longittude: String?
    
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
    
    func parse(dateFromString dateString: String) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMMM dd yyyy hh:mm:ss +zzzz"
        date = dateFormatter.date(from: dateString)!
    }
    
    func getDateString() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMMM dd"
        let stringDate = date.toString(formatDate: false)
        return stringDate
    }
    
    func serialize() -> [String:Any] {
        var dictionary: [String:Any] = [:]
    
        dictionary.updateValue(date.toString(formatDate: true), forKey: "date")
        dictionary.updateValue(type.rawValue, forKey: "type")
        dictionary.updateValue("", forKey: "image")
        dictionary.updateValue(sender.rawValue, forKey: "sender")
        dictionary.updateValue("", forKey: "text")
        if type == .location {
            dictionary.updateValue(longittude ?? "", forKey: "longittude")
            dictionary.updateValue(latitude ?? "", forKey: "latitude")
        }
        if text != nil {
            dictionary.updateValue(text!, forKey: "text")
        }
        
        return ["message": dictionary]
    }
    
}
extension Date {
    func toString(formatDate isFull: Bool) -> String {
        let dateFormatter = DateFormatter()
        if isFull == true {
            dateFormatter.dateFormat = "MMMM dd yyyy hh:mm:ss +zzzz"
        } else {
            dateFormatter.dateFormat = "MMMM dd"
        }
        return dateFormatter.string(from: self)
    }
}

