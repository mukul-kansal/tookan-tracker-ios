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
    
    //  @IBOutlet weak var myLocationButtontrailingConstraint: NSLayoutConstraint!
    //   @IBOutlet weak var myLocationButton: UIButton!
    @IBOutlet weak var googleMapView: GMSMapView!
    @IBOutlet var currentLocation: UIButton!
    @IBOutlet var logout: UIButton!
    //    @IBOutlet weak var menuButton: UIButton!
    @IBOutlet var stopTrackingButton: UIButton!
    var userStatus = USER_JOB_STATUS.free
    var getLocationTimer:Timer!
    var path = GMSMutablePath()
    let loc = LocationTrackerFile.sharedInstance()
    let model = TrackerModel()
//    var bottomView:BottomButtonView!
    var viewShowStatus:Int!
    var mapCurrentZoomLevel:Float = 16
    var searchMarker:GMSMarker? = GMSMarker()
    var pathMarker = GMSMarker()
//    var sessionID = ""
    var currentCameraPosition: GMSCameraPosition!
    var moving = true
    var trackingDelegate:TrackingDelegate!
    var isTrackingEnabled = true
//    var sessionDetailView:SessionDetailView!
    struct SHOW_HIDE {
        static let showBottomView = 1
        static let hideBottomView = 2
        static let showLoadingStatus = 3
        static let showStopLocationButton = 4
        static let showStopTrackingButton = 5
        static let showSliderButton = 6
    }
    
    override var preferredStatusBarStyle:UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        /*----------------- Location Tracker --------------*/
        self.loc.delegate = self
//        self.loc.setLocationUpdate()
        self.loc.registerAllRequiredInitilazers()
//        self.loc.initMqtt()
//        self.loc.locationFrequencyMode = LocationFrequency.high
//        self.loc.setLocationUpdate()
//        _ = self.loc.startLocationService()
//        self.loc.subsribeMQTTForTracking()
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
        // self.googleMapView.isTrafficEnabled = true
        self.googleMapView.isMyLocationEnabled = true
        
