//
//  OTPController.swift
//  Tookan
//
//  Created by cl-macmini-45 on 31/05/17.
//  Copyright © 2017 Click Labs. All rights reserved.
//

import UIKit
import TookanTracker
import CoreLocation

class OTPController: UIViewController, TookanTrackerDelegate {

    @IBOutlet var subTitleLabel: UILabel!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var firstField: UITextField!
    @IBOutlet var secondField: UITextField!
    @IBOutlet var thirdField: UITextField!
    @IBOutlet var fourthField: UITextField!
    @IBOutlet var firstLine: UIView!
    @IBOutlet var secondLine: UIView!
    @IBOutlet var thirdLine: UIView!
    @IBOutlet var fourthLine: UIView!
    @IBOutlet var resendOtpButton: UIButton!
    @IBOutlet var verifyButton: UIButton!
    @IBOutlet var logoutButton: UIButton!
//    var keyboardToolbar:KeyboardToolbar!
    var mobileNo = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setTitleLabels()
        self.setTextFields()
        self.setButtons()
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.backgroundTouch))
        tap.numberOfTapsRequired = 1
        self.view.addGestureRecognizer(tap)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        UIApplication.shared.statusBarStyle = .default
        /*--------- Keyboard Toolbar -------------*/
//        keyboardToolbar = KeyboardToolbar()
//        keyboardToolbar.keyboardDelegate = self
//        keyboardToolbar.addButtons()
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillHide(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        UIApplication.shared.statusBarStyle = .lightContent
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    @objc func backgroundTouch() {
        self.view.endEditing(true)
    }
    
    func setTitleLabels() {
        /*================ Sign up title Label Design======================*/
        self.titleLabel.font = UIFont(name: "system", size: 20)
        self.titleLabel.textColor =  UIColor.black
        self.titleLabel.text = "Verify Mobile"
//        self.titleLabel.setLetterSpacing(value: 0.5)
        
        self.subTitleLabel.font = UIFont(name: "system", size: 14)
        self.subTitleLabel.textColor = UIColor.black
        self.subTitleLabel.text = "ENTER_OTP"
    }
    
    func setTextFields() {
        self.firstField.textColor = UIColor.black
        self.firstField.font = UIFont(name: "system", size: 20)
        self.firstField.delegate = self
        self.firstField.becomeFirstResponder()
        self.firstLine.backgroundColor = UIColor.lightGray
        
        self.secondField.textColor = UIColor.black
        self.secondField.delegate = self
        self.secondField.font = UIFont(name: "system", size: 20)
        self.secondLine.backgroundColor = UIColor.lightGray
        
        self.thirdField.textColor = UIColor.black
        self.thirdField.delegate = self
        self.thirdField.font = UIFont(name: "system", size: 20)
        self.thirdLine.backgroundColor = UIColor.lightGray
        
        self.fourthField.textColor = UIColor.black
        self.fourthField.delegate = self
        self.fourthField.font = UIFont(name: "system", size: 20)
        self.fourthLine.backgroundColor = UIColor.lightGray
    }
    
    func setButtons() {
        self.resendOtpButton.titleLabel?.font = UIFont(name: "system", size: 16)
        self.resendOtpButton.setTitleColor(UIColor.black, for: .normal)
        self.resendOtpButton.setTitle("TEXT.RESEND_OTP", for: .normal)
        
        /*================Verify Button Design======================*/
        self.verifyButton?.setTitle("TEXT.VERIFY", for: .normal)
        self.verifyButton?.titleLabel?.font = UIFont(name: "system", size: 16)
        self.verifyButton.backgroundColor = UIColor.blue
        self.verifyButton.setTitleColor(UIColor.white, for: .normal)
        self.verifyButton.layer.cornerRadius = 3.0
        
        /*================ logout Button ======================*/
        self.logoutButton.setTitle("TEXT.LOGOUT", for: .normal)
        self.logoutButton?.titleLabel?.font = UIFont(name: "system", size: 16)
        self.logoutButton.setTitleColor(UIColor.lightGray, for: .normal)
//        self.logoutButton.titleLabel?.setLetterSpacing(value: 0.5)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func sendOTPRequestToServer( ) {
//        ActivityIndicator.sharedInstance.showActivityIndicator()
        let otp = "\(self.firstField.text!)\(self.secondField.text!)\(self.thirdField.text!)\(self.fourthField.text!)"
        var params:[String:Any] = ["mobile_no": self.mobileNo]
        params["otp"] = otp
        Networking.sharedInstance.commonServerCall(apiName: "authenticate_otp", params: params as [String : AnyObject]?, httpMethod: HTTP_METHOD.POST) { (isSucceeded, response) in
            DispatchQueue.main.async {
//                ActivityIndicator.sharedInstance.hideActivityIndicator()
                print(response)
                if isSucceeded == true {
                    if let status = response["status"] as? Int {
                        switch status {
                        case STATUS_CODES.SHOW_DATA:
                            if self.navigationController != nil {
                                UserDefaults.standard.set(false, forKey: USER_DEFAULT.isSessionExpire)
                                TookanTracker.shared.delegate = self
//                                TookanTracker.shared.createSession(userID: userID, apiKey: apiKey, navigationController: self.navigationController!)
                            }
//                            if Singleton.sharedInstance.fleetDetails == nil {
//                                Singleton.sharedInstance.fleetDetails = FleetInfoDetails(json: [:])
//                            }
//                            if let data = response["data"] as? [String:Any] {
//                                if let registration_status = data["registration_status"] as? String {
//                                    Singleton.sharedInstance.fleetDetails.registrationStatus = Int(registration_status)!
//                                } else if let registration_status = data["registration_status"] as? Int {
//                                    Singleton.sharedInstance.fleetDetails.registrationStatus = registration_status
//                                }
//                            }
//                            let controller  = self.storyboard?.instantiateViewController(withIdentifier:STORYBOARD_ID.verificationStateController) as! VerificationStateController
//                            self.navigationController?.pushViewController(controller, animated: true)
                            break
                        case STATUS_CODES.INVALID_ACCESS_TOKEN:
//                            let alert = UIAlertController(title: "", message: response["message"] as? String, preferredStyle: UIAlertControllerStyle.alert)
//                            let actionPickup = UIAlertAction(title: TEXT.OK, style: UIAlertActionStyle.default, handler: { (UIAlertAction) -> Void in
//                                DispatchQueue.main.async(execute: { () -> Void in
//                                    Auxillary.logoutFromDevice()
//                                    NotificationCenter.default.removeObserver(self)
//                                })
//                            })
//                            alert.addAction(actionPickup)
//                            self.present(alert, animated: true, completion: nil)
                            break
                        default:
//                           Singleton.sharedInstance.showErrorMessage(error: (response["message"] as? String)!, isError: .error)
                            break
                        }
                    }
                } else {
//                    Singleton.sharedInstance.showErrorMessage(error: (response["message"] as? String)!, isError: .error)
                    self.firstField.text = ""
                    self.secondField.text = ""
                    self.thirdField.text = ""
                    self.fourthField.text = ""
                }
            }
        }
    }
    
//    func resendOTPRequestToServer( ) {
//        ActivityIndicator.sharedInstance.showActivityIndicator()
//        let params:[String:Any] = ["access_token": Singleton.sharedInstance.getAccessToken()]
//        NetworkingHelper.sharedInstance.commonServerCall(apiName: API_NAME.resend_signup_otp, params: params as [String : AnyObject]?, httpMethod: HTTP_METHOD.POST) { (isSucceeded, response) in
//            DispatchQueue.main.async {
//                ActivityIndicator.sharedInstance.hideActivityIndicator()
//                if isSucceeded == true {
//                    if let status = response["status"] as? Int {
//                        switch status {
//                        case STATUS_CODES.SHOW_DATA:
//                            Singleton.sharedInstance.showErrorMessage(error: (response["message"] as? String)!, isError: .success)
//                            break
//                        case STATUS_CODES.INVALID_ACCESS_TOKEN:
//                            let alert = UIAlertController(title: "", message: response["message"] as? String, preferredStyle: UIAlertControllerStyle.alert)
//                            let actionPickup = UIAlertAction(title: TEXT.OK, style: UIAlertActionStyle.default, handler: { (UIAlertAction) -> Void in
//                                DispatchQueue.main.async(execute: { () -> Void in
//                                    Auxillary.logoutFromDevice()
//                                    NotificationCenter.default.removeObserver(self)
//                                })
//                            })
//                            alert.addAction(actionPickup)
//                            self.present(alert, animated: true, completion: nil)
//                            break
//                        default:
//                            Singleton.sharedInstance.showErrorMessage(error: (response["message"] as? String)!, isError: .error)
//                        }
//                    }
//                } else {
//                    Singleton.sharedInstance.showErrorMessage(error: (response["message"] as? String)!, isError: .error)
//                }
//            }
//        }
//    }
    
    @IBAction func resendAction(_ sender: Any) {
        self.view.endEditing(true)
        self.firstField.text = ""
        self.secondField.text = ""
        self.thirdField.text = ""
        self.fourthField.text = ""
        UserDefaults.standard.set(false, forKey: USER_DEFAULT.isSessionExpire)
        TookanTracker.shared.delegate = self
//        TookanTracker.shared.createSession(userID: userID, apiKey: apiKey, navigationController: self.navigationController!)
//        TookanTracker.shared.delegate = self
//        TookanTracker.shared.getLocationCoordinates = { (coordinates) in
//            print("INAPP COORDINATES \(coordinates)")
//        }
//        self.resendOTPRequestToServer()
    }
//    var length: Int {
//        return self.characters.count
//    }
    
    internal func getCurrentCoordinates(_ location: CLLocation) {
        print("INAPP COORDINATES \(location)")
    }
    
    @IBAction func verifyAction(_ sender: Any) {
        guard self.firstField.text?.count == 1 else {
            print("PLEASE_ENTER_VALID1")
//            Singleton.sharedInstance.showErrorMessage(error: "\(ERROR_MESSAGE.PLEASE_ENTER_VALID) OTP", isError: .error)
            return
        }
        
        guard self.secondField.text?.count == 1 else {
            print("PLEASE_ENTER_VALID2")
//            Singleton.sharedInstance.showErrorMessage(error: "\(ERROR_MESSAGE.PLEASE_ENTER_VALID) OTP", isError: .error)
            return
        }
        
        guard self.thirdField.text?.count == 1 else {
            print("PLEASE_ENTER_VALID3")
//            Singleton.sharedInstance.showErrorMessage(error: "\(ERROR_MESSAGE.PLEASE_ENTER_VALID) OTP", isError: .error)
            return
        }
        
        guard self.fourthField.text?.count == 1 else {
            print("PLEASE_ENTER_VALID4")
//            Singleton.sharedInstance.showErrorMessage(error: "\(ERROR_MESSAGE.PLEASE_ENTER_VALID) OTP", isError: .error)
            return
        }
        
        self.sendOTPRequestToServer()
    }
    @IBAction func logoutAction(_ sender: Any) {
        /*------------- Firebase ---------------*/
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: UIAlertController.Style.actionSheet)
        let confirmAction = UIAlertAction(title: "TEXT.LOGOUT", style: UIAlertAction.Style.destructive) { (confirmed) -> Void in
//            self.sendRequestForLogout()
            self.navigationController?.popViewController(animated: true)
        }
        
        let cancelAction = UIAlertAction(title: "TEXT.CANCEL", style: UIAlertAction.Style.cancel, handler: {(UIAlertAction) in
        })
        alertController.addAction(confirmAction)
        alertController.addAction(cancelAction)
        self.present(alertController, animated: true, completion: nil)
    }
    
