//
//  JobData.swift
//  TookanTracker
//
//  Created by Mukul Kansal on 17/01/20.
//  Copyright © 2020 CL-Macmini-110. All rights reserved.
//

import Foundation

class JobData : NSObject {
//    var jobs :[[String:Any]]? = [[String:Any]]()
    var jobs = [Jobs]()
    var routedJobs = [RoutedJobs]()
    
    override init() {
        
    }
    
    init(json:[String:Any]) {
    
    super.init()
    print(json)
        
        if let value = json["jobs"] as? [[String:Any]]{
            if value.count > 0 {
                for dict in value {
                    let jobObj = Jobs.init(json: dict)
                    self.jobs.append(jobObj)
                }
                print("Aftr saving jobs are \(self.jobs)")
            }
//            self.jobs = value
        }
        
        if let value = json["routed_jobs"] as? [[String:Any]]{
            if value.count > 0 {
                for dict in value{
                    let routedjobObj = RoutedJobs.init(json: dict)
                    self.routedJobs.append(routedjobObj)
                }
            }
        }
    }

}

class RoutedJobs : NSObject{
    
    init(json:[String:Any]) {
    
    super.init()
    }
}
