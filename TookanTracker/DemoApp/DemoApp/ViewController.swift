//
//  ViewController.swift
//  TookanTracker-Demo
//
//  Created by CL-Macmini-110 on 11/20/17.
//  Copyright © 2017 CL-Macmini-110. All rights reserved.
//

import UIKit
import TookanTracker
import CoreLocation

let apiKey = "546b6480f1075f02431774714310214114e7ccf22ad87d3b581d"

struct USER_DEFAULT {
    static let isSessionExpire = "isSessionExpire"
    static let applicationMode = "ApplicationMode"
    static let isHitInProgress = "isHitInProgress"
    static let isLocationTrackingRunning = "isLocationTrackingRunning"
    static let deviceToken = "DeviceToken"
    static let sessionId = "sessionID"
    static let updatingLocationPathArray = "updatingPathLocationArray"
    static let subscribeLocation = "subscribeLocation"
    static let requestID = "requestID"
    static let sessionURL = "sessionUrl"
    static let userId = "userId"
}



class ViewController: UIViewController, TookanTrackerDelegate {

    var getLocationTimer:Timer!
    let SCREEN_SIZE = UIScreen.main.bounds
    var sessionId = ""
    @IBOutlet var emailTextField: UITextField!
    @IBOutlet var passwordTextField: UITextField!
    @IBOutlet var topLabel: UILabel!
    @IBOutlet var signInButton: UIButton!
    @IBOutlet var signup: UIButton!
    
    @IBOutlet var userIdTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setTopLabel()
        self.setTextField()
        self.setSignInButton()
        self.setSignUpButton()
        self.navigationController?.isNavigationBarHidden = true
        self.emailTextField.isHidden = true
        self.signup.isHidden = true
        
    }
    
    internal func getCurrentCoordinates(_ location: CLLocation) {
        print("INAPP COORDINATES \(location)")
    }
    
    internal func logout() {
        UserDefaults.standard.set(true, forKey: USER_DEFAULT.isSessionExpire)
    }
    
    func setTextField() {
        self.emailTextField.placeholder = "Enter Agent Id"
        self.passwordTextField.placeholder = "Enter Job Id"
        self.userIdTextField.placeholder = "Enter User Id"
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.dismissKeyboard (_:)))
        self.view.addGestureRecognizer(tapGesture)
    }
    
    @objc func dismissKeyboard (_ sender: UITapGestureRecognizer) {
        self.emailTextField.resignFirstResponder()
        self.passwordTextField.resignFirstResponder()
        self.userIdTextField.resignFirstResponder()
    }
    
    func setSignInButton() {
        self.signInButton.setTitle("Start Tarcking", for: .normal)
        self.signInButton.backgroundColor = UIColor(red: 70/255, green: 149/255, blue: 246/255, alpha: 1.0)
        self.signInButton.setTitleColor(UIColor.white, for: .normal)
    }
    
    func setSignUpButton() {

        self.signup.setTitle("Start Tracking For Agent", for: .normal)
        self.signup.backgroundColor = UIColor(red: 70/255, green: 149/255, blue: 246/255, alpha: 1.0)
        self.signup.setTitleColor(UIColor.white, for: .normal)
    }
    
    func setTopLabel() {
        self.topLabel.text = ""
        self.topLabel.font = UIFont.systemFont(ofSize: 20)
    }
    
    @IBAction func signInAction(_ sender: Any) {
        TookanTracker.shared.delegate = self
        TookanTracker.shared.googleMapKey = "AIzaSyDHjZIxrZR2R9RAVCb3YXs_FOP5bbFeVgU"
        TookanTracker.shared.createSession(userID: "27278", apiKey: apiKey, isUINeeded: false, navigationController: self.navigationController!)
        TookanTracker.shared.startTarckingByJob(sharedSecertId: "tookan-sdk-345#!@", jobId: "\(self.passwordTextField.text ?? "")", userId: "\(self.userIdTextField.text ?? "")")

        
    }
    
    
    @IBAction func signupAction(_ sender: Any) {
        TookanTracker.shared.delegate = self
        TookanTracker.shared.googleMapKey = "AIzaSyDHjZIxrZR2R9RAVCb3YXs_FOP5bbFeVgU"
        TookanTracker.shared.createSession(userID:"68451", apiKey: apiKey, isUINeeded: false, navigationController:self.navigationController!)
        TookanTracker.shared.startTrackingByAgent(sharedSecertId: "tookan-sdk-345#!@", fleetId: "\(self.emailTextField.text ?? "")", userId: "\(self.userIdTextField.text ?? "")")


        
    }
    
    @IBAction func stopTracking(_ sender: Any) {
        
        TookanTracker.shared.stopTracking(sessionID: self.sessionId)
    }
    
    
    func getAspectRatioValue(value:CGFloat) -> CGFloat {
        return (value / 375) * SCREEN_SIZE.width
    }
   

    //MARK: RESET LOCATION TIMER
    func resetLocationTimer() {
        if getLocationTimer != nil {
            getLocationTimer.invalidate()
            getLocationTimer = nil
        }
    }
    

    
    func getSessionId(sessionId: String) {
        print("Sessionid: \(sessionId)")
        self.sessionId = sessionId
    }
}

