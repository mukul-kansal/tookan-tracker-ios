//
//  Networking Helper.swift
//  Tookan
//
//  Created by Click Labs on 7/7/15.
//  Copyright (c) 2015 Click Labs. All rights reserved.
//

import Foundation
import CoreLocation
import UIKit
import GoogleMaps
import GooglePlaces

class NetworkingHelper: NSObject {
    
    
    //    "api_key":"e740d9d626c69da995bb80c0415c6179",
    //    "unique_user_id":"00000001",
    //    "lat":23,
    //    "lng":32,
    //    "unique_session_id":"e23e"
    //
    //
    //    "http://tracking.tookan.io:3008/create_session"
    static let sharedInstance = NetworkingHelper()
    var requestId:String = ""
    var sessionId:String = ""
    var sessionURL:String = ""
    var requestRole = -1
    /*------------ Share and Stop Tracking ---------------*/
    func shareLocationSession(api_key:String, unique_user_id:String, lat:String, lng:String, sessionId:String, receivedResponse:@escaping (_ succeeded:Bool, _ response:[String:Any]) -> ()) {
        var params: [String : Any] = ["api_key":api_key]
        params["unique_user_id"] = unique_user_id
        params["lat"] = lat
        params["lng"] = lng
        params["unique_session_id"] = sessionId
        
        //            "request_type":requestType, // 1 for start sesstion, 0 for stop session
        //            "session_id":"",
        //            "request_id":requestID,
        //            "email": emailId]
        NSLog("Params = %@", params)
        if IJReachability.isConnectedToNetwork() == true {
            sendRequestToServer("start_sharing", params: params as [String : AnyObject], httpMethod: "POST") { (succeeded:Bool, response:[String:Any]) -> () in
                print(response)
                if(succeeded){
                    NetworkingHelper.sharedInstance.requestId = ""
                    switch(response["status"] as! Int) {
                    case STATUS_CODES.SHOW_DATA, STATUS_CODES.INVALID_ACCESS_TOKEN:
                        DispatchQueue.main.async(execute: { () -> Void in
                            receivedResponse(true, response)
                        })
                        break
                        
                    case STATUS_CODES.SHOW_MESSAGE:
                        Auxillary.showAlert(response["message"] as? String ?? "")
                        receivedResponse(false, [:])
                        break
                        
                    default:
                        Auxillary.showAlert(response["message"] as? String ?? "")
                        receivedResponse(false, [:])
                    }
                } else {
                    Auxillary.showAlert(STATUS_CODES.SERVER_NOT_RESPONDING)
                    receivedResponse(false, [:])
                }
            }
        } else {
            Auxillary.showAlert(STATUS_CODES.NO_INTERNET_CONNECTION)
            receivedResponse(false, [:])
        }
    }
    /*------------ Start Tracking Acoording To Related Job ---------------*/
    func getLocationForJobTracking(sharedSecert:String, jobId:String,userId:String, receivedResponse:@escaping (_ succeeded:Bool, _ response:[String:Any]) -> ()){
        
        let params = ["shared_secret":sharedSecert,
                      "job_id":jobId,
                      "user_id":userId,
                      "request_type":"1",
                      "fleet_tracking":"1"]
        print(params)
        if IJReachability.isConnectedToNetwork() == true{
            sendRequestToServer("create_sdk_tracking_session",params: params as [String : AnyObject], httpMethod: "POST") { (succeeded:Bool, response:[String:Any]) -> () in
               if(succeeded) {
                    switch(response["status"] as! Int) {
                    case STATUS_CODES.SHOW_DATA, STATUS_CODES.INVALID_ACCESS_TOKEN:
                        DispatchQueue.main.async(execute: { () -> Void in
                            receivedResponse(true, response)
                        })
                        break
                        
                    case STATUS_CODES.SHOW_MESSAGE:
                        Auxillary.showAlert(response["message"] as? String ?? "")
                        receivedResponse(false, [:])
                        break
                        
                    default:
                        Auxillary.showAlert(response["message"] as? String ?? "")
                        receivedResponse(false, [:])
                    }
                } else{
                    Auxillary.showAlert(STATUS_CODES.SERVER_NOT_RESPONDING)
                    receivedResponse(false, [:])
                }
                
            }
        } else{
            Auxillary.showAlert(STATUS_CODES.NO_INTERNET_CONNECTION)
            receivedResponse(false, [:])
        }
    }
    /*------------ Start Tracking Acoording To Related Job ---------------*/
    func getLocationRelatedToAgent(sharedSecert:String, fleetId:String,userId:String, receivedResponse:@escaping (_ succeeded:Bool, _ response:[String:Any]) -> ()) {
        let params = ["shared_secret":sharedSecert,
                      "fleet_id":fleetId,
                      "user_id":userId,
                      "request_type":"1"]
        print(params)
        if IJReachability.isConnectedToNetwork() == true{
            sendRequestToServer("sdk_track_agent", params: params as [String : AnyObject], httpMethod: "POST") { (succeeded:Bool, response:[String:Any]) -> () in
                print(response)
                if(succeeded){
                    switch (response["status"] as! Int) {
                    case STATUS_CODES.SHOW_DATA, STATUS_CODES.INVALID_ACCESS_TOKEN:
                        DispatchQueue.main.async(execute: { () -> Void in
                            receivedResponse(true, response)
                        })
                        break
                        
                    case STATUS_CODES.SHOW_MESSAGE:
                        Auxillary.showAlert(response["message"] as? String ?? "")
                        receivedResponse(false, [:])
                        break
                        
                    default:
                        Auxillary.showAlert(response["message"] as? String ?? "")
                        receivedResponse(false, [:])
                    }
                } else {
                    Auxillary.showAlert(STATUS_CODES.SERVER_NOT_RESPONDING)
                    receivedResponse(false, [:])
                }
            }
        }else{
            Auxillary.showAlert(STATUS_CODES.NO_INTERNET_CONNECTION)
        }
    }
       func fetchPathPoints(_ from: CLLocationCoordinate2D, to: CLLocationCoordinate2D, completion: @escaping ((NSDictionary?) -> Void)) -> () {
           let session = URLSession.shared
           let urlString = GoogleMapsUtils.getDirectionUrl(from, to: to)///"https://maps.googleapis.com/maps/api/directions/json?origin=\(from.latitude),\(from.longitude)&destination=\(to.latitude),\(to.longitude)&mode=driving&key=\(APIKeyForGoogleMaps)"
           
           guard let url = URL(string: urlString) else {
               return
           }
           
           UIApplication.shared.isNetworkActivityIndicatorVisible = true
           
           session.dataTask(with: url) {data, response, error in
               var encodedRoute: NSDictionary?
               if(data != nil) {
                   do {
                       let json = try JSONSerialization.jsonObject(with: data!, options:[]) as? [String:AnyObject]
                       if let jsonData = json {
                           encodedRoute = jsonData as NSDictionary
                       }
                   } catch {
                       print("Error")
                   }
               }
               DispatchQueue.main.async {
                   if(encodedRoute != nil) {
                       completion(encodedRoute)
                   } else {
                       completion([:])
                   }
               }
               }.resume()
       }

