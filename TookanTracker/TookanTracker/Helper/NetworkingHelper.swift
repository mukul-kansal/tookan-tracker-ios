//
//  Networking Helper.swift
//  Tookan
//
//  Created by Click Labs on 7/7/15.
//  Copyright (c) 2015 Click Labs. All rights reserved.
//

import Foundation
import CoreLocation
import UIKit

class NetworkingHelper: NSObject {
    
    
    //    "api_key":"e740d9d626c69da995bb80c0415c6179",
    //    "unique_user_id":"00000001",
    //    "lat":23,
    //    "lng":32,
    //    "unique_session_id":"e23e"
    //
    //
    //    "http://tracking.tookan.io:3008/create_session"
    static let sharedInstance = NetworkingHelper()
    var requestId:String = ""
    var sessionId:String = ""
    var sessionURL:String = ""
    var requestRole = -1
    /*------------ Share and Stop Tracking ---------------*/
    func shareLocationSession(api_key:String, unique_user_id:String, lat:String, lng:String, sessionId:String, receivedResponse:@escaping (_ succeeded:Bool, _ response:[String:Any]) -> ()) {
        var params: [String : Any] = ["api_key":api_key]
        params["unique_user_id"] = unique_user_id
        params["lat"] = lat
        params["lng"] = lng
        params["unique_session_id"] = sessionId
        //            "request_type":requestType, // 1 for start sesstion, 0 for stop session
        //            "session_id":"",
        //            "request_id":requestID,
        //            "email": emailId]
        NSLog("Params = %@", params)
        if IJReachability.isConnectedToNetwork() == true {
            sendRequestToServer("create_session", params: params as [String : AnyObject], httpMethod: "POST") { (succeeded:Bool, response:[String:Any]) -> () in
                print(response)
                if(succeeded){
                    NetworkingHelper.sharedInstance.requestId = ""
                    switch(response["status"] as! Int) {
                    case STATUS_CODES.SHOW_DATA, STATUS_CODES.INVALID_ACCESS_TOKEN:
                        DispatchQueue.main.async(execute: { () -> Void in
                            receivedResponse(true, response)
                        })
                        break
                        
                    case STATUS_CODES.SHOW_MESSAGE:
                        Auxillary.showAlert(response["message"] as! String!)
                        receivedResponse(false, [:])
                        break
                        
                    default:
                        Auxillary.showAlert(response["message"] as! String!)
                        receivedResponse(false, [:])
                    }
                } else {
                    Auxillary.showAlert(STATUS_CODES.SERVER_NOT_RESPONDING)
                    receivedResponse(false, [:])
                }
            }
        } else {
            Auxillary.showAlert(STATUS_CODES.NO_INTERNET_CONNECTION)
            receivedResponse(false, [:])
        }
    }
    
