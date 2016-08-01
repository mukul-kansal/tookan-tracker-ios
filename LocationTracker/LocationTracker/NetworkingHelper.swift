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
extension NSURLSession {
    
    /// Return data from synchronous URL request
    public static func requestSynchronousData(request: NSURLRequest) -> NSData? {
        var data: NSData? = nil
        let semaphore: dispatch_semaphore_t = dispatch_semaphore_create(0)
        let task = NSURLSession.sharedSession().dataTaskWithRequest(request, completionHandler: {
            taskData, _, error -> () in
            data = taskData
            if data == nil, let error = error {print(error)}
            dispatch_semaphore_signal(semaphore);
        })
        task.resume()
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER)
        return data
    }
    
    /// Return data synchronous from specified endpoint
    public static func requestSynchronousDataWithURLString(requestString: String) -> NSData? {
        guard let url = NSURL(string:requestString) else {return nil}
        let request = NSURLRequest(URL: url)
        return NSURLSession.requestSynchronousData(request)
    }
    
    /// Return JSON synchronous from URL request
    public static func requestSynchronousJSON(request: NSURLRequest) -> AnyObject? {
        guard let data = NSURLSession.requestSynchronousData(request) else {return nil}
        return try? NSJSONSerialization.JSONObjectWithData(data, options: [])
    }
    
    /// Return JSON synchronous from specified endpoint
    public static func requestSynchronousJSONWithURLString(requestString: String) -> AnyObject? {
        guard let url = NSURL(string: requestString) else {return nil}
        let request = NSMutableURLRequest(URL:url)
        request.HTTPMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        return NSURLSession.requestSynchronousJSON(request)
    }
}

extension String {
    var getUTCDateString:String! {
        let date = NSDate()
        let dateFormatter = NSDateFormatter()
        dateFormatter.timeZone = NSTimeZone(abbreviation:  "UTC")
        dateFormatter.locale = NSLocale(localeIdentifier: "en_US_POSIX")
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return dateFormatter.stringFromDate(date)
    }
    
    var jsonObject: NSMutableArray {
        do {
            let value = try NSJSONSerialization.JSONObjectWithData(self.dataUsingEncoding(NSUTF8StringEncoding)!, options: NSJSONReadingOptions.MutableLeaves)
            return (NSMutableArray(array: value as! [AnyObject]))
        } catch {
            print("Error")
        }
        return NSMutableArray()
    }
}

extension NSMutableArray {
    var jsonString:String {
        do {
            let dataObject:NSData? = try NSJSONSerialization.dataWithJSONObject(self, options: NSJSONWritingOptions.PrettyPrinted)
            if let data = dataObject {
                let json = NSString(data: data, encoding: NSUTF8StringEncoding)
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
    
    func getLatLongFromDirectionAPI(origin:String, destination:String) -> NSDictionary! {
        var encodedRoute = NSDictionary()
        if IJReachability.isConnectedToNetwork() == true {
            let urlString = "https://maps.googleapis.com/maps/api/directions/json?origin=\(origin)&destination=\(destination)&sensor=false&mode=driving&alternatives=false"
            print(urlString)
            UIApplication.sharedApplication().networkActivityIndicatorVisible = true
            if let json = NSURLSession.requestSynchronousJSONWithURLString(urlString) {
                encodedRoute = json as! NSDictionary
                UIApplication.sharedApplication().networkActivityIndicatorVisible = false
            }
        } else {
            encodedRoute = [:]
        }
        return encodedRoute
    }
    
    func getValidation(url:String, params: NSDictionary) -> (Bool,NSDictionary!) {
        let urlString = url.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())
        let request = NSMutableURLRequest(URL: NSURL(string: "http://tracking.tookan.io:3012/" + urlString!)!)
        request.HTTPMethod = "POST"
        request.timeoutInterval = 20
        request.HTTPBody = try! NSJSONSerialization.dataWithJSONObject(params, options: [])
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        if IJReachability.isConnectedToNetwork() == true {
            UIApplication.sharedApplication().networkActivityIndicatorVisible = true
            if let json = NSURLSession.requestSynchronousJSON(request) {
                UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                return (true, json as! NSDictionary)
            } else {
                UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                return (false, ["message":"Invalid Access"])
            }
        } else {
            return (false, ["message":"No Internet Connection"])
        }
    }
    
    func decodePolylineForCoordinates(encodedPolyline: String, precision: Double = 1e5) -> [CLLocation]! {
        let data = encodedPolyline.dataUsingEncoding(NSUTF8StringEncoding)!
        let byteArray = unsafeBitCast(data.bytes, UnsafePointer<Int8>.self)
        let length = Int(data.length)
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
    
    
    private func decodeSingleCoordinate(byteArray byteArray: UnsafePointer<Int8>, length: Int, inout position: Int, precision: Double = 1e6) throws -> Double {
        
        guard position < length else { throw PolylineError.SingleCoordinateDecodingError }
        
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
            throw PolylineError.SingleCoordinateDecodingError
        }
        
        if (coordinate & 0x01) == 0x01 {
            coordinate = ~(coordinate >> 1)
        } else {
            coordinate = coordinate >> 1
        }
        
        return Double(coordinate) / precision
    }
    
    enum PolylineError: ErrorType {
        case SingleCoordinateDecodingError
        case ChunkExtractingError
    }

    
}