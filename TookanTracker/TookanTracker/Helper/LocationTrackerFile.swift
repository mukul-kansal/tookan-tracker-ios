

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
import MapKit

@objc public protocol LocationTrackerDelegate {
    @objc optional func currentLocationOfUser(_ location:CLLocation)
    
}

@objc public protocol TrackingDelegate {
    @objc optional func getCoordinates(_ location:CLLocation)
    @objc optional func logout()
}

public enum LocationFrequency: Int {
    case low = 0
    case medium
    case high
}

open class LocationTrackerFile:NSObject, CLLocationManagerDelegate, MKMapViewDelegate {
    
    open var delegate:LocationTrackerDelegate!
    var trackingDelegate:TrackingDelegate!
    //fileprivate var host = "dev.tracking.tookan.io"////"test.mosquitto.org"//"test.tookanapp.com"//
    //fileprivate var portNumber:UInt16 = 1883
    fileprivate var slotTime = 5.0
    fileprivate var maxSpeed:Float = 30.0
    var maxAccuracy = 20.0
    fileprivate var maxDistance = 20.0
    open var locationFrequencyMode = LocationFrequency.high
  //  open var accessToken:String = ""
  //  open var uniqueKey:String = ""
    open var topic = ""
    var firstTime = true
    fileprivate static let locationManagerObj = CLLocationManager()
    fileprivate static let locationTracker = LocationTrackerFile()
    
    fileprivate var myLastLocation: CLLocation!
    fileprivate var myLocation: CLLocation!
    var myLocationAccuracy: CLLocationAccuracy!
    fileprivate var locationUpdateTimer: Timer!
    fileprivate var locationManager:CLLocationManager!
    fileprivate var speed:Float = 0
    fileprivate var bgTask: BackgroundTaskManager?
//    var getCoordinates : ((_ coordinates: CLLocation) -> Void)?
    
    let SDKVersion = "1.0"
    
    override init() {
        super.init()
//        NotificationCenter.default.addObserver(self, selector: #selector(LocationTrackerFile.applicationEnterBackground), name: NSNotification.Name.UIApplicationDidEnterBackground, object: nil)
//        NotificationCenter.default.addObserver(self, selector: #selector(LocationTrackerFile.appEnterInTerminateState), name: NSNotification.Name.UIApplicationWillTerminate, object: nil)
//        NotificationCenter.default.addObserver(self, selector: #selector(LocationTrackerFile.enterInForegroundFromBackground), name: NSNotification.Name.UIApplicationWillEnterForeground, object: nil)
////        NotificationCenter.default.addObserver(self, selector: #selector(LocationTrackerFile.becomeActive), name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
//        UserDefaults.standard.set(false, forKey: USER_DEFAULT.isHitInProgress)
        UIDevice.current.isBatteryMonitoringEnabled = true
    }
    
    
    open class func sharedInstance() -> LocationTrackerFile {
        return locationTracker
    }
    
    open class func sharedLocationManager() -> CLLocationManager {
        return locationManagerObj
    }
    
