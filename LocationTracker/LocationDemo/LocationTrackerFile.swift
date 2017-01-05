


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
    @objc optional func currentLocation(_ location:CLLocation)
    @objc optional func trackingLatLong(_ locations:[CLLocation])
}
protocol recieveDataFromMqttClass :class {
    func recievedLatlong(data:[CLLocationCoordinate2D])
}

public enum LocationFrequency: Int {
    case low = 0
    case medium
    case high
}

public enum ServiceType{
    case tracking
    case sending
    case both
    
}

public class LocationTrackerFile:NSObject, CLLocationManagerDelegate,recieveDataFromMqttClass {
    
    
    open var delegate:LocationTrackerDelegate!
    public var host = "test.tookanapp.com"
    public var portNumber:UInt16 = 1883
    public var slotTime = 5.0
    public var maxSpeed:Float = 30.0
    public var maxAccuracy = 20.0
    public var maxDistance = 20.0
    
    private static let locationManagerObj = CLLocationManager()
    private static let locationTracker = LocationTrackerFile()
    
    var myLastLocation: CLLocation!
    var myLocation: CLLocation!
    var myLocationAccuracy: CLLocationAccuracy!
    var locationUpdateTimer: Timer!
    var locationManager:CLLocationManager!
    var speed:Float = 0
    var bgTask: BackgroundTaskManager?
    
    private var locationFrequencyMode = LocationFrequency.high
    open var accessToken:String = ""
    open var uniqueKey:String = ""
    
    let SDKVersion = "1.0"
    
    var apiKey = ""
    var serviceType = ServiceType.tracking
    
    var jobId = ""
    var sessionId = ""
    var subscribeTimer:Timer!
    
    
    
    override init() {
        super.init()
        MqttClass.sharedInstance.delegate = self
        NotificationCenter.default.addObserver(self, selector: #selector(LocationTrackerFile.applicationEnterBackground), name: NSNotification.Name.UIApplicationDidEnterBackground, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(LocationTrackerFile.appEnterInTerminateState), name: NSNotification.Name.UIApplicationWillTerminate, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(LocationTrackerFile.enterInForegroundFromBackground), name: NSNotification.Name.UIApplicationWillEnterForeground, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(LocationTrackerFile.becomeActive), name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
        UserDefaults.standard.set(false, forKey: USER_DEFAULT.isHitInProgress)
        UIDevice.current.isBatteryMonitoringEnabled = true
    }
    
    func recievedLatlong(data: [CLLocationCoordinate2D]) {
        print("\(data)" + " finalLatLong")
        var locationArrayToSend = [CLLocation]()
        for i in data {
            locationArrayToSend.append(CLLocation(latitude: i.latitude, longitude: i.longitude))
        }
        delegate.trackingLatLong!(locationArrayToSend)
    }
    
    
    
    public class func sharedInstance() -> LocationTrackerFile {
        return locationTracker
    }
    
    public class func sharedLocationManager() -> CLLocationManager {
        return locationManagerObj
    }
    
    func applicationEnterBackground() {
//        self.setLocationUpdate()
//        self.bgTask = BackgroundTaskManager.sharedBackgroundTaskManager()
//        self.bgTask!.beginNewBackgroundTask()
//        UserDefaults.standard.setValue("Background", forKey: USER_DEFAULT.applicationMode)
//        self.updateLocationToServer()
//        if(self.locationUpdateTimer != nil) {
//            self.locationUpdateTimer.invalidate()
//            self.locationUpdateTimer = nil
//        }
//        self.locationUpdateTimer = Timer.scheduledTimer(timeInterval: slotTime, target: self, selector: #selector(LocationTrackerFile.updateLocationToServer), userInfo: nil, repeats: true)
    }
    
    
    
    
    func enterInForegroundFromBackground(){
//        UserDefaults.standard.setValue("Foreground", forKey: USER_DEFAULT.applicationMode)
//        self.updateLocationToServer()
//        if(self.locationUpdateTimer != nil) {
//            self.locationUpdateTimer.invalidate()
//            self.locationUpdateTimer = nil
//        }
//        self.locationUpdateTimer = Timer.scheduledTimer(timeInterval: self.slotTime, target: self, selector: #selector(LocationTrackerFile.updateLocationToServer), userInfo: nil, repeats: true)
    }
    
    
    func appEnterInTerminateState() {
//        UserDefaults.standard.setValue("Terminate", forKey: USER_DEFAULT.applicationMode)
//        if(self.locationManager != nil) {
//            self.locationManager.stopUpdatingLocation()
//            print("stop update")
//            self.locationManager.startMonitoringSignificantLocationChanges()
//        }
    }
    
    func becomeActive() {
//        if(self.locationManager == nil) {
//            self.restartLocationUpdates()
//        }
    }

   
    
    open func getCurrentLocation() -> CLLocation {
        if(self.myLocation == nil) {
            return CLLocation()
        }
        return self.myLocation
    }
    
    
    
    
    
    
    
    public func setLocationUpdate() {
        
         if(UserDefaults.standard.bool(forKey: USER_DEFAULT.isLocationTrackingRunning) == true) {
        MqttClass.sharedInstance.mqttSetting()
        MqttClass.sharedInstance.connectToServer()
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
            print("start updating")
        locationManager.startUpdatingLocation()
        }
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
            slotTime = 2.0
            maxDistance = 5
            break
        }
    }
    
    
    
    
    
    
    
    
    
