

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
import Darwin.C

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
    var shareModel: LocationShareModel?
     var sendFirstTimeLocation = true
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

    
    let SDKVersion = "1.0"
    var sessionId = ""
    override init() {
        super.init()
        self.shareModel = LocationShareModel.sharedModel()
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
//        self.setLocationUpdate()
        _ = self.startLocationService()
        self.subsribeMQTTForTracking()
    }
    
    open func getCurrentLocation() -> CLLocation! {
        if(self.myLocation == nil) {
            return CLLocation()
        }
        return self.myLocation
    }
    func getLatestLocationForForegroundMode() -> CLLocation! {
        if self.myLocation != nil && self.myLocation.coordinate.latitude > 0.0 {
            return self.myLocation
        }  else {
            return nil
        }
     }

    open func initMqtt() {
        MqttClass.sharedInstance.mqttSetting()
        MqttClass.sharedInstance.topic = LocationTrackerFile.sharedInstance().sessionId
        if MqttClass.sharedInstance.connectVar != true{
        MqttClass.sharedInstance.connectToServer()
        }
        self.subsribeMQTTForTracking()
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
        guard let sessionid = UserDefaults.standard.value(forKey: USER_DEFAULT.sessionId)  as? String else {
            return
        }

        MqttClass.sharedInstance.topic =  sessionid
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
//        self.myLocation = nil
//        MqttClass.sharedInstance.stopLocation()
        UserDefaults.standard.set(false, forKey: USER_DEFAULT.isLocationTrackingRunning)
        MqttClass.sharedInstance.unsubscribeLocation()
        MqttClass.sharedInstance.disconnect()
    }
    
    open func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if locations.last != nil {
            if firstTime == true {
                self.myLocation = locations.last! as CLLocation
//                NotificationCenter.default.post(name: Foundation.Notification.Name(rawValue: NOTIFICATION_OBSERVER.currentLocationFetched), object: self)
                firstTime = false
            }
            self.locationManager.stopUpdatingLocation()
        }
    }
   func sendLocationThroughUDP(socketLocation:CLLocation){
        
        if(UserDefaults.standard.value(forKey: USER_DEFAULT.apiKey) != nil) {
            let timestamp = socketLocation.timestamp.timeIntervalSince1970 * 1000
            var myLocationToSend:[String:Any] = ["lat" : socketLocation.coordinate.latitude as Double]
            myLocationToSend["lng"] = socketLocation.coordinate.longitude as Double
            myLocationToSend["tm_stmp"] = timestamp
            myLocationToSend["bat_lvl"] = UIDevice.current.batteryLevel * 100
            myLocationToSend["acc"] = socketLocation.horizontalAccuracy
            //myLocationToSend = ["lat" : socketLocation.coordinate.latitude as Double,"lng" :socketLocation.coordinate.longitude as Double, "tm_stmp" : timestamp, "bat_lvl" : UIDevice.current.batteryLevel * 100,"acc":socketLocation.horizontalAccuracy]\
            var udpData:[String:Any] = ["flag" : 0]
            udpData["data"] = myLocationToSend
            //let udpData = ["flag":0, "data":myLocationToSend, "fleet_id":Singleton.sharedInstance.fleetDetails.fleetId!, "device_type":DEVICE_TYPE] as [String : Any]
            
           let client:UDPClient = UDPClient(addr: IP_ADDRESS, port: PORT)
            _ = client.send(str: udpData.jsonString)
            _ = client.close()
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
                        guard let sessionid = UserDefaults.standard.value(forKey: USER_DEFAULT.sessionId) else {
                            return
                        }
//                        let apikey = UserDefaults.standard.value(forKey: USER_DEFAULT.apiKey)
//                        let userId = UserDefaults.standard.value(forKey: USER_DEFAULT.userId)
                        myLocationToSend = ["lat" : myLocation!.coordinate.latitude as Double,"lng" :myLocation!.coordinate.longitude as Double, "tm_stmp" : timestamp, "bat_lvl" : UIDevice.current.batteryLevel * 100, "acc":(self.myLocationAccuracy != nil ? self.myLocationAccuracy! : 300), "api_key": globalAPIKey, "unique_user_id": globalUserId, "session_id" : sessionid]
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
                        
//                        let locationString = [myLocationToSend]
//                        sendRequestToServer(locationString.jsonString)
                        /*-------------------------------------------*/

                    } else {
                        if(self.getSpeed() < maxSpeed) {
                            var myLocationToSend = [String:Any]()
                            let timestamp = "\(Date().millisecondsSince1970)" //String().getUTCDateString as String
                            guard let sessionid = UserDefaults.standard.value(forKey: USER_DEFAULT.sessionId) else {
                                return
                            }
                            myLocationToSend = ["lat" : myLocation!.coordinate.latitude as Double,"lng" :myLocation!.coordinate.longitude as Double, "tm_stmp" : timestamp, "bat_lvl" : UIDevice.current.batteryLevel * 100, "acc":(self.myLocationAccuracy != nil ? self.myLocationAccuracy! : 300), "api_key": globalAPIKey, "unique_user_id": globalUserId, "session_id" : sessionid]
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
    
    func sendFirstLocation() {
        var myLocationToSend = [String:Any]()
        let timestamp = "\(Date().millisecondsSince1970)"  //String().getUTCDateString as String
        guard let sessionid = UserDefaults.standard.value(forKey: USER_DEFAULT.sessionId) else {
            return
        }
        //                        let apikey = UserDefaults.standard.value(forKey: USER_DEFAULT.apiKey)
        //                        let userId = UserDefaults.standard.value(forKey: USER_DEFAULT.userId)
        myLocationToSend = ["lat" : myLocation!.coordinate.latitude as Double,"lng" :myLocation!.coordinate.longitude as Double, "tm_stmp" : timestamp, "bat_lvl" : UIDevice.current.batteryLevel * 100, "acc":(self.myLocationAccuracy != nil ? self.myLocationAccuracy! : 300), "api_key": globalAPIKey, "unique_user_id": globalUserId, "session_id" : sessionid]
        self.addFilteredLocationToLocationArray(myLocationToSend)
        self.myLastLocation = self.myLocation
        /*------- For Updating Path ------------*/
        var locationDictionary = [String:Any]()
        var updatingLocationArray = [Any]()
        locationDictionary = ["Latitude":myLocation!.coordinate.latitude, "Longitude":myLocation!.coordinate.longitude]
        if let array = UserDefaults.standard.value(forKey: USER_DEFAULT.updatingLocationPathArray) as? [Any]{
            updatingLocationArray = array
        }
        print("First Location")
        updatingLocationArray.append(locationDictionary)
        UserDefaults.standard.setValue(updatingLocationArray, forKey: USER_DEFAULT.updatingLocationPathArray)
//        NotificationCenter.default.post(name: Foundation.Notification.Name(rawValue: OBSERVER.updatePath), object: nil)
        
        let locationString = [myLocationToSend]
        sendRequestToServer(locationString.jsonString)
    }
    
    func sendLastLocation() {
        var myLocationToSend = [String:Any]()
        let timestamp = "\(Date().millisecondsSince1970)"  //String().getUTCDateString as String
        guard let sessionid = UserDefaults.standard.value(forKey: USER_DEFAULT.sessionId) else {
            return
        }
        //                        let apikey = UserDefaults.standard.value(forKey: USER_DEFAULT.apiKey)
        //                        let userId = UserDefaults.standard.value(forKey: USER_DEFAULT.userId)
        myLocationToSend = ["lat" : myLocation!.coordinate.latitude as Double,"lng" :myLocation!.coordinate.longitude as Double, "tm_stmp" : timestamp, "bat_lvl" : UIDevice.current.batteryLevel * 100, "acc":(self.myLocationAccuracy != nil ? self.myLocationAccuracy! : 300), "api_key": globalAPIKey, "unique_user_id": globalUserId, "session_id" : sessionid]
        self.addFilteredLocationToLocationArray(myLocationToSend)
        self.myLastLocation = self.myLocation
        /*------- For Updating Path ------------*/
        var locationDictionary = [String:Any]()
        var updatingLocationArray = [Any]()
        locationDictionary = ["Latitude":myLocation!.coordinate.latitude, "Longitude":myLocation!.coordinate.longitude]
        if let array = UserDefaults.standard.value(forKey: USER_DEFAULT.updatingLocationPathArray) as? [Any]{
            updatingLocationArray = array
        }
        print("Last Location")
        updatingLocationArray.append(locationDictionary)
        UserDefaults.standard.setValue(updatingLocationArray, forKey: USER_DEFAULT.updatingLocationPathArray)
        //        NotificationCenter.default.post(name: Foundation.Notification.Name(rawValue: OBSERVER.updatePath), object: nil)
        
        let locationString = [myLocationToSend]
        sendRequestToServer(locationString.jsonString)
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

                speed = Float(distance) / Float(time)
                if(speed > 0) {
                    return speed
                }
                return 0.0
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

