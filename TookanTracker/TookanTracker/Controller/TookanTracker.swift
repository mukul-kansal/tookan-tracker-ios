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

@objc public protocol TookanTrackerDelegate {
    @objc optional func getCurrentCoordinates(_ location:CLLocation)
    @objc optional func logout()
}

public class TookanTracker: NSObject {
    public static var shared = TookanTracker()
    private var merchantNavigationController:UINavigationController?
    let loc = LocationTrackerFile.sharedInstance()
    public var delegate:TookanTrackerDelegate!
    let model = TrackerModel()
    
    public func createSession(userID:String, apiKey: String, navigationController:UINavigationController) {
        globalUserId = userID
        globalAPIKey = apiKey
        self.merchantNavigationController = navigationController
        
        self.loc.trackingDelegate = self
        let location = self.loc.getCurrentLocation()
        Auxillary.showAlert("ENterd")
            if let sessionIDText = UserDefaults.standard.value(forKey: USER_DEFAULT.sessionId) as? String {
                Auxillary.showAlert("direct")
                self.registerForGoogle()
                self.initHome(sessionID: sessionIDText)
            } else {
                Auxillary.showAlert("indirect")
                UserDefaults.standard.set(apiKey, forKey: USER_DEFAULT.apiKey)
                UserDefaults.standard.set(userID, forKey: USER_DEFAULT.userId)
                NetworkingHelper.sharedInstance.shareLocationSession(api_key: globalAPIKey, unique_user_id: globalUserId, lat: "\(location?.coordinate.latitude ?? 0)", lng: "\(location?.coordinate.longitude ?? 0)", sessionId: "") { (isSucceeded, response) in
                    
                    DispatchQueue.main.async {
                        print(response)
                        if isSucceeded == true {
                            var sessionID = ""
                            if let data = response["data"] as? [String:Any]{
                                sessionID = "\(data["session_id"] ?? "")"
                                UserDefaults.standard.set(sessionID, forKey: USER_DEFAULT.sessionId)
                            }
                            self.loc.registerAllRequiredInitilazers()
                            self.registerForGoogle()
                            self.initHome(sessionID: sessionID)
                            
                        }
                    }
                }
            }
    }
    
    func initHome(sessionID: String) {
        var home : HomeController!
        let storyboard = UIStoryboard(name: STORYBOARD_NAME.main, bundle: frameworkBundle)
        home = storyboard.instantiateViewController(withIdentifier: STORYBOARD_ID.home) as! HomeController
        home.sessionID = sessionID
        home.trackingDelegate = self
        self.merchantNavigationController?.pushViewController(home, animated: true)
    }
    
    func registerForGoogle(){
        GMSPlacesClient.provideAPIKey(APIKeyForGoogleMaps)
        GMSServices.provideAPIKey(APIKeyForGoogleMaps)
    }
    
    
    public func stopTracking(sessionID: String) {
        NetworkingHelper.sharedInstance.stopTracking(sessionID, userID: globalUserId, apiKey: globalAPIKey) { (isSucceeded, response) in
            if isSucceeded == true {
//                self.googleMapView.clear()
//                self.userStatus = USER_JOB_STATUS.free
                self.loc.stopLocationService()
                self.model.resetAllData()
//                self.navigationController?.popViewController(animated: true)
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
