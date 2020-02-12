//
//  LocationShareModel.swift
//  TookanTracker
//
//  Created by Mukul Kansal on 03/02/20.
//  Copyright © 2020 CL-Macmini-110. All rights reserved.
//

import Foundation

class LocationShareModel: NSObject {
    
    var timer: Timer?
    
    var delay10Seconds: Timer?
    
    var bgTask: BackgroundTaskManager?
    
    fileprivate static let shareMyModel = LocationShareModel()
    
    class func sharedModel() -> LocationShareModel {
        return shareMyModel
    }
}
