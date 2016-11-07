//
//  Message.swift
//  self-chat
//
//  Created by Yura Reutskiy on 06/11/2016.
//  Copyright © 2016 Yura Reutskiy. All rights reserved.
//

import UIKit


enum MessageType {
    case text
    case image
    case location
}

struct Message {
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
}
