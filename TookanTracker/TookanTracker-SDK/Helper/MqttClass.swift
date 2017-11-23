//
//  MqttClass.swift
//  Tookan
//
//  Created by cl-macmini-45 on 11/07/16.
//  Copyright © 2016 Click Labs. All rights reserved.
//

import UIKit
import CoreLocation
//import CocoaMQTT

open class MqttClass: NSObject {
    
    static let sharedInstance = MqttClass()
    var mqtt: CocoaMQTT?
    var didConnectAck = false
    var hostAddress = "broker.tookan.io"//"dev.tracking.tookan.io"////"test.mosquitto.org"//
    var portNumber:UInt16 = 1883
    //var accessToken = ""
  //  var key = ""
    var topic = ""
    
    override init() {
        mqtt = CocoaMQTT(clientId: "", host: hostAddress, port:portNumber)
    }
    
    func connectToServer() {
        _ = mqtt!.connect()
    }
    
    func mqttSetting() {
        if let mqtt = mqtt {
          //  mqtt.username = "t"
           // mqtt.password = "t"
            mqtt.willMessage = CocoaMQTTWill(topic: "/will", message: "dieout")
            mqtt.keepAlive = 90
            mqtt.delegate = self
        }
    }
    
    func sendLocation(_ location:String) {
        if IJReachability.isConnectedToNetwork() == true {
            if(didConnectAck == true) {
                UserDefaults.standard.set(true, forKey: USER_DEFAULT.isHitInProgress)
                UIApplication.shared.isNetworkActivityIndicatorVisible = true
                let sendData = ["location":"\(location)"]
                print("Send Data = \(sendData)")
                var sendDataArray = [Any]()
                sendDataArray.append(sendData)
                //mqttObject?.publish(topic: "UpdateLocation", withString: sendDataArray.jsonString, qos: .qos1, retained: false, dup: false)
               _ = mqtt!.publish(topic: self.topic, withString:sendDataArray.jsonString , qos: .QOS2)
                
               // mqttObject?.willMessage = CocoaMQTTWill(topic: self.topic, message: sendDataArray.jsonString)
            } else {
                if(mqtt?.connState == CocoaMQTTConnState.DISCONNECTED) {
                    self.mqttSetting()
                    self.connectToServer()
                }
            }
        }
    }
    
    func stopLocation() {
       // let sendData = ["access_token":accessToken,
                     //   "key":key]
     //   var sendDataArray = [Any]()
     //   sendDataArray.append(sendData)
        //mqtt?.publish(topic: <#T##String#>, withString: <#T##String#>)
      //  _ = mqttObject!.publish(topic: self.topic, withString:sendDataArray.jsonString , qos: .QOS1)
    }
    
    func disconnect() {
        mqtt!.disconnect()
    }
    
    func subscribeLocation() {
        print(self.topic)
        if IJReachability.isConnectedToNetwork() == true {
            if(didConnectAck == true) {
                UserDefaults.standard.set(true, forKey: USER_DEFAULT.isHitInProgress)
                UIApplication.shared.isNetworkActivityIndicatorVisible = true
                _ = mqtt?.subscribe(topic: self.topic, qos: CocoaMQTTQOS.QOS2)
            } else {
                if(mqtt?.connState == CocoaMQTTConnState.DISCONNECTED) {
                    self.mqttSetting()
                    self.connectToServer()
                }
            }
        }
    }
    
    func unsubscribeLocation() {
       _ = mqtt?.unsubscribe(topic: self.topic)
    }
}

extension MqttClass: CocoaMQTTDelegate {
    
    public func mqtt(_ mqtt: CocoaMQTT, didConnect host: String, port: Int) {
        print("didConnect \(host):\(port)")
    }
    
    public func mqtt(_ mqtt: CocoaMQTT, didConnectAck ack: CocoaMQTTConnAck) {
        if ack == .ACCEPT {
           // _ = mqtt.subscribe(topic: self.accessToken, qos: CocoaMQTTQOS.QOS1)
            mqtt.ping()
            didConnectAck = true
            if UserDefaults.standard.bool(forKey: USER_DEFAULT.subscribeLocation) == true {
                _ = mqtt.subscribe(topic: self.topic, qos: CocoaMQTTQOS.QOS2)
            }
           // _ = mqtt.publish(topic: "UpdateLocation", withString:"Hello" , qos: .QOS1)
        }
        
    }
    
