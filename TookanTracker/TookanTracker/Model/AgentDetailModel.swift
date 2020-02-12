//
//  AgentDetailModel.swift
//  TookanTracker
//
//  Created by Mukul Kansal on 16/01/20.
//  Copyright © 2020 CL-Macmini-110. All rights reserved.
//

import Foundation

class AgentDetailModel: NSObject {
    
    
    var jobLatitude : String?
    var jobLongitude : String?
    var sessionId : String?
    var sessionUrl : String?
    
    init(json:[String:Any]) {
        
        super.init()
        print(json)
        
        if let value = json["latitude"] as? String{
            self.jobLatitude = value
        }
        
        if let value = json["longitude"] as? String{
            self.jobLongitude = value
        }
        
        if let value = json["session_id"] as? String{
            self.sessionId = value
        }
        
        if let value = json["session_url"] as? String{
            self.sessionUrl = value
        }
    }
    
    func getDuplicateInstance() -> AgentDetailModel {
        let task = AgentDetailModel(json: [String : Any]())
        task.jobLatitude = self.jobLatitude
        task.jobLongitude = self.jobLongitude
        task.sessionId = self.sessionId
        task.sessionUrl = self.sessionUrl
        return task
    }
    
}
