//
//  HomeController.swift
//  Tracker
//
//  Created by cl-macmini-45 on 29/09/16.
//  Copyright © 2016 clicklabs. All rights reserved.
//

import UIKit
import GoogleMaps
import GooglePlaces


class HomeController: UIViewController, LocationTrackerDelegate {
    
    @IBOutlet var callButton: UIButton!
    @IBOutlet var licenceNumber: UILabel!
    @IBOutlet var driverName: UILabel!
    @IBOutlet var detailView: UIView!
    @IBOutlet var profileImage: UIImageView!
    @IBOutlet var viewETASelection: UIView!
    @IBOutlet var btnCloseETA: UIButton!
    @IBOutlet var btnForMap: UIButton!
    @IBOutlet var btnForEta: UIButton!
    @IBOutlet var selectionView: UIView!
    @IBOutlet var lblETAValue: UILabel!
    @IBOutlet var viewETA: UIView!
    @IBOutlet weak var googleMapView: GMSMapView!
    @IBOutlet var currentLocation: UIButton!
    @IBOutlet var logout: UIButton!
    @IBOutlet var stopTrackingButton: UIButton!
    var userStatus = USER_JOB_STATUS.free
    var getLocationTimer:Timer!
    var path = GMSMutablePath()
    let loc = LocationTrackerFile.sharedInstance()
    let model = TrackerModel()
    var viewShowStatus:Int!
    var mapCurrentZoomLevel:Float = 16
    var searchMarker:GMSMarker? = GMSMarker()
    var pathMarker = GMSMarker()
    var currentCameraPosition: GMSCameraPosition!
    var moving = true
    var trackingDelegate:TrackingDelegate!
    var isTrackingEnabled = true
    var myCurrentLocation:CLLocation!
    var jobModel: JobModel?
    var jobData: Jobs?
    var getETA: ((String)->Void)?
    var etaDict: String = ""
    var currentMarker:GMSMarker? = GMSMarker()
    var startingPointMarker:GMSMarker? = GMSMarker()
    var endPointMarker:GMSMarker? = GMSMarker()
    var contactNumber: String = ""
    let apiKey = "546b6480f1075f02431774714310214114e7ccf22ad87d3b581d"
    var latlngArray = [CLLocationCoordinate2D]()
    var polylineArray = [GMSPolyline]()
    var markers = [GMSMarker]()
    var mapPolyline = GMSPolyline()
    override var preferredStatusBarStyle:UIStatusBarStyle {
        if #available(iOS 13.0, *) {
            return .darkContent
        } else {
            return .lightContent
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        /*----------------- Location Tracker --------------*/
        self.viewETA.isHidden = true
        self.selectionView.isHidden = false

        
        self.loc.delegate = self

        self.loc.registerAllRequiredInitilazers()
        self.loc.sessionId = self.jobModel?.sessionId ?? ""

        self.currentLocation.setImage(getCurrentLocation?.withRenderingMode(.alwaysTemplate), for: .normal)
        self.currentLocation.tintColor = UIColor.white
        
        /*----------------- Google Map ---------------*/
        
        if let styleURL = frameworkBundle?.url(forResource: "style", withExtension: "json") {
            do {
                // Set the map style by passing the URL of the local file.
                self.googleMapView.mapStyle = try GMSMapStyle(contentsOfFileURL: styleURL)
            } catch {
                NSLog("The style definition could not be loaded: \(error)")
            }
        } else {
            NSLog("Unable to find style.json")
        }
        self.googleMapView.delegate = self
        
        
        
        /*--------------- Set User Status ----------------*/
        if model.isSessionIdExist() == true {
            if model.isTrackingLocation() == true {
                userStatus = USER_JOB_STATUS.trackingLocation
            } else {
                userStatus = USER_JOB_STATUS.sharingLocation
            }
        } else {
            userStatus = USER_JOB_STATUS.free
        }
        /*-------------------------------------------------*/
        self.setUserCurrentJob()
        self.setTrackingButton()
        self.sliderShareAction()
        if TookanTracker.shared.jobArrayCount > 1{
            for i in (0..<TookanTracker.shared.jobArrayCount){
                if TookanTracker.shared.jobArray[i].jobId == TookanTracker.shared.jobID{
                    if self.jobData?.jobPickupLat != "" {
                        print("yea \(i)")
                        switch TookanTracker.shared.jobArray[i].jobStatus{
                        case JOB_STATUS.started, JOB_STATUS.arrived:
                            self.drawPathFromCurrentToDestination()
                            break
                        default:
                            self.setMarkerForJob(self.getLatitudeLongitudeOf() ?? CLLocationCoordinate2D(), destinationCoordinate: self.getLatitudeLongitudeOfDest() ?? CLLocationCoordinate2D(), minOrigin: 0.5 + 20)
                            break
                        }
                    }
                    
                }
            }
        }
        else{
            if self.jobData?.jobPickupLat != "" {
                switch self.jobData?.jobStatus{
                case JOB_STATUS.started, JOB_STATUS.arrived:
                    self.drawPathFromCurrentToDestination()
                    break
                default:
                    self.setMarkerForJob(self.getLatitudeLongitudeOf() ?? CLLocationCoordinate2D(), destinationCoordinate: self.getLatitudeLongitudeOfDest() ?? CLLocationCoordinate2D(), minOrigin: 0.5 + 20)
                    break
                }
            }
        }
        
         /*--------------- Set Driver Detail ----------------*/

        let imageString = self.jobData?.fleetThumbImage
        if let image = getImage(from: imageString ?? ""){
        self.profileImage.image =  image
        }
        self.profileImage.layer.cornerRadius = 20
        self.callButton.layer.cornerRadius = 22
        self.driverName.text = self.jobData?.fleetName
        self.licenceNumber.text = self.jobData?.licenseNumber
        self.contactNumber = "\(self.jobData?.fleetPhone ?? "")"
        /*-------------------------------------------------*/
        
        
    }
    