    @objc func applicationEnterBackground() {
        self.setLocationUpdate()
        self.bgTask = BackgroundTaskManager.sharedBackgroundTaskManager()
        _ = self.bgTask!.beginNewBackgroundTask()
        UserDefaults.standard.setValue("Background", forKey: USER_DEFAULT.applicationMode)
        self.updateLocationToServer()
        if(self.locationUpdateTimer != nil) {
            self.locationUpdateTimer.invalidate()
            self.locationUpdateTimer = nil
        }
        self.locationUpdateTimer = Timer.scheduledTimer(timeInterval: slotTime, target: self, selector: #selector(LocationTrackerFile.updateLocationToServer), userInfo: nil, repeats: true)
    }
    
    @objc func enterInForegroundFromBackground(){
        UserDefaults.standard.setValue("Foreground", forKey: USER_DEFAULT.applicationMode)
        self.updateLocationToServer()
        if(self.locationUpdateTimer != nil) {
            self.locationUpdateTimer.invalidate()
            self.locationUpdateTimer = nil
        }
        self.locationUpdateTimer = Timer.scheduledTimer(timeInterval: self.slotTime, target: self, selector: #selector(LocationTrackerFile.updateLocationToServer), userInfo: nil, repeats: true)
    }
    
    @objc func appEnterInTerminateState() {
        UserDefaults.standard.setValue("Terminate", forKey: USER_DEFAULT.applicationMode)
        if(self.locationManager != nil) {
            self.locationManager.stopUpdatingLocation()
            self.locationManager.startMonitoringSignificantLocationChanges()
        }
    }
    
    @objc func becomeActive() {
        if(UserDefaults.standard.bool(forKey: USER_DEFAULT.isLocationTrackingRunning) == true) && self.locationManager == nil{
            self.restartLocationUpdates()
        }
    }

    func registerAllRequiredInitilazers()  {
//        self.delegate = controller as! LocationTrackerDelegate
        self.initMqtt()
        self.locationFrequencyMode = LocationFrequency.high
        self.setLocationUpdate()
        _ = self.startLocationService()
        self.subsribeMQTTForTracking()
    }
    
    open func getCurrentLocation() -> CLLocation! {
        if(self.myLocation == nil) {
            return CLLocation()
        }
        return self.myLocation
    }
    
    open func initMqtt() {
        MqttClass.sharedInstance.mqttSetting()
        MqttClass.sharedInstance.connectToServer()
    }
    
    open func setLocationUpdate() {
        //if(UserDefaults.standard.bool(forKey: USER_DEFAULT.isLocationTrackingRunning) == true) {
            if(self.locationManager != nil) {
                self.locationManager.stopMonitoringSignificantLocationChanges()
            }
            locationManager = LocationTrackerFile.sharedLocationManager()
            self.setFrequency()
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
            locationManager.activityType = CLActivityType.automotiveNavigation
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
        //}
    }
    
    
     fileprivate func setFrequency() {
        switch locationFrequencyMode {
        case LocationFrequency.low:
            slotTime = 60.0
            maxDistance = 100.0
            break
        case LocationFrequency.medium:
            slotTime = 30.0
            maxDistance = 50.0
            break
        case LocationFrequency.high:
            slotTime = 5.0
            maxDistance = 0
            break
        }
    }
    
    fileprivate func restartLocationUpdates() {
        if(self.locationUpdateTimer != nil) {
            self.locationUpdateTimer.invalidate()
            self.locationUpdateTimer = nil
        }
        if(self.locationManager != nil) {
            self.locationManager.stopMonitoringSignificantLocationChanges()
        }
                
        setLocationUpdate()
        self.updateLocationToServer()
        self.locationUpdateTimer = Timer.scheduledTimer(timeInterval: slotTime, target: self, selector: #selector(LocationTrackerFile.updateLocationToServer), userInfo: nil, repeats: true)
    }
    
    open func subsribeMQTTForTracking() {
        //MqttClass.sharedInstance.hostAddress = self.host
        //MqttClass.sharedInstance.portNumber = self.portNumber
       // MqttClass.sharedInstance.accessToken = self.accessToken
       // MqttClass.sharedInstance.key = self.uniqueKey
      //  MqttClass.sharedInstance.mqttSetting()
      //  MqttClass.sharedInstance.connectToServer()
        MqttClass.sharedInstance.topic = self.topic
        MqttClass.sharedInstance.subscribeLocation()
    }
    
    open func startLocationService() -> (Bool, String) {
        let response = self.isAllPermissionAuthorized()
        if(response.0 == true) {
            //UserDefaults.standard.set(true, forKey: USER_DEFAULT.isLocationTrackingRunning)
            //setLocationUpdate()
            if(self.locationUpdateTimer != nil) {
                self.locationUpdateTimer?.invalidate()
                self.locationUpdateTimer = nil
            }
            //self.updateLocationToServer()
           // self.locationUpdateTimer = Timer.scheduledTimer(timeInterval: self.slotTime, target: self, selector: #selector(LocationTrackerFile.updateLocationToServer), userInfo: nil, repeats: true)
        }
        return response
    }
    
    open func stopLocationService() {
        if(self.locationUpdateTimer != nil) {
            self.locationUpdateTimer.invalidate()
            self.locationUpdateTimer = nil
        }
        let locationManager: CLLocationManager = LocationTrackerFile.sharedLocationManager()
        locationManager.stopUpdatingLocation()
        
//        MqttClass.sharedInstance.stopLocation()
        UserDefaults.standard.set(false, forKey: USER_DEFAULT.isLocationTrackingRunning)
        MqttClass.sharedInstance.unsubscribeLocation()
        MqttClass.sharedInstance.disconnect()
    }
    
    open func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        self.bgTask = BackgroundTaskManager.sharedBackgroundTaskManager()
        _ = self.bgTask!.beginNewBackgroundTask()
        if locations.last != nil {
            
            self.myLocation = locations.last! as CLLocation
            print("didUpdateLocations  \(self.myLocation.coordinate.latitude)")
            self.myLocationAccuracy = self.myLocation.horizontalAccuracy
            if(firstTime == true) {
                firstTime = false
                delegate?.currentLocationOfUser?(locations.last!)
            }
            self.trackingDelegate?.getCoordinates?(locations.last!)
            if(UserDefaults.standard.bool(forKey: USER_DEFAULT.isLocationTrackingRunning) == true) {
                self.applyFilterOnGetLocation()
            }
        }
    }
    
    
    
    fileprivate func applyFilterOnGetLocation() {
        if self.myLocation != nil  {
            var locationArray = [Any]()
            if let array = UserDefaults.standard.object(forKey: USER_DEFAULT.locationArray) as? [Any] {
                locationArray = array
            }
            
            if UserDefaults.standard.bool(forKey: USER_DEFAULT.isLocationTrackingRunning) == true {
                if(self.myLocationAccuracy < maxAccuracy){
                    if(self.myLastLocation == nil) {
                        var myLocationToSend = [String:Any]()
                        let timestamp = "\(Date().millisecondsSince1970)"  //String().getUTCDateString as String
                        myLocationToSend = ["lat" : myLocation!.coordinate.latitude as Double,"lng" :myLocation!.coordinate.longitude as Double, "tm_stmp" : timestamp, "bat_lvl" : UIDevice.current.batteryLevel * 100, "acc":(self.myLocationAccuracy != nil ? self.myLocationAccuracy! : 300), "api_key": globalAPIKey, "unique_user_id": globalUserId]
                        self.addFilteredLocationToLocationArray(myLocationToSend)
                        self.myLastLocation = self.myLocation
                        /*------- For Updating Path ------------*/
                        var locationDictionary = [String:Any]()
                        var updatingLocationArray = [Any]()
                        locationDictionary = ["Latitude":myLocation!.coordinate.latitude, "Longitude":myLocation!.coordinate.longitude]
                        if let array = UserDefaults.standard.value(forKey: USER_DEFAULT.updatingLocationPathArray) as? [Any]{
                            updatingLocationArray = array
                        }
                        updatingLocationArray.append(locationDictionary)
                        UserDefaults.standard.setValue(updatingLocationArray, forKey: USER_DEFAULT.updatingLocationPathArray)
                        NotificationCenter.default.post(name: Foundation.Notification.Name(rawValue: OBSERVER.updatePath), object: nil)
                        /*-------------------------------------------*/

                    } else {
                        if(self.getSpeed() < maxSpeed) {
                            var myLocationToSend = [String:Any]()
                            let timestamp = "\(Date().millisecondsSince1970)" //String().getUTCDateString as String
                            myLocationToSend = ["lat" : myLocation!.coordinate.latitude as Double,"lng" :myLocation!.coordinate.longitude as Double, "tm_stmp" : timestamp, "bat_lvl" : UIDevice.current.batteryLevel * 100, "acc":(self.myLocationAccuracy != nil ? self.myLocationAccuracy! : 300), "api_key": globalAPIKey, "unique_user_id": globalUserId]
                            self.addFilteredLocationToLocationArray(myLocationToSend)
                            self.myLastLocation = self.myLocation

                            /*------- For Updating Path ------------*/
                            var locationDictionary = [String:Any]()
                            var updatingLocationArray = [Any]()
                            locationDictionary = ["Latitude":myLocation!.coordinate.latitude, "Longitude":myLocation!.coordinate.longitude]
                            if let array = UserDefaults.standard.value(forKey: USER_DEFAULT.updatingLocationPathArray) as? [Any]{
                                updatingLocationArray = array
                            }
                            updatingLocationArray.append(locationDictionary)
                            UserDefaults.standard.setValue(updatingLocationArray, forKey: USER_DEFAULT.updatingLocationPathArray)
                            NotificationCenter.default.post(name: Foundation.Notification.Name(rawValue: OBSERVER.updatePath), object: nil)
                            /*-------------------------------------------*/

                        }
                    }
                }
            }
            
          //  if(NSUserDefaults.standardUserDefaults().valueForKey(USER_DEFAULT.applicationMode) != nil && (NSUserDefaults.standardUserDefaults().valueForKey(USER_DEFAULT.applicationMode) as! String == "Background" || NSUserDefaults.standardUserDefaults().valueForKey(USER_DEFAULT.applicationMode) as! String == "Terminate")) {
                if(UserDefaults.standard.bool(forKey: USER_DEFAULT.isHitInProgress) == false) {
                    if locationArray.count >= 5 {
                        let locationString = locationArray.jsonString
                        sendRequestToServer(locationString)
                    }
                }
            //}
        }
    }
    
    fileprivate func addFilteredLocationToLocationArray(_ myLocationToSend:[String:Any]) {
        if(UserDefaults.standard.bool(forKey: USER_DEFAULT.isLocationTrackingRunning) == true){
            var locationArray = [Any]()
            if let array = UserDefaults.standard.object(forKey: USER_DEFAULT.locationArray) as? [Any] {
                locationArray = array
            }
            if(locationArray.count >= 1000) {
                locationArray.remove(at: 0)
            }
            locationArray.append(myLocationToSend)
            UserDefaults.standard.set(locationArray, forKey: USER_DEFAULT.locationArray)
        }
    }
    
    
     @objc func updateLocationToServer() {
        var locationArray = [Any]()
        if let array = UserDefaults.standard.object(forKey: USER_DEFAULT.locationArray) as? [Any] {
            locationArray = array
        }
        if IJReachability.isConnectedToNetwork(){
            if(UserDefaults.standard.bool(forKey: USER_DEFAULT.isHitInProgress) == false) {
                if locationArray.count > 0 {
                    let locationString = locationArray.jsonString
                    sendRequestToServer(locationString)
                }
            }
        }
    }
    
    fileprivate func sendRequestToServer(_ locationString:String) {
        if(UserDefaults.standard.bool(forKey: USER_DEFAULT.isLocationTrackingRunning) == true) {
          //  MqttClass.sharedInstance.hostAddress = self.host
         //   MqttClass.sharedInstance.portNumber = self.portNumber
         //   MqttClass.sharedInstance.accessToken = self.accessToken
         //   MqttClass.sharedInstance.key = self.uniqueKey
            MqttClass.sharedInstance.topic = self.topic
            MqttClass.sharedInstance.sendLocation(locationString)//MQTT
        }
    }
    
    fileprivate func updateLastSavedLocationOnServer() {
        if(UserDefaults.standard.bool(forKey: USER_DEFAULT.isLocationTrackingRunning) == true) {
            var locationArray = [Any]()
            if let array = UserDefaults.standard.object(forKey: USER_DEFAULT.locationArray) as? [Any]{
                locationArray = array
            }
           // self.setLocationUpdate()
            if(UserDefaults.standard.bool(forKey: USER_DEFAULT.isHitInProgress) == false) {
                if(locationArray.count > 0) {
                    sendRequestToServer(locationArray.jsonString)
                } else {
                    var myLocationToSend = [String:Any]()
                    myLocationToSend = ["bat_lvl" : UIDevice.current.batteryLevel * 100]
                    var highLocationArray = [Any]()
                    highLocationArray.append(myLocationToSend)
                    let locationString = highLocationArray.jsonString
                    sendRequestToServer(locationString)
                }
            }
        }
    }
    
    fileprivate func getSpeed() -> Float {
        if(myLastLocation != nil) {
            let time = self.myLocation.timestamp.timeIntervalSince(myLastLocation.timestamp)
            let distance:CLLocationDistance = myLocation.distance(from: myLastLocation)
//            if(distance > 200) {
//                self.locationManager.stopUpdatingLocation()
//                if let json = NetworkingHelper.sharedInstance.getLatLongFromDirectionAPI("\(myLastLocation.coordinate.latitude),\(myLastLocation.coordinate.longitude)", destination: "\(myLocation.coordinate.latitude),\(myLocation.coordinate.longitude)") {
//                    UIApplication.shared.isNetworkActivityIndicatorVisible = false
//                    print(json)
//                    if let routes = json["routes"] as? [AnyObject] {
//                        if(routes.count > 0) {
//                            if let legs = routes[0]["legs"] as? [AnyObject]{
//                                if(legs.count > 0) {
//                                    if let distance = legs[0]["distance"] as? [String:Any]{
//                                        print(distance)
//                                        if let value = distance["value"] as? Int {
//                                            print(value)
//                                            if let overviewPolyline = routes[0]["overview_polyline"] as? [String:Any] {
//                                                if let polyline = overviewPolyline["points"] as? String {
//                                                    let locations = NetworkingHelper.sharedInstance.decodePolylineForCoordinates(polyline) as [CLLocation]
//                                                    for i in (0..<locations.count) {
//                                                        var myLocationToSend = [String:Any]()
//                                                        let timestamp = String().getUTCDateString as String
//                                                        myLocationToSend = ["lat" : locations[i].coordinate.latitude as Double,"lng" :locations[i].coordinate.longitude as Double, "tm_stmp" : timestamp, "bat_lvl" : UIDevice.current.batteryLevel * 100,"acc":(self.myLocationAccuracy != nil ? self.myLocationAccuracy! : 300)]
//                                                        
//                                                        self.addFilteredLocationToLocationArray(myLocationToSend)
//                                                        self.myLastLocation = CLLocation(latitude: locations[i].coordinate.latitude, longitude: locations[i].coordinate.longitude)
//                                                        self.setLocationUpdate()
//                                                        /*------- For Updating Path ------------*/
//                                                        var locationDictionary = [String:Any]()
//                                                        var updatingLocationArray = [Any]()
//                                                        locationDictionary = ["Latitude":myLocation!.coordinate.latitude, "Longitude":myLocation!.coordinate.longitude]
//                                                        if let array = UserDefaults.standard.value(forKey: USER_DEFAULT.updatingLocationPathArray) as? [Any] {
//                                                            updatingLocationArray = array
//                                                        }
//                                                        updatingLocationArray.append(locationDictionary)
//                                                        UserDefaults.standard.setValue(updatingLocationArray, forKey: USER_DEFAULT.updatingLocationPathArray)
//                                                        NotificationCenter.default.post(name: Foundation.Notification.Name(rawValue: OBSERVER.updatePath), object: nil)
//                                                        /*----------------------------------------------*/
//                                                    }
//                                                }
//                                            }
//
//                                        }
//                                    }
//                                }
//                            }
//                        }
//                    } else {
//                        UIApplication.shared.isNetworkActivityIndicatorVisible = false
//                        self.setLocationUpdate()
//                        speed = Float(distance) / Float(time)
//                        if(speed > 0) {
//                            return speed
//                        }
//                        return 0.0
//                    }
//                } else {
//                    UIApplication.shared.isNetworkActivityIndicatorVisible = false
//                    self.setLocationUpdate()
//                    speed = Float(distance) / Float(time)
//                    if(speed > 0) {
//                        return speed
//                    }
//                    return 0.0
//                }
//                return 0.0
//            } else {
                speed = Float(distance) / Float(time)
                if(speed > 0) {
                    return speed
                }
                return 0.0
           // }
        }
        return 0.0
    }
    
    fileprivate func isAllPermissionAuthorized() -> (Bool, String) {
        //We have to make sure that the Background App Refresh is enable for the Location updates to work in the background.
        if(UIApplication.shared.backgroundRefreshStatus == UIBackgroundRefreshStatus.denied) {
            return (false,"The app doesn't work without the Background App Refresh enabled.")
        } else if (UIApplication.shared.backgroundRefreshStatus == UIBackgroundRefreshStatus.restricted) {
            return (false,"The app doesn't work without the Background App Refresh enabled.")
        } else {
            return self.isAppLocationEnabled()
        }
    }
    
    fileprivate func isAppLocationEnabled() -> (Bool,String) {
        if CLLocationManager.locationServicesEnabled() == false {
            return (false,"Background Location Access Disabled")
        } else {
            let authorizationStatus = CLLocationManager.authorizationStatus()
            if authorizationStatus == CLAuthorizationStatus.denied || authorizationStatus == CLAuthorizationStatus.restricted {
                return (false,"Background Location Access Disabled")
            } else {
                return self.isAuthorizedUser()
            }
        }
    }
    
    fileprivate func isAuthorizedUser() -> (Bool,String) {
        return (true,"")
//        let params = ["u_socket_id":uniqueKey,
//                      "f_socket_id":self.accessToken,
//                      "sdk_version":SDKVersion,
//                      "timezone":NSTimeZone.system.secondsFromGMT() / 60,
//                      "frequency":"\(self.locationFrequencyMode.rawValue)",
//                      "device_details":["device_type":"1",
//                                        "device_name":UIDevice.current.name,
//                                        "imei":"",
//                                        "os":(UIDevice.current.systemVersion as NSString).doubleValue,
//                                        "manufacturer":"Apple",
//                                        "model":UIDevice.current.modelName,
//                                        "locale": Locale.current.identifier
//                                        ]] as [String : Any]
//        print(params)
//        let jsonResponse = NetworkingHelper.sharedInstance.getValidation("validate", params: (params as NSDictionary))
//        if(jsonResponse.0 == true) {
//            let json = jsonResponse.1
//            if let status = json?["status"] as? Int {
//                if status == 200 {
//                   return (true,json!["message"] as! String)
//                } else {
//                    return (false,json!["message"] as! String)
//                }
//            }
//            return (false,"Invalid Access")
//        } else {
//            let json = jsonResponse.1
//            return (false,json!["message"] as! String)
//        }
    }
}