    /*------------ Start Tracking ---------------*/
    func getLocationForStartTracking(_ sessionId:String, receivedResponse:@escaping (_ succeeded:Bool, _ response:[String:Any]) -> ()) {
        let params = [
            "session_id":sessionId]
        NSLog("Params = %@", params)
        
        if IJReachability.isConnectedToNetwork() == true {
            sendRequestToServer("track_session", params: params as [String : AnyObject], httpMethod: "POST") { (succeeded:Bool, response:[String:Any]) -> () in
                print(response)
                if(succeeded){
                    switch(response["status"] as! Int) {
                    case STATUS_CODES.SHOW_DATA, STATUS_CODES.INVALID_ACCESS_TOKEN:
                        DispatchQueue.main.async(execute: { () -> Void in
                            receivedResponse(true, response)
                        })
                        break
                        
                    case STATUS_CODES.SHOW_MESSAGE:
                        Auxillary.showAlert(response["message"] as? String ?? "")
                        receivedResponse(false, [:])
                        break
                        
                    default:
                        Auxillary.showAlert(response["message"] as? String ?? "")
                        receivedResponse(false, [:])
                    }
                } else {
                    Auxillary.showAlert(STATUS_CODES.SERVER_NOT_RESPONDING)
                    receivedResponse(false, [:])
                }
            }
        } else {
            Auxillary.showAlert(STATUS_CODES.NO_INTERNET_CONNECTION)
            receivedResponse(false, [:])
        }
    }
    
    
    /*------------ Request Tracking ---------------*/
    func requestForTracking(_ name:String, receivedResponse:@escaping (_ succeeded:Bool, _ response:[String:Any]) -> ()) {
        let params = [
            "device_token":UserDefaults.standard.object(forKey: USER_DEFAULT.deviceToken) != nil ? (UserDefaults.standard.object(forKey: USER_DEFAULT.deviceToken) as? String)! : "deviceToken",
            "device_type":1,
            "name":name,
            "device_id":UserDefaults.standard.object(forKey: USER_DEFAULT.deviceToken) != nil ? (UserDefaults.standard.object(forKey: USER_DEFAULT.deviceToken) as? String)! : "deviceToken"] as [String : Any]
        NSLog("Params = %@", params)
        
        if IJReachability.isConnectedToNetwork() == true {
            sendRequestToServer("request_location", params: params as [String : AnyObject], httpMethod: "POST") { (succeeded:Bool, response:[String:Any]) -> () in
                print(response)
                if(succeeded){
                    switch(response["status"] as! Int) {
                    case STATUS_CODES.SHOW_DATA, STATUS_CODES.INVALID_ACCESS_TOKEN:
                        DispatchQueue.main.async(execute: { () -> Void in
                            receivedResponse(true, response)
                        })
                        break
                        
                    case STATUS_CODES.SHOW_MESSAGE:
                        Auxillary.showAlert(response["message"] as? String ?? "")
                        receivedResponse(false, [:])
                        break
                        
                    default:
                        Auxillary.showAlert(response["message"] as? String ?? "")
                        receivedResponse(false, [:])
                    }
                } else {
                    Auxillary.showAlert(STATUS_CODES.SERVER_NOT_RESPONDING)
                    receivedResponse(false, [:])
                }
            }
        } else {
            Auxillary.showAlert(STATUS_CODES.NO_INTERNET_CONNECTION)
            receivedResponse(false, [:])
        }
    }
    
    
    /*------------ Validate Request ID ---------------*/
    func validateUserRequestId(_ requestID:String, receivedResponse:@escaping (_ succeeded:Bool, _ response:[String:Any]) -> ()) {
        let params = [
            "device_id":UserDefaults.standard.object(forKey: USER_DEFAULT.deviceToken) != nil ? (UserDefaults.standard.object(forKey: USER_DEFAULT.deviceToken) as? String)! : "deviceToken",
            "request_id":requestID] as [String : Any]
        
        NSLog("Params = %@", params)
        if IJReachability.isConnectedToNetwork() == true {
            sendRequestToServer("validate_request_id", params: params as [String : AnyObject], httpMethod: "POST") { (succeeded:Bool, response:[String:Any]) -> () in
                print(response)
                if(succeeded){
                    switch(response["status"] as! Int) {
                    case STATUS_CODES.SHOW_DATA, STATUS_CODES.INVALID_ACCESS_TOKEN:
                        DispatchQueue.main.async(execute: { () -> Void in
                            receivedResponse(true, response)
                        })
                        break
                        
                    case STATUS_CODES.SHOW_MESSAGE:
                        Auxillary.showAlert(response["message"] as? String ?? "")
                        receivedResponse(false, [:])
                        break
                        
                    default:
                        Auxillary.showAlert(response["message"] as? String ?? "")
                        receivedResponse(false, [:])
                    }
                } else {
                    Auxillary.showAlert(STATUS_CODES.SERVER_NOT_RESPONDING)
                    receivedResponse(false, [:])
                }
            }
        } else {
            Auxillary.showAlert(STATUS_CODES.NO_INTERNET_CONNECTION)
            receivedResponse(false, [:])
        }
    }
    