//    func sendRequestForLogout() {
//        if let accessToken = UserDefaults.standard.value(forKey: USER_DEFAULT.accessToken) as? String {
//            ActivityIndicator.sharedInstance.showActivityIndicator((self.navigationController?.visibleViewController)!)
//            NetworkingHelper.sharedInstance.commonServerCall(apiName: API_NAME.logout, params: [
//                "access_token":accessToken as AnyObject], httpMethod: HTTP_METHOD.POST, receivedResponse: { (isSucceeded, response) in
//                    DispatchQueue.main.async {
//                        ActivityIndicator.sharedInstance.hideActivityIndicator()
//                        if isSucceeded == true {
//                            switch(response["status"] as! Int) {
//                            case STATUS_CODES.SHOW_DATA, STATUS_CODES.INVALID_ACCESS_TOKEN:
//                                NotificationCenter.default.removeObserver(self)
//                                Auxillary.logoutFromDevice()
//                                break
//                            default:
//                                Singleton.sharedInstance.showErrorMessage(error: response["message"] as! String, isError: .error)
//                                break
//                            }
//                        } else {
//                            Singleton.sharedInstance.showErrorMessage(error: response["message"] as! String, isError: .error)
//                        }
//                    }
//            })
//        } else {
//            NotificationCenter.default.removeObserver(self)
//            Auxillary.logoutFromDevice()
//        }
//    }
    
    @objc func keyboardWillShow(_ notification : Foundation.Notification){
//        let value: NSValue = (notification as NSNotification).userInfo![UIKeyboardFrameEndUserInfoKey] as! NSValue
//        Singleton.sharedInstance.keyboardSize = value.cgRectValue.size
        //let keyboardSize = value.cgRectValue.size
    }
    
    @objc func keyboardWillHide(_ notification: Foundation.Notification) {
        
    }
    
    func getSessionId(sessionId: String) {
        print("SeSSiOn_ID: \(sessionId)")
    }
}

