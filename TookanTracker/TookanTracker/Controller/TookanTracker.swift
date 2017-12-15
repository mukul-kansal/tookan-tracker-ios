//
//  TookanTracker.swift
//  TookanTracker-SDK
//
//  Created by CL-Macmini-110 on 11/21/17.
//  Copyright © 2017 CL-Macmini-110. All rights reserved.
//

import Foundation
import GooglePlaces
import GoogleMaps
import CoreLocation

@objc public protocol TookanTrackerDelegate {
    @objc optional func getCurrentCoordinates(_ location:CLLocation)
    @objc optional func getSessionId(sessionId: String)
    @objc optional func logout()
}

public class TookanTracker: NSObject, CLLocationManagerDelegate {
    public static var shared = TookanTracker()
    private var merchantNavigationController:UINavigationController?
    let loc = LocationTrackerFile.sharedInstance()
    public var delegate:TookanTrackerDelegate!
    let model = TrackerModel()
    var locationManager:CLLocationManager!
    var uiNeeded = false
    public func createSession(userID:String, apiKey: String,isUINeeded:Bool, navigationController:UINavigationController) {
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.requestAlwaysAuthorization()
        self.uiNeeded = isUINeeded
        globalUserId = userID
        globalAPIKey = apiKey
        self.merchantNavigationController = navigationController
        UserDefaults.standard.set(apiKey, forKey: USER_DEFAULT.apiKey)
        UserDefaults.standard.set(userID, forKey: USER_DEFAULT.userId)
        self.loc.trackingDelegate = self
    }
    
    public func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        
        
        if status == .denied {
            locationManager = CLLocationManager()
            locationManager.requestAlwaysAuthorization()
        } else if status == .authorizedWhenInUse || status == .authorizedAlways {
            
            if let _ = UserDefaults.standard.value(forKey: USER_DEFAULT.sessionId) as? String {
                self.registerForGoogle()
                if uiNeeded {
                    self.initHome()
                } else {
                    self.loc.topic = "\(globalAPIKey)\(globalUserId)"
                    UserDefaults.standard.set(true, forKey: USER_DEFAULT.isLocationTrackingRunning)
                    self.loc.registerAllRequiredInitilazers()
                    UserDefaults.standard.set(true, forKey: USER_DEFAULT.subscribeLocation)
                }
                
            } else {
                if let _ = UserDefaults.standard.value(forKey: USER_DEFAULT.isLocationTrackingRunning) {
                    self.registerForGoogle()
                    if uiNeeded {
                        self.initHome()
                    } else {
                        self.loc.topic = "\(globalAPIKey)\(globalUserId)"
                        UserDefaults.standard.set(true, forKey: USER_DEFAULT.isLocationTrackingRunning)
                        self.loc.registerAllRequiredInitilazers()
                        UserDefaults.standard.set(true, forKey: USER_DEFAULT.subscribeLocation)
                    }
                } else {
                    self.startSharingLocation()
                }
            }
        }
    }
    
    @objc func becomeActive() {
        self.loc.trackingDelegate = self
        self.loc.becomeActive()
    }
    
    func initHome() {
        var home : HomeController!
        let storyboard = UIStoryboard(name: STORYBOARD_NAME.main, bundle: frameworkBundle)
        home = storyboard.instantiateViewController(withIdentifier: STORYBOARD_ID.home) as! HomeController
        home.trackingDelegate = self
        self.merchantNavigationController?.pushViewController(home, animated: true)
    }
    
    func startSharingLocation() {
        let location = self.loc.getCurrentLocation()
        NetworkingHelper.sharedInstance.shareLocationSession(api_key: globalAPIKey, unique_user_id: globalUserId, lat: "\(location?.coordinate.latitude ?? 0)", lng: "\(location?.coordinate.longitude ?? 0)", sessionId: "") { (isSucceeded, response) in
            
            DispatchQueue.main.async {
                print(response)
                if isSucceeded == true {
                    var sessionID = ""
                    if let data = response["data"] as? [String:Any]{
                        sessionID = "\(data["session_id"] ?? "")"
                        self.delegate.getSessionId?(sessionId: sessionID)
                        UserDefaults.standard.set(sessionID, forKey: USER_DEFAULT.sessionId)
                    }
                    
                    
//                    self.loc.sendFirstLocation()
                    self.registerForGoogle()
                    if self.uiNeeded {
                        self.loc.registerAllRequiredInitilazers()
                        self.initHome()
                    } else {
                        self.loc.topic = "\(globalAPIKey)\(globalUserId)"
                        UserDefaults.standard.set(true, forKey: USER_DEFAULT.isLocationTrackingRunning)
                        UserDefaults.standard.set(true, forKey: USER_DEFAULT.subscribeLocation)
                        self.loc.registerAllRequiredInitilazers()
                    }
                } else {
                    self.model.resetAllData()
                }
            }
        }
    }
    
    func registerForGoogle(){
        GMSPlacesClient.provideAPIKey(APIKeyForGoogleMaps)
        GMSServices.provideAPIKey(APIKeyForGoogleMaps)
    }
    
    
    public func stopTracking(sessionID: String) {
        NetworkingHelper.sharedInstance.stopTracking(sessionID, userID: globalUserId, apiKey: globalAPIKey) { (isSucceeded, response) in
            if isSucceeded == true {
                self.loc.stopLocationService()
                self.model.resetAllData()
                UserDefaults.standard.removeObject(forKey: USER_DEFAULT.userId)
                UserDefaults.standard.removeObject(forKey: USER_DEFAULT.apiKey)
                UserDefaults.standard.removeObject(forKey: USER_DEFAULT.isLocationTrackingRunning)
            }
        }
    }
}

extension TookanTracker: TrackingDelegate {
    
    public func getCoordinates(_ location: CLLocation) {
        self.delegate.getCurrentCoordinates!(location)
        print("LocationTrackerDelegate inside SDK")
    }
    
    public func logout() {
        self.delegate.logout!()
    }
}
