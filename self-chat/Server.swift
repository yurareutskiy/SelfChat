//
//  Server.swift
//  self-chat
//
//  Created by Yura Reutskiy on 10/11/2016.
//  Copyright © 2016 Yura Reutskiy. All rights reserved.
//

import UIKit

class ServerTask: NSObject {
    static let baseUrl = "http://77.244.215.147:3007/"
    
    let defaultSession = URLSession(configuration: URLSessionConfiguration.default)
    
    var dataTask: URLSessionDataTask?
    
    func loadAllMessages(_ callback:@escaping ((Dictionary<String, Any>?) -> Void)) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        dataTask = defaultSession.dataTask(with: URL.init(string: ServerTask.baseUrl + "messages")!, completionHandler: { (data, response, error) in
            DispatchQueue.main.async {
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
            }
            if let error = error {
                print(error.localizedDescription)
            } else if let responseData = response as? HTTPURLResponse {
                if responseData.statusCode == 200 {
                    do {
                        if let json = try JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions.init(rawValue: 0)) as? Dictionary<String, Any> {
                            print(json)
                            callback(json)
                        }
                    } catch {
                        print("invalid json")
                        callback(nil)
                    }
                    
                }
            }
            callback(nil)
        })
        dataTask?.resume()
    }
    
    
    func sendMessage(stringData data: Data, callback: @escaping ((Bool, String?) -> Void)) {
        var request = URLRequest(url: URL.init(string: ServerTask.baseUrl + "messages")!)
        request.httpMethod = "POST"
        request.httpBody = data
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        dataTask = defaultSession.dataTask(with: request, completionHandler: { (data, response, error) in
            if let error = error {
                print(error.localizedDescription)
                callback(false, nil)
            } else if let responseData = response as? HTTPURLResponse {
                if responseData.statusCode == 200 {
                    do {
                        let insertedId = try JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions.init(rawValue: 0)) as? [String: String]
                        callback(true, insertedId?["resultId"])
                    } catch {
                        print("invalid json")
                        callback(false, nil)
                    }
                }
            }
            callback(false, nil)
        })
        dataTask?.resume()
    }
    
    func sendPhoto(data imageData: Data, messageId: String, callback: @escaping ((Bool) -> Void)) {
        var request = URLRequest(url: URL.init(string: ServerTask.baseUrl + "uploadimage")!)
        request.httpMethod = "POST"
        request.cachePolicy = .reloadIgnoringLocalCacheData

        
        // Set Content-Type in HTTP header.
        let boundaryConstant = "Boundary-\(arc4random_uniform(300000000))"; // This should be auto-generated.
        print(boundaryConstant)
        let contentType = "multipart/form-data; boundary=" + boundaryConstant
        
        let mimeType = "image/jpeg"
        
        request.setValue(contentType, forHTTPHeaderField: "Content-Type")
        
        // Set data
        let data = NSMutableData()
        data.appendString(string: "--\(boundaryConstant)\r\n")
        data.appendString(string: "Content-Disposition: form-data; name=\"image\"; filename=\"image.jpg\"\r\n")
        data.appendString(string: "Content-Type: \(mimeType)\r\n\r\n")
        data.append(imageData)
        data.appendString(string: "\r\n")
        data.appendString(string: "--\(boundaryConstant)\r\n")
        data.appendString(string: "Content-Disposition: form-data; name=\"id\"\r\n\r\n\(messageId)")
        data.appendString(string: "\r\n")
        data.appendString(string: "--\(boundaryConstant)--\r\n")

        
        
        // Set the HTTPBody we'd like to submit
        let requestBodyData = data
        request.httpBody = requestBodyData as Data
        
        // Make an asynchronous call so as not to hold up other processes.
        dataTask = defaultSession.dataTask(with: request, completionHandler: { (data, response, error) in
            if (error != nil) {
                print(error.debugDescription)
                callback(false)
            } else {
                print("photo send \(data) & \(response)")
                callback(true)
            }
        })
        dataTask?.resume()
    }
}

extension NSMutableData {
    
    func appendString(string: String) {
        let data = string.data(using: .utf8, allowLossyConversion: true)
        append(data!)
    }
}
