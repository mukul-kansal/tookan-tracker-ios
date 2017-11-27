//
//  TrackerModel.swift
//  Tracker
//
//  Created by cl-macmini-45 on 29/09/16.
//  Copyright © 2016 clicklabs. All rights reserved.
//

import UIKit
import CoreLocation

class TrackerModel: NSObject {

    func isSessionIdExist() -> Bool {
        if let sessionIDText = UserDefaults.standard.value(forKey: USER_DEFAULT.sessionId) as? String {
            if sessionIDText != "" {
                return true
            }
        }
        return false
    }
    
    func isTrackingLocation() -> Bool {
        if UserDefaults.standard.bool(forKey: USER_DEFAULT.subscribeLocation) {
            return UserDefaults.standard.bool(forKey: USER_DEFAULT.subscribeLocation)
        }
        return false
    }
    
    func getLocationArrayObject(location:CLLocation) -> [Any] {
        let locationObject:[String:Any] = ["lat":location.coordinate.latitude,"lng":location.coordinate.longitude]
        var locationArray = [Any]()
        locationArray.append(locationObject)
        return locationArray
    }
    
    func updatePathLocations(locationArray:[String:Any]) -> CLLocationCoordinate2D {
        /*------- For Updating Path ------------*/
        var locationDictionary = [String:Any]()
        var updatingLocationArray = [Any]()
        var latitudeString:Double?
        var longitudeString:Double?
        if let lat = locationArray["lat"] as? NSNumber {
            latitudeString = Double(lat)
        } else if let lat = locationArray["lat"] as? String {
            latitudeString = Double(lat)
        }
        
        if let long = locationArray["lng"] as? NSNumber {
            longitudeString = Double(long)
        } else if let long = locationArray["lng"] as? String {
            longitudeString = Double(long)
        }
        
        let coordinate = CLLocationCoordinate2D(latitude: latitudeString!, longitude: longitudeString!)
        locationDictionary = ["Latitude":coordinate.latitude, "Longitude":coordinate.longitude]
        if let array = UserDefaults.standard.value(forKey: USER_DEFAULT.updatingLocationPathArray) as? [Any]{
            updatingLocationArray = array
        }
        updatingLocationArray.append(locationDictionary)
        UserDefaults.standard.setValue(updatingLocationArray, forKey: USER_DEFAULT.updatingLocationPathArray)
        return coordinate
    }
    
    
    //MARK: Reset Data
    func resetSessionId() {
        UserDefaults.standard.removeObject(forKey: USER_DEFAULT.sessionId)
    }
    
    func resetTrackingBool() {
        UserDefaults.standard.set(false, forKey: USER_DEFAULT.subscribeLocation)
    }
    
    func resetLocationArray() {
        UserDefaults.standard.set([Any](), forKey: USER_DEFAULT.locationArray)
    }
    
    func resetPathLocationsArray() {
        UserDefaults.standard.setValue([Any](), forKey: USER_DEFAULT.updatingLocationPathArray)
    }
    
    func resetSessionUrl() {
        UserDefaults.standard.removeObject(forKey: USER_DEFAULT.sessionURL)
    }
    
    func resetAllData() {
        self.resetSessionId()
        self.resetTrackingBool()
        self.resetLocationArray()
        self.resetPathLocationsArray()
        self.resetSessionUrl()
    }
}