    func parsingLocations(locationArray:[Any]) {
        if locationArray.count > 0 {
            for i in (0..<locationArray.count) {
                if let locationData = locationArray[i] as? [String:Any] {
                    /*------- For Updating Path ------------*/
                    var locationDictionary = [String:Any]()
                    var updatingLocationArray = [Any]()
                    var latitudeString:Double?
                    var longitudeString:Double?
                    if let lat = locationData["lat"] as? NSNumber {
                        latitudeString = Double(truncating: lat)
                    } else if let lat = locationData["lat"] as? String {
                        latitudeString = Double(lat)
                    }
                    
                    if let long = locationData["lng"] as? NSNumber {
                        longitudeString = Double(truncating: long)
                    } else if let long = locationData["lng"] as? String {
                        longitudeString = Double(long)
                    }
                    if latitudeString != nil && longitudeString != nil  {
                        let coordinate = CLLocationCoordinate2D(latitude: latitudeString!, longitude: longitudeString!)
                        locationDictionary = [
                            "Latitude":coordinate.latitude,
                            "Longitude":coordinate.longitude
                        ]
                        if let array = UserDefaults.standard.value(forKey: USER_DEFAULT.updatingLocationPathArray) as? [Any] {
                            updatingLocationArray = array
                        }
                        updatingLocationArray.append(locationDictionary)
                        UserDefaults.standard.setValue(updatingLocationArray, forKey: USER_DEFAULT.updatingLocationPathArray)
                    }
                    /*----------------------------------------------*/
                }
                
            }
        }
//        NotificationCenter.default.post(name: Foundation.Notification.Name(rawValue: NOTIFICATION_OBSERVER.updatePath), object: nil)
    }
    func stopTracking(_ sessionID:String,userID: String, apiKey:String, receivedResponse:@escaping (_ succeeded:Bool, _ response:[String:Any]) -> ()){
        var params : [String : Any] = ["session_id": sessionID]
        params["unique_user_id"] = userID
        params["api_key"] = apiKey
        NSLog("logout = %@", params)
        if IJReachability.isConnectedToNetwork() == true {
            sendRequestToServer("stop_sharing", params: params as [String : AnyObject], httpMethod: "POST") { (succeeded:Bool, response:[String:Any]) -> () in
                print(response)
                if(succeeded){
                    switch(response["status"] as! Int) {
                    case STATUS_CODES.SHOW_DATA, STATUS_CODES.INVALID_ACCESS_TOKEN:
                        DispatchQueue.main.async(execute: { () -> Void in
                            receivedResponse(true, response)
                        })
                        break
                        
                    case STATUS_CODES.SHOW_MESSAGE:
                        Auxillary.showAlert(response["message"] as? String ?? "")
                        receivedResponse(false, [:])
                        break
                        
                    default:
                        Auxillary.showAlert(response["message"] as? String ?? "")
                        receivedResponse(false, [:])
                    }
                } else {
                    Auxillary.showAlert(STATUS_CODES.SERVER_NOT_RESPONDING)
                    receivedResponse(false, [:])
                }
            }
        } else {
            Auxillary.showAlert(STATUS_CODES.NO_INTERNET_CONNECTION)
            receivedResponse(false, [:])
        }
    }
    