     func restartLocationUpdates() {
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
    
    
    

    
    
    
    
    
    
    private func startLocationTracking()  -> (Bool, String){
//        let response = self.isAllPermissionAuthorized()
//        //setLocationUpdate()
//        if(response.0 == true) {
//            UserDefaults.standard.set(true, forKey: USER_DEFAULT.isLocationTrackingRunning)
//            setLocationUpdate()
//            if(self.locationUpdateTimer != nil) {
//                self.locationUpdateTimer?.invalidate()
//                self.locationUpdateTimer = nil
//            }
//            //self.updateLocationToServer()
//            //self.locationUpdateTimer = Timer.scheduledTimer(timeInterval: self.slotTime, target: self, selector: #selector(LocationTrackerFile.updateLocationToServer), userInfo: nil, repeats: true)
//        }
//        return response
    }
    
    public func stopLocationTracking() {
//        if(self.locationUpdateTimer != nil) {
//            self.locationUpdateTimer.invalidate()
//            self.locationUpdateTimer = nil
//        }
//        //MqttClass.sharedInstance.disconnect()
//       
//        let locationManager: CLLocationManager = LocationTrackerFile.sharedLocationManager()
//        locationManager.stopUpdatingLocation()
//        print("stoped update")
//        UserDefaults.standard.set(false, forKey: USER_DEFAULT.isLocationTrackingRunning)
//        MqttClass.sharedInstance.disconnect()
    }
    
    
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        self.bgTask = BackgroundTaskManager.sharedBackgroundTaskManager()
        _ = self.bgTask!.beginNewBackgroundTask()
        print("delegate location = \(self.myLocation)")
        if locations.last != nil {
            self.myLocation = locations.last! as CLLocation
            print("delegate location = \(self.myLocation)")
            self.myLocationAccuracy = self.myLocation.horizontalAccuracy
            self.applyFilterOnGetLocation()
            if(UserDefaults.standard.bool(forKey: USER_DEFAULT.isLocationTrackingRunning) == true) {
                delegate.currentLocation!(self.myLocation)
            }
        }
    }
    