extension OTPController:UITextFieldDelegate {
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
//        textField.inputAccessoryView = keyboardToolbar
//        keyboardToolbar.currentTextField = textField
        return true
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let updatedText = textField.text!
        var updatedString:NSString = "\(updatedText)" as NSString
        updatedString = updatedString.replacingCharacters(in: range, with: string) as NSString
        print(updatedString)
        if updatedString.length >= 1 {
            self.updateTextField(updatedTextField: textField, updatedText:updatedString as String)
        }
        return false
    }
    
    func updateTextField(updatedTextField:UITextField, updatedText:String) {
        updatedTextField.text = updatedText
        updatedTextField.resignFirstResponder()
        switch(updatedTextField) {
        case self.firstField:
            if self.secondField.text?.count == 0 {
                self.secondField.becomeFirstResponder()
            }
            break
        case self.secondField:
            if self.thirdField.text?.count == 0 {
                self.thirdField.becomeFirstResponder()
            }
            break
        case self.thirdField:
            if self.fourthField.text?.count == 0 {
                self.fourthField.becomeFirstResponder()
            }
            break
        case self.fourthField:
            self.fourthField.resignFirstResponder()
            self.verifyAction("action")
            break
        default:
            break
        }
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        textField.text = ""
        switch(textField) {
        case self.firstField:
            self.firstLine.backgroundColor = UIColor.blue
            break
        case self.secondField:
            self.secondLine.backgroundColor = UIColor.blue
            break
        case self.thirdField:
            self.thirdLine.backgroundColor = UIColor.blue
            break
        case self.fourthField:
            self.fourthLine.backgroundColor = UIColor.blue
            break
        default:
            break
        }
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        switch(textField) {
        case self.firstField:
            self.firstLine.backgroundColor = UIColor.lightGray
            break
        case self.secondField:
            self.secondLine.backgroundColor = UIColor.lightGray
            break
        case self.thirdField:
            self.thirdLine.backgroundColor = UIColor.lightGray
            break
        case self.fourthField:
            self.fourthLine.backgroundColor = UIColor.lightGray
            break
        default:
            break
        }
    }
}

//extension OTPController:KeyboardDelegate {
//    func nextFromKeyboard(_ nextField: AnyObject) {
//        let textField = nextField as! UITextField
//        switch(textField) {
//        case self.firstField:
//            self.secondField.becomeFirstResponder()
//            break
//        case self.secondField:
//            self.thirdField.becomeFirstResponder()
//            break
//        case self.thirdField:
//            self.fourthField.becomeFirstResponder()
//            break
//        case self.fourthField:
//            self.view.endEditing(true)
//            break
//        default:
//            break
//        }
//    }
//    
//    func prevFromKeyboard(_ prevField: AnyObject) {
//        let textField = prevField as! UITextField
//        switch(textField) {
//        case self.firstField:
//            break
//        case self.secondField:
//            self.firstField.becomeFirstResponder()
//            break
//        case self.thirdField:
//            self.secondField.becomeFirstResponder()
//            break
//        case self.fourthField:
//            self.thirdField.becomeFirstResponder()
//            break
//        default:
//            break
//        }
//    }
//    
//    func doneFromKeyboard() {
//        // self.signScrollView.setContentOffset(CGPointMake(0, 0), animated: true)
//        self.view.endEditing(true)
//    }
//}