//        self.logout.setImage(close?.withRenderingMode(.alwaysTemplate), for: .normal)
//        self.logout.tintColor = UIColor.white
        self.logout.setTitle("Logout", for: .normal)
        
        
        
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
    }
    
    func setTrackingButton() {
        self.stopTrackingButton.layer.cornerRadius = 5.0
        self.setTrackingTitle()
        self.stopTrackingButton.backgroundColor = UIColor(red: 70/255, green: 149/255, blue: 246/255, alpha: 1.0)
        self.stopTrackingButton.setTitleColor(UIColor.white, for: .normal)
    }
    
    func setTrackingTitle() {
        if let _ = UserDefaults.standard.value(forKey: USER_DEFAULT.sessionId) as? String {
            self.stopTrackingButton.setTitle("Stop Sharing Location", for: .normal)
            self.isTrackingEnabled = true
        } else {
            self.stopTrackingButton.setTitle("Start Sharing Location", for: .normal)
            self.userStatus = USER_JOB_STATUS.free
            self.isTrackingEnabled = false
        }
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        //        menuButton.layer.cornerRadius = 45/2
        NotificationCenter.default.addObserver(self, selector: #selector(self.updatePath), name: NSNotification.Name(rawValue: OBSERVER.updatePath), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.requestIdReceivedFromURL), name: NSNotification.Name(rawValue: OBSERVER.requestIdURL), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.sessionIDRecivedFromPush), name: NSNotification.Name(rawValue: OBSERVER.sessionIdPush), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.startTrackingFromURL), name: NSNotification.Name(rawValue: OBSERVER.sessionIdURL), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.stopSharingOrTracking), name: NSNotification.Name(rawValue: OBSERVER.stopTracking), object: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        if let mylocation = loc.getCurrentLocation() {
            let camera = GMSCameraPosition.camera(withLatitude: mylocation.coordinate.latitude, longitude: mylocation.coordinate.longitude, zoom: 16)
            googleMapView.camera = camera
            self.mapCurrentZoomLevel = self.googleMapView.camera.zoom
        } else {
            print("User's location is unknown")
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: OBSERVER.updatePath), object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: OBSERVER.requestIdURL), object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: OBSERVER.sessionIdURL), object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: OBSERVER.stopTracking), object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: OBSERVER.sessionIdPush), object: nil)
    }
    
    @IBAction func logoutAction(_ sender: Any) {
        
        self.stopTrackingConformation(pop: true)
        
    }
    
    
    @IBAction func stopTrackingAction(_ sender: Any) {
        
        self.stopTrackingConformation(pop: false)
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
        let alertController = UIAlertController(title: nil, message: "Are you sure?", preferredStyle: UIAlertControllerStyle.actionSheet)
        let confirmAction = UIAlertAction(title: "Yes", style: UIAlertActionStyle.destructive) { (confirmed) -> Void in
            self.stopTrackingButton.isHidden = true
            self.stopTracking(pop: pop)
        }
        
        let cancelAction = UIAlertAction(title: "No", style: UIAlertActionStyle.cancel, handler: {(UIAlertAction) in
        })
        alertController.addAction(confirmAction)
        alertController.addAction(cancelAction)
        self.present(alertController, animated: true, completion: nil)
    }
    
    func startTracking() {
        
        let api_key = UserDefaults.standard.value(forKey: USER_DEFAULT.apiKey) as? String ?? ""
        let unique_user_id = UserDefaults.standard.value(forKey: USER_DEFAULT.userId) as? String ?? ""
        let location = self.loc.getCurrentLocation()
        NetworkingHelper.sharedInstance.shareLocationSession(api_key: api_key, unique_user_id: unique_user_id, lat: "\(location?.coordinate.latitude ?? 0)", lng: "\(location?.coordinate.longitude ?? 0)", sessionId: "") { (isSucceeded, response) in
            
            DispatchQueue.main.async {
                print(response)
                self.stopTrackingButton.isHidden = false
                if isSucceeded == true {
                    var sessionID = ""
                    if let data = response["data"] as? [String:Any]{
                        sessionID = "\(data["session_id"] ?? "")"
                        UserDefaults.standard.set(sessionID, forKey: USER_DEFAULT.sessionId)
                    }
//                    self.loc.setLocationUpdate()
                    self.loc.registerAllRequiredInitilazers()
                    self.setUserCurrentJob()
                    self.setTrackingTitle()
                    self.sliderShareAction()
                    
                }
            }
        }
    }
    
    func stopTracking(pop: Bool) {
        if let sessionId = UserDefaults.standard.value(forKey: USER_DEFAULT.sessionId) as? String {
            NetworkingHelper.sharedInstance.stopTracking(sessionId, userID: globalUserId, apiKey: globalAPIKey) { (isSucceeded, response) in
                DispatchQueue.main.async {
                    self.stopTrackingButton.isHidden = false
                    if isSucceeded == true {
                        self.googleMapView.clear()
                        self.userStatus = USER_JOB_STATUS.free
                        self.loc.stopLocationService()
                        self.model.resetAllData()
                        self.setTrackingTitle()
                        if pop == true {
                            self.dismissVC()
                        }
                    }
                }
                
            }
        }else {
            if pop == true {
                self.dismissVC()
            }
        }
        
    }
    
    func dismissVC() {
        self.navigationController?.popToRootViewController(animated: true)
        self.trackingDelegate.logout!()
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
            self.viewShowStatus = SHOW_HIDE.showBottomView
            //            self.setBottomButtonView(stopTitle: "", isSlider: true)
            break
        case USER_JOB_STATUS.sharingLocation:
            //            self.menuButton.isHidden = false
            //            self.myLocationButtontrailingConstraint.constant = 56
            //            self.menuButton.setImage(UIImage(named:"share"), for: UIControlState.normal)
            let response = loc.startLocationService()
            if(response.0 == true) {
                self.shareLocation()
                self.viewShowStatus = SHOW_HIDE.showStopLocationButton
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
        //        NetworkingHelper.sharedInstance.shareStartStopLocationSession("", location: model.getLocationArrayObject(location: location), phone: "", requestType: 1, sessionId: sessionId, requestID: requestId, receivedResponse: { (succeeded, response) in
        //            DispatchQueue.main.async {
        //                if(succeeded == true) {
        //                    if let data = response["data"] as? [String:Any] {
        //                        if let sessionID = data["session_id"] {
        //                            self.menuButton.isHidden = false
        //                            self.myLocationButtontrailingConstraint.constant = 56
        //                            self.menuButton.setImage(UIImage(named:"share"), for: UIControlState.normal)
//                                    UserDefaults.standard.set(sessionId, forKey: USER_DEFAULT.sessionId)
//                                    UserDefaults.standard.set(true, forKey: USER_DEFAULT.isLocationTrackingRunning)
                                    UserDefaults.standard.set(false, forKey: USER_DEFAULT.subscribeLocation)
                                    self.userStatus = USER_JOB_STATUS.sharingLocation
                                    self.shareLocation()
        //                            if let sessionUrl = data["session_url"] as? String {
        //                                NetworkingHelper.sharedInstance.sessionURL = sessionUrl
        //                                UserDefaults.standard.setValue(sessionUrl, forKey: USER_DEFAULT.sessionURL)
        //                                self.showActivityViewController(link: sessionUrl)
        //                            }
        //                        }
        //                    }
        //                } else {
        //                    DispatchQueue.main.async {
        //                        self.menuButton.setImage(UIImage(named:"menu"), for: UIControlState.normal)
        //                        self.userStatus = USER_JOB_STATUS.free
        //                        self.menuButton.isHidden = false
        //                        self.myLocationButtontrailingConstraint.constant = 56
        //                        self.model.resetAllData()
        //                        self.viewShowStatus = SHOW_HIDE.showBottomView
        //                        self.setBottomButtonView(stopTitle: "", isSlider: true)
        //                    }
        //                }
        //            }
        //
        //        })
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
        NetworkingHelper.sharedInstance.validateUserRequestId(NetworkingHelper.sharedInstance.requestId) { (succeeded, response) in
            if(succeeded == true) {
                if let data = response["data"] as? [String:Any] {
                    if let id = data["session_id"] as? String {
                        NetworkingHelper.sharedInstance.sessionId = id
                    }
                    
                    if let sessionUrl = data["session_url"] as? String {
                        NetworkingHelper.sharedInstance.sessionURL = sessionUrl
                    }
                    
                    if let role = data["role"] as? Int {
                        NetworkingHelper.sharedInstance.requestRole = role
                    }
                    self.setFlowAfterValidationOfRequest()
                }
            }
        }
    }
    
    func setFlowAfterValidationOfRequest() {
        switch userStatus {
        case USER_JOB_STATUS.free:
            if NetworkingHelper.sharedInstance.requestRole == 0 {
                self.showAlertForSharingLocation()
            } else if NetworkingHelper.sharedInstance.requestRole == 1 {
                self.showAlertForTrackingOwnRequestedLocation()
            }
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
            self.startTracking(sessionId: NetworkingHelper.sharedInstance.sessionId)
        }))
        alert.addAction(UIAlertAction(title: "No", style: .cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    func shareLocationAfterConfirmation() {
        switch userStatus {
        case USER_JOB_STATUS.free:
            self.startSessionHit(sessionId: NetworkingHelper.sharedInstance.sessionId, location: loc.getCurrentLocation())
            break
        case USER_JOB_STATUS.sharingLocation:
            self.startSessionHit(sessionId: NetworkingHelper.sharedInstance.sessionId, location: loc.getCurrentLocation())
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
            self.startTracking(sessionId: NetworkingHelper.sharedInstance.sessionId)
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
        NetworkingHelper.sharedInstance.getLocationForStartTracking(sessionId) { (succeeded, response) in
            print(response)
            DispatchQueue.main.async {
                if succeeded == true {
                    if let locationArray = response["location"] as? [String:Any] {
//                        self.menuButton.isHidden = true
//                        self.myLocationButtontrailingConstraint.constant = 11
//                        self.menuButton.setImage(UIImage(named:"menu"), for: UIControlState.normal)
                        self.userStatus = USER_JOB_STATUS.trackingLocation
                        UserDefaults.standard.set(sessionId, forKey: USER_DEFAULT.sessionId)
                        let coordinate = self.model.updatePathLocations(locationArray: locationArray)
                        self.animationForCameraLocation(coordinate: coordinate)
                        print(UserDefaults.standard.value(forKey: USER_DEFAULT.sessionId) as! String)
                        self.loc.topic = "\(globalAPIKey)\(globalUserId)"  //UserDefaults.standard.value(forKey: USER_DEFAULT.sessionId) as! String
                        self.loc.subsribeMQTTForTracking()
                        UserDefaults.standard.set(true, forKey: USER_DEFAULT.subscribeLocation)
                        self.viewShowStatus = SHOW_HIDE.showStopTrackingButton
                        //                        self.setBottomButtonView(stopTitle: "", isSlider: true)
                    }
                } else {
                    //                    self.menuButton.setImage(UIImage(named:"menu"), for: UIControlState.normal)
                    //                    self.userStatus = USER_JOB_STATUS.free
                    //                    self.menuButton.isHidden = false
                    //                    self.myLocationButtontrailingConstraint.constant = 56
                    self.model.resetAllData()
                    self.viewShowStatus = SHOW_HIDE.showBottomView
                    //                    self.setBottomButtonView(stopTitle: "", isSlider: true)
                }
            }
        }
    }
    
    //    func alertPopupForSessionId() {
    //        guard sessionDetailView == nil else {
    //            return
    //        }
    //        UIView.animate(withDuration: 0.5, animations: {
    //            self.bottomView.transform = CGAffineTransform.identity
    //            }, completion: { finished in
    //                DispatchQueue.main.async {
    //
    //                    self.sessionDetailView = UINib(nibName: "SessionDetailView", bundle: frameworkBundle).instantiate(withOwner: self, options: nil)[0] as! SessionDetailView
    //                    self.sessionDetailView.frame = self.view.frame
    //                    self.sessionDetailView.delegate = self
    //                    self.sessionDetailView.setSessionView()
    //                    self.sessionDetailView.delegate = self
    //                    self.view.addSubview(self.sessionDetailView)
    //                }
    //        })
    //
    ////        let alert = UIAlertController(title: "Enter session id for tracking", message: nil, preferredStyle: .alert)
    ////        alert.addTextField(configurationHandler: { (textField) -> Void in
    ////            textField.placeholder = "Session id"
    ////        })
    ////        alert.addAction(UIAlertAction(title: "Submit", style: .default, handler: { (action) -> Void in
    ////            let textField = alert.textFields![0] as UITextField
    ////            if !(textField.text!.blank(textField.text!)){
    ////                self.startTracking(sessionId: textField.text!.trimText)
    ////            } else{
    ////                Auxillary.showAlert("Pleas enter session id.")
    ////            }
    ////        }))
    ////        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action) -> Void in
    ////
    ////        }))
    ////        self.present(alert, animated: true, completion: nil)
    //    }
    
    func alertPopupForTracking() {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: UIAlertControllerStyle.actionSheet)
        let trackAction = UIAlertAction(title: "Track", style: UIAlertActionStyle.default) { (UIAlertAction) in
            //            self.alertPopupForSessionId()
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler:nil)
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
//                    self.bottomView.transform = CGAffineTransform.identity
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
//                self.bottomView.transform = CGAffineTransform.identity
            }, completion: { finished in
                DispatchQueue.main.async {
                    switch self.userStatus {
                    case USER_JOB_STATUS.free:
                        self.viewShowStatus = SHOW_HIDE.showSliderButton
                        break
                    case USER_JOB_STATUS.sharingLocation:
                        self.viewShowStatus = SHOW_HIDE.showStopLocationButton
                        break
                    default:
                        break
                    }
                    //                        self.animationForBottomView()
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
    
    //MARK: MAP
    @objc func updatePath() {
        guard self.loc.myLocationAccuracy < self.loc.maxAccuracy else {
            return
        }
        self.googleMapView.isMyLocationEnabled = true
        self.mapCurrentZoomLevel = self.googleMapView.camera.zoom
        path = GMSMutablePath()
        var coordinate = CLLocationCoordinate2D()
        if let locationDictionaryArray = UserDefaults.standard.value(forKey: USER_DEFAULT.updatingLocationPathArray) as? [Any] {
            for i in (0..<locationDictionaryArray.count) {
                if let locationDictionary = locationDictionaryArray[i] as? [String:Any] {
                    let latitudeString = locationDictionary["Latitude"] as! NSNumber
                    let longitudeString = locationDictionary["Longitude"] as! NSNumber
                    coordinate = CLLocationCoordinate2D(latitude: latitudeString.doubleValue, longitude: longitudeString.doubleValue)
                    path.add(CLLocationCoordinate2D(latitude: locationDictionary["Latitude"] as! Double, longitude: locationDictionary["Longitude"] as! Double))
                }
            }
        }
        self.createRoutePathArray(originCoordinate: coordinate)
    }
    
    func setMarker(_ originCoordinate: CLLocationCoordinate2D, marker:GMSMarker) {
        CATransaction.begin()
        CATransaction.setValue(NSNumber(value: 2.0), forKey: kCATransactionAnimationDuration)
        marker.position = originCoordinate
        marker.icon = destinationMarker
        marker.map = googleMapView
        CATransaction.commit()
    }
    
    func createRoutePathArray(originCoordinate: CLLocationCoordinate2D) {
        
        let polyline = GMSPolyline(path: path)
        polyline.strokeColor = UIColor.blue
        polyline.strokeWidth = 8.0
        polyline.geodesic = true;
        
        pathMarker.position = originCoordinate
        pathMarker.icon = destinationMarker
        
        CATransaction.begin()
        CATransaction.setValue(NSNumber(value: 2.0), forKey: kCATransactionAnimationDuration)
        googleMapView.clear()
        
        self.mapCurrentZoomLevel = self.googleMapView.camera.zoom
        self.currentCameraPosition = GMSCameraPosition.camera(withLatitude: originCoordinate.latitude, longitude: originCoordinate.longitude, zoom: self.mapCurrentZoomLevel)
        if moving == true {
            self.googleMapView.animate(to: self.currentCameraPosition)
        }
        polyline.map = googleMapView
        self.mapCurrentZoomLevel = self.googleMapView.camera.zoom
        if userStatus == USER_JOB_STATUS.trackingLocation {
            pathMarker.map = googleMapView
        }
        CATransaction.commit()
    }
    
    //MARK: LocationTrackerDelegate Method
    func currentLocationOfUser(_ location: CLLocation) {
        //  self.mapCurrentZoomLevel = self.googleMapView.camera.zoom
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
        NetworkingHelper.sharedInstance.requestForTracking("") { (succeeded, response) in
            print(response)
            if succeeded == true {
                if let data = response["data"] as? [String:Any] {
                    if let requestURL = data["requestURL"] {
                        self.showActivityViewController(link: requestURL as! String)
                    }
                }
            } else {
                //                self.menuButton.setImage(UIImage(named:"menu"), for: UIControlState.normal)
                self.userStatus = USER_JOB_STATUS.free
                //                self.menuButton.isHidden = false
                //                self.myLocationButtontrailingConstraint.constant = 56
                self.model.resetAllData()
                self.viewShowStatus = SHOW_HIDE.showBottomView
                //                self.setBottomButtonView(stopTitle: "", isSlider: true)
            }
        }
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
//            self.bottomView.transform = CGAffineTransform.identity
        }, completion: { finished in
            DispatchQueue.main.async {
                self.viewShowStatus = SHOW_HIDE.showLoadingStatus
                UIView.animate(withDuration: 1.0, delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: 1.0, options: UIViewAnimationOptions(), animations: { () -> Void in
//                    self.bottomView.stopButton.isHidden = true
//                    if(self.bottomView.sliderRequestShareButton != nil) {
//                        self.bottomView.sliderRequestShareButton.isHidden = true
//                    }
//                    self.bottomView.pleaseWaitLabel.isHidden = false
//                    self.bottomView.acitivityIndicator.startAnimating()
//                    self.bottomView.transform = CGAffineTransform(translationX: 0, y: -self.bottomView.frame.height)
                }, completion: { finished in
                    //                        NetworkingHelper.sharedInstance.shareStartStopLocationSession("", location: [""], phone: "", requestType: 0, sessionId: UserDefaults.standard.value(forKey: USER_DEFAULT.sessionId) as! String, requestID: "") { (succeeded, response) in
                    //                            DispatchQueue.main.async {
                    //                                if succeeded == true {
                    //                                    self.stopSession()
                    //                                } else {
                    //                                    UIView.animate(withDuration: 0.5, delay:0.0, options: UIViewAnimationOptions.curveEaseInOut, animations: {
                    //                                        self.bottomView.transform = CGAffineTransform.identity
                    //                                        }, completion: { finished in
                    //                                            self.viewShowStatus = SHOW_HIDE.showStopLocationButton
                    //                                            self.animationForBottomView()
                    //                                    })
                    //
                    //                                }
                    //                            }
                    //                        }
                })
            }
        })
    }
    
    func stopSession() {
        UIView.animate(withDuration: 0.5, delay:0.0, options: UIViewAnimationOptions.curveEaseInOut, animations: {
//            self.bottomView.transform = CGAffineTransform.identity
        }, completion: { finished in
            self.googleMapView.clear()
            self.userStatus = USER_JOB_STATUS.free
            //            self.menuButton.isHidden = false
            //            self.myLocationButtontrailingConstraint.constant = 56
            //            self.menuButton.setImage(UIImage(named:"menu"), for: UIControlState.normal)
            self.loc.stopLocationService()
            self.model.resetAllData()
            self.viewShowStatus = SHOW_HIDE.showSliderButton
            //            self.animationForBottomView()
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
        UIView.animate(withDuration: 1.0, delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: 1.0, options: UIViewAnimationOptions(), animations: { () -> Void in
//            self.bottomView.transform = CGAffineTransform.identity
        }, completion: nil)
    }
    
    func showLoadingStatus() {
        UIView.animate(withDuration: 0.2, animations: {
//            self.bottomView.transform = CGAffineTransform.identity
        }, completion: { finished in
            DispatchQueue.main.async {
                self.viewShowStatus = SHOW_HIDE.showLoadingStatus
                //                    self.animationForBottomView()
            }
        })
    }
    
    //MARK: Set Bottom Button View
    //    func setBottomButtonView(stopTitle:String, isSlider:Bool) {
    //        if(bottomView == nil) {
    //            bottomView = UINib(nibName: "BottomButtonView", bundle: frameworkBundle).instantiate(withOwner: self, options: nil)[0] as! BottomButtonView
    //            bottomView.delegate = self
    //            self.view.addSubview(bottomView)
    //        }
    //        self.bottomView.transform = CGAffineTransform.identity
    //        bottomView.frame = CGRect(x: 0, y: self.view.frame.height, width: self.view.frame.width, height: bottomView.frame.height)
    //        bottomView.setView("Swipe to Request", rejectButtonTitle: "Swipe to Share", stopButtonTitle: stopTitle, sliderType: isSlider)
    //        animationForBottomView()
    //    }
    
    //    func animationForBottomView() {
    //        var height:CGFloat!
    //        switch(viewShowStatus) {
    //        case SHOW_HIDE.showBottomView:
    //            self.bottomView.pleaseWaitLabel.isHidden = true
    //            self.bottomView.acitivityIndicator.stopAnimating()
    //            height = -self.bottomView.frame.height
    //        case SHOW_HIDE.hideBottomView:
    //            height = self.view.frame.height
    //        case SHOW_HIDE.showLoadingStatus:
    //            self.bottomView.stopButton.isHidden = true
    //            if(self.bottomView.sliderRequestShareButton != nil) {
    //                self.bottomView.sliderRequestShareButton.isHidden = true
    //            }
    //            self.bottomView.pleaseWaitLabel.isHidden = false
    //            self.bottomView.acitivityIndicator.startAnimating()
    //            height = -self.bottomView.frame.height
    //            break
    //        case SHOW_HIDE.showStopLocationButton:
    //            self.bottomView.stopButton.isHidden = false
    //            self.bottomView.stopButton.setTitle("Stop sharing location", for: UIControlState.normal)
    //            if(self.bottomView.sliderRequestShareButton != nil) {
    //                self.bottomView.sliderRequestShareButton.isHidden = true
    //            }
    //            self.bottomView.pleaseWaitLabel.isHidden = true
    //            self.bottomView.acitivityIndicator.stopAnimating()
    //            height = -self.bottomView.frame.height
    //            break
    //        case SHOW_HIDE.showStopTrackingButton:
    //            self.bottomView.stopButton.isHidden = false
    //            self.bottomView.stopButton.setTitle("Stop tracking location", for: UIControlState.normal)
    //            if(self.bottomView.sliderRequestShareButton != nil) {
    //                self.bottomView.sliderRequestShareButton.isHidden = true
    //            }
    //            self.bottomView.pleaseWaitLabel.isHidden = true
    //            self.bottomView.acitivityIndicator.stopAnimating()
    //            height = -self.bottomView.frame.height
    //            break
    //        case SHOW_HIDE.showSliderButton:
    //            self.bottomView.sliderRequestShareButton.backToOriginalPosition()
    //            self.bottomView.stopButton.isHidden = true
    //            if(self.bottomView.sliderRequestShareButton != nil) {
    //                self.bottomView.sliderRequestShareButton.isHidden = false
    //            }
    //            self.bottomView.pleaseWaitLabel.isHidden = true
    //            self.bottomView.acitivityIndicator.stopAnimating()
    //            height = -self.bottomView.frame.height
    //            break
    //        default:
    //            break
    //        }
    //        UIView.animate(withDuration: 1.0, delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: 1.0, options: UIViewAnimationOptions(), animations: { () -> Void in
    //            self.bottomView.transform = CGAffineTransform(translationX: 0, y: height)
    //            }, completion: nil)
    //    }
    
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
//        if self.sessionDetailView != nil {
//            self.sessionDetailView.removeFromSuperview()
//            self.sessionDetailView = nil
//            //            self.animationForBottomView()
//        }
    }
    
    func delegateStartTracking(sessionId: String) {
        self.startTracking(sessionId: sessionId)
//        if self.sessionDetailView != nil {
//            self.sessionDetailView.removeFromSuperview()
//            self.sessionDetailView = nil
//        }
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
//        if self.currentCameraPosition != nil {
        
            if ((lat == framelat) && (long == framelong)) {
                self.moving = true
            } else {
                self.moving = false
            }
//        }
    }
    
    func mapView(_ mapView: GMSMapView, idleAt position: GMSCameraPosition) {
        print("idleAt position: GMSCameraPosition")
    }
    
}