    func getImage(from string: String) -> UIImage? {
        //2. Get valid URL
        guard let url = URL(string: string)
            else {
                print("Unable to create URL")
                return nil
        }

        var image: UIImage? = nil
        do {
            //3. Get valid data
            let data = try Data(contentsOf: url, options: [])

            //4. Make image
            image = UIImage(data: data)
        }
        catch {
            print(error.localizedDescription)
        }

        return image
    }
    func  getLatitudeLongitudeOf() -> CLLocationCoordinate2D?{
         var coordinate: CLLocationCoordinate2D!
        let latitudeString = jobData?.fleetLatitude ?? ""//jobModel?.jobLat as? String ?? ""
        let longitudeString = jobData?.fleetlongitude ?? ""//jobModel?.joblng as? String ?? ""
        coordinate = CLLocationCoordinate2D(latitude: Double(latitudeString) as! CLLocationDegrees, longitude: Double(longitudeString) as! CLLocationDegrees)
         return coordinate
     }
    func  getLatitudeLongitudeOfDest() -> CLLocationCoordinate2D?{
         var coordinate: CLLocationCoordinate2D!
        var latitudeString:String!
        var longitudeString:String!
        if TookanTracker.shared.jobArrayCount > 1{
            for i in (0..<TookanTracker.shared.jobArray.count){
                if TookanTracker.shared.jobArray[i].jobId == TookanTracker.shared.jobID{
                    if self.jobData?.jobPickupLat != "" {
                         latitudeString = TookanTracker.shared.jobArray[i].jobPickupLat
                         longitudeString = TookanTracker.shared.jobArray[i].jobPickupLng

                    }
                    
            }
            }
        }else{
             latitudeString = jobData?.jobPickupLat ?? ""
            longitudeString = jobData?.jobPickupLng ?? ""
        }
     
        coordinate = CLLocationCoordinate2D(latitude: Double(latitudeString) as! CLLocationDegrees, longitude: Double(longitudeString) as! CLLocationDegrees)
         return coordinate
     }
    func drawPath(_ encodedPathString: String, originCoordinate:CLLocationCoordinate2D, destinationCoordinate:CLLocationCoordinate2D, minOrigin:CGFloat, durationDict:[String : AnyObject]?,setBoundOnlyOnOrigin:Bool?) -> Void{
        DispatchQueue.main.async {
            guard UIApplication.shared.applicationState == UIApplication.State.active else {
                return
            }
//             self.googleMapView.clear()
            CATransaction.begin()
            CATransaction.setValue(NSNumber(value: 1), forKey: kCATransactionAnimationDuration)
            let path = GMSPath(fromEncodedPath: encodedPathString)
            switch self.jobData?.jobStatus{
            case JOB_STATUS.started, JOB_STATUS.arrived:
                self.mapPolyline.map=nil
                self.mapPolyline = GMSPolyline(path: path)
               self.mapPolyline.strokeWidth = 4.0
                self.mapPolyline.strokeColor = UIColor(red: 70/255, green: 149/255, blue: 246/255, alpha: 1.0)
                self.mapPolyline.geodesic = true
                self.mapPolyline.isTappable = true
               self.mapPolyline.map = self.googleMapView//mapPolyline
                break
            default:
                break
            }

           
            var bounds = GMSCoordinateBounds()
            if setBoundOnlyOnOrigin == true{
//                self.googleMapView.camera = GMSCameraPosition.camera(withTarget: originCoordinate, zoom: 15)
//                 self.googleMapView.animate(toLocation: originCoordinate)
            }else{
                bounds = GMSCoordinateBounds(coordinate: originCoordinate, coordinate: destinationCoordinate)
                let update = GMSCameraUpdate.fit(bounds, withPadding: CGFloat(40))
                self.googleMapView.moveCamera(update)
                let imageString = ""//"https://tookan.s3.amazonaws.com/fleet_thumb_profile/thumb-LvgR1581675711907-KCd31581675711258178198rng2w.jpg"
                if imageString != ""{
                    if let image = self.getImage(from: imageString ){
                        self.startingPointMarker?.icon = self.image(image, scaledToSize: CGSize(width: 22, height: 22))
                    }
                }else{
                    self.startingPointMarker?.icon = UIImage(named: "car", in: frameworkBundle, compatibleWith: nil)
                }
                self.startingPointMarker?.position = originCoordinate
                self.startingPointMarker?.map = self.googleMapView
            }
           
           
//            self.setMarker(originCoordinate, destinationCoordinate: destinationCoordinate, minOrigin: minOrigin,durationDict:durationDict)
            // change the camera, set the zoom, whatever.  Just make sure to call the animate* method.
            self.googleMapView.animate(toViewingAngle: 0)
            let imageString = ""
         if TookanTracker.shared.jobArrayCount > 1{
                     for i in (0..<TookanTracker.shared.jobArray.count){
//                         if TookanTracker.shared.jobArray[i].jobId == TookanTracker.shared.jobID{
                     switch TookanTracker.shared.jobArray[i].jobType {
                     case "0":
                          if imageString != ""{
                              if let image = self.getImage(from: imageString ){
                                  self.endPointMarker?.icon = self.image(image, scaledToSize: CGSize(width: 22, height: 22))
                              }
                          }else{
                               self.endPointMarker?.icon = UIImage(named: "arrived_pickup", in: frameworkBundle, compatibleWith: nil)
                          }

                         break
                     case "1":
                         if imageString != ""{
                             if let image = self.getImage(from: imageString ){
                                 self.endPointMarker?.icon = self.image(image, scaledToSize: CGSize(width: 22, height: 22))
                             }
                         }else{
                              self.endPointMarker?.icon = UIImage(named: "arrived_delivery", in: frameworkBundle, compatibleWith: nil)
                         }
                         break
                     case "2":
                          if imageString != ""{
                              if let image = self.getImage(from: imageString ){
                                  self.endPointMarker?.icon = self.image(image, scaledToSize: CGSize(width: 22, height: 22))
                              }
                          }else{
                               self.endPointMarker?.icon = UIImage(named: "arrived_appointment", in: frameworkBundle, compatibleWith: nil)
                          }
                         break
                     default:
                         break
                     }
                 }
                 
             }else{
                switch self.jobData?.jobType {
                case "0":
                    if imageString != ""{
                        if let image = self.getImage(from: imageString ){
                            self.endPointMarker?.icon = self.image(image, scaledToSize: CGSize(width: 22, height: 22))
                        }
                    }else{
                        self.endPointMarker?.icon = UIImage(named: "arrived_pickup", in: frameworkBundle, compatibleWith: nil)
                    }

                    break
                case "1":
                    if imageString != ""{
                        if let image = self.getImage(from: imageString ){
                            self.endPointMarker?.icon = self.image(image, scaledToSize: CGSize(width: 22, height: 22))
                        }
                    }else{
                        self.endPointMarker?.icon = UIImage(named: "arrived_delivery", in: frameworkBundle, compatibleWith: nil)
                    }
                    
                    break
                case "2":
                    if imageString != ""{
                        if let image = self.getImage(from: imageString ){
                            self.endPointMarker?.icon = self.image(image, scaledToSize: CGSize(width: 22, height: 22))
                        }
                    }else{
                        self.endPointMarker?.icon = UIImage(named: "arrived_appointment", in: frameworkBundle, compatibleWith: nil)
                    }
                    break
                default:
                    break
                }
             
            }
            


                       self.endPointMarker?.position = destinationCoordinate
                       
                       if durationDict != nil {
                           self.endPointMarker?.title = durationDict!["text"] as? String ?? ""
                       }
                       self.endPointMarker?.map = self.googleMapView
                       self.endPointMarker?.isFlat = true
                       self.googleMapView.selectedMarker = self.endPointMarker
            if durationDict != nil {
                let dict = "\(durationDict!["text"] as? String ?? "")"
                    self.etaDict = dict
                
            }
            
            if let eta = self.getETA {
                eta(self.etaDict)
            }
          if TookanTracker.shared.jobArrayCount > 1{
             self.setJobMarkers()
            }

            CATransaction.commit()
        }
    }
    func image(_ originalImage:UIImage, scaledToSize:CGSize) -> UIImage {
        if originalImage.size.equalTo(scaledToSize) {
            return originalImage
        }
        UIGraphicsBeginImageContextWithOptions(scaledToSize, false, 0.0)
        originalImage.draw(in: CGRect(x: 0, y: 0, width: scaledToSize.width, height: scaledToSize.height))
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image!
    }
    func setJobMarkers()
    {

             let first = 0
            let last = TookanTracker.shared.jobArray.count
             let interval = 1
             let sequence = stride(from: first, to: last, by: interval)
             for element in sequence {
                 let cateAryrray = TookanTracker.shared.jobArray[element]
                let mylatitude = Double(cateAryrray.jobPickupLat)
                let mylongitude = Double(cateAryrray.jobPickupLng)
                if TookanTracker.shared.jobArray[element].jobId != TookanTracker.shared.jobID{
                    let marker = GMSMarker()
                    marker.position =  CLLocationCoordinate2D.init(latitude: mylatitude!, longitude: mylongitude!)
                    switch cateAryrray.jobType {
                    case "0":
                         let imageString = "https://tookan.s3.amazonaws.com/fleet_thumb_profile/thumb-LvgR1581675711907-KCd31581675711258178198rng2w.jpg"
                         if imageString != nil{
                            if let image = self.getImage(from: imageString ){
                                marker.icon = self.image(image, scaledToSize: CGSize(width: 22, height: 22))
                            }
                         }else{
                            marker.icon = UIImage(named: "arrived_pickup", in: frameworkBundle, compatibleWith: nil)
                         }

                        break
                    case "1":
                        let imageString = "https://tookan.s3.amazonaws.com/company_images/UmTo1581675480321-178191bwgp7l.jpeg"
                        if imageString != nil{
                           if let image = self.getImage(from: imageString ){
                               marker.icon = self.image(image, scaledToSize: CGSize(width: 22, height: 22))
                           }
                        }else{
                           marker.icon = UIImage(named: "arrived_delivery", in: frameworkBundle, compatibleWith: nil)
                        }
                        break
                    case "2":
                         let imageString = "https://tookan.s3.amazonaws.com/company_images/UmTo1581675480321-178191bwgp7l.jpeg"
                         if imageString != nil{
                            if let image = self.getImage(from: imageString ){
                                marker.icon = self.image(image, scaledToSize: CGSize(width: 22, height: 22))
                            }
                         }else{
                            marker.icon = UIImage(named: "arrived_appointment", in: frameworkBundle, compatibleWith: nil)
                         }
                        break
                    default:
                        break
                    }
                    
                    marker.map = self.googleMapView
                }


                
          }
        

        
    }
      func drawPathFromCurrentToDestination() {
          let originCoordinate = self.getLatitudeLongitudeOf()
          let destinationCoordinate = self.getLatitudeLongitudeOfDest()

      }
    
    
    func setMarker(_ originCoordinate: CLLocationCoordinate2D, destinationCoordinate: CLLocationCoordinate2D, minOrigin:CGFloat,durationDict: [String:AnyObject]?){
         googleMapView.padding = UIEdgeInsets.init(top: 0, left: 0, bottom: 0, right: 0)
        let imageString = ""//"https://tookan.s3.amazonaws.com/fleet_thumb_profile/thumb-LvgR1581675711907-KCd31581675711258178198rng2w.jpg"
             if imageString != ""{
                 if let image = self.getImage(from: imageString ){
                     self.startingPointMarker?.icon = self.image(image, scaledToSize: CGSize(width: 22, height: 22))
                 }
             }else{
                 self.startingPointMarker?.icon = UIImage(named: "car", in: frameworkBundle, compatibleWith: nil)
             }
                      if TookanTracker.shared.jobArrayCount > 1{
                                  for i in (0..<TookanTracker.shared.jobArray.count){
             //                         if TookanTracker.shared.jobArray[i].jobId == TookanTracker.shared.jobID{
                                  switch TookanTracker.shared.jobArray[i].jobType {
                     case "0":
                          if imageString != ""{
                              if let image = self.getImage(from: imageString ){
                                  self.endPointMarker?.icon = self.image(image, scaledToSize: CGSize(width: 22, height: 22))
                              }
                          }else{
                               self.endPointMarker?.icon = UIImage(named: "arrived_pickup", in: frameworkBundle, compatibleWith: nil)
                          }

                         break
                     case "1":
                         if imageString != ""{
                             if let image = self.getImage(from: imageString ){
                                 self.endPointMarker?.icon = self.image(image, scaledToSize: CGSize(width: 22, height: 22))
                             }
                         }else{
                              self.endPointMarker?.icon = UIImage(named: "arrived_delivery", in: frameworkBundle, compatibleWith: nil)
                         }
                         break
                     case "2":
                          if imageString != ""{
                              if let image = self.getImage(from: imageString ){
                                  self.endPointMarker?.icon = self.image(image, scaledToSize: CGSize(width: 22, height: 22))
                              }
                          }else{
                               self.endPointMarker?.icon = UIImage(named: "arrived_appointment", in: frameworkBundle, compatibleWith: nil)
                          }
                         break
                     default:
                         break
                     }
                 }
                 
             }else{

             switch self.jobData?.jobType {
             case "0":
                 if imageString != ""{
                     if let image = self.getImage(from: imageString ){
                         self.endPointMarker?.icon = self.image(image, scaledToSize: CGSize(width: 22, height: 22))
                     }
                 }else{
                     self.endPointMarker?.icon = UIImage(named: "arrived_pickup", in: frameworkBundle, compatibleWith: nil)
                 }

                 break
             case "1":
                 if imageString != ""{
                     if let image = self.getImage(from: imageString ){
                         self.endPointMarker?.icon = self.image(image, scaledToSize: CGSize(width: 22, height: 22))
                     }
                 }else{
                     self.endPointMarker?.icon = UIImage(named: "arrived_delivery", in: frameworkBundle, compatibleWith: nil)
                 }
                 
                 break
             case "2":
                 if imageString != ""{
                     if let image = self.getImage(from: imageString ){
                         self.endPointMarker?.icon = self.image(image, scaledToSize: CGSize(width: 22, height: 22))
                     }
                 }else{
                     self.endPointMarker?.icon = UIImage(named: "arrived_appointment", in: frameworkBundle, compatibleWith: nil)
                 }
                 break
             default:
                 break
             }
        }
        self.startingPointMarker?.position = originCoordinate
        
        self.startingPointMarker?.map = self.googleMapView
        self.endPointMarker?.position = destinationCoordinate
        self.endPointMarker?.map = self.googleMapView
        if durationDict != nil {
            endPointMarker?.title = durationDict!["text"] as? String ?? ""
        }
        endPointMarker?.isFlat = true
        self.googleMapView.selectedMarker = endPointMarker
         let northEastCoordinate = CLLocationCoordinate2D(latitude: max(originCoordinate.latitude, destinationCoordinate.latitude), longitude: max(originCoordinate.longitude, destinationCoordinate.longitude))
         let southWestCoordinate = CLLocationCoordinate2D(latitude: min(originCoordinate.latitude, destinationCoordinate.latitude), longitude: min(originCoordinate.longitude, destinationCoordinate.longitude))
         
         _ = GMSCameraPosition(target: CLLocationCoordinate2D(latitude: (northEastCoordinate.latitude + southWestCoordinate.latitude)/2, longitude: (northEastCoordinate.longitude + southWestCoordinate.longitude)/2), zoom: 12, bearing: 0, viewingAngle: 0)
         
         
         let bounds = GMSCoordinateBounds(coordinate: originCoordinate, coordinate: destinationCoordinate)
         let update = GMSCameraUpdate.fit(bounds, withPadding: CGFloat(40))
         googleMapView.moveCamera(update)
     }
    
