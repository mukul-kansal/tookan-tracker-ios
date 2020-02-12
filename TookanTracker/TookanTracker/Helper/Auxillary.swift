//
//  Auxillary.swift
//  Tookan
//
//  Created by Click Labs on 8/1/15.
//  Copyright (c) 2015 Click Labs. All rights reserved.
//

import Foundation
import CoreLocation
import UIKit
import CoreTelephony
import CoreData
import AVFoundation

class Auxillary: NSObject {
    
    
    var newArray = [String]()
    
    class func validateEmail(_ candidate: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,6}"
        return NSPredicate(format: "SELF MATCHES %@", emailRegex).evaluate(with: candidate)
    }
    
    class func verifyUrl (_ urlString: String?) -> Bool {
        //Check for nil
        let urlRegex = "((http|https)://)?((\\w)*|([0-9]*)|([-|_])*)+([\\.|/]((\\w)*|([0-9]*)|([-|_])*))+"
        return NSPredicate(format: "SELF MATCHES %@", urlRegex).evaluate(with: urlString)
    }
    
    class func getTimeFromTimeAndDate(_ dateReceived: String, onlyTime:Bool, onlyDate:Bool) -> String{
        var timeToSend = String()
        
        let formatter  = DateFormatter()
        formatter.locale = NSLocale(localeIdentifier: "en_US_POSIX") as Locale?
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss" 
        let time1 = formatter.date(from: dateReceived)
        if(time1 != nil) {
            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
           // print(dateReceived)
            let todayDate = formatter.date(from: dateReceived)!
            if(onlyTime) {
                formatter.dateFormat = "hh:mm a"
            } else if(onlyDate == true) {
                formatter.dateFormat = "dd MMM, yyyy"
            } else {
                formatter.dateFormat = "hh:mm a, dd MMM"
            }
            timeToSend = formatter.string(from: todayDate)
        } else {
            timeToSend = "N/A"
        }
        
        return timeToSend
    }

    class func convertStringToDate(_ dateString:String) -> Date {
        let styler = DateFormatter()
        styler.locale = NSLocale(localeIdentifier: "en_US_POSIX") as Locale?
        styler.timeZone = TimeZone(abbreviation:  "UTC")
        styler.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let dateFromServer = styler.date(from: dateString)
        //NSTimeZone(name: "UTC")
        if(dateFromServer != nil) {
            styler.timeZone = TimeZone.autoupdatingCurrent
            let utcDateString = styler.string(from: dateFromServer!)
            styler.timeZone = TimeZone(abbreviation:  "UTC")
            return styler.date(from: utcDateString)!
        } else {
            return Date()
        }
    }
    
    class func convertUTCStringToLocalString(_ utcDate:String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone(abbreviation:  "UTC")
        dateFormatter.locale = NSLocale(localeIdentifier: "en_US_POSIX") as Locale?
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let date = dateFormatter.date(from: utcDate)
        dateFormatter.timeZone = TimeZone.current
        return dateFormatter.string(from: date!)
    }
    
    class func getLocalDateString() -> String {
        let date = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone.current
        dateFormatter.locale = NSLocale(localeIdentifier: "en_US_POSIX") as Locale?
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return dateFormatter.string(from: date)
    }
    
    class func getUTCDateString() -> String {
        let date = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone(abbreviation:  "UTC")
        dateFormatter.locale = NSLocale(localeIdentifier: "en_US_POSIX") as Locale?
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return dateFormatter.string(from: date)
    }
    
    
    class func convertDateToString() -> String {
        let styler = DateFormatter()
        styler.locale = NSLocale(localeIdentifier: "en_US_POSIX") as Locale?
        styler.timeZone = TimeZone(abbreviation:  "UTC")
        styler.dateFormat = "yyyy-MM-dd_HH:mm:ss"
        return styler.string(from: Date())
    }
    
    
    class func currentDate() -> Date {
       let styler = DateFormatter()
        styler.locale = NSLocale(localeIdentifier: "en_US_POSIX") as Locale?
        styler.timeZone = TimeZone.autoupdatingCurrent
        styler.dateFormat = "yyyy-MM-dd HH:mm:ss +0000"
        let currentDateString = styler.string(from: Date())
         styler.timeZone = TimeZone(abbreviation:  "UTC")
        return (styler.date(from: currentDateString))!
    }
    
    class func showAlert(_ message:String) {
        DispatchQueue.main.async(execute: { () -> Void in
            let alertView = UIAlertView(title: "", message: message, delegate: nil, cancelButtonTitle: "OK")
            alertView.show()
        })
    }
    
    class func currentDialingCode() -> String {
        let networkInfo = CTTelephonyNetworkInfo()
        let carrier = networkInfo.subscriberCellularProvider
            // Get carrier name
        return (carrier?.isoCountryCode) != nil ? (carrier?.isoCountryCode)! : ""
    }
    
    class func logoutFromDevice() {
        
        UserDefaults.standard.removeObject(forKey: "accessToken")
        UserDefaults.standard.set([Any](), forKey: USER_DEFAULT.locationArray)
        UserDefaults.standard.setValue([Any](), forKey: USER_DEFAULT.updatingLocationPathArray)
    }
    
    class func deleteAllFilesFromDocumentDirectory(){
        let dirPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as String
        let imagePath = URL(fileURLWithPath: dirPath).appendingPathComponent("Image")
        let fileManager = FileManager.default
        do {
            let directoryContents:[URL] = try fileManager.contentsOfDirectory(at: imagePath, includingPropertiesForKeys: nil, options: FileManager.DirectoryEnumerationOptions.skipsHiddenFiles) //fileManager.contentsOfDirectoryAtPath(tempDirPath, error: error)?
            for path in directoryContents {
                //print(path)
                let fullPath = imagePath.appendingPathComponent((path).path)//dirPath.stringByAppendingString(path as! String)
                do {
                    //print(fullPath)
                    try fileManager.removeItem(at: fullPath)
                } catch let error as NSError {
                    print("Error in removing Path = \(error.description)")
                }
            }
        } catch let error as NSError {
           print("Error in removing Path = \(error.description)")
        }
    }
    
    class func deleteImageFromDocumentDirectory(_ imagePath:String) {
       // print(imagePath)
        let fileManager = FileManager.default
        let filePath = self.createPath(imagePath)
        do {
            try fileManager.removeItem(atPath: filePath)
        } catch let error as NSError {
            print("Error in removing Path = \(error.description)")
        }
    }
    
    class func createPath(_ imageName:String) -> String {
        let fileManager = FileManager.default
        let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as String
        let url = URL(fileURLWithPath: path)
        let imageDirUrl = url.appendingPathComponent("Image")
        var isDirectory:ObjCBool = false
        if fileManager.fileExists(atPath: imageDirUrl.path, isDirectory: &isDirectory) == false {
            do {
                try FileManager.default.createDirectory(atPath: imageDirUrl.path, withIntermediateDirectories: false, attributes: nil)
            } catch let error as NSError {
                print(error.localizedDescription);
            }
        }
        let filePath = imageDirUrl.appendingPathComponent(imageName).path
        return filePath
    }
    
    class func isFileExistAtPath(_ path:String) -> Bool {
      //  print(path)
        let filePath = self.createPath(path)
        let fileManager = FileManager.default
        return fileManager.fileExists(atPath: filePath)
    }
    
    class func locationWithBearing(_ bearing:Double, distanceMeters:Double, origin:CLLocationCoordinate2D) -> CLLocationCoordinate2D {
        let distRadians = distanceMeters / (6372797.6)
        let rbearing = bearing * M_PI / 180.0
        let lat1 = origin.latitude * M_PI / 180
        let lon1 = origin.longitude * M_PI / 180
        let lat2 = asin(sin(lat1) * cos(distRadians) + cos(lat1) * sin(distRadians) * cos(rbearing))
        let lon2 = lon1 + atan2(sin(rbearing) * sin(distRadians) * cos(lat1), cos(distRadians) - sin(lat1) * sin(lat2))
        return CLLocationCoordinate2D(latitude: lat2 * 180 / M_PI, longitude: lon2 * 180 / M_PI)
    }
    
}