    public func mqtt(_ mqtt: CocoaMQTT, didPublishMessage message: CocoaMQTTMessage, id: UInt16) {
        print("didPublishMessage with message: \(message.string)")
        var locationArray = [Any]()
        if let array = UserDefaults.standard.object(forKey: USER_DEFAULT.locationArray) as? [Any]{
            locationArray = array
        }
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
        
        var sentLocationArray = [Any]()
        if let sentJsonString = message.string {
            let locationObject = sentJsonString.jsonObjectArray
            let locationObjectArray = locationObject[0] as! [String:Any]
            let locationString = locationObjectArray["location"] as! String
            sentLocationArray = locationString.jsonObjectArray
        }
        
        for i in (0..<sentLocationArray.count) {
            //  print(sentLocationArray[i])
            let sendDictionaryObject = sentLocationArray[i] as! [String:Any]
            //  locationArray.addObject(sendDictionaryObject)
            //  print(sendDictionaryObject)
            if let sendTimeStamp = sendDictionaryObject["tm_stmp"] as? String {
                for j in (0..<locationArray.count) {
                    let locationDictionaryObject = locationArray[j] as! [String:Any]
                    if let locationTimeStamp = locationDictionaryObject["tm_stmp"] as? String {
                        if(sendTimeStamp == locationTimeStamp) {
                            locationArray.remove(at: j)
                            break
                        }
                    }
                }
            }
        }
        UserDefaults.standard.set(locationArray, forKey: USER_DEFAULT.locationArray)
        UserDefaults.standard.synchronize()
        UserDefaults.standard.set(false, forKey: USER_DEFAULT.isHitInProgress)
    }
    
    public func mqtt(_ mqtt: CocoaMQTT, didPublishAck id: UInt16) {
        print("didPublishAck with id: \(id)")
        UserDefaults.standard.set(false, forKey: USER_DEFAULT.isHitInProgress)
    }
    
    
    
    public func mqtt(_ mqtt: CocoaMQTT, didReceiveMessage message: CocoaMQTTMessage, id: UInt16 ) {
        let locationDictionary = message.string?.jsonObjectArray[0] as! [String:Any]
        
        if let locationString = locationDictionary["location"] as? String {
            let locationArray = locationString.jsonObjectArray
            for i in (0..<locationArray.count) {
                let locationData = locationArray[i] as! [String:Any]
                /*------- For Updating Path ------------*/
                var locationDictionary = [String:Any]()
                var updatingLocationArray = [Any]()
                var latitudeString:Double?
                var longitudeString:Double?
                if let lat = locationData["lat"] as? NSNumber {
                    latitudeString = Double(lat)
                } else if let lat = locationData["lat"] as? String {
                    latitudeString = Double(lat)
                }
                
                if let long = locationData["lng"] as? NSNumber {
                    longitudeString = Double(long)
                } else if let long = locationData["lng"] as? String {
                    longitudeString = Double(long)
                }

                let coordinate = CLLocationCoordinate2D(latitude: latitudeString!, longitude: longitudeString!)
                locationDictionary = ["Latitude":coordinate.latitude, "Longitude":coordinate.longitude]
                if let array = UserDefaults.standard.value(forKey: USER_DEFAULT.updatingLocationPathArray) as? [Any] {
                    updatingLocationArray = array
                }
                updatingLocationArray.append(locationDictionary)
                UserDefaults.standard.setValue(updatingLocationArray, forKey: USER_DEFAULT.updatingLocationPathArray)
                NotificationCenter.default.post(name: Foundation.Notification.Name(rawValue: OBSERVER.updatePath), object: nil)
                /*----------------------------------------------*/
                
            }
        } else {
            NotificationCenter.default.post(name: Foundation.Notification.Name(rawValue: OBSERVER.stopTracking), object: nil)
        }
    }
    
    public func mqtt(_ mqtt: CocoaMQTT, didSubscribeTopic topic: String) {
        print("didSubscribeTopic to \(topic)")
    }
    
    public func mqtt(_ mqtt: CocoaMQTT, didUnsubscribeTopic topic: String) {
        print("didUnsubscribeTopic to \(topic)")
    }
    
    public func mqttDidPing(_ mqtt: CocoaMQTT) {
        print("didPing")
    }
    
    public func mqttDidReceivePong(_ mqtt: CocoaMQTT) {
        _console("didReceivePong")
    }
    
    public func mqttDidDisconnect(_ mqtt: CocoaMQTT, withError err: NSError?) {
        didConnectAck = false
        _console("mqttDidDisconnect")
        UserDefaults.standard.set(false, forKey: USER_DEFAULT.isHitInProgress)
        
        if UserDefaults.standard.bool(forKey: USER_DEFAULT.subscribeLocation) == true {
            if(mqtt.connState == CocoaMQTTConnState.DISCONNECTED) {
                self.mqttSetting()
                self.connectToServer()
            }
        }
    }
    
    func _console(_ info: String) {
        print("Delegate: \(info)")
    }
}