    func applyFilterOnGetLocation() {
        if self.myLocation != nil  {
            var locationArray = [Any]()
            if let array = UserDefaults.standard.object(forKey: USER_DEFAULT.locationArray) as? [Any] {
                locationArray = array
            }
            if UserDefaults.standard.bool(forKey: USER_DEFAULT.isLocationTrackingRunning) == true {
                if(self.myLocationAccuracy < maxAccuracy){
                    if(self.myLastLocation == nil) {
                        var myLocationToSend = [String:Any]()
                        let timestamp = String().getUTCDateString
                        myLocationToSend = ["lat" : myLocation!.coordinate.latitude as Double,"lng" :myLocation!.coordinate.longitude as Double, "tm_stmp" : timestamp!, "bat_lvl" : UIDevice.current.batteryLevel * 100, "gps":1,"acc":(self.myLocationAccuracy != nil ? self.myLocationAccuracy! : 300), "d_acc":"1"]
                        self.addFilteredLocationToLocationArray(myLocationToSend: myLocationToSend)
                        self.myLastLocation = self.myLocation
                    } else {
                        if(self.getSpeed() < maxSpeed) {
                            var myLocationToSend = [String:Any]()
                            let timestamp = String().getUTCDateString
                            myLocationToSend = ["lat" : myLocation!.coordinate.latitude as Double,"lng" :myLocation!.coordinate.longitude as Double, "tm_stmp" : timestamp!, "bat_lvl" : UIDevice.current.batteryLevel * 100, "gps":1,"acc":(self.myLocationAccuracy != nil ? self.myLocationAccuracy! : 300), "d_acc":"1"]
                            self.addFilteredLocationToLocationArray(myLocationToSend: myLocationToSend)
                            self.myLastLocation = self.myLocation
                        }
                    }
                }
            }
            
           // if(UserDefaults.standard.value(forKey: USER_DEFAULT.applicationMode) != nil && (UserDefaults.standard.value(forKey: USER_DEFAULT.applicationMode) as! String == "Background" || UserDefaults.standard.value(forKey: USER_DEFAULT.applicationMode) as! String == "Terminate")) {
                if(UserDefaults.standard.bool(forKey: USER_DEFAULT.isHitInProgress) == false) {
                    if locationArray.count >= 5 {
                        let locationString = locationArray.jsonString
                        sendRequestToServer(locationString: locationString)
                    }
                }
           // }
        }
    }
    
    
    
    func addFilteredLocationToLocationArray(myLocationToSend:[String:Any]) {
        if(UserDefaults.standard.bool(forKey: USER_DEFAULT.isLocationTrackingRunning) == true){
            var locationArray = [Any]()
            if let array = UserDefaults.standard.object(forKey: USER_DEFAULT.locationArray) as? [Any] {
                locationArray = array
            }
            if(locationArray.count >= 1000) {
                locationArray.remove(at: 0)
            }
            print(myLocationToSend)
            locationArray.append(myLocationToSend as! Any)
           // UserDefaults.standard.set(locationArray, forKey: USER_DEFAULT.locationArray)
        }
    }
    
    
    
    func updateLocationToServer() {
        var locationArray = [Any]()
        if let array = UserDefaults.standard.object(forKey: USER_DEFAULT.locationArray) as? [Any] {
            locationArray = array
        }
        if IJReachability.isConnectedToNetwork(){
            if(UserDefaults.standard.bool(forKey: USER_DEFAULT.isHitInProgress) == false) {
                if locationArray.count > 0 {
                    let locationString = locationArray.jsonString
                    sendRequestToServer(locationString: locationString)
                }
            }
        }
    }
    
