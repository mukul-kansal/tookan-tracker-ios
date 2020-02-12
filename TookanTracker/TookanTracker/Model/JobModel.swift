//
//  JobModel.swift
//  TookanTracker
//
//  Created by Mukul Kansal on 17/01/20.
//  Copyright © 2020 CL-Macmini-110. All rights reserved.
//

import Foundation

class JobModel :NSObject{
    var jobData = [String: Any]()
    var jobLat = ""
    var joblng = ""
    var sessionId = ""
    var sessionUrl = ""
    override init() {
        
    }
    
    
    init(json:[String:Any]) {
          
          super.init()
          print(json)
          
        if let value = json["jobs_data"] as? [String:Any]{
            self.jobData = value
        }
        
          if let value = json["latitude"] as? String{
              self.jobLat = value
          }
          
          if let value = json["longitude"] as? String{
              self.joblng = value
          }
          
          if let value = json["session_id"] as? String{
              self.sessionId = value
               LocationTrackerFile.sharedInstance().sessionId = value
          }
          
          if let value = json["session_url"] as? String{
              self.sessionUrl = value
          }
      }
      
      func getDuplicateInstance() -> AgentDetailModel {
          let task = AgentDetailModel(json: [String : Any]())
          task.jobLatitude = self.jobLat
          task.jobLongitude = self.joblng
          task.sessionId = self.sessionId
          task.sessionUrl = self.sessionUrl
        return task
      }

}
