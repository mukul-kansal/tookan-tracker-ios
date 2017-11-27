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

public class TookanTracker: NSObject {
    public static var shared = TookanTracker()
    private var merchantNavigationController:UINavigationController?
    
    public func createSession(userID:String, apiKey: String, navigationController:UINavigationController) {
        globalUserId = userID
        globalAPIKey = apiKey
        self.merchantNavigationController = navigationController
        
        NetworkingHelper.sharedInstance.shareLocationSession(api_key: globalAPIKey, unique_user_id: globalUserId, lat: "", lng: "", sessionId: "") { (isSucceeded, response) in
            DispatchQueue.main.async {
                print(response)
//                self.registerForGoogle()
//                self.initHome()
                if isSucceeded == true {
                    self.registerForGoogle()
                    self.initHome()
                } else {
                    
                }
            }
        }
        
        
    }
    
    func initHome() {
        var home : HomeController!
        let storyboard = UIStoryboard(name: STORYBOARD_NAME.main, bundle: frameworkBundle)
        home = storyboard.instantiateViewController(withIdentifier: STORYBOARD_ID.home) as! HomeController
        self.merchantNavigationController?.pushViewController(home, animated: true)
    }
    
    public func registerForGoogle(){
        GMSPlacesClient.provideAPIKey(APIKeyForGoogleMaps)
        GMSServices.provideAPIKey(APIKeyForGoogleMaps)
    }
}