    func sendRequestToServer(locationString:String) {
         if(UserDefaults.standard.bool(forKey: USER_DEFAULT.isLocationTrackingRunning) == true) {
            MqttClass.sharedInstance.hostAddress = self.host
            MqttClass.sharedInstance.portNumber = self.portNumber
            MqttClass.sharedInstance.accessToken = self.accessToken
            MqttClass.sharedInstance.key = self.uniqueKey
            MqttClass.sharedInstance.sendLocation(location:locationString)//MQTT
        }
    }
    
    
    func updateLastSavedLocationOnServer() {
         if(UserDefaults.standard.bool(forKey: USER_DEFAULT.isLocationTrackingRunning) == true) {
            var locationArray = [Any]()
            if let array = UserDefaults.standard.object(forKey: USER_DEFAULT.locationArray) as? [Any] {
                locationArray = array
            }
            self.setLocationUpdate()
            if(UserDefaults.standard.bool(forKey: USER_DEFAULT.isHitInProgress) == false) {
                if(locationArray.count > 0) {
                    sendRequestToServer(locationString: locationArray.jsonString)
                } else {
                    var myLocationToSend = [String:Any]()
                    myLocationToSend = ["bat_lvl" : UIDevice.current.batteryLevel * 100]
                    var highLocationArray = [Any]()
                    highLocationArray.append(myLocationToSend)
                    let locationString = highLocationArray.jsonString
                    sendRequestToServer(locationString: locationString)
                }
            }
        }
    }
    
    
    
    
    func getSpeed() -> Float {
        if(myLastLocation != nil) {
            let time = self.myLocation.timestamp.timeIntervalSince(myLastLocation.timestamp)
            let distance:CLLocationDistance = myLocation.distance(from: myLastLocation)
            if(distance > 200) {
                self.locationManager.stopUpdatingLocation()
                print("stopUpdate" + "\(myLastLocation.coordinate.latitude),\(myLastLocation.coordinate.longitude)" + "asdasdasd" + "\(myLocation.coordinate.latitude),\(myLocation.coordinate.longitude)" )
                if let json = NetworkingHelper.sharedInstance.getLatLongFromDirectionAPI("\(myLastLocation.coordinate.latitude),\(myLastLocation.coordinate.longitude)", destination: "\(myLocation.coordinate.latitude),\(myLocation.coordinate.longitude)") {
                    print("inside Json")
                    print(json)
                    UIApplication.shared.isNetworkActivityIndicatorVisible = false
                    if let jsonData = json as? [String:AnyObject]{
                        print("stopUpdateasdasd342342")
                    if let routes = json["routes"] as? [AnyObject] {
                        print("stopUpdat22222")
                        if(routes.count > 0) {
                            print("stopUpdate3333333")
                            if let legs = routes[0]["legs"] as? [AnyObject]{
                                if(legs.count > 0) {
                                    if let _ = (legs[0]["distance"] as! [String:AnyObject])["value"] as? Int {
                                        //                                if(distance < 200) {
                                        if let polyline = (routes[0]["overview_polyline"] as! [String:AnyObject])["points"] as? String {
                                            let locations = NetworkingHelper.sharedInstance.decodePolylineForCoordinates(polyline)
                                            for i in (0..<locations!.count) {
                                                var myLocationToSend = [String:Any]()
                                                let timestamp = String().getUTCDateString
                                                myLocationToSend = ["lat" : locations![i].coordinate.latitude as Double,"lng" :locations![i].coordinate.longitude as Double, "tm_stmp" : timestamp!, "bat_lvl" : UIDevice.current.batteryLevel * 100, "gps":1,"acc":(self.myLocationAccuracy != nil ? self.myLocationAccuracy! : 300), "d_acc":"1","status":"1"]
                                               
                                                self.addFilteredLocationToLocationArray(myLocationToSend: myLocationToSend)
                                                self.myLastLocation = CLLocation(latitude: (locations?[i].coordinate.latitude)!, longitude: (locations?[i].coordinate.longitude)!)
                                                self.setLocationUpdate()
                                            }
                                        }
                                    }
                                }
                            }
                        }else{
                            UIApplication.shared.isNetworkActivityIndicatorVisible = false
                            self.setLocationUpdate()
                            speed = Float(distance) / Float(time)
                            if(speed > 0) {
                                return speed
                            }
                            return 0.0
                        }
                        }
                    } else {
                        UIApplication.shared.isNetworkActivityIndicatorVisible = false
                        self.setLocationUpdate()
                        speed = Float(distance) / Float(time)
                        if(speed > 0) {
                            return speed
                        }
                        return 0.0
                    }
                } else {
                    UIApplication.shared.isNetworkActivityIndicatorVisible = false
                    self.setLocationUpdate()
                    speed = Float(distance) / Float(time)
                    if(speed > 0) {
                        return speed
                    }
                    return 0.0
                }
                return maxSpeed
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
//        if(UIApplication.shared.backgroundRefreshStatus == UIBackgroundRefreshStatus.denied) {
//            return (false,"The app doesn't work without the Background App Refresh enabled.")
//        } else if (UIApplication.shared.backgroundRefreshStatus == UIBackgroundRefreshStatus.restricted) {
//            return (false,"The app doesn't work without the Background App Refresh enabled.")
//        } else {
//            return self.isAppLocationEnabled()
//        }
        return (true,"")
    }
    
    private func isAppLocationEnabled() -> (Bool,String) {
//        if CLLocationManager.locationServicesEnabled() == false {
//            return (false,"Background Location Access Disabled")
//        } else {
//            let authorizationStatus = CLLocationManager.authorizationStatus()
//            if authorizationStatus == CLAuthorizationStatus.denied || authorizationStatus == CLAuthorizationStatus.restricted {
//                return (false,"Background Location Access Disabled")
//            } else {
//                return (true,"Tracking Started")
//            }
//        }
        return (true,"")
    }
    
    
    
    
    
    
    
    
    
    fileprivate func isAuthorizedUser() -> (Bool,String) {
        let params = [
        "api_key":self.apiKey,
        "job_id":self.jobId,
        "request_type":"1"
        ]
        //print(params)
        let jsonResponse = NetworkingHelper.sharedInstance.getValidation("generate_session", params: params)
        print("in isAuthorizedUser")
        if jsonResponse.1 != nil{
        if(jsonResponse.0 == true) {
            let jsonData = jsonResponse.1!
                if let data = jsonData["data"] as? [String:Any] {
                    if let sessionId = data["session_id"] as? String {
                       self.sessionId = sessionId
                        print("in recieved sessionId")
                        return(true,"recieved sessionId")
                    }else{
                        return(false,"Invalid Access")
                    }
            }
            return(false,"Invalid Access")
        } else {
            let jsonData = jsonResponse.1!
           // let json = jsonResponse.1
            return (false,jsonData["message"] as! String)
        }
    }
        return (true,"Invalid Access")
    }
    
    
    
}

// For tracking purpose


extension LocationTrackerFile{
    
    
   open func startTracking(jobId:String) -> (Bool, String) {
    if IJReachability.isConnectedToNetwork() == true{
    if (self.serviceType == ServiceType.tracking) || (self.serviceType == .both){
        var permissionResponse = self.isAllPermissionAuthorized()
        if apiKey == ""{
            return (false,"Please provide the api key.")
        }else{
            if permissionResponse.0 == true{
             self.jobId = jobId
             let sessionIdData = isAuthorizedUser()
                permissionResponse = sessionIdData
                initMqtt()
                }
        }
    }else{
        return (false,"Please choose for tracking service type.")
    }
    }else{
       return (false,"No internet connection found")
    }
    return (true,"\(jobId) \(sessionId) \(apiKey)")
    }
    
    open func stopTrackingService(){
        self.stopTracking()
    }
    
    open func setApiKey(apiKey:String,serviceType:ServiceType) {
        self.apiKey = apiKey
        self.serviceType = serviceType
    }
    
    //d27cba08585826d65bda03ff78332ddd0cd1a4d862882548e5f3b18e9dc0a2b5
    
    
    //MARK: MQTT
    func initMqtt() {
        MqttClass.sharedInstance.mqttSetting()
        MqttClass.sharedInstance.connectToServer()
        self.subsribeMQTTForTracking()
    }
    
    func subsribeMQTTForTracking() {
        if MqttClass.sharedInstance.mqtt?.connState == CocoaMQTTConnState.CONNECTED {
            MqttClass.sharedInstance.topic = sessionId
            MqttClass.sharedInstance.subscribeLocation()
        } else {
            self.subscribeTimer = Timer.scheduledTimer(timeInterval: 2.0, target: self, selector: #selector(self.checkMqttConnectionState), userInfo: nil, repeats: true)
        }
    }
    
    func stopTracking() {
        if  MqttClass.sharedInstance.mqtt?.connState == CocoaMQTTConnState.CONNECTED{
            MqttClass.sharedInstance.unsubscribeLocation()
            print("stopped")
            if subscribeTimer != nil {
            subscribeTimer.invalidate()
            }
        }
        print("not stoped")
        // UserDefaults.standard.setValue([Any](), forKey: USER_DEFAULT.updatingLocationPathArray)
    }
    
    func checkMqttConnectionState() {
        if MqttClass.sharedInstance.mqtt?.connState == CocoaMQTTConnState.CONNECTED {
            MqttClass.sharedInstance.topic = sessionId
            MqttClass.sharedInstance.subscribeLocation()
            if subscribeTimer != nil{
                self.subscribeTimer.invalidate()
            }
            self.subscribeTimer = nil
        }
    }
}

