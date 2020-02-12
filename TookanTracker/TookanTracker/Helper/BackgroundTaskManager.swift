//
//  BackgroundTaskManager.swift
//  Tookan
//
//  Created by Click Labs on 8/14/15.
//  Copyright (c) 2015 Click Labs. All rights reserved.
//

import Foundation
import UIKit

class BackgroundTaskManager: LocationTrackerFile {
    
    fileprivate var masterTaskId: UIBackgroundTaskIdentifier!
    fileprivate var bgTaskIdList: NSMutableArray!
    fileprivate static let sharedBGTaskManager = BackgroundTaskManager()
    
    override init() {
        super.init()
        bgTaskIdList = NSMutableArray()
        masterTaskId = UIBackgroundTaskIdentifier.invalid
    }

    class func sharedBackgroundTaskManager() -> BackgroundTaskManager {
        return sharedBGTaskManager
    }
    
    func beginNewBackgroundTask() -> UIBackgroundTaskIdentifier {
        let application = UIApplication.shared
        var bgTaskId = UIBackgroundTaskIdentifier.invalid
        
        if application.responds(to: #selector(UIApplication.beginBackgroundTask(expirationHandler:))){
            bgTaskId = application.beginBackgroundTask(expirationHandler: {
                
            })
            if self.masterTaskId == UIBackgroundTaskIdentifier.invalid {
                self.masterTaskId = bgTaskId
            }
            else {
                self.bgTaskIdList.add(bgTaskId)
                self.endBackgroundTasks()
            }
        }
        return bgTaskId
    }

    
    func endBackgroundTasks(){
        self.drainBGTaskList(false)
    }
    
    func endAllBackgroundTasks() {
        self.drainBGTaskList(true)
    }
    
    func drainBGTaskList(_ all: Bool) {
        let application: UIApplication = UIApplication.shared
        if application.responds(to: #selector(UIApplication.endBackgroundTask(_:))) {
            let count = self.bgTaskIdList.count
            for _ in ((all ? 0 : 1)..<count){
//            for var i = (all ? 0 : 1); i < count; i += 1 {
                let bgTaskId: UIBackgroundTaskIdentifier = self.bgTaskIdList.object(at: 0) as! UIBackgroundTaskIdentifier
                application.endBackgroundTask(bgTaskId)
                self.bgTaskIdList.removeObject(at: 0)
            }
            if self.bgTaskIdList.count > 0 {
            }
            if all {
                application.endBackgroundTask(self.masterTaskId)
                self.masterTaskId = UIBackgroundTaskIdentifier.invalid
            }
            else {
            }
        }
    }
    
}
