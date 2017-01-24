//
//  MqttClass.swift
//  Tookan
//
//  Created by cl-macmini-45 on 11/07/16.
//  Copyright © 2016 Click Labs. All rights reserved.
//

import UIKit
//import CocoaAsyncSocket

public class MqttClass: NSObject {
    
    static let sharedInstance = MqttClass()
    var mqtt: CocoaMQTT?
    var didConnectAck = false
    var hostAddress = "broker.tookan.io"
    var portNumber:UInt16 = 1883
    
    var accessToken = ""
    var key = ""
    var topic = ""
    weak var delegate : recieveDataFromMqttClass?
    
    
    func connectToServer() {
       _ =  mqtt!.connect()
        
    }
    
    func mqttSetting() {
       // let clientIdPid = "CocoaMQTT--" + String(ProcessInfo().processIdentifier)
        mqtt = CocoaMQTT(clientId: "", host: hostAddress, port:portNumber)
        //mqtts
        if let mqtt = mqtt {
          //  mqtt.username = "test"
         //   mqtt.password = "public"
            mqtt.willMessage = CocoaMQTTWill(topic: "/will", message: "dieout")
            mqtt.keepAlive = 90
            mqtt.delegate = self
        }
    }
    
    public func sendLocation(location:String) {
        if IJReachability.isConnectedToNetwork() == true {
            if(didConnectAck == true) {
                UserDefaults.standard.set(true, forKey: USER_DEFAULT.isHitInProgress)
                UIApplication.shared.isNetworkActivityIndicatorVisible = true
                let sendData = ["access_token":accessToken,
                                "location":"\(location)"]
                var sendDataArray = [Any]()
                sendDataArray.append(sendData)
                _ =  mqtt?.publish(topic: "UpdateLocation", withString: sendDataArray.jsonString, qos: .QOS1)
                //mqtt!.publish("UpdateLocation", withString:sendDataArray.jsonString , qos: .QOS1)
            } else {
                if(mqtt?.connState == CocoaMQTTConnState.DISCONNECTED) {
                    self.mqttSetting()
                    self.connectToServer()
                }
            }
        }
    }
    
    func subscribeLocation() {
        if IJReachability.isConnectedToNetwork() == true {
            if(didConnectAck == true) {
                UserDefaults.standard.set(true, forKey: USER_DEFAULT.isHitInProgress)
                _ = mqtt?.subscribe(topic: self.topic, qos: CocoaMQTTQOS.QOS1)
            } else {
                if(mqtt?.connState == CocoaMQTTConnState.DISCONNECTED) {
                    self.mqttSetting()
                    self.connectToServer()
                }
            }
        }
    }
    
    func stopLocation() {
        let sendData = ["access_token":accessToken,
                        "key":key]
        var sendDataArray = [Any]()
        sendDataArray.append(sendData)
        _ = mqtt?.publish(topic: "UpdateLocation", withString: sendDataArray.jsonString, qos: .QOS1)
    }
    
    func disconnect() {
        mqtt!.disconnect()
    }
    
    
    func isConnectionEstablished() -> Bool {
        if(mqtt?.connState == CocoaMQTTConnState.DISCONNECTED || mqtt?.connState == CocoaMQTTConnState.CONNECTING) {
            return false
        }
        return true
    }
    
    func unsubscribeLocation() {
       // mqtt?.disconnect()
        _ = mqtt?.unsubscribe(topic: self.topic)
    }
    
    
}


extension MqttClass: CocoaMQTTDelegate {
    
