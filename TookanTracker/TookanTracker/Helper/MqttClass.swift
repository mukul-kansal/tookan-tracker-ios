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
    var cocoaMqtt: CocoaMQTT?
    var didConnectAck = false
    var hostAddress = "tracking.tookan.io"//"dev.tracking.tookan.io"////"test.mosquitto.org"//
    var portNumber:UInt16 = 1883
    //var accessToken = ""
  //  var key = ""
    var topic = ""
    var connectVar = false
    
    override init() {
        let clientID = "CocoaMQTT-" + String(ProcessInfo().processIdentifier)
        cocoaMqtt = CocoaMQTT(clientId: clientID, host: hostAddress, port: portNumber)
    }
    
    func connectToServer() {
        _ = cocoaMqtt!.connect()
        self.connectVar = true
    }
    
    func mqttSetting() {
        if let mqtt = cocoaMqtt {
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
                var sendData : [String:Any] = ["location":"\(location)"]
                sendData["origin"] = SERVER_KEY
                print("Send Data = \(sendData)")
                var sendDataArray = [Any]()
                sendDataArray.append(sendData)
                //mqttObject?.publish(topic: "UpdateLocation", withString: sendDataArray.jsonString, qos: .qos1, retained: false, dup: false)
                _ = cocoaMqtt!.publish(topic: self.topic, withString:sendDataArray.jsonString , qos: .QOS2)
                
               // mqttObject?.willMessage = CocoaMQTTWill(topic: self.topic, message: sendDataArray.jsonString)
            } else {
                if(cocoaMqtt?.connState == CocoaMQTTConnState.DISCONNECTED) {
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
        cocoaMqtt!.disconnect()
    }
    
    func subscribeLocation() {
        print(self.topic)
        if IJReachability.isConnectedToNetwork() == true {
            if(didConnectAck == true) {
                UserDefaults.standard.set(true, forKey: USER_DEFAULT.isHitInProgress)
                UIApplication.shared.isNetworkActivityIndicatorVisible = true
                _ = cocoaMqtt?.subscribe(topic: self.topic, qos: CocoaMQTTQOS.QOS2)
            } else {
                if(cocoaMqtt?.connState == CocoaMQTTConnState.DISCONNECTED) {
                    self.mqttSetting()
                    self.connectToServer()
                }
            }
        }
    }
    
    func unsubscribeLocation() {
        _ = cocoaMqtt?.unsubscribe(topic: self.topic)
    }
}

extension MqttClass: CocoaMQTTDelegate {
    public func mqttDidDisconnect(_ mqtt: CocoaMQTT, withError err: NSError?) {
        didConnectAck = false
        _console("mqttDidDisconnect")
        print(err?.localizedDescription ?? "error")
        if UserDefaults.standard.bool(forKey: "subscribeLocation") == true {
            if(mqtt.connState == CocoaMQTTConnState.DISCONNECTED) {
                self.mqttSetting()
                self.connectToServer()

            }
        }
    }
    
    
    public func mqtt(_ mqtt: CocoaMQTT, didConnect host: String, port: Int) {
        print("didConnect \(host):\(port)")
    }
    
    public func mqtt(_ mqtt: CocoaMQTT, didConnectAck ack: CocoaMQTTConnAck) {
        _ = mqtt.subscribe(topic: self.topic)
 }

    
    public func mqtt(_ mqtt: CocoaMQTT, didPublishMessage message: CocoaMQTTMessage, id: UInt16) {

    }
    
    public func mqtt(_ mqtt: CocoaMQTT, didPublishAck id: UInt16) {
        print("didPublishAck with id: \(id)")
        UserDefaults.standard.set(false, forKey: USER_DEFAULT.isHitInProgress)
    }

    
    public func mqtt(_ mqtt: CocoaMQTT, didReceiveMessage message: CocoaMQTTMessage, id: UInt16 ) {
        
        var locationDictionary1 = [[String:Any]]()
        if message.string != "NaN"{
        locationDictionary1 = message.string!.parseJSONString as! [[String : Any]]
        let locationDictionary = locationDictionary1[0] 
        print(locationDictionary)
        var dictProfileInfo: [String: Any]?
        if let jobArray = (locationDictionary["resp_obj"] as? [[String: Any]]){
            print("jobArray -- >>>")
            var jobData = Jobs()
            for i in (0..<jobArray.count){
                jobData = Jobs(json: jobArray[i] )
                 dictProfileInfo = ["data": jobData] as? [String: Any]
//                if let image = jobData["fleet_image"] as? String {
//                    jobData.fleetImage = image
//                }
                
            }
            NotificationCenter.default.post(name: Foundation.Notification.Name(rawValue: OBSERVER.updateJobData), object: nil,userInfo: dictProfileInfo)
        }
        if let locationArray = (locationDictionary["location"] as? [[String: Any]]){
         for i in (0..<locationArray.count) {
                
                
                let locationData = locationArray[i] as! [String:Any]

                /*------- For Updating Path ------------*/
                var locationDictionary = [String:Any]()
                var updatingLocationArray = [Any]()
                var latitudeString:Double?
                var longitudeString:Double?
            var bearingString:String?
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
            if let bearing = locationData["bearing"] as? NSNumber{
                bearingString = "\(bearing)"
            }else if let bearing = locationData["bearing"] as? String{
                bearingString = bearing
            }
                if latitudeString != nil && longitudeString != nil  {
                    let coordinate = CLLocationCoordinate2D(latitude: latitudeString!, longitude: longitudeString!)
                    locationDictionary = [
                        "Latitude":coordinate.latitude,
                        "Longitude":coordinate.longitude,
                        "bearing":bearingString ?? ""
                    ]
                    if let array = UserDefaults.standard.value(forKey: USER_DEFAULT.updatingLocationPathArray) as? [Any] {
                        updatingLocationArray = array
                    }
                    updatingLocationArray.append(locationDictionary)
                    UserDefaults.standard.setValue(updatingLocationArray, forKey: USER_DEFAULT.updatingLocationPathArray)
                }
            }
            NotificationCenter.default.post(name: Foundation.Notification.Name(rawValue: OBSERVER.updatePath), object: nil)
        }
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
    
    public func mqttDidDisconnect(_ mqtt: CocoaMQTT, withError err: Error?) {
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

extension String
{
var parseJSONString: AnyObject?
{
    let data = self.data(using: String.Encoding.utf8, allowLossyConversion: false)
    if let jsonData = data {
        do {
            let message = try JSONSerialization.jsonObject(with: jsonData, options:.mutableContainers)
            if let jsonResult = message as? NSMutableArray {
                return jsonResult //Will return the json array output
            } else if let jsonResult = message as? NSMutableDictionary {
                return jsonResult //Will return the json dictionary output
            } else {
                return nil
            }
        } catch let error as NSError {
            print("An error occurred: \(error)")
            return nil
        }
    } else {
        return nil
    }
}
}