    /*-------------------- Start Session with request ID ----------------------*/
    //    func createSessionWithRequestId(_ emailId:String, location:[Any],phone:String, requestType:Int, sessionId:String, receivedResponse:@escaping (_ succeeded:Bool, _ response:[String:Any]) -> ()) {
    //        let params = [
    //            "device_id":UserDefaults.standard.object(forKey: USER_DEFAULT.deviceToken) != nil ? (UserDefaults.standard.object(forKey: USER_DEFAULT.deviceToken) as? String)! : "deviceToken",
    //            "location":location,
    //            "phone":phone,
    //            "request_type":requestType, // 1 for start sesstion, 0 for stop session
    //            "session_id":sessionId,
    //            "email": emailId] as [String : Any]
    //        NSLog("Params = %@", params)
    //
    //        if IJReachability.isConnectedToNetwork() == true {
    //            sendRequestToServer("create_session", params: params as [String : AnyObject], httpMethod: "POST") { (succeeded:Bool, response:[String:Any]) -> () in
    //                print(response)
    //                if(succeeded){
    //                    switch(response["status"] as! Int) {
    //                    case STATUS_CODES.SHOW_DATA, STATUS_CODES.INVALID_ACCESS_TOKEN:
    //                        DispatchQueue.main.async(execute: { () -> Void in
    //                            receivedResponse(true, response)
    //                        })
    //                        break
    //
    //                    case STATUS_CODES.SHOW_MESSAGE:
    //                        Auxillary.showAlert(response["message"] as! String!)
    //                        receivedResponse(false, [:])
    //                        break
    //
    //                    default:
    //                        Auxillary.showAlert(response["message"] as! String!)
    //                        receivedResponse(false, [:])
    //                    }
    //                } else {
    //                    Auxillary.showAlert(STATUS_CODES.SERVER_NOT_RESPONDING)
    //                    receivedResponse(false, [:])
    //                }
    //            }
    //        } else {
    //            Auxillary.showAlert(STATUS_CODES.NO_INTERNET_CONNECTION)
    //            receivedResponse(false, [:])
    //        }
    //    }
    
    
    //    func checkSessionIdExist() -> (Bool,String) {
    //        if let sessionIDText = UserDefaults.standard.value(forKey: USER_DEFAULT.sessionId) {
    //            if UserDefaults.standard.bool(forKey: USER_DEFAULT.subscribeLocation) == true {
    //                Auxillary.showAlert("You are already on tracking. Please try again.")
    //                return (true,sessionIDText as! String)
    //            } else {
    //                return (false,sessionIDText as! String)
    //            }
    //        } else {
    //            return (false,"")
    //        }
    //    }
    
    
    func getLatLongFromDirectionAPI(_ origin:String, destination:String) -> [String:Any]! {
        var encodedRoute = [String:Any]()
        if IJReachability.isConnectedToNetwork() == true {
            let urlString = "https://maps.googleapis.com/maps/api/directions/json?origin=\(origin)&destination=\(destination)&sensor=false&mode=driving&alternatives=false"
            print(urlString)
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
            if let json = URLSession.requestSynchronousJSONWithURLString(urlString) {
                encodedRoute = json as! [String:Any]
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
            }
        } else {
            encodedRoute = [:]
        }
        return encodedRoute
    }
    