    /*------------ Start Tracking ---------------*/
    func getLocationForStartTracking(_ sessionId:String, receivedResponse:@escaping (_ succeeded:Bool, _ response:[String:Any]) -> ()) {
        let params = [
            "session_id":sessionId]
        NSLog("Params = %@", params)
        
        if IJReachability.isConnectedToNetwork() == true {
            sendRequestToServer("track_session", params: params as [String : AnyObject], httpMethod: "POST") { (succeeded:Bool, response:[String:Any]) -> () in
                print(response)
                if(succeeded){
                    switch(response["status"] as! Int) {
                    case STATUS_CODES.SHOW_DATA, STATUS_CODES.INVALID_ACCESS_TOKEN:
                        DispatchQueue.main.async(execute: { () -> Void in
                            receivedResponse(true, response)
                        })
                        break
                        
                    case STATUS_CODES.SHOW_MESSAGE:
                        Auxillary.showAlert(response["message"] as! String!)
                        receivedResponse(false, [:])
                        break
                        
                    default:
                        Auxillary.showAlert(response["message"] as! String!)
                        receivedResponse(false, [:])
                    }
                } else {
                    Auxillary.showAlert(STATUS_CODES.SERVER_NOT_RESPONDING)
                    receivedResponse(false, [:])
                }
            }
        } else {
            Auxillary.showAlert(STATUS_CODES.NO_INTERNET_CONNECTION)
            receivedResponse(false, [:])
        }
    }
    
    
    /*------------ Request Tracking ---------------*/
    func requestForTracking(_ name:String, receivedResponse:@escaping (_ succeeded:Bool, _ response:[String:Any]) -> ()) {
        let params = [
            "device_token":UserDefaults.standard.object(forKey: USER_DEFAULT.deviceToken) != nil ? (UserDefaults.standard.object(forKey: USER_DEFAULT.deviceToken) as? String)! : "deviceToken",
            "device_type":1,
            "name":name,
            "device_id":UserDefaults.standard.object(forKey: USER_DEFAULT.deviceToken) != nil ? (UserDefaults.standard.object(forKey: USER_DEFAULT.deviceToken) as? String)! : "deviceToken"] as [String : Any]
        NSLog("Params = %@", params)
        
        if IJReachability.isConnectedToNetwork() == true {
            sendRequestToServer("request_location", params: params as [String : AnyObject], httpMethod: "POST") { (succeeded:Bool, response:[String:Any]) -> () in
                print(response)
                if(succeeded){
                    switch(response["status"] as! Int) {
                    case STATUS_CODES.SHOW_DATA, STATUS_CODES.INVALID_ACCESS_TOKEN:
                        DispatchQueue.main.async(execute: { () -> Void in
                            receivedResponse(true, response)
                        })
                        break
                        
                    case STATUS_CODES.SHOW_MESSAGE:
                        Auxillary.showAlert(response["message"] as! String!)
                        receivedResponse(false, [:])
                        break
                        
                    default:
                        Auxillary.showAlert(response["message"] as! String!)
                        receivedResponse(false, [:])
                    }
                } else {
                    Auxillary.showAlert(STATUS_CODES.SERVER_NOT_RESPONDING)
                    receivedResponse(false, [:])
                }
            }
        } else {
            Auxillary.showAlert(STATUS_CODES.NO_INTERNET_CONNECTION)
            receivedResponse(false, [:])
        }
    }
    
    
    /*------------ Validate Request ID ---------------*/
    func validateUserRequestId(_ requestID:String, receivedResponse:@escaping (_ succeeded:Bool, _ response:[String:Any]) -> ()) {
        let params = [
            "device_id":UserDefaults.standard.object(forKey: USER_DEFAULT.deviceToken) != nil ? (UserDefaults.standard.object(forKey: USER_DEFAULT.deviceToken) as? String)! : "deviceToken",
            "request_id":requestID] as [String : Any]
        
        NSLog("Params = %@", params)
        if IJReachability.isConnectedToNetwork() == true {
            sendRequestToServer("validate_request_id", params: params as [String : AnyObject], httpMethod: "POST") { (succeeded:Bool, response:[String:Any]) -> () in
                print(response)
                if(succeeded){
                    switch(response["status"] as! Int) {
                    case STATUS_CODES.SHOW_DATA, STATUS_CODES.INVALID_ACCESS_TOKEN:
                        DispatchQueue.main.async(execute: { () -> Void in
                            receivedResponse(true, response)
                        })
                        break
                        
                    case STATUS_CODES.SHOW_MESSAGE:
                        Auxillary.showAlert(response["message"] as! String!)
                        receivedResponse(false, [:])
                        break
                        
                    default:
                        Auxillary.showAlert(response["message"] as! String!)
                        receivedResponse(false, [:])
                    }
                } else {
                    Auxillary.showAlert(STATUS_CODES.SERVER_NOT_RESPONDING)
                    receivedResponse(false, [:])
                }
            }
        } else {
            Auxillary.showAlert(STATUS_CODES.NO_INTERNET_CONNECTION)
            receivedResponse(false, [:])
        }
    }
    
