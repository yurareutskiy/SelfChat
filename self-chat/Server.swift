//
//  Server.swift
//  self-chat
//
//  Created by Yura Reutskiy on 10/11/2016.
//  Copyright © 2016 Yura Reutskiy. All rights reserved.
//

import UIKit

class ServerTask: NSObject {
    let url = URL(string: "http://77.244.215.147:3001/messages")
    
    let defaultSession = URLSession(configuration: URLSessionConfiguration.default)
    
    var dataTask: URLSessionDataTask?
    
    func loadAllMessages(_ callback:@escaping ((Dictionary<String, Any>?) -> Void)) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        dataTask = defaultSession.dataTask(with: url!, completionHandler: { (data, response, error) in
            DispatchQueue.main.async {
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
            }
            if let error = error {
                print(error.localizedDescription)
            } else if let responseData = response as? HTTPURLResponse {
                if responseData.statusCode == 200 {
                    do {
                        if let json = try JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions.init(rawValue: 0)) as? Dictionary<String, Any> {
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
    
}