    func decodePolylineForCoordinates(_ encodedPolyline: String, precision: Double = 1e5) -> [CLLocation]! {
        let data = encodedPolyline.data(using: String.Encoding.utf8)!
        let byteArray = unsafeBitCast((data as NSData).bytes, to: UnsafePointer<Int8>.self)
        let length = Int(data.count)
        var position = Int(0)
        
        var decodedCoordinates = [CLLocation]()
        
        var lat = 0.0
        var lon = 0.0
        
        while position < length {
            
            do {
                let resultingLat = try decodeSingleCoordinate(byteArray: byteArray, length: length, position: &position, precision: precision)
                lat += resultingLat
                
                let resultingLon = try decodeSingleCoordinate(byteArray: byteArray, length: length, position: &position, precision: precision)
                lon += resultingLon
            } catch {
                return nil
            }
            let location = CLLocation(latitude: lat, longitude: lon)
            decodedCoordinates.append(location)
        }
        
        return decodedCoordinates
    }
    
    
    fileprivate func decodeSingleCoordinate(byteArray: UnsafePointer<Int8>, length: Int, position: inout Int, precision: Double = 1e6) throws -> Double {
        
        guard position < length else { throw PolylineError.singleCoordinateDecodingError }
        
        let bitMask = Int8(0x1F)
        
        var coordinate: Int32 = 0
        
        var currentChar: Int8
        var componentCounter: Int32 = 0
        var component: Int32 = 0
        
        repeat {
            currentChar = byteArray[position] - 63
            component = Int32(currentChar & bitMask)
            coordinate |= (component << (5*componentCounter))
            position += 1
            componentCounter += 1
        } while ((currentChar & 0x20) == 0x20) && (position < length) && (componentCounter < 6)
        
        if (componentCounter == 6) && ((currentChar & 0x20) == 0x20) {
            throw PolylineError.singleCoordinateDecodingError
        }
        
        if (coordinate & 0x01) == 0x01 {
            coordinate = ~(coordinate >> 1)
        } else {
            coordinate = coordinate >> 1
        }
        
        return Double(coordinate) / precision
    }
    
    enum PolylineError: Error {
        case singleCoordinateDecodingError
        case chunkExtractingError
    }
    
    func setMarker(_ originCoordinate: CLLocationCoordinate2D, destinationCoordinate: CLLocationCoordinate2D, minOrigin:CGFloat,googleMapView: GMSMapView){
        googleMapView.padding = UIEdgeInsets.init(top: 0, left: 0, bottom: 0, right: 0)
        let destinationLocationMarker = GMSMarker(position: destinationCoordinate)
//        destinationLocationMarker.icon = #imageLiteral(resourceName: "selectedIcon").withRenderingMode(.alwaysTemplate)//self.jobModel.getSelectedMarker(jobStatus: Singleton.sharedInstance.selectedTaskDetails.jobStatus)
        destinationLocationMarker.map = googleMapView
        
        
        let northEastCoordinate = CLLocationCoordinate2D(latitude: max(originCoordinate.latitude, destinationCoordinate.latitude), longitude: max(originCoordinate.longitude, destinationCoordinate.longitude))
        let southWestCoordinate = CLLocationCoordinate2D(latitude: min(originCoordinate.latitude, destinationCoordinate.latitude), longitude: min(originCoordinate.longitude, destinationCoordinate.longitude))
        
        _ = GMSCameraPosition(target: CLLocationCoordinate2D(latitude: (northEastCoordinate.latitude + southWestCoordinate.latitude)/2, longitude: (northEastCoordinate.longitude + southWestCoordinate.longitude)/2), zoom: 12, bearing: 0, viewingAngle: 0)
        
        //        googleMapView.animateToCameraPosition(cameraPosition)
        
        let bounds = GMSCoordinateBounds(coordinate: originCoordinate, coordinate: destinationCoordinate)
        let update = GMSCameraUpdate.fit(bounds, with: UIEdgeInsets.init(top: 0, left: 20, bottom: minOrigin, right: 20))
        googleMapView.moveCamera(update)
    }
    
