//
//  AutoReplier.swift
//  self-chat
//
//  Created by Yura Reutskiy on 15/11/2016.
//  Copyright © 2016 Yura Reutskiy. All rights reserved.
//

import UIKit

class AutoReplier: NSObject {

    private var rawMessage: Message?
    
    init(_ message: Message) {
        rawMessage = message
    }
    
    func commonReply() -> Message? {
        var replyText: String?
        switch rawMessage!.type {
        case .image:
            replyText = simpleImageReply()
        case .text:
            replyText = simpleTextReply()
        case .location:
            replyText = simpleLocationReply()
        default:
            return nil
        }
        if replyText == nil {
            return nil
        }
        
        let replyMessage = Message(messageText: replyText!)
        replyMessage.sender = .income
        return replyMessage
    }
    
    private func simpleTextReply() -> String? {
        let messageText = rawMessage?.text?.lowercased()
        let wordsArray: [String] = messageText!.components(separatedBy: CharacterSet.whitespacesAndNewlines.union(.punctuationCharacters))
        
        if wordsArray.contains("привет") {
            return "И тебе привет"
        } else if wordsArray.contains("как") && wordsArray.contains("дела") {
            return "Отлично!"
        } else if wordsArray.contains("как") {
            return "Легко"
        } else {
            return "😊"
        }
    }
    
    private func simpleImageReply() -> String? {
        return "Главное горизонт не завалить..."
    }
    
    private func simpleLocationReply() -> String? {
        return "О, я тоже тут"
    }
    
}
