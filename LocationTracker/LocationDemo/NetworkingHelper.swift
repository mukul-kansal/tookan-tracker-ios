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

//MARK: NSURLSession
extension URLSession {
    
    /// Return data from synchronous URL request
    public static func requestSynchronousData(_ request: URLRequest) -> Data? {
        var data: Data? = nil
        let semaphore: DispatchSemaphore = DispatchSemaphore(value: 0)
        let task = URLSession.shared.dataTask(with: request, completionHandler: {
            taskData, _, error -> () in
            data = taskData
            if data == nil, let error = error {print(error)}
            semaphore.signal();
        })
        task.resume()
        semaphore.wait(timeout: DispatchTime.distantFuture)
        return data
    }
    
    /// Return data synchronous from specified endpoint
    public static func requestSynchronousDataWithURLString(_ requestString: String) -> Data? {
        guard let url = URL(string:requestString) else {return nil}
        let request = URLRequest(url: url)
        return URLSession.requestSynchronousData(request)
    }
    
    /// Return JSON synchronous from URL request
    public static func requestSynchronousJSON(_ request: URLRequest) -> AnyObject? {
        guard let data = URLSession.requestSynchronousData(request) else {return nil}
        return try! JSONSerialization.jsonObject(with: data, options: []) as AnyObject?
    }
    
    /// Return JSON synchronous from specified endpoint
    public static func requestSynchronousJSONWithURLString(_ requestString: String) -> AnyObject? {
        guard let url = URL(string: requestString) else {return nil}
        let request = NSMutableURLRequest(url:url)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        return URLSession.requestSynchronousJSON(request as URLRequest)
    }
}

extension String {
    var getUTCDateString:String! {
        let date = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone(abbreviation:  "UTC")
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return dateFormatter.string(from: date)
    }
    
    var jsonObject: [Any] {
        do {
            let value = try JSONSerialization.jsonObject(with: self.data(using: String.Encoding.utf8)!, options: JSONSerialization.ReadingOptions.mutableLeaves)
            print("asdasdadasdad"+"\(value)" + "dasdasdasdasdasd")
            if let array = value as? [Any]{
                print("samneet")
                return array
            }
            return value as! [Any]
        } catch {
            print("Error")
        }
        return [Any]()
    }
}

extension Array {
    var jsonString:String {
        do {
            let dataObject:Data? = try JSONSerialization.data(withJSONObject: self, options: JSONSerialization.WritingOptions.prettyPrinted)
            if let data = dataObject {
                let json = NSString(data: data, encoding: String.Encoding.utf8.rawValue)
                if let json = json {
                    return json as String
                }
            }
        } catch {
            print("Error")
        }
        return ""
    }
}

struct USER_DEFAULT {
    static let locationArray = "LocationArray"
    static let applicationMode = "ApplicationMode"
    static let isHitInProgress = "isHitInProgress"
    static let isLocationTrackingRunning = "isLocationTrackingRunning"
}


class NetworkingHelper: NSObject {
    
    static let sharedInstance = NetworkingHelper()
    
    func getLatLongFromDirectionAPI(_ origin:String, destination:String) -> NSDictionary! {
        var encodedRoute = NSDictionary()
        if IJReachability.isConnectedToNetwork() == true {
            let urlString = "https://maps.googleapis.com/maps/api/directions/json?origin=\(origin)&destination=\(destination)&sensor=false&mode=driving&alternatives=false"
            print(urlString)
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
            if let json = URLSession.requestSynchronousJSONWithURLString(urlString) {
                encodedRoute = json as! NSDictionary
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
    
    
    func getValidation(_ url:String, params: [String:Any]) -> (Bool,[String:Any]?) {
        
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        let urlString = url.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)
        let request = NSMutableURLRequest(url: URL(string: "https://api2.tookanapp.com:8080/" + urlString!)!)
        request.httpMethod = "POST"
        request.timeoutInterval = 20
        request.httpBody = try! JSONSerialization.data(withJSONObject: params, options: [])
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        if IJReachability.isConnectedToNetwork() == true {
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
            if let json = URLSession.requestSynchronousJSON(request as URLRequest) {
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
               // print("jsonData" + "\(json)")
                return (true, json as! [String:Any])
            } else {
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
                return (false, ["message":"Invalid Access"])
            }
        } else {
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
            return (false, ["message":"No Internet Connection"])
        }
    }

    
}
