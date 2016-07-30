//
//  MqttClass.swift
//  Tookan
//
//  Created by cl-macmini-45 on 11/07/16.
//  Copyright © 2016 Click Labs. All rights reserved.
//

import UIKit
import CocoaMQTT

public class MqttClass: NSObject {
    
    static let sharedInstance = MqttClass()
    var mqtt: CocoaMQTT?
    var didConnectAck = false
    var hostAddress = "test.tookanapp.com"
    var portNumber:UInt16 = 1883
    var accessToken = ""
    var key = ""
    
    func connectToServer() {
        mqtt!.connect()
    }
    
    func mqttSetting() {
        let clientIdPid = "CocoaMQTT--" + String(NSProcessInfo().processIdentifier)
        mqtt = CocoaMQTT(clientId: clientIdPid, host: hostAddress, port:portNumber)
        //mqtts
        if let mqtt = mqtt {
            mqtt.username = "t"
            mqtt.password = "t"
            mqtt.willMessage = CocoaMQTTWill(topic: "/will", message: "dieout")
            mqtt.keepAlive = 90
            mqtt.delegate = self
        }
    }
    
    func sendLocation(location:String) {
        if IJReachability.isConnectedToNetwork() == true {
            if(didConnectAck == true) {
                NSUserDefaults.standardUserDefaults().setBool(true, forKey: USER_DEFAULT.isHitInProgress)
                UIApplication.sharedApplication().networkActivityIndicatorVisible = true
                let sendData = ["access_token":accessToken,
                                "key":key,
                                "location":"\(location)"]
                let sendDataArray = NSMutableArray()
                sendDataArray.addObject(sendData)
                mqtt!.publish("UpdateLocation", withString:sendDataArray.jsonString , qos: .QOS1)
            } else {
                if(mqtt?.connState == CocoaMQTTConnState.DISCONNECTED) {
                    self.mqttSetting()
                    self.connectToServer()
                }
            }
        }
    }
    func disconnect() {
        mqtt!.disconnect()
    }
    
}

extension MqttClass: CocoaMQTTDelegate {
    
    public func mqtt(mqtt: CocoaMQTT, didConnect host: String, port: Int) {
        print("didConnect \(host):\(port)")
    }
    
    public func mqtt(mqtt: CocoaMQTT, didConnectAck ack: CocoaMQTTConnAck) {
        if ack == .ACCEPT {
            mqtt.subscribe("UpdateLocation", qos: CocoaMQTTQOS.QOS1)
            mqtt.ping()
            didConnectAck = true
            //mqtt.publish("UpdateLocation", withString:"Hello" , qos: .QOS1)
        }
        
    }
    
    public func mqtt(mqtt: CocoaMQTT, didPublishMessage message: CocoaMQTTMessage, id: UInt16) {
        print("didPublishMessage with message: \(message.string)")
    }
    
    public func mqtt(mqtt: CocoaMQTT, didPublishAck id: UInt16) {
        print("didPublishAck with id: \(id)")
        NSUserDefaults.standardUserDefaults().setBool(false, forKey: USER_DEFAULT.isHitInProgress)
    }
    
    public func mqtt(mqtt: CocoaMQTT, didReceiveMessage message: CocoaMQTTMessage, id: UInt16 ) {
        print("didReceivedMessage: \(message.string) with id \(id)")
        var locationArray = NSMutableArray()
        if let array = NSUserDefaults.standardUserDefaults().objectForKey(USER_DEFAULT.locationArray) as? NSMutableArray {
            locationArray = NSMutableArray(array: array)
        }
        UIApplication.sharedApplication().networkActivityIndicatorVisible = false
        
        var sentLocationArray = NSMutableArray()
        if let sentJsonString = message.string {
            let locationObject = sentJsonString.jsonObject
            let locationObjectArray = locationObject.objectAtIndex(0) as! NSDictionary
            let locationString = locationObjectArray["location"] as! String
            sentLocationArray = NSMutableArray(array: locationString.jsonObject)
        }
        for i in (0..<sentLocationArray.count) {
            let sendDictionaryObject = sentLocationArray.objectAtIndex(i) as! NSDictionary
            if let sendTimeStamp = sendDictionaryObject["tm_stmp"] as? String {
                for j in (0..<locationArray.count) {
                    let locationDictionaryObject = locationArray.objectAtIndex(j) as! NSDictionary
                    if let locationTimeStamp = locationDictionaryObject["tm_stmp"] as? String {
                        if(sendTimeStamp == locationTimeStamp) {
                            locationArray.removeObjectAtIndex(j)
                            break
                        }
                    }
                }
            }
        }
        NSUserDefaults.standardUserDefaults().setObject(locationArray, forKey: USER_DEFAULT.locationArray)
        NSUserDefaults.standardUserDefaults().synchronize()
        NSUserDefaults.standardUserDefaults().setBool(false, forKey: USER_DEFAULT.isHitInProgress)
    }
    
    public func mqtt(mqtt: CocoaMQTT, didSubscribeTopic topic: String) {
        print("didSubscribeTopic to \(topic)")
    }
    
    public func mqtt(mqtt: CocoaMQTT, didUnsubscribeTopic topic: String) {
        print("didUnsubscribeTopic to \(topic)")
    }
    
    public func mqttDidPing(mqtt: CocoaMQTT) {
        print("didPing")
    }
    
    public func mqttDidReceivePong(mqtt: CocoaMQTT) {
        _console("didReceivePong")
    }
    
    public func mqttDidDisconnect(mqtt: CocoaMQTT, withError err: NSError?) {
        didConnectAck = false
        _console("mqttDidDisconnect")
        NSUserDefaults.standardUserDefaults().setBool(false, forKey: USER_DEFAULT.isHitInProgress)
    }
    
    func _console(info: String) {
        print("Delegate: \(info)")
    }
}
