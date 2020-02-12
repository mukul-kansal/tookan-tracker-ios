//
//  ExtensionClass.swift
//  Tracker
//
//  Created by cl-macmini-45 on 27/09/16.
//  Copyright © 2016 clicklabs. All rights reserved.
//

import UIKit
import CoreLocation
class ExtensionClass: NSObject {

}

extension CLLocationDegrees {
    var accuracyFive:CLLocationDegrees! {
        return (self.accuracyFive*10000)/100000
    }
}

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
        _ = semaphore.wait(timeout: DispatchTime.distantFuture)
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
    
    var jsonObject: NSMutableArray {
        do {
            let value = try JSONSerialization.jsonObject(with: self.data(using: String.Encoding.utf8)!, options: JSONSerialization.ReadingOptions.mutableLeaves)
            return (NSMutableArray(array: value as! [AnyObject]))
        } catch {
            print("Error")
        }
        return NSMutableArray()
    }
    
    var jsonObjectArray: [Any] {
        do {
            let value = try JSONSerialization.jsonObject(with: self.data(using: String.Encoding.utf8)!, options: JSONSerialization.ReadingOptions.mutableLeaves) as? [Any]
            return value!
        } catch {
            print("Error")
        }
        return []
    }
    
    func blank(_ text: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        return trimmed.isEmpty
    }
    
    var trimText:String {
        return self.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
    }
}

//MARK: NSDictionary
extension Dictionary {
    var jsonString:String {
        do {
            
//            let jsonData = try JSONSerialization.data(withJSONObject: self, options: .prettyPrinted)
//            // here "jsonData" is the dictionary encoded in JSON data
//
//            let decoded = try JSONSerialization.jsonObject(with: jsonData, options: [])
//            // here "decoded" is an `AnyObject` decoded from JSON data
//
//            // you can now cast it with the right type
//            if let dictFromJSON = decoded as? [String:String] {
//                // use dictFromJSON
//            }
            
            
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

extension Date {
    var millisecondsSince1970:Int64 {
        return Int64((self.timeIntervalSince1970 * 1000.0).rounded())
    }
    
    init(milliseconds:Int) {
        self = Date(timeIntervalSince1970: TimeInterval(milliseconds / 1000))
    }
}

extension NSMutableArray {
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

//MARK: Array
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

//MARK: UIColor
extension UIColor {
    var trackerColor:UIColor {
        return UIColor(red: 48/255, green: 51/255, blue: 57/255, alpha: 1.0)
    }
    
    var poweredColor:UIColor {
        return UIColor(red: 0, green: 0, blue: 0, alpha: 0.8)
    }
    
    var stopButtonColor:UIColor {
        return UIColor(red: 22/255, green: 144/255, blue: 247/255, alpha: 1.0)
    }
    
    var stopButtonTitleColor:UIColor {
        return UIColor.white
    }
}



public extension UIDevice {
    
    var modelName: String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8 , value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        
        switch identifier {
        case "iPod5,1":                                 return "iPod Touch 5"
        case "iPod7,1":                                 return "iPod Touch 6"
        case "iPhone3,1", "iPhone3,2", "iPhone3,3":     return "iPhone 4"
        case "iPhone4,1":                               return "iPhone 4s"
        case "iPhone5,1", "iPhone5,2":                  return "iPhone 5"
        case "iPhone5,3", "iPhone5,4":                  return "iPhone 5c"
        case "iPhone6,1", "iPhone6,2":                  return "iPhone 5s"
        case "iPhone7,2":                               return "iPhone 6"
        case "iPhone7,1":                               return "iPhone 6 Plus"
        case "iPhone8,1":                               return "iPhone 6s"
        case "iPhone8,2":                               return "iPhone 6s Plus"
        case "iPhone8,4":                               return "iPhone SE"
        case "iPad2,1", "iPad2,2", "iPad2,3", "iPad2,4":return "iPad 2"
        case "iPad3,1", "iPad3,2", "iPad3,3":           return "iPad 3"
        case "iPad3,4", "iPad3,5", "iPad3,6":           return "iPad 4"
        case "iPad4,1", "iPad4,2", "iPad4,3":           return "iPad Air"
        case "iPad5,3", "iPad5,4":                      return "iPad Air 2"
        case "iPad2,5", "iPad2,6", "iPad2,7":           return "iPad Mini"
        case "iPad4,4", "iPad4,5", "iPad4,6":           return "iPad Mini 2"
        case "iPad4,7", "iPad4,8", "iPad4,9":           return "iPad Mini 3"
        case "iPad5,1", "iPad5,2":                      return "iPad Mini 4"
        case "iPad6,3", "iPad6,4", "iPad6,7", "iPad6,8":return "iPad Pro"
        case "AppleTV5,3":                              return "Apple TV"
        case "i386", "x86_64":                          return "Simulator"
        default:                                        return identifier
        }
    }
    
}