    func drawPath(_ encodedPathString: String, originCoordinate:CLLocationCoordinate2D, destinationCoordinate:CLLocationCoordinate2D, minOrigin:CGFloat, googleMapView: GMSMapView) -> Void{
        DispatchQueue.main.async {
            guard UIApplication.shared.applicationState == UIApplication.State.active else {
                return
            }
         //   self.googleMapView.clear()
            CATransaction.begin()
            CATransaction.setValue(NSNumber(value: 1), forKey: kCATransactionAnimationDuration)
            let path = GMSPath(fromEncodedPath: encodedPathString)
            let line = GMSPolyline(path: path)
            line.strokeWidth = 4.0
            line.strokeColor = UIColor(red: 70/255, green: 149/255, blue: 246/255, alpha: 1.0)
            line.isTappable = true
            line.map = googleMapView
            self.setMarker(originCoordinate, destinationCoordinate: destinationCoordinate, minOrigin: minOrigin,googleMapView:googleMapView)
            // change the camera, set the zoom, whatever.  Just make sure to call the animate* method.
            googleMapView.animate(toViewingAngle: 45)
            CATransaction.commit()
        }
    }
    
    func getPath(coordinate: CLLocationCoordinate2D, destinationCoordinate: CLLocationCoordinate2D, completionHander:@escaping (String,[String : AnyObject]) -> Void, mapview: GMSMapView) {
        NetworkingHelper.sharedInstance.fetchPathPoints((coordinate), to: destinationCoordinate ) { (optionalRoute) in


            if let jsonRoutes = optionalRoute,
                let routes = jsonRoutes["routes"] as? NSArray{
                if routes.count > 0 {
                    if let shortestRoute = routes[0] as? [String: AnyObject],
                        let legs = shortestRoute["legs"] as? Array<[String: AnyObject]>,
                        let durationDict = legs[0]["duration"] as? [String: AnyObject],
                        let distanceDict = legs[0]["distance"] as? [String: AnyObject],
                        let distance = distanceDict["value"] as? NSNumber,
                        let polyline = shortestRoute["overview_polyline"] as? [String: String],
                        let points = polyline["points"]
                        , distance.doubleValue >= 0 {
                        completionHander(points,durationDict)
                      //  self.drawPath(points, originCoordinate:(originCoordinate?.coordinate)!, destinationCoordinate:destinationCoordinate!, minOrigin:0.5 + 20)
                    }
                } else{
                   // self.setMarker((originCoordinate?.coordinate)!, destinationCoordinate: destinationCoordinate ?? CLLocationCoordinate2D(), minOrigin:0.5 + 20)
                }
            } else {
                // check
                self.setMapview(googleMapView: mapview, coordinate: coordinate, destinationCoordinate: destinationCoordinate)
            }
        }
    }
    
    func setMapview(googleMapView: GMSMapView, coordinate: CLLocationCoordinate2D, destinationCoordinate: CLLocationCoordinate2D) {
        DispatchQueue.main.async {
            guard UIApplication.shared.applicationState == UIApplication.State.active else {
                return
            }
            googleMapView.padding = UIEdgeInsets.init(top: 0, left: 0, bottom: 0, right: 0)
            CATransaction.begin()
            CATransaction.setValue(NSNumber(value: 1), forKey: kCATransactionAnimationDuration)
            let bounds = GMSCoordinateBounds(coordinate: (coordinate), coordinate: destinationCoordinate ?? CLLocationCoordinate2D())
            let update = GMSCameraUpdate.fit(bounds, with: UIEdgeInsets.init(top: 40, left: 20, bottom: 0.5 + 20, right: 20))
            googleMapView.moveCamera(update)
            //googleMapView.padding = UIEdgeInsetsMake(0, 0, 0, 0)
            googleMapView.animate(toViewingAngle: 45)
            CATransaction.commit()
        }
    }
    
}