    public func mqtt(_ mqtt: CocoaMQTT, didConnect host: String, port: Int) {
    }
    
    
    public func mqtt(_ mqtt: CocoaMQTT, didConnectAck ack: CocoaMQTTConnAck) {
        if ack == .ACCEPT {
           // mqtt.subscribe("UpdateLocation", qos: CocoaMQTTQOS.QOS1)
            _ =  mqtt.subscribe(topic: "UpdateLocation", qos:  CocoaMQTTQOS.QOS1)
            mqtt.ping()
            didConnectAck = true
            //mqtt.publish("UpdateLocation", withString:"Hello" , qos: .QOS1)
        }
    }
    
//    public func mqtt(_ mqtt: CocoaMQTT, didSubscribeTopic topic: String) {
//        print(topic)
//    }
//    
//    public func mqtt(_ mqtt: CocoaMQTT, didUnsubscribeTopic topic: String) {
//        print(topic)
//    }
    
//    public func mqtt(_ mqtt: CocoaMQTT, didPublishMessage message: CocoaMQTTMessage, id: UInt16) {
//        print(message)
//    }
    
//    public func mqtt(_ mqtt: CocoaMQTT, didReceiveMessage message: CocoaMQTTMessage, id: UInt16) {
//        print(message)
//    }
    
    
    public func mqtt(_ mqtt: CocoaMQTT, didPublishMessage message: CocoaMQTTMessage, id: UInt16) {
//        print("didPublishMessage with message: \(message.string)")
//        var locationArray = [Any]()
//        if let array = UserDefaults.standard.object(forKey: USER_DEFAULT.locationArray) as? [Any] {
//            locationArray = array
//        }
//        UIApplication.shared.isNetworkActivityIndicatorVisible = false
//        
//        var sentLocationArray = [Any]()
//        if let sentJsonString = message.string {
//            let locationObject = sentJsonString.jsonObject
//            let locationObjectArray = locationObject[0] as! [String:Any]
//            let locationString = locationObjectArray["location"] as! String
//            print(locationString)
//            sentLocationArray = locationString.jsonObject
//        }
//        for i in (0..<sentLocationArray.count) {
//            let sendDictionaryObject = sentLocationArray[i] as! [String:Any]
//            if let sendTimeStamp = sendDictionaryObject["tm_stmp"] as? String {
//                for j in (0..<locationArray.count) {
//                    let locationDictionaryObject = locationArray[j] as!  [String:Any]
//                    if let locationTimeStamp = locationDictionaryObject["tm_stmp"] as? String {
//                        if(sendTimeStamp == locationTimeStamp) {
//                            locationArray.remove(at: j)
//                            break
//                        }
//                    }
//                }
//            }
//        }
//        UserDefaults.standard.set(locationArray, forKey: USER_DEFAULT.locationArray)
//        UserDefaults.standard.synchronize()
//        UserDefaults.standard.set(false, forKey: USER_DEFAULT.isHitInProgress)
    }
    
    public func mqtt(_ mqtt: CocoaMQTT, didPublishAck id: UInt16) {
        UserDefaults.standard.set(false, forKey: USER_DEFAULT.isHitInProgress)
    }
    
    public func mqtt(_ mqtt: CocoaMQTT, didReceiveMessage message: CocoaMQTTMessage, id: UInt16 ) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        let locationDictionaryArray = message.string?.jsonObjectArray
        if locationDictionaryArray!.count > 0{
            let locationDictionary = message.string?.jsonObjectArray[0] as! [String:Any]
        if let locationArray = locationDictionary["location"] as? [Any] {
          let data = parsingLocations(locationArray: locationArray)
            delegate?.recievedLatlong(data: data,message:message.string!)
            }
        } else {
            if message.string == "NaN"{
                delegate?.unsubscribeSocket()
            }
            //NotificationCenter.default.post(name: Foundation.Notification.Name(rawValue: NOTIFICATION_OBSERVER.stopTracking), object: nil)
        }
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
    }
    
    public func mqtt(_ mqtt: CocoaMQTT, didSubscribeTopic topic: String) {
    }
    
    public func mqtt(_ mqtt: CocoaMQTT, didUnsubscribeTopic topic: String) {
    }
    
    
    public func mqttDidPing(_ mqtt: CocoaMQTT) {
    }
    
    
    
    public func mqttDidReceivePong(_ mqtt: CocoaMQTT) {
        _console(info: "didReceivePong")
    }
    
    
    
    public func mqttDidDisconnect(_ mqtt: CocoaMQTT, withError err: NSError?) {
        didConnectAck = false
        _console(info: "mqttDidDisconnect")
            if(mqtt.connState == CocoaMQTTConnState.DISCONNECTED) {
                self.mqttSetting()
                self.connectToServer()
        }
        _console(info: "mqttDidDisconnect")
        UserDefaults.standard.set(false, forKey: USER_DEFAULT.isHitInProgress)
    }
    func _console(info: String) {
    }
    
    
}
