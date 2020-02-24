//
//  Networking.swift
//  TookanTracker-Demo
//
//  Created by CL-Macmini-110 on 11/20/17.
//  Copyright © 2017 CL-Macmini-110. All rights reserved.
//

import Foundation

struct STATUS_CODES {
    static let INVALID_ACCESS_TOKEN = 101
    static let BAD_REQUEST = 400
    static let UNAUTHORIZED_ACCESS = 401
    static let PICKUP_TASK = 410
    static let ERROR_IN_EXECUTION = 500
    static let SHOW_ERROR_MESSAGE = 304
    static let NOT_FOUND_MESSAGE = 404
    static let UNAUTHORIZED_FOR_AVAILABILITY = 210
    static let SHOW_MESSAGE = 201
    static let SHOW_DATA = 200
    static let SLOW_INTERNET_CONNECTION = 999
    static let DELETED_TASK = 501
}


struct HTTP_METHOD {
    static let POST = "POST"
    static let GET = "GET"
    static let PUT = "PUT"
}

class Networking: NSObject {
    static let sharedInstance = Networking()
    var baseURL = "https://node1-api.tookanapp.com:444/"
    var VERSION = "123"
    
    func sendRequestToServer(_ url: String, params: [String:AnyObject], httpMethod: String, isZipped:Bool, receivedResponse:@escaping (_ succeeded:Bool, _ response:[String:Any]) -> ()){
        
        let urlString = url.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)
        var request = URLRequest(url: URL(string: baseURL + urlString!)!)
        request.httpMethod = httpMethod as String
        request.timeoutInterval = 20
        if(httpMethod == "POST")
        {
            request.httpBody = try! JSONSerialization.data(withJSONObject: params, options: [])
            request.addValue(VERSION, forHTTPHeaderField: "version")
            if isZipped == false {
                request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            } else {
                request.addValue("application/octet-stream", forHTTPHeaderField: "Content-Type")
                request.addValue("application/octet-stream", forHTTPHeaderField: "Content-Encoding: gzip")
            }
            request.addValue("application/json", forHTTPHeaderField: "Accept")
        }
        let task = URLSession.shared.dataTask(with: request) {data, response, error in
            if(response != nil && data != nil) {
                do {
                    if let json = try JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions.mutableContainers) as? [String:Any] {
                        //     let success = json["success"] as? Int                                  // Okay, the `json` is here, let's get the value for 'success' out of it
                        // print("Success: \(success)")
//                        Analytics.logEvent(ANALYTICS_KEY.API_SUCCESS, parameters: ["API":urlString! as NSObject])
//                        Answers.logCustomEvent(withName: ANALYTICS_KEY.API_SUCCESS, customAttributes: ["API":urlString ?? ""])
                        receivedResponse(true, json)
                    } else {
//                        Analytics.logEvent(ANALYTICS_KEY.API_FAILURE, parameters: ["API":urlString! as NSObject])
//                        Answers.logCustomEvent(withName: ANALYTICS_KEY.API_FAILURE, customAttributes: ["API":urlString ?? ""])
                        
                        let jsonStr = NSString(data: data!, encoding: String.Encoding.utf8.rawValue)    // No error thrown, but not NSDictionary
                        print("Error could not parse JSON: \(jsonStr ?? "")")
                        receivedResponse(false, [:])
                    }
                } catch let parseError {
                    print(parseError)                                                          // Log the error thrown by `JSONObjectWithData`
                    let jsonStr = NSString(data: data!, encoding: String.Encoding.utf8.rawValue)
                    print("Error could not parse JSON: '\(jsonStr ?? "")'")
//                    Analytics.logEvent(ANALYTICS_KEY.API_FAILURE, parameters: ["API":urlString! as NSObject])
//                    Answers.logCustomEvent(withName: ANALYTICS_KEY.API_FAILURE, customAttributes: ["API":urlString ?? ""])
                    receivedResponse(false, [:])
                }
            } else {
//                Analytics.logEvent(ANALYTICS_KEY.API_FAILURE, parameters: ["API":urlString! as NSObject])
//                Answers.logCustomEvent(withName: ANALYTICS_KEY.API_FAILURE, customAttributes: ["API":urlString ?? ""])
                receivedResponse(false, [:])
            }
        }
        task.resume()
    }
    
    
    
    func commonServerCall(apiName:String,params: [String : AnyObject]?,httpMethod:String,receivedResponse:@escaping (_ succeeded:Bool, _ response:[String:Any]) -> ()) {
        if IJReachability.isConnectedToNetwork() == true {
            sendRequestToServer(apiName, params: params! , httpMethod: httpMethod, isZipped:false) { (succeeded:Bool, response:[String:Any]) -> () in
                DispatchQueue.main.async {
                    print(response)
                    if(succeeded){
                        if let status = response["status"] as? Int {
                            switch(status) {
                            case STATUS_CODES.SHOW_DATA, STATUS_CODES.UNAUTHORIZED_FOR_AVAILABILITY:
                                receivedResponse(true, response)
                            case STATUS_CODES.INVALID_ACCESS_TOKEN:
                                if let message = response["message"] as? String {
                                    receivedResponse(true, ["data":response["data"] as! [String:Any],"status":status, "message":message])
                                } else {
                                    receivedResponse(true, ["data":response["data"] as! [String:Any],"status":status, "message":"ERROR_MESSAGE.INVALID_ACCESS_TOKEN"])
                                }
                            case STATUS_CODES.SHOW_MESSAGE:
                                if let message = response["message"] as? String {
                                    receivedResponse(false, ["status":status, "message":message])
                                } else {
                                    receivedResponse(false, ["status":status, "message":"ERROR_MESSAGE.SERVER_NOT_RESPONDING"])
                                }
                            default:
                                if let message = response["message"] as? String {
                                    receivedResponse(false, ["status":status, "message":message])
                                } else {
                                    receivedResponse(false, ["status":status, "message":"ERROR_MESSAGE.SERVER_NOT_RESPONDING"])
                                }
                            }
                        } else {
                            receivedResponse(false, ["status":0,"message":"ERROR_MESSAGE.SERVER_NOT_RESPONDING"])
                        }
                    } else {
                        receivedResponse(false, ["status":0, "message":"ERROR_MESSAGE.SERVER_NOT_RESPONDING"])
                    }
                }
            }
        } else {
            receivedResponse(false, ["status":0, "message":"ERROR_MESSAGE.NO_INTERNET_CONNECTION"])
        }
    }
}