    func setMarkerForJob(_ originCoordinate: CLLocationCoordinate2D, destinationCoordinate: CLLocationCoordinate2D, minOrigin:CGFloat){
         googleMapView.padding = UIEdgeInsets.init(top: 0, left: 0, bottom: 0, right: 0)
          let imageString = ""
               if imageString != ""{
                   if let image = self.getImage(from: imageString ){
                       self.startingPointMarker?.icon = self.image(image, scaledToSize: CGSize(width: 22, height: 22))
                   }
               }else{
                   self.startingPointMarker?.icon = UIImage(named: "car", in: frameworkBundle, compatibleWith: nil)
               }
                    if TookanTracker.shared.jobArrayCount > 1{
                                 for i in (0..<TookanTracker.shared.jobArray.count){
            //                         if TookanTracker.shared.jobArray[i].jobId == TookanTracker.shared.jobID{
                                 switch TookanTracker.shared.jobArray[i].jobType {
                       case "0":
                            if imageString != ""{
                                if let image = self.getImage(from: imageString ){
                                    self.endPointMarker?.icon = self.image(image, scaledToSize: CGSize(width: 22, height: 22))
                                }
                            }else{
                                 self.endPointMarker?.icon = UIImage(named: "arrived_pickup", in: frameworkBundle, compatibleWith: nil)
                            }

                           break
                       case "1":
                           if imageString != ""{
                               if let image = self.getImage(from: imageString ){
                                   self.endPointMarker?.icon = self.image(image, scaledToSize: CGSize(width: 22, height: 22))
                               }
                           }else{
                                self.endPointMarker?.icon = UIImage(named: "arrived_delivery", in: frameworkBundle, compatibleWith: nil)
                           }
                           break
                       case "2":
                            if imageString != ""{
                                if let image = self.getImage(from: imageString ){
                                    self.endPointMarker?.icon = self.image(image, scaledToSize: CGSize(width: 22, height: 22))
                                }
                            }else{
                                 self.endPointMarker?.icon = UIImage(named: "arrived_appointment", in: frameworkBundle, compatibleWith: nil)
                            }
                           break
                       default:
                           break
                       }
                   }
                   
               }else{

                    switch self.jobData?.jobType {
                    case "0":
                        if imageString != ""{
                            if let image = self.getImage(from: imageString ){
                                self.endPointMarker?.icon = self.image(image, scaledToSize: CGSize(width: 22, height: 22))
                            }
                        }else{
                            self.endPointMarker?.icon = UIImage(named: "arrived_pickup", in: frameworkBundle, compatibleWith: nil)
                        }

                        break
                    case "1":
                        if imageString != ""{
                            if let image = self.getImage(from: imageString ){
                                self.endPointMarker?.icon = self.image(image, scaledToSize: CGSize(width: 22, height: 22))
                            }
                        }else{
                            self.endPointMarker?.icon = UIImage(named: "arrived_delivery", in: frameworkBundle, compatibleWith: nil)
                        }
                        
                        break
                    case "2":
                        if imageString != ""{
                            if let image = self.getImage(from: imageString ){
                                self.endPointMarker?.icon = self.image(image, scaledToSize: CGSize(width: 22, height: 22))
                            }
                        }else{
                            self.endPointMarker?.icon = UIImage(named: "arrived_appointment", in: frameworkBundle, compatibleWith: nil)
                        }
                        break
                    default:
                        break
                    }
               }

          self.startingPointMarker?.position = originCoordinate
          
          self.startingPointMarker?.map = self.googleMapView
          self.endPointMarker?.position = destinationCoordinate
          self.endPointMarker?.map = self.googleMapView
        endPointMarker?.isFlat = true
        self.googleMapView.selectedMarker = endPointMarker
         let northEastCoordinate = CLLocationCoordinate2D(latitude: max(originCoordinate.latitude, destinationCoordinate.latitude), longitude: max(originCoordinate.longitude, destinationCoordinate.longitude))
         let southWestCoordinate = CLLocationCoordinate2D(latitude: min(originCoordinate.latitude, destinationCoordinate.latitude), longitude: min(originCoordinate.longitude, destinationCoordinate.longitude))
         
         _ = GMSCameraPosition(target: CLLocationCoordinate2D(latitude: (northEastCoordinate.latitude + southWestCoordinate.latitude)/2, longitude: (northEastCoordinate.longitude + southWestCoordinate.longitude)/2), zoom: 12, bearing: 0, viewingAngle: 0)
         
         
         let bounds = GMSCoordinateBounds(coordinate: originCoordinate, coordinate: destinationCoordinate)
         let update = GMSCameraUpdate.fit(bounds, withPadding: CGFloat(40))
         googleMapView.moveCamera(update)
        if TookanTracker.shared.jobArrayCount > 1{
            self.setJobMarkers()
        }
     }
    
