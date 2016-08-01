

//
//  LocationHandler.swift
//  Tookan
//
//  Created by Click Labs on 8/13/15.
//  Copyright (c) 2015 Click Labs. All rights reserved.
//

import Foundation
import CoreLocation
import UIKit
import SystemConfiguration

@objc public protocol LocationTrackerDelegate {
    optional func currentLocation(location:CLLocation)
}


public enum LocationFrequency: Int {
    case LOW = 0
    case MEDIUM
    case HIGH
}

public class LocationTrackerFile:NSObject, CLLocationManagerDelegate {
    
    public var delegate:LocationTrackerDelegate!
    public var host = "test.tookanapp.com"
    public var portNumber:UInt16 = 1883
    public var slotTime = 5.0
    public var maxSpeed:Float = 30.0
    public var maxAccuracy = 20.0
    public var maxDistance = 20.0
    public var locationFrequencyMode = LocationFrequency.HIGH
    public var accessToken:String = ""
    public var uniqueKey:String = ""
    
    private static let locationManagerObj = CLLocationManager()
    private static let locationTracker = LocationTrackerFile()
    
    private var myLastLocation: CLLocation!
    private var myLocation: CLLocation!
    private var myLocationAccuracy: CLLocationAccuracy!
    private var locationUpdateTimer: NSTimer!
    private var locationManager:CLLocationManager!
    private var speed:Float = 0
    private var bgTask: BackgroundTaskManager?
    
    
    override init() {
        super.init()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(LocationTrackerFile.applicationEnterBackground), name: UIApplicationDidEnterBackgroundNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(LocationTrackerFile.appEnterInTerminateState), name: UIApplicationWillTerminateNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(LocationTrackerFile.enterInForegroundFromBackground), name: UIApplicationWillEnterForegroundNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(LocationTrackerFile.becomeActive), name: UIApplicationDidBecomeActiveNotification, object: nil)
        NSUserDefaults.standardUserDefaults().setBool(false, forKey: USER_DEFAULT.isHitInProgress)
        UIDevice.currentDevice().batteryMonitoringEnabled = true
    }
    
    
    public class func sharedInstance() -> LocationTrackerFile {
        return locationTracker
    }
    
    public class func sharedLocationManager() -> CLLocationManager {
        return locationManagerObj
    }
    
    func applicationEnterBackground() {
        self.setLocationUpdate()
        self.bgTask = BackgroundTaskManager.sharedBackgroundTaskManager()
        self.bgTask!.beginNewBackgroundTask()
        NSUserDefaults.standardUserDefaults().setValue("Background", forKey: USER_DEFAULT.applicationMode)
        self.updateLocationToServer()
        if(self.locationUpdateTimer != nil) {
            self.locationUpdateTimer.invalidate()
            self.locationUpdateTimer = nil
        }
        self.locationUpdateTimer = NSTimer.scheduledTimerWithTimeInterval(slotTime, target: self, selector: #selector(LocationTrackerFile.updateLocationToServer), userInfo: nil, repeats: true)
    }
    
    func enterInForegroundFromBackground(){
        NSUserDefaults.standardUserDefaults().setValue("Foreground", forKey: USER_DEFAULT.applicationMode)
        self.updateLocationToServer()
        if(self.locationUpdateTimer != nil) {
            self.locationUpdateTimer.invalidate()
            self.locationUpdateTimer = nil
        }
        self.locationUpdateTimer = NSTimer.scheduledTimerWithTimeInterval(self.slotTime, target: self, selector: #selector(LocationTrackerFile.updateLocationToServer), userInfo: nil, repeats: true)
    }
    
    func appEnterInTerminateState() {
        NSUserDefaults.standardUserDefaults().setValue("Terminate", forKey: USER_DEFAULT.applicationMode)
        if(self.locationManager != nil) {
            self.locationManager.stopUpdatingLocation()
            self.locationManager.startMonitoringSignificantLocationChanges()
        }
    }
    
    func becomeActive() {
        if(self.locationManager == nil) {
            self.restartLocationUpdates()
        }
    }

    public func getCurrentLocation() -> CLLocation {
        if(self.myLocation == nil) {
            return CLLocation()
        }
        return self.myLocation
    }
    
    private func setLocationUpdate() {
        if(NSUserDefaults.standardUserDefaults().boolForKey(USER_DEFAULT.isLocationTrackingRunning) == true) {
            MqttClass.sharedInstance.mqttSetting()
            MqttClass.sharedInstance.connectToServer()
            if(self.locationManager != nil) {
                self.locationManager.stopMonitoringSignificantLocationChanges()
            }
            locationManager = LocationTrackerFile.sharedLocationManager()
            self.setFrequency()
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
            locationManager.activityType = CLActivityType.AutomotiveNavigation
            locationManager.pausesLocationUpdatesAutomatically = false
            if(maxDistance == 0) {
                locationManager.distanceFilter = kCLDistanceFilterNone
            } else {
                locationManager.distanceFilter = maxDistance
            }
        
            if #available(iOS 9.0, *) {
                locationManager.allowsBackgroundLocationUpdates = true
            } else {
                // Fallback on earlier versions
            }
            locationManager.requestAlwaysAuthorization()
            locationManager.startUpdatingLocation()
        }
    }
    
    
     private func setFrequency() {
        switch locationFrequencyMode {
        case LocationFrequency.LOW:
            slotTime = 60.0
            maxDistance = 100.0
            break
        case LocationFrequency.MEDIUM:
            slotTime = 30.0
            maxDistance = 50.0
            break
        case LocationFrequency.HIGH:
            slotTime = 5.0
            maxDistance = 20.0
            break
        }
    }
    
    private func restartLocationUpdates() {
        if(self.locationUpdateTimer != nil) {
            self.locationUpdateTimer.invalidate()
            self.locationUpdateTimer = nil
        }
        if(self.locationManager != nil) {
            self.locationManager.stopMonitoringSignificantLocationChanges()
        }
                
        setLocationUpdate()
        self.updateLocationToServer()
        self.locationUpdateTimer = NSTimer.scheduledTimerWithTimeInterval(slotTime, target: self, selector: #selector(LocationTrackerFile.updateLocationToServer), userInfo: nil, repeats: true)
    }
    
    public func startLocationTracking() {
        NSUserDefaults.standardUserDefaults().setBool(true, forKey: USER_DEFAULT.isLocationTrackingRunning)
        setLocationUpdate()
        if(self.locationUpdateTimer != nil) {
            self.locationUpdateTimer?.invalidate()
            self.locationUpdateTimer = nil
        }
        self.updateLocationToServer()
        self.locationUpdateTimer = NSTimer.scheduledTimerWithTimeInterval(self.slotTime, target: self, selector: #selector(LocationTrackerFile.updateLocationToServer), userInfo: nil, repeats: true)
    }
    
    public func stopLocationTracking() {
        if(self.locationUpdateTimer != nil) {
            self.locationUpdateTimer.invalidate()
            self.locationUpdateTimer = nil
        }
        NSUserDefaults.standardUserDefaults().setBool(false, forKey: USER_DEFAULT.isLocationTrackingRunning)
        MqttClass.sharedInstance.disconnect()
        let locationManager: CLLocationManager = LocationTrackerFile.sharedLocationManager()
        locationManager.stopUpdatingLocation()
    }
    
    public func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        self.bgTask = BackgroundTaskManager.sharedBackgroundTaskManager()
        self.bgTask!.beginNewBackgroundTask()
        if locations.last != nil {
            self.myLocation = locations.last! as CLLocation
            self.myLocationAccuracy = self.myLocation.horizontalAccuracy
            self.applyFilterOnGetLocation()
            if(NSUserDefaults.standardUserDefaults().boolForKey(USER_DEFAULT.isLocationTrackingRunning) == true) {
                delegate.currentLocation!(self.myLocation)
            }
        }
    }
    
    private func applyFilterOnGetLocation() {
        if self.myLocation != nil  {
            var locationArray = NSMutableArray()
            if let array = NSUserDefaults.standardUserDefaults().objectForKey(USER_DEFAULT.locationArray) as? NSMutableArray {
                locationArray = NSMutableArray(array: array)
            }
            if NSUserDefaults.standardUserDefaults().boolForKey(USER_DEFAULT.isLocationTrackingRunning) == true {
                if(self.myLocationAccuracy < maxAccuracy){
                    if(self.myLastLocation == nil) {
                        var myLocationToSend = NSMutableDictionary()
                        let timestamp = String().getUTCDateString
                        myLocationToSend = ["lat" : myLocation!.coordinate.latitude as Double,"lng" :myLocation!.coordinate.longitude as Double, "tm_stmp" : timestamp, "bat_lvl" : UIDevice.currentDevice().batteryLevel * 100, "acc":(self.myLocationAccuracy != nil ? self.myLocationAccuracy! : 300)]
                        self.addFilteredLocationToLocationArray(myLocationToSend)
                        self.myLastLocation = self.myLocation
                    } else {
                        if(self.getSpeed() < maxSpeed) {
                            var myLocationToSend = NSMutableDictionary()
                            let timestamp = String().getUTCDateString
                            myLocationToSend = ["lat" : myLocation!.coordinate.latitude as Double,"lng" :myLocation!.coordinate.longitude as Double, "tm_stmp" : timestamp, "bat_lvl" : UIDevice.currentDevice().batteryLevel * 100, "acc":(self.myLocationAccuracy != nil ? self.myLocationAccuracy! : 300)]
                            self.addFilteredLocationToLocationArray(myLocationToSend)
                            self.myLastLocation = self.myLocation
                        }
                    }
                }
            }
            
          //  if(NSUserDefaults.standardUserDefaults().valueForKey(USER_DEFAULT.applicationMode) != nil && (NSUserDefaults.standardUserDefaults().valueForKey(USER_DEFAULT.applicationMode) as! String == "Background" || NSUserDefaults.standardUserDefaults().valueForKey(USER_DEFAULT.applicationMode) as! String == "Terminate")) {
                if(NSUserDefaults.standardUserDefaults().boolForKey(USER_DEFAULT.isHitInProgress) == false) {
                    if locationArray.count >= 5 {
                        let locationString = locationArray.jsonString
                        sendRequestToServer(locationString)
                    }
                }
            //}
        }
    }
    
    private func addFilteredLocationToLocationArray(myLocationToSend:NSMutableDictionary) {
        if(NSUserDefaults.standardUserDefaults().boolForKey(USER_DEFAULT.isLocationTrackingRunning) == true){
            var locationArray = NSMutableArray()
            if let array = NSUserDefaults.standardUserDefaults().objectForKey(USER_DEFAULT.locationArray) as? NSMutableArray {
                locationArray = NSMutableArray(array: array)
            }
            if(locationArray.count >= 1000) {
                locationArray.removeObjectAtIndex(0)
            }
            locationArray.addObject(myLocationToSend)
            NSUserDefaults.standardUserDefaults().setObject(locationArray, forKey: USER_DEFAULT.locationArray)
        }
    }
    
    
     func updateLocationToServer() {
        var locationArray = NSMutableArray()
        if let array = NSUserDefaults.standardUserDefaults().objectForKey(USER_DEFAULT.locationArray) as? NSMutableArray {
            locationArray = NSMutableArray(array: array)
        }
        if IJReachability.isConnectedToNetwork(){
            if(NSUserDefaults.standardUserDefaults().boolForKey(USER_DEFAULT.isHitInProgress) == false) {
                if locationArray.count > 0 {
                    let locationString = locationArray.jsonString
                    sendRequestToServer(locationString)
                }
            }
        }
    }
    
    private func sendRequestToServer(locationString:String) {
        if(NSUserDefaults.standardUserDefaults().boolForKey(USER_DEFAULT.isLocationTrackingRunning) == true) {
            MqttClass.sharedInstance.hostAddress = self.host
            MqttClass.sharedInstance.portNumber = self.portNumber
            MqttClass.sharedInstance.accessToken = self.accessToken
            MqttClass.sharedInstance.key = self.uniqueKey
            MqttClass.sharedInstance.sendLocation(locationString)//MQTT
        }
    }
    
    private func updateLastSavedLocationOnServer() {
        if(NSUserDefaults.standardUserDefaults().boolForKey(USER_DEFAULT.isLocationTrackingRunning) == true) {
            var locationArray = NSMutableArray()
            if let array = NSUserDefaults.standardUserDefaults().objectForKey(USER_DEFAULT.locationArray) as? NSMutableArray {
                locationArray = NSMutableArray(array: array)
            }
            self.setLocationUpdate()
            if(NSUserDefaults.standardUserDefaults().boolForKey(USER_DEFAULT.isHitInProgress) == false) {
                if(locationArray.count > 0) {
                    sendRequestToServer(locationArray.jsonString)
                } else {
                    var myLocationToSend = NSMutableDictionary()
                    myLocationToSend = ["bat_lvl" : UIDevice.currentDevice().batteryLevel * 100]
                    let highLocationArray = NSMutableArray()
                    highLocationArray.addObject(myLocationToSend)
                    let locationString = highLocationArray.jsonString
                    sendRequestToServer(locationString)
                }
            }
        }
    }
    
    private func getSpeed() -> Float {
        if(myLastLocation != nil) {
            let time = self.myLocation.timestamp.timeIntervalSinceDate(myLastLocation.timestamp)
            let distance:CLLocationDistance = myLocation.distanceFromLocation(myLastLocation)
            if(distance > 200) {
                self.locationManager.stopUpdatingLocation()
                if let json = NetworkingHelper.sharedInstance.getLatLongFromDirectionAPI("\(myLastLocation.coordinate.latitude),\(myLastLocation.coordinate.longitude)", destination: "\(myLocation.coordinate.latitude),\(myLocation.coordinate.longitude)") {
                    UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                    if let routes = json["routes"] {
                        if(routes.count > 0) {
                            if let legs = routes[0]["legs"]!{
                                if(legs.count > 0) {
                                    if let _ = legs[0]["distance"]!!["value"] as? Int {
                                        //                                if(distance < 200) {
                                        if let polyline = routes[0]["overview_polyline"]!!["points"] as? String {
                                            let locations = NetworkingHelper.sharedInstance.decodePolylineForCoordinates(polyline)
                                            for i in (0..<locations.count) {
                                                var myLocationToSend = NSMutableDictionary()
                                                let timestamp = String().getUTCDateString
                                                myLocationToSend = ["lat" : locations[i].coordinate.latitude as Double,"lng" :locations[i].coordinate.longitude as Double, "tm_stmp" : timestamp, "bat_lvl" : UIDevice.currentDevice().batteryLevel * 100,"acc":(self.myLocationAccuracy != nil ? self.myLocationAccuracy! : 300)]
                                               
                                                self.addFilteredLocationToLocationArray(myLocationToSend)
                                                self.myLastLocation = CLLocation(latitude: locations[i].coordinate.latitude, longitude: locations[i].coordinate.longitude)
                                                self.setLocationUpdate()
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    } else {
                        UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                        self.setLocationUpdate()
                        speed = Float(distance) / Float(time)
                        if(speed > 0) {
                            return speed
                        }
                        return 0.0
                    }
                } else {
                    UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                    self.setLocationUpdate()
                    speed = Float(distance) / Float(time)
                    if(speed > 0) {
                        return speed
                    }
                    return 0.0
                }
                return 0.0
            } else {
                speed = Float(distance) / Float(time)
                if(speed > 0) {
                    return speed
                }
                return 0.0
            }
        }
        return 0.0
    }
    
    public func isAllPermissionAuthorized() -> (Bool, String) {
        //We have to make sure that the Background App Refresh is enable for the Location updates to work in the background.
        if(UIApplication.sharedApplication().backgroundRefreshStatus == UIBackgroundRefreshStatus.Denied) {
            return (false,"The app doesn't work without the Background App Refresh enabled.")
        } else if (UIApplication.sharedApplication().backgroundRefreshStatus == UIBackgroundRefreshStatus.Restricted) {
            return (false,"The app doesn't work without the Background App Refresh enabled.")
        } else {
            return self.isAppLocationEnabled()
        }
    }
    
    private func isAppLocationEnabled() -> (Bool,String) {
        if CLLocationManager.locationServicesEnabled() == false {
            return (false,"Background Location Access Disabled")
        } else {
            let authorizationStatus = CLLocationManager.authorizationStatus()
            if authorizationStatus == CLAuthorizationStatus.Denied || authorizationStatus == CLAuthorizationStatus.Restricted {
                return (false,"Background Location Access Disabled")
            } else {
                return self.isAuthorizedUser()
            }
        }
    }
    
    private func isAuthorizedUser() -> (Bool,String) {
        let params = ["u_socket_id":uniqueKey,"f_socket_id":self.accessToken]
        let jsonResponse = NetworkingHelper.sharedInstance.getValidation("validate", params: params)
        if(jsonResponse.0 == true) {
            let json = jsonResponse.1
            if let status = json["status"] as? Int {
                if status == 200 {
                   return (true,json["message"] as! String)
                } else {
                    return (false,json["message"] as! String)
                }
            }
            return (false,"Invalid Access")
        } else {
            let json = jsonResponse.1
            return (false,json["message"] as! String)
        }
    }
}

