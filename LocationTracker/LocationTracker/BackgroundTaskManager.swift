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
    
    private var masterTaskId: UIBackgroundTaskIdentifier!
    private var bgTaskIdList: NSMutableArray!
    private static let sharedBGTaskManager = BackgroundTaskManager()
    
    override init() {
        super.init()
        bgTaskIdList = NSMutableArray()
        masterTaskId = UIBackgroundTaskInvalid
    }

    class func sharedBackgroundTaskManager() -> BackgroundTaskManager {
        return sharedBGTaskManager
    }
    
    func beginNewBackgroundTask() -> UIBackgroundTaskIdentifier {
        let application = UIApplication.sharedApplication()
        var bgTaskId = UIBackgroundTaskInvalid
        if application.respondsToSelector(#selector(UIApplication.beginBackgroundTaskWithExpirationHandler(_:))){
            bgTaskId = application.beginBackgroundTaskWithExpirationHandler({

            })
            if self.masterTaskId == UIBackgroundTaskInvalid {
                self.masterTaskId = bgTaskId
            }
            else {
                self.bgTaskIdList.addObject(bgTaskId)
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
    
    func drainBGTaskList(all: Bool) {
        let application: UIApplication = UIApplication.sharedApplication()
        if application.respondsToSelector(#selector(UIApplication.endBackgroundTask(_:))) {
            let count = self.bgTaskIdList.count
            for _ in ((all ? 0 : 1)..<count){
//            for var i = (all ? 0 : 1); i < count; i += 1 {
                let bgTaskId: UIBackgroundTaskIdentifier = self.bgTaskIdList.objectAtIndex(0).integerValue
                application.endBackgroundTask(bgTaskId)
                self.bgTaskIdList.removeObjectAtIndex(0)
            }
            if self.bgTaskIdList.count > 0 {
            }
            if all {
                application.endBackgroundTask(self.masterTaskId)
                self.masterTaskId = UIBackgroundTaskInvalid
            }
            else {
            }
        }
    }
    
}