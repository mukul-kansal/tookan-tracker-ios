//
//  CommonFunctions.swift
//  DemoApp
//
//  Created by CL-Macmini-110 on 12/1/17.
//  Copyright © 2017 CL-Macmini-110. All rights reserved.
//

import Foundation
import CoreLocation

class CommomFunctions: NSObject {
    
    static let sharedInstance = CommomFunctions()
    
    func checkLocationAuthorization() -> Bool {
        return CLLocationManager.locationServicesEnabled() == true
    }
    
    
    
    
//
//    if(UIApplication.shared.backgroundRefreshStatus == UIBackgroundRefreshStatus.denied) {
//    DispatchQueue.main.async {
//    if(UIApplication.shared.applicationState == UIApplicationState.active) {
//    //                    UIAlertView(title: "", message: "The app doesn't work without the Background App Refresh enabled. To turn it on, go to Settings > General > Background App Refresh", delegate: nil, cancelButtonTitle: "OK").show()
//    self.popupForBackgroundRefresh(message: "The app doesn't work without the Background App Refresh enabled. To turn it on, go to Settings > General > Background App Refresh")
//    }
//    }
//    return false
//    } else if (UIApplication.shared.backgroundRefreshStatus == UIBackgroundRefreshStatus.restricted) {
//    DispatchQueue.main.async {
//    if(UIApplication.shared.applicationState == UIApplicationState.active) {
//    //                    UIAlertView(title: "", message: "The functions of this app are limited because the Background App Refresh is disable.", delegate: nil, cancelButtonTitle: "OK").show()
//    self.popupForBackgroundRefresh(message: "The functions of this app are limited because the Background App Refresh is disable.")
//    }
//    }
//    return false
//    } else if CLLocationManager.locationServicesEnabled() == false {
//    NotificationCenter.default.post(name: Foundation.Notification.Name(rawValue: NotifRequestingResponse.locationServicesDisabled.rawValue), object: self)
//    return false
//    }
//    else {
//    let authorizationStatus = CLLocationManager.authorizationStatus()
//    if authorizationStatus == CLAuthorizationStatus.denied || authorizationStatus == CLAuthorizationStatus.restricted {
//    NotificationCenter.default.post(name: Foundation.Notification.Name(rawValue: NotifRequestingResponse.locationServicesDisabled.rawValue), object: self)
//    return false
//    }
//    return true
//    }
    
    
    
}
