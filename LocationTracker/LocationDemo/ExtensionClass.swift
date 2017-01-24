//
//  ExtensionClass.swift
//  TookanVendor
//
//  Created by cl-macmini-45 on 15/11/16.
//  Copyright © 2016 clicklabs. All rights reserved.
//

import UIKit
import CoreLocation

class ExtensionClass: NSObject {

}

//MARK: String
extension String {
    func blank(_ text: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        return trimmed.isEmpty
    }
    
    var trimText:String {
        return self.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
    }
    
//    var localized: String {
//        if let path = Bundle.main.path(forResource: UserDefaults.standard.value(forKey: USER_DEFAULT.selectedLocale) as? String, ofType: "lproj") {
//            let bundle = Bundle(path: path)
//            return NSLocalizedString(self, tableName: nil, bundle: bundle!, value: "", comment: "")
//        }
//        return self
//    }
    
    var length: Int {
        return self.characters.count
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
    
    func heightWithConstrainedWidth(width: CGFloat, font: UIFont) -> CGRect {
        let constraintRect = CGSize(width: width, height: CGFloat.greatestFiniteMagnitude)
        
        let boundingBox = self.boundingRect(with: constraintRect, options: NSStringDrawingOptions.usesLineFragmentOrigin, attributes: [NSFontAttributeName: font], context: nil)
        return boundingBox
    }
    
    
    func datefromYourInputFormatToOutputFormat(input:String,output:String)-> String {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = NSLocale(localeIdentifier: "en_US_POSIX") as Locale!
        dateFormatter.dateFormat = input
        dateFormatter.timeZone = TimeZone(abbreviation:  "UTC")
        let date = dateFormatter.date(from: self)
        dateFormatter.dateFormat = output
        //dateFormatter.timeZone = NSTimeZone.local
        guard date != nil else {
            return ""
        }
        let timeStamp = dateFormatter.string(from: date!)
        return timeStamp
    }
    
    func convertDateFromUTCtoLocal(input:String,output:String)-> String {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = NSLocale(localeIdentifier: "en_US_POSIX") as Locale!
        dateFormatter.dateFormat = input
        dateFormatter.timeZone = TimeZone(abbreviation:  "UTC")
        let date = dateFormatter.date(from: self)
        dateFormatter.dateFormat = output
        dateFormatter.timeZone = NSTimeZone.local
        guard date != nil else {
            return ""
        }
        let timeStamp = dateFormatter.string(from: date!)
        return timeStamp
    }
    
    func dateFromString(withFormat:String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = NSLocale(localeIdentifier: "en_US_POSIX") as Locale!
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        dateFormatter.timeZone = NSTimeZone.local
        let date = dateFormatter.date(from: self)
        dateFormatter.dateFormat = withFormat
        dateFormatter.timeZone = NSTimeZone.local
        guard date != nil else {
            return ""
        }
        let timeStamp = dateFormatter.string(from: date!)
        return timeStamp
    }
}

extension UIView{
    func setCornerRadius(radius:CGFloat) {
        self.layer.cornerRadius = radius
        self.layer.masksToBounds = true
    }
    
    func setBorder(borderColor:UIColor) {
        self.layer.borderColor = borderColor.cgColor
        self.layer.borderWidth = 1.0
        self.layer.masksToBounds = true
    }
}

//MARK: UIButton
extension UIButton {
    func setShadow() {
        self.layer.shadowOffset = CGSize(width: 2, height: 3)
        self.layer.shadowOpacity = 0.7
        self.layer.shadowColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.5).cgColor
        self.layer.shadowRadius = 3
    }
}

extension UILabel {
    func setLabelWithFontColorText(yourtext:String, yourColor:UIColor, fontSize: CGFloat,fontName:String) {
        self.font = UIFont(name: fontName, size: fontSize)
        self.textColor = yourColor
        self.text = yourtext
    }
}

//MARK: NSLocale
extension NSLocale {
    struct locale {
        let countryCode: String
        let countryName: String
    }
    
    class func locales() -> [locale] {
        var locales = [locale]()
        for localeCode in NSLocale.isoCountryCodes {
            let countryName = Locale.current.localizedString(forRegionCode: localeCode)
            // let countryName = NSLocale().displayName(forKey: NSLocale.Key.countryCode, value: localeCode)!
            let countryCode = localeCode
            let loc = locale(countryCode: countryCode, countryName: countryName!)
            locales.append(loc)
        }
        return locales
    }
}

//MARK: Array
//extension Array {
//    var jsonString:String {
//        do {
//            let dataObject:Data? = try JSONSerialization.data(withJSONObject: self, options: JSONSerialization.WritingOptions.prettyPrinted)
//            if let data = dataObject {
//                let json = NSString(data: data, encoding: String.Encoding.utf8.rawValue)
//                if let json = json {
//                    return json as String
//                }
//            }
//        } catch {
//            print("Error")
//        }
//        return ""
//    }

func parsingLocations(locationArray:[Any])  -> [CLLocationCoordinate2D] {
    var array = [CLLocationCoordinate2D]()
    for i in (0..<locationArray.count) {
        let locationData = locationArray[i] as! [String:Any]
        /*------- For Updating Path ------------*/
        var locationDictionary = [String:Any]()
        var updatingLocationArray = [Any]()
        var latitudeString:Double?
        var longitudeString:Double?
        if let lat = locationData["lat"] as? NSNumber {
            latitudeString = Double(lat)
        } else if let lat = locationData["lat"] as? String {
            latitudeString = Double(lat)
        }
        
        if let long = locationData["lng"] as? NSNumber {
            longitudeString = Double(long)
        } else if let long = locationData["lng"] as? String {
            longitudeString = Double(long)
        }
        if let lat = locationData["latitude"] as? NSNumber {
            latitudeString = Double(lat)
        } else if let lat = locationData["latitude"] as? String {
            latitudeString = Double(lat)
        }
        
        if let long = locationData["longitude"] as? NSNumber {
            longitudeString = Double(long)
        } else if let long = locationData["longitude"] as? String {
            longitudeString = Double(long)
        }
        
        let coordinate = CLLocationCoordinate2D(latitude: latitudeString!, longitude: longitudeString!)
        locationDictionary = ["Latitude":coordinate.latitude, "Longitude":coordinate.longitude]
        array.append(coordinate)
        /*----------------------------------------------*/
    }
    return array
}