    func setTrackingButton() {
        self.stopTrackingButton.layer.cornerRadius = 5.0
        self.setTrackingTitle()
        self.stopTrackingButton.backgroundColor = UIColor(red: 70/255, green: 149/255, blue: 246/255, alpha: 1.0)
        self.stopTrackingButton.setTitleColor(UIColor.white, for: .normal)
    }
    
    func setTrackingTitle() {
        self.stopTrackingButton.setTitle("Stop Sharing Location", for: .normal)
        self.isTrackingEnabled = true
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        NotificationCenter.default.addObserver(self, selector: #selector(self.updatePath), name: NSNotification.Name(rawValue: OBSERVER.updatePath), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.requestIdReceivedFromURL), name: NSNotification.Name(rawValue: OBSERVER.requestIdURL), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.sessionIDRecivedFromPush), name: NSNotification.Name(rawValue: OBSERVER.sessionIdPush), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.startTrackingFromURL), name: NSNotification.Name(rawValue: OBSERVER.sessionIdURL), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.stopSharingOrTracking), name: NSNotification.Name(rawValue: OBSERVER.stopTracking), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.updateJobData), name: NSNotification.Name(rawValue: OBSERVER.updateJobData), object: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {


    }
    
    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: OBSERVER.updatePath), object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: OBSERVER.requestIdURL), object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: OBSERVER.sessionIdURL), object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: OBSERVER.stopTracking), object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: OBSERVER.sessionIdPush), object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: OBSERVER.updateJobData), object: nil)
    }
    
    @IBAction func logoutAction(_ sender: Any) {
        
        self.stopTrackingConformation(pop: true)
        
    }
    
    @IBAction func btnForETa(_ sender: Any) {
        self.viewETA.isHidden = false
        self.selectionView.isHidden = true
        self.lblETAValue.text = "ETA - \(etaDict)"

    }
    
    @IBAction func mapBtnAction(_ sender: Any) {
        self.viewETA.isHidden = true
        self.selectionView.isHidden = true
        viewETASelection.isHidden = true
    }
    @IBAction func stopTrackingAction(_ sender: Any) {
        

        self.stopTrackingConformation(pop: true)
    }
    
    
    func stopTrackingConformation(pop: Bool) {
        
        if pop == true {
            self.stopCalling(pop: pop)
        } else {
            if self.isTrackingEnabled == true {
                self.stopCalling(pop: pop)
            } else {
                self.stopTrackingButton.isHidden = true
                self.startTracking()
            }
            
        }
        
    }
    
    
    func stopCalling(pop: Bool) {
        let alertController = UIAlertController(title: nil, message: "Are you sure?", preferredStyle: UIAlertController.Style.actionSheet)
        let confirmAction = UIAlertAction(title: "Yes", style: UIAlertAction.Style.destructive) { (confirmed) -> Void in
            self.stopTrackingButton.isHidden = true
            self.dismissVC()
        }
        
        let cancelAction = UIAlertAction(title: "No", style: UIAlertAction.Style.cancel, handler: {(UIAlertAction) in
        })
        alertController.addAction(confirmAction)
        alertController.addAction(cancelAction)
        self.present(alertController, animated: true, completion: nil)
    }
    
    func startTracking() {
    
    }
    
    func stopTracking(pop: Bool) {
        
    }
    
    func dismissVC() {
        self.trackingDelegate.logout!()
        self.navigationController?.popToRootViewController(animated: true)
        UserDefaults.standard.removeObject(forKey: USER_DEFAULT.userId)
        UserDefaults.standard.removeObject(forKey: USER_DEFAULT.apiKey)
        UserDefaults.standard.removeObject(forKey: USER_DEFAULT.isLocationTrackingRunning)
    }
    
    //MARK: SET USER FLOW
    func setUserCurrentJob() {
        switch self.userStatus {
        case USER_JOB_STATUS.free:
            //            self.menuButton.isHidden = false
            //            self.myLocationButtontrailingConstraint.constant = 56
            //            self.menuButton.setImage(UIImage(named:"menu"), for: UIControlState.normal)
//            self.viewShowStatus = SHOW_HIDE.showBottomView
            //            self.setBottomButtonView(stopTitle: "", isSlider: true)
            break
        case USER_JOB_STATUS.sharingLocation:
            //            self.menuButton.isHidden = false
            //            self.myLocationButtontrailingConstraint.constant = 56
            //            self.menuButton.setImage(UIImage(named:"share"), for: UIControlState.normal)
            let response = loc.startLocationService()
            if(response.0 == true) {
                self.shareLocation()
//                self.viewShowStatus = SHOW_HIDE.showStopLocationButton
                //                self.setBottomButtonView(stopTitle: "", isSlider: true)
            } else {
                print(response.1)
                UIAlertView(title: "", message: response.1, delegate: self, cancelButtonTitle: "OK").show()
            }
            break
        case USER_JOB_STATUS.trackingLocation:
            //            self.menuButton.isHidden = true
            //            self.myLocationButtontrailingConstraint.constant = 11
            //            self.menuButton.setImage(UIImage(named:"menu"), for: UIControlState.normal)
            //            if let id = UserDefaults.standard.value(forKey: USER_DEFAULT.sessionId) as? String {
            //                self.startTracking(sessionId: id)
            //            }
            break
        default:
            break
        }
    }
    
    
    
    //MARK: SHARE LOCATION
    func shareLocation() {
        UserDefaults.standard.set(true, forKey: USER_DEFAULT.isLocationTrackingRunning)
        self.loc.topic = "\(globalAPIKey)\(globalUserId)" //UserDefaults.standard.value(forKey: USER_DEFAULT.sessionId) as! String
        self.loc.updateLocationToServer()
    }
    
    //MARK: START SESSION
    @objc func startSession() {
        let location = loc.getCurrentLocation()
        if  location != nil && location?.coordinate.latitude != 0.0 {
            self.resetLocationTimer()
            if let id = UserDefaults.standard.value(forKey: USER_DEFAULT.sessionId){
                self.startSessionHit(sessionId: id as! String, location: location!)
            }
        }
    }
    
    func startSessionHit(sessionId:String, location:CLLocation) {
        
        UserDefaults.standard.set(false, forKey: USER_DEFAULT.subscribeLocation)
        self.userStatus = USER_JOB_STATUS.sharingLocation
        self.shareLocation()
        
    }
    
    /*----------------------------------- REQUEST ID URL ---------------------------------*/
    //MARK: REQUEST ID FROM URL
    @objc func requestIdReceivedFromURL() {
        switch userStatus {
        case USER_JOB_STATUS.free:
            self.validateRequestId()
            break
        case USER_JOB_STATUS.sharingLocation:
            self.validateRequestId()
            break
        case USER_JOB_STATUS.trackingLocation:
            Auxillary.showAlert(ALERT_MESSAGE.ALREADY_TRACKING_LOCATION)
            break
        default:
            break
        }
    }
    
    func validateRequestId() {
    }
    
    func setFlowAfterValidationOfRequest() {
        switch userStatus {
        case USER_JOB_STATUS.free:
            break
        case USER_JOB_STATUS.sharingLocation:
            self.showAlertForSharingLocation()
            break
        case USER_JOB_STATUS.trackingLocation:
            break
        default:
            break
        }
    }
    
    func showAlertForSharingLocation() {
        let alert = UIAlertController(title: "", message: ALERT_MESSAGE.SHARE_LOCATION, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { (action) -> Void in
            self.shareLocationAfterConfirmation()
        }))
        alert.addAction(UIAlertAction(title: "No", style: .cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    func showAlertForTrackingOwnRequestedLocation() {
        let alert = UIAlertController(title: "", message: ALERT_MESSAGE.OWN_REQUEST_LINK, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { (action) -> Void in
        }))
        alert.addAction(UIAlertAction(title: "No", style: .cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    func shareLocationAfterConfirmation() {
        switch userStatus {
        case USER_JOB_STATUS.free:
            break
        case USER_JOB_STATUS.sharingLocation:
            break
        case USER_JOB_STATUS.trackingLocation:
            break
        default:
            break
        }
    }
    /*---------------------------------------------------------------------------------------*/
    
    /*----------------------------------- SESSION ID URL ---------------------------------*/
    //MARK: SESSION ID FROM URL
    @objc func startTrackingFromURL() {
        switch userStatus {
        case USER_JOB_STATUS.free:
            break
        case USER_JOB_STATUS.sharingLocation:
            Auxillary.showAlert(ALERT_MESSAGE.ALREADY_SHARING_LOCATION)
            break
        case USER_JOB_STATUS.trackingLocation:
            Auxillary.showAlert(ALERT_MESSAGE.ALREADY_TRACKING_FOR_TRACKING)
            break
        default:
            break
        }
    }
    
    /*---------------------------------- SESSION ID PUSH --------------------------------*/
    @objc func sessionIDRecivedFromPush() {
        let alert = UIAlertController(title: "", message: ALERT_MESSAGE.TRACKING_PUSH_ALERT, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { (action) -> Void in
            self.startTrackingFromURL()
        }))
        alert.addAction(UIAlertAction(title: "No", style: .cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    /*---------------------------------------------------------------------------------------*/
    
    //MARK: START TRACKING
    func startTracking(sessionId:String) {
    }
    

    @IBAction func tapCloseETA(_ sender: Any) {
        self.viewETA.isHidden = true
        self.selectionView.isHidden = false
    }
    
    func alertPopupForTracking() {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: UIAlertController.Style.actionSheet)
        let trackAction = UIAlertAction(title: "Track", style: UIAlertAction.Style.default) { (UIAlertAction) in
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertAction.Style.cancel, handler:nil)
        alertController.addAction(trackAction)
        alertController.addAction(cancelAction)
        self.present(alertController, animated: true, completion: nil)
    }
    
    //MARK: BUTTON ACTION
    @IBAction func menuAction(_ sender: AnyObject) {
        switch userStatus {
        case USER_JOB_STATUS.free:
            self.alertPopupForTracking()
            break
        case USER_JOB_STATUS.sharingLocation:
            if let sessionURL = UserDefaults.standard.value(forKey: USER_DEFAULT.sessionURL) as? String {
                UIView.animate(withDuration: 0.2, animations: {
                }, completion: nil)
                
                self.showActivityViewController(link: sessionURL)
            }
            break
        case USER_JOB_STATUS.trackingLocation:
            break
        default:
            break
        }
    }
    
    @IBAction func currentLocationAction(_ sender: Any) {
        
        let location = loc.getCurrentLocation() as CLLocation
        CATransaction.begin()
        CATransaction.setValue(NSNumber(value: 1), forKey: kCATransactionAnimationDuration)
        let camera = GMSCameraPosition.camera(withLatitude: location.coordinate.latitude, longitude: location.coordinate.longitude, zoom: 16)
        self.googleMapView.animate(to: camera)
        self.mapCurrentZoomLevel = self.googleMapView.camera.zoom
        CATransaction.commit()
        
        
    }
    
    
    @IBAction func searchAction(_ sender: AnyObject) {
        let acController = GMSAutocompleteViewController()
        acController.delegate = self
        acController.view.backgroundColor = UIColor.clear
        self.present(acController, animated: true, completion: nil)
    }
    
    //MARK: SHARING ACTIVITY
    func showActivityViewController(link:String) {
        let urlLink = URL(string: link)
        var sharingText = ""
        switch self.userStatus {
        case USER_JOB_STATUS.free:
            sharingText = SHARE_MESSAGE.REQUEST_MESSAGE
            break
        case USER_JOB_STATUS.sharingLocation:
            sharingText = SHARE_MESSAGE.SHARE_LOCATION_MESSAGE
            break
        default:
            break
        }
        let activityController = UIActivityViewController(activityItems: [sharingText, urlLink!], applicationActivities: [])
        
        DispatchQueue.main.async {
            self.present(activityController, animated: true, completion: nil)
        }
        /*----------------- Handling when any event called off on activity controller -----------------*/
        activityController.completionWithItemsHandler = { activity, success, items, error in
            UIView.animate(withDuration: 0.5, animations: {

            }, completion: { finished in
                DispatchQueue.main.async {
                    switch self.userStatus {
                    case USER_JOB_STATUS.free:

                        break
                    case USER_JOB_STATUS.sharingLocation:

                        break
                    default:
                        break
                    }
            
                }
            })
        }
    }
    
    //MARK: RESET LOCATION TIMER
    func resetLocationTimer() {
        if getLocationTimer != nil {
            getLocationTimer.invalidate()
            getLocationTimer = nil
        }
    }
    //MARK: Driver Detail
    @objc func updateJobData(_ notification: NSNotification){
        
        print(notification.userInfo ?? "")
        if let dict = notification.userInfo as NSDictionary? {
            if let id = dict["data"] as? Jobs{
                let imageString = id.fleetImage
                if let image = getImage(from: imageString ){
                    self.profileImage.image =  image
                }
                self.licenceNumber.text = id.licenseNumber
                self.driverName.text = id.fleetName
                self.contactNumber = "\(id.fleetPhone)"
                self.googleMapView.clear()
                self.jobData?.jobStatus = id.jobStatus
                if self.jobData?.fleetID != id.fleetID{
                    self.trackingDelegate.logout?()
                    TookanTracker.shared.createSession(userID: id.userID, isUINeeded: false, navigationController: self.navigationController!)
                    TookanTracker.shared.startTarckingByJob(sharedSecertId: "tookan-sdk-345#!@", jobId: id.jobId, userId: id.userID)
                }else{
                     TookanTracker.shared.createSession(userID: id.userID, isUINeeded: false, navigationController: self.navigationController!)
                    TookanTracker.shared.startTarckingByJob(sharedSecertId: "tookan-sdk-345#!@", jobId: id.jobId, userId: id.userID)
                }

            }
        }

    }
    //MARK: MAP
    @objc func updatePath() {
        
        self.mapCurrentZoomLevel = self.googleMapView.camera.zoom
        let path = GMSMutablePath()
        var startingCoordinate = CLLocationCoordinate2D(latitude: 30.741482, longitude: 76.768066)
        startingCoordinate = CLLocationCoordinate2D()
        
        var coordinate: CLLocationCoordinate2D?
        var lastSecondCoordinate: CLLocationCoordinate2D?
        var count = Int()
        if let locationDictionaryArray = UserDefaults.standard.value(forKey: USER_DEFAULT.updatingLocationPathArray) as? [Any] {
            print("locationDictionaryArray count",locationDictionaryArray.count )
            print("locationDictionaryArray val",locationDictionaryArray)
            count = locationDictionaryArray.count
            for i in (0..<locationDictionaryArray.count) {
                if let locationDictionary = locationDictionaryArray[i] as? [String:Any] {
                    let latitudeString = locationDictionary["Latitude"] as! NSNumber
                    let longitudeString = locationDictionary["Longitude"] as! NSNumber
                    coordinate = CLLocationCoordinate2D(latitude: latitudeString.doubleValue, longitude: longitudeString.doubleValue)
                    path.add(coordinate!)
                    if i == 0 {
                        startingCoordinate = coordinate!
                    }
                    if locationDictionaryArray.count > 1 {
                        if i == (locationDictionaryArray.count - 2) {
                            lastSecondCoordinate = coordinate
                        }
                    }
                    
                    print("inloop coordinate \(i)", coordinate ?? 0)
                }
            }
        }
        
        
        if coordinate == nil {
            coordinate = CLLocationCoordinate2D(latitude: 30.741482, longitude: 76.768066)
            coordinate = CLLocationCoordinate2D()
        }
        let destinationCoordinate = self.getLatitudeLongitudeOfDest()
        self.movingMarker(originCoordinate: coordinate!, destinationCoordinate: destinationCoordinate ?? CLLocationCoordinate2D())
    }
    func movingMarker(originCoordinate:CLLocationCoordinate2D, destinationCoordinate:CLLocationCoordinate2D){
            DispatchQueue.main.async {
                guard UIApplication.shared.applicationState == UIApplication.State.active else {
                    return
                }
                CATransaction.begin()
                CATransaction.setValue(NSNumber(value: 1), forKey: kCATransactionAnimationDuration)

                self.googleMapView.animate(toViewingAngle: 0)
                self.googleMapView.camera = GMSCameraPosition.camera(withTarget: originCoordinate, zoom: 15)
                self.googleMapView.animate(toLocation: originCoordinate)
           let imageString = ""
                if imageString != ""{
                    if let image = self.getImage(from: imageString ){
                        self.startingPointMarker?.icon = self.image(image, scaledToSize: CGSize(width: 22, height: 22))
                    }
                }else{
                    self.startingPointMarker?.icon = UIImage(named: "car", in: frameworkBundle, compatibleWith: nil)
                }
                         if TookanTracker.shared.jobArrayCount > 1{
                                     for i in (0..<TookanTracker.shared.jobArray.count){
                //                         if TookanTracker.shared.jobArray[i].jobId == TookanTracker.shared.jobID{
                                     switch TookanTracker.shared.jobArray[i].jobType {
                         case "0":
                              if imageString != ""{
                                  if let image = self.getImage(from: imageString ){
                                      self.endPointMarker?.icon = self.image(image, scaledToSize: CGSize(width: 22, height: 22))
                                  }
                              }else{
                                   self.endPointMarker?.icon = UIImage(named: "arrived_pickup", in: frameworkBundle, compatibleWith: nil)
                              }

                             break
                         case "1":
                             if imageString != ""{
                                 if let image = self.getImage(from: imageString ){
                                     self.endPointMarker?.icon = self.image(image, scaledToSize: CGSize(width: 22, height: 22))
                                 }
                             }else{
                                  self.endPointMarker?.icon = UIImage(named: "arrived_delivery", in: frameworkBundle, compatibleWith: nil)
                             }
                             break
                         case "2":
                              if imageString != ""{
                                  if let image = self.getImage(from: imageString ){
                                      self.endPointMarker?.icon = self.image(image, scaledToSize: CGSize(width: 22, height: 22))
                                  }
                              }else{
                                   self.endPointMarker?.icon = UIImage(named: "arrived_appointment", in: frameworkBundle, compatibleWith: nil)
                              }
                             break
                         default:
                             break
                         }
                                    }
                     }else{
                    switch self.jobData?.jobType {
                    case "0":
                        if imageString != ""{
                            if let image = self.getImage(from: imageString ){
                                self.endPointMarker?.icon = self.image(image, scaledToSize: CGSize(width: 22, height: 22))
                            }
                        }else{
                            self.endPointMarker?.icon = UIImage(named: "arrived_pickup", in: frameworkBundle, compatibleWith: nil)
                        }

                        break
                    case "1":
                        if imageString != ""{
                            if let image = self.getImage(from: imageString ){
                                self.endPointMarker?.icon = self.image(image, scaledToSize: CGSize(width: 22, height: 22))
                            }
                        }else{
                            self.endPointMarker?.icon = UIImage(named: "arrived_delivery", in: frameworkBundle, compatibleWith: nil)
                        }
                        
                        break
                    case "2":
                        if imageString != ""{
                            if let image = self.getImage(from: imageString ){
                                self.endPointMarker?.icon = self.image(image, scaledToSize: CGSize(width: 22, height: 22))
                            }
                        }else{
                            self.endPointMarker?.icon = UIImage(named: "arrived_appointment", in: frameworkBundle, compatibleWith: nil)
                        }
                        break
                    default:
                        break
                    }
                 
                }
                

                           self.startingPointMarker?.position = originCoordinate
                          
                           self.startingPointMarker?.map = self.googleMapView
                           self.endPointMarker?.position = destinationCoordinate
                           self.endPointMarker?.map = self.googleMapView
                           self.endPointMarker?.isFlat = true
                           self.googleMapView.selectedMarker = self.endPointMarker
//              if TookanTracker.shared.jobArrayCount > 1{
//                 self.setJobMarkers()
//                }

                CATransaction.commit()
            }
        }
    func setMarker(_ originCoordinate: CLLocationCoordinate2D, marker:GMSMarker) {
        CATransaction.begin()
        CATransaction.setValue(NSNumber(value: 2.0), forKey: kCATransactionAnimationDuration)
        marker.position = originCoordinate
        marker.icon = destinationMarker
        marker.title = "eta"
        marker.isFlat = true
        marker.map = googleMapView
        CATransaction.commit()
    }
    

    
    //MARK: LocationTrackerDelegate Method
    func currentLocationOfUser(_ location: CLLocation) {
        
        NSLog("Current Location = %@", location)
        CATransaction.begin()
        CATransaction.setValue(NSNumber(value: 1), forKey: kCATransactionAnimationDuration)
        let camera = GMSCameraPosition.camera(withLatitude: location.coordinate.latitude, longitude: location.coordinate.longitude, zoom: Float(self.mapCurrentZoomLevel))
        self.googleMapView.animate(to: camera)
        self.googleMapView.animate(toViewingAngle: 45)
        CATransaction.commit()
    }
    
    //MARK: Bottom Button Delegate Methods
    func sliderRequestAction() {
        self.showLoadingStatus()
    }
    
    func sliderShareAction() {
        print("Share")
        self.showLoadingStatus()
        let response = loc.startLocationService()
        if(response.0 == true) {
            self.resetLocationTimer()
            getLocationTimer = Timer.scheduledTimer(timeInterval: 2.0, target: self, selector: #selector(self.startSession), userInfo: nil, repeats: true)
        } else {
            print(response.1)
            UIAlertView(title: "", message: response.1, delegate: self, cancelButtonTitle: "OK").show()
        }
    }
    
    func stopSharingAfterConfirmation() {
        UIView.animate(withDuration: 0.2, animations: {

        }, completion: { finished in
            DispatchQueue.main.async {

                UIView.animate(withDuration: 1.0, delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: 1.0, options: UIView.AnimationOptions(), animations: { () -> Void in

                }, completion: { finished in

                })
            }
        })
    }
    
    func stopSession() {
        UIView.animate(withDuration: 0.5, delay:0.0, options: UIView.AnimationOptions.curveEaseInOut, animations: {

        }, completion: { finished in
            self.googleMapView.clear()
            self.userStatus = USER_JOB_STATUS.free

            self.loc.stopLocationService()
            self.model.resetAllData()

        })
    }
    
    @objc func stopSharingOrTracking() {
        switch userStatus {
        case USER_JOB_STATUS.sharingLocation:
            let alert = UIAlertController(title: "", message: ALERT_MESSAGE.STOP_SHARING, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { (action) -> Void in
                self.stopSharingAfterConfirmation()
            }))
            alert.addAction(UIAlertAction(title: "No", style: .cancel, handler: nil))
            self.present(alert, animated: true, completion: nil)
            break
        case USER_JOB_STATUS.trackingLocation:
            let alert = UIAlertController(title: "", message: ALERT_MESSAGE.STOP_TRACKING, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { (action) -> Void in
                self.stopSession()
            }))
            alert.addAction(UIAlertAction(title: "No", style: .cancel, handler: nil))
            self.present(alert, animated: true, completion: nil)
            break
        default:
            break
        }
    }
    
    func dismissComplete() {
        UIView.animate(withDuration: 1.0, delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: 1.0, options: UIView.AnimationOptions(), animations: { () -> Void in

        }, completion: nil)
    }
    
    func showLoadingStatus() {
        UIView.animate(withDuration: 0.2, animations: {

        }, completion: { finished in
            DispatchQueue.main.async {

            }
        })
    }
    
 
    
    func animationForCameraLocation(coordinate:CLLocationCoordinate2D) {
        CATransaction.begin()
        CATransaction.setValue(NSNumber(value: 1), forKey: kCATransactionAnimationDuration)
        let camera = GMSCameraPosition.camera(withLatitude: coordinate.latitude, longitude: coordinate.longitude, zoom: 16)
        self.googleMapView.animate(to: camera)
        self.setMarker(coordinate, marker: self.pathMarker)
        self.mapCurrentZoomLevel = self.googleMapView.camera.zoom
        CATransaction.commit()
    }
    
    //MARK: SessionViewDelegate Methods
    func dismissSessionView() {

    }
    
    func delegateStartTracking(sessionId: String) {
        self.startTracking(sessionId: sessionId)

    }
    
    @IBAction func callBtn(_ sender: Any) {
        self.makeCall(phone: self.contactNumber)
    }
    
    func makeCall(phone: String) {
        let formatedNumber = phone.components(separatedBy: NSCharacterSet.decimalDigits.inverted).joined(separator: "")
        print("calling \(formatedNumber)")
        let phoneUrl = "tel://\(formatedNumber)"
        let url:URL = URL(string: phoneUrl)!
        UIApplication.shared.openURL(url)
    }
}
extension HomeController: GMSAutocompleteViewControllerDelegate, GMSMapViewDelegate {
    // Handle the user's selection.
    //    func viewController(_ viewController: GMSAutocompleteViewController, didAutocompleteWith place: GMSPlace) {
    //        self.dismiss(animated: true, completion: { finished in
    //
    //        })
    //    }
    
    func viewController(_ viewController: GMSAutocompleteViewController, didAutocompleteWith place: GMSPlace) {
        self.dismiss(animated: true) {
            CATransaction.begin()
            CATransaction.setValue(NSNumber(value: 1), forKey: kCATransactionAnimationDuration)
            let camera = GMSCameraPosition.camera(withLatitude: place.coordinate.latitude, longitude: place.coordinate.longitude, zoom: 16)
            self.googleMapView.animate(to: camera)
            
            self.setMarker(place.coordinate, marker: self.searchMarker!)
            self.mapCurrentZoomLevel = self.googleMapView.camera.zoom
            CATransaction.commit()
        }
    }
    
    func viewController(_ viewController: GMSAutocompleteViewController, didFailAutocompleteWithError error: Error) {
        // TODO: handle the error.
        print("Error: \(error.localizedDescription)")
        self.dismiss(animated: true, completion: nil)
    }
    
    
    // User canceled the operation.
    func wasCancelled(_ viewController: GMSAutocompleteViewController) {
        print("Autocomplete was cancelled.")
        self.dismiss(animated: true, completion: nil)
    }
    
    func mapView(_ mapView: GMSMapView, didChange position: GMSCameraPosition) {
        print("didChange position : GMSMapView")
        let location = loc.getCurrentLocation() as CLLocation
        self.currentCameraPosition = GMSCameraPosition.camera(withLatitude: location.coordinate.latitude, longitude: location.coordinate.longitude, zoom: self.mapCurrentZoomLevel)
        let lat = round(location.coordinate.latitude*1000)/1000
        let long = round(location.coordinate.longitude*1000)/1000
        
        let framelat = round(position.target.latitude * 1000) / 1000 //position.target.latitude
        let framelong = round(position.target.longitude * 1000) / 1000
        print("currnt \(lat) \(long)" )
        print("frame \(framelat) \(framelong)" )

        
            if ((lat == framelat) && (long == framelong)) {
                self.moving = true
            } else {
                self.moving = false
            }

    }
    
    func mapView(_ mapView: GMSMapView, idleAt position: GMSCameraPosition) {
        print("idleAt position: GMSCameraPosition")
    }
    
}

