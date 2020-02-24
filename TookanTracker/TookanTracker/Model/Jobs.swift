//
//  Jobs.swift
//  TookanTracker
//
//  Created by Mukul Kansal on 21/01/20.
//  Copyright © 2020 CL-Macmini-110. All rights reserved.
//

import Foundation

class Jobs: NSObject{


    var jobAddress = ""
    var jobHash = ""
    var jobId = ""
    var jobLat = ""
    var jobLng = ""
    var jobPickupAddress = ""
    var jobPickupLat = ""
    var jobPickupLng = ""
    var jobStatus = ""
    var jobType = ""
    var licenseNumber = ""
    var fleetID = ""
    var fleetImage = ""
    var fleetLatitude = ""
    var fleetlongitude = ""
    var fleetName = ""
    var fleetPhone = ""
    var fleetStatus = ""
    var fleetThumbImage = ""
    var userID = ""
    override init() {
        
    }
    
    init(json:[String:Any]) {
    
    super.init()
    print(json)
        
        if let value = json["job_address"] as? String{
            self.jobAddress = value
        }
        
        if let value = json["job_hash"] as? String{
            self.jobHash = value
        }else if let value = json["job_hash"] as? NSNumber{
            self.jobHash = "\(value)"
        }
        
        if let value = json["job_id"] as? String{
            self.jobId = value
        }else if let value = json["job_id"] as? NSNumber{
            self.jobId = "\(value)"
        }
        
        if let value = json["job_latitude"] as? String{
            self.jobLat = value
        }
        
        if let value = json["job_longitude"] as? String{
            self.jobLng = value
        }
        if let value = json["job_pickup_address"] as? String{
            self.jobPickupAddress = value
        }
        if let value = json["job_pickup_latitude"] as? String{
            self.jobPickupLat = value
        }else if let value = json["job_pickup_latitude"] as? NSNumber{
            self.jobPickupLat = "\(value)"
        }
        if let value = json["job_pickup_longitude"] as? String{
            self.jobPickupLng = value
        }else if let value = json["job_pickup_longitude"] as? NSNumber{
            self.jobPickupLng = "\(value)"
        }
        if let value = json["job_status"] as? String{
            self.jobStatus = value
        }else if let value = json["job_status"] as? NSNumber{
            self.jobStatus = "\(value)"
        }
        if let value = json["job_type"] as? String{
            self.jobType = value
        }else if let value = json["job_type"] as? NSNumber{
            self.jobType = "\(value)"
        }
        if let value = json["license"] as? String{
            self.licenseNumber = value
        }else if let value = json["license"] as? NSNumber{
            self.licenseNumber = "\(value)"
        }
        if let value = json["fleet_id"] as? String{
            self.fleetID = value
        }else if let value = json["fleet_id"] as? NSNumber{
            self.fleetID = "\(value)"
        }
        if let value = json["fleet_image"] as? String{
            self.fleetImage = value
        }else if let value = json["fleet_image"] as? NSNumber{
            self.fleetImage = "\(value)"
        }
        if let value = json["fleet_latitude"] as? String{
            self.fleetLatitude = value
        }else if let value = json["fleet_latitude"] as? NSNumber{
            self.fleetLatitude = "\(value)"
        }
        if let value = json["fleet_latitude"] as? String{
            self.fleetLatitude = value
        }else if let value = json["fleet_latitude"] as? NSNumber{
            self.fleetLatitude = "\(value)"
        }
        if let value = json["fleet_longitude"] as? String{
            self.fleetlongitude = value
        }else if let value = json["fleet_longitude"] as? NSNumber{
            self.fleetlongitude = "\(value)"
        }
        if let value = json["fleet_name"] as? String{
            self.fleetName = value
        }else if let value = json["fleet_name"] as? NSNumber{
            self.fleetName = "\(value)"
        }
        if let value = json["fleet_phone"] as? String{
            self.fleetPhone = value
        }else if let value = json["fleet_phone"] as? NSNumber{
            self.fleetPhone = "\(value)"
        }
        if let value = json["fleet_status"] as? String{
            self.fleetStatus = value
        }else if let value = json["fleet_status"] as? NSNumber{
            self.fleetStatus = "\(value)"
        }
        if let value = json["fleet_thumb_image"] as? String{
             self.fleetThumbImage = value
         }else if let value = json["fleet_thumb_image"] as? NSNumber{
             self.fleetThumbImage = "\(value)"
         }
        if let value = json["user_id"] as? String{
             self.userID = value
         }else if let value = json["user_id"] as? NSNumber{
             self.userID = "\(value)"
         }

        
        
    }
    

    
}
