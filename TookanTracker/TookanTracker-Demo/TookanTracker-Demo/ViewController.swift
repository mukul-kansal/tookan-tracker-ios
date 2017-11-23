//
//  ViewController.swift
//  TookanTracker-Demo
//
//  Created by CL-Macmini-110 on 11/20/17.
//  Copyright © 2017 CL-Macmini-110. All rights reserved.
//

import UIKit
import TookanTracker_SDK

let userID = "1"
let apiKey = "e740d9d626c69da995bb80c0415c6179"

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
}



class ViewController: UIViewController {

//    let loc = LocationTrackerFile.sharedInstance()
    var getLocationTimer:Timer!
    let SCREEN_SIZE = UIScreen.main.bounds
    
    @IBOutlet var mobileTextField: UITextField!
    @IBOutlet var textFieldBottomView: UIView!
    @IBOutlet var topLabel: UILabel!
    @IBOutlet var generateOTPButton: UIButton!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        if navigationController != nil {
            if UserDefaults.standard.bool(forKey: USER_DEFAULT.isSessionExpire) == false {
                UserDefaults.standard.set(false, forKey: USER_DEFAULT.isSessionExpire)
                TookanTracker.shared.createSession(userID:userID, apiKey: apiKey, navigationController:self.navigationController!)
            }
        }
        
        self.setTopLabel()
        self.setTextField()
        self.setBottomView()
        self.setGenerateOTPButton()
        self.navigationController?.isNavigationBarHidden = true
        
    }

    func setTextField() {
        self.mobileTextField.placeholder = "Phone Number"
    }
    
    func setBottomView() {
        self.textFieldBottomView.backgroundColor = UIColor.black
    }
    
    func setGenerateOTPButton() {
        self.generateOTPButton.layer.cornerRadius = 25.0
        self.generateOTPButton.setTitle("Generate OTP", for: .normal)
        self.generateOTPButton.backgroundColor = UIColor.blue
        self.generateOTPButton.setTitleColor(UIColor.white, for: .normal)
    }
    
    func setTopLabel() {
        self.topLabel.text = "Sign in to your account!"
        self.topLabel.font = UIFont.systemFont(ofSize: 20)
    }
    
    @IBAction func generateOTPAction(_ sender: Any) {
        
        
        
        
//        TookanTracker.shared.createSession(userID:"", apiKey: "", navigationController:self.navigationController)
        
        
        let param:[String:Any] = ["mobile_no":"+91\(self.mobileTextField.text ?? "")" ]


        Networking.sharedInstance.commonServerCall(apiName: "log_in", params: param as [String : AnyObject]?, httpMethod: HTTP_METHOD.POST) { (isSucceeded, response) in
            DispatchQueue.main.async {
                print(response)
                if isSucceeded == true {
                    if let status = response["status"] as? Int {
                        switch status {
                        case STATUS_CODES.SHOW_DATA:

                            let controller  = self.storyboard?.instantiateViewController(withIdentifier:"OTPController") as! OTPController
                            controller.mobileNo = "+91\(self.mobileTextField.text ?? "")"
                            self.navigationController?.pushViewController(controller, animated: true)
                            break
                        case STATUS_CODES.INVALID_ACCESS_TOKEN:
                            print(response["message"] as? String ?? "somthingWrong")
                            break
                        default:
                            break
                        }
                    }
                } else {
                    print(response["message"] as? String ?? "somthingWrong")
                }
            }
        }
        
        
        
    }
    
    func getAspectRatioValue(value:CGFloat) -> CGFloat {
        return (value / 375) * SCREEN_SIZE.width
    }
    
    
    
    
    
    
    
    
    
    func loginAction() {
//        let response = loc.startLocationService()
//        if(response.0 == true) {
//            self.resetLocationTimer()
//            getLocationTimer = Timer.scheduledTimer(timeInterval: 2.0, target: self, selector: #selector(self.startSession), userInfo: nil, repeats: true)
//        } else {
//            print(response.1)
//            UIAlertView(title: "", message: response.1, delegate: self, cancelButtonTitle: "OK").show()
//        }
    }
    
    //MARK: RESET LOCATION TIMER
    func resetLocationTimer() {
        if getLocationTimer != nil {
            getLocationTimer.invalidate()
            getLocationTimer = nil
        }
    }
    
    //MARK: START SESSION
//    @objc func startSession() {
//        let location = loc.getCurrentLocation()
//        if  location != nil && location?.coordinate.latitude != 0.0 {
//            self.resetLocationTimer()
////            self.startSessionHit(sessionId: "", location: location!,requestId: "")
//        }
//    }
    
}