    /*-------------------- Start Session with request ID ----------------------*/
    //    func createSessionWithRequestId(_ emailId:String, location:[Any],phone:String, requestType:Int, sessionId:String, receivedResponse:@escaping (_ succeeded:Bool, _ response:[String:Any]) -> ()) {
    //        let params = [
    //            "device_id":UserDefaults.standard.object(forKey: USER_DEFAULT.deviceToken) != nil ? (UserDefaults.standard.object(forKey: USER_DEFAULT.deviceToken) as? String)! : "deviceToken",
    //            "location":location,
    //            "phone":phone,
    //            "request_type":requestType, // 1 for start sesstion, 0 for stop session
    //            "session_id":sessionId,
    //            "email": emailId] as [String : Any]
    //        NSLog("Params = %@", params)
    //
    //        if IJReachability.isConnectedToNetwork() == true {
    //            sendRequestToServer("create_session", params: params as [String : AnyObject], httpMethod: "POST") { (succeeded:Bool, response:[String:Any]) -> () in
    //                print(response)
    //                if(succeeded){
    //                    switch(response["status"] as! Int) {
    //                    case STATUS_CODES.SHOW_DATA, STATUS_CODES.INVALID_ACCESS_TOKEN:
    //                        DispatchQueue.main.async(execute: { () -> Void in
    //                            receivedResponse(true, response)
    //                        })
    //                        break
    //
    //                    case STATUS_CODES.SHOW_MESSAGE:
    //                        Auxillary.showAlert(response["message"] as! String!)
    //                        receivedResponse(false, [:])
    //                        break
    //
    //                    default:
    //                        Auxillary.showAlert(response["message"] as! String!)
    //                        receivedResponse(false, [:])
    //                    }
    //                } else {
    //                    Auxillary.showAlert(STATUS_CODES.SERVER_NOT_RESPONDING)
    //                    receivedResponse(false, [:])
    //                }
    //            }
    //        } else {
    //            Auxillary.showAlert(STATUS_CODES.NO_INTERNET_CONNECTION)
    //            receivedResponse(false, [:])
    //        }
    //    }
    
    
    //    func checkSessionIdExist() -> (Bool,String) {
    //        if let sessionIDText = UserDefaults.standard.value(forKey: USER_DEFAULT.sessionId) {
    //            if UserDefaults.standard.bool(forKey: USER_DEFAULT.subscribeLocation) == true {
    //                Auxillary.showAlert("You are already on tracking. Please try again.")
    //                return (true,sessionIDText as! String)
    //            } else {
    //                return (false,sessionIDText as! String)
    //            }
    //        } else {
    //            return (false,"")
    //        }
    //    }
    
    
    func getLatLongFromDirectionAPI(_ origin:String, destination:String) -> [String:Any]! {
        var encodedRoute = [String:Any]()
        if IJReachability.isConnectedToNetwork() == true {
            let urlString = "https://maps.googleapis.com/maps/api/directions/json?origin=\(origin)&destination=\(destination)&sensor=false&mode=driving&alternatives=false"
            print(urlString)
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
            if let json = URLSession.requestSynchronousJSONWithURLString(urlString) {
                encodedRoute = json as! [String:Any]
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
            }
        } else {
            encodedRoute = [:]
        }
        return encodedRoute
    }
    
    func decodePolylineForCoordinates(_ encodedPolyline: String, precision: Double = 1e5) -> [CLLocation]! {
        let data = encodedPolyline.data(using: String.Encoding.utf8)!
        let byteArray = unsafeBitCast((data as NSData).bytes, to: UnsafePointer<Int8>.self)
        let length = Int(data.count)
        var position = Int(0)
        
        var decodedCoordinates = [CLLocation]()
        
        var lat = 0.0
        var lon = 0.0
        
        while position < length {
            
            do {
                let resultingLat = try decodeSingleCoordinate(byteArray: byteArray, length: length, position: &position, precision: precision)
                lat += resultingLat
                
                let resultingLon = try decodeSingleCoordinate(byteArray: byteArray, length: length, position: &position, precision: precision)
                lon += resultingLon
            } catch {
                return nil
            }
            let location = CLLocation(latitude: lat, longitude: lon)
            decodedCoordinates.append(location)
        }
        
        return decodedCoordinates
    }
    
    
    fileprivate func decodeSingleCoordinate(byteArray: UnsafePointer<Int8>, length: Int, position: inout Int, precision: Double = 1e6) throws -> Double {
        
        guard position < length else { throw PolylineError.singleCoordinateDecodingError }
        
        let bitMask = Int8(0x1F)
        
        var coordinate: Int32 = 0
        
        var currentChar: Int8
        var componentCounter: Int32 = 0
        var component: Int32 = 0
        
        repeat {
            currentChar = byteArray[position] - 63
            component = Int32(currentChar & bitMask)
            coordinate |= (component << (5*componentCounter))
            position += 1
            componentCounter += 1
        } while ((currentChar & 0x20) == 0x20) && (position < length) && (componentCounter < 6)
        
        if (componentCounter == 6) && ((currentChar & 0x20) == 0x20) {
            throw PolylineError.singleCoordinateDecodingError
        }
        
        if (coordinate & 0x01) == 0x01 {
            coordinate = ~(coordinate >> 1)
        } else {
            coordinate = coordinate >> 1
        }
        
        return Double(coordinate) / precision
    }
    
    enum PolylineError: Error {
        case singleCoordinateDecodingError
        case chunkExtractingError
    }
    
    
}

