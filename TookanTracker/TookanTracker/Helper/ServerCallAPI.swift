//
//  ServerCallAPI.swift
//  Butlers
//
//  Created by Rakesh Kumar on 5/14/15.
//  Copyright (c) 2015 Click Labs. All rights reserved.
//

import Foundation
import UIKit

func sendRequestToServer(_ url: String, params: [String:AnyObject], httpMethod: String, receivedResponse:@escaping (_ succeeded:Bool, _ response:[String:Any]) -> ()){

    let urlString = url.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)
    var selectedServer:String?
    switch(SERVER_PORT) {
        case 1:
        selectedServer = SERVER.dev
        break
        
        case 2:
        selectedServer = SERVER.test
        break
        
        default:
        selectedServer = SERVER.live
        break
    }
    
    var request = URLRequest(url: URL(string: (selectedServer)! + urlString!)!)
    request.httpMethod = httpMethod as String
    request.timeoutInterval = 20
    
    if(httpMethod == "POST")
    {
        request.httpBody = try! JSONSerialization.data(withJSONObject: params, options: [])
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
    }
    let task = URLSession.shared.dataTask(with: request) {data, response, error in
        if(response != nil && data != nil) {
            do {
                if let json = try JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions.mutableContainers) as? [String:Any] {
                    //     let success = json["success"] as? Int                                  // Okay, the `json` is here, let's get the value for 'success' out of it
                    // print("Success: \(success)")
                    receivedResponse(true, json)
                } else {
                    let jsonStr = NSString(data: data!, encoding: String.Encoding.utf8.rawValue)    // No error thrown, but not NSDictionary
                    print("Error could not parse JSON: \(jsonStr)")
                    receivedResponse(false, [:])
                }
            } catch let parseError {
                print(parseError)                                                          // Log the error thrown by `JSONObjectWithData`
                let jsonStr = NSString(data: data!, encoding: String.Encoding.utf8.rawValue)
                print("Error could not parse JSON: '\(jsonStr)'")
                receivedResponse(false, [:])
            }
        } else {
            receivedResponse(false, [:])
        }
    }
    task.resume()
}



