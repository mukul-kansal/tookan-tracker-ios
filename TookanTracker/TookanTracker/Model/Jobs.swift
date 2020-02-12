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
        
 
        //                    "job_address" = "Unnamed Road, Chaunki, Panchkula, Haryana, India, 134107";
        //                    "job_hash" = 8dd7ee77caeb20519798d7522a106bd2;
        //                    "job_id" = 436463;
        //                    "job_latitude" = "30.6951933";
        //                    "job_longitude" = "76.8793952";
        //                    "job_pickup_address" = "Unnamed Road, Chaunki, Panchkula, Haryana, India, 134107";
        //                    "job_pickup_latitude" = "30.6951933";
        //                    "job_pickup_longitude" = "76.8793952";
        //                    "job_status" = 4;
        //                    "job_type" = 3;

        
        
    }
    

    
}
