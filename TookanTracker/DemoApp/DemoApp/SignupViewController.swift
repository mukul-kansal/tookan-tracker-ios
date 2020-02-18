//
//  SignupViewController.swift
//  Tookan
//
//  Created by cl-macmini-45 on 30/05/17.
//  Copyright © 2017 Click Labs. All rights reserved.
//

import UIKit
import TookanTracker

enum SIGNUP_FIELD:Int {
    case name = 0
    case email
    case phone
    case password
//    case confirmPassword
    
}

class SignupViewController: UIViewController {
    
    @IBOutlet var bottomConstraint: NSLayoutConstraint!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var signupTable: UITableView!
    var footerView:SignupFooterView?
//    var keyboardToolbar:KeyboardToolbar!
    var signupVCModel = SignupVCModel()
    var countryCodeAndCountryName:[String:Any] = [:] //Dictionary<String, Any>()
    var selectedLocale:String!
    let tableFooterHeight:CGFloat = 188.0
//    var drowDownWithSearch:TemplateController!
    
    //MARK: UIViewController Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setTableView()
        self.setTitleLabel()
//        self.selectedLocale = Auxillary.currentDialingCode().uppercased()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        UIApplication.shared.statusBarStyle = .default
        /*--------- Keyboard Toolbar -------------*/
//        self.keyboardToolbar = KeyboardToolbar()
//        self.keyboardToolbar.keyboardDelegate = self
//        self.keyboardToolbar.addButtons()
        self.addingObserver()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        UIApplication.shared.statusBarStyle = .lightContent
        self.removingObserver()
    }
    
    func setTableView() {
        self.signupTable.delegate = self
        self.signupTable.dataSource = self
        self.signupTable.register(UINib(nibName: "SignupCell", bundle: nil), forCellReuseIdentifier: "SignupCell")
        self.signupTable.rowHeight = UITableView.automaticDimension
        self.setFooterView()
    }

    func setFooterView() {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: self.signupTable.frame.width, height: self.tableFooterHeight))
        self.footerView = UINib(nibName: "SignupFooterView", bundle: nil).instantiate(withOwner: self, options: nil)[0] as? SignupFooterView
        self.footerView?.frame = CGRect(x: 0, y: 0, width: self.signupTable.frame.width, height: self.tableFooterHeight)
        view.addSubview(self.footerView!)
        self.signupTable.tableFooterView = view
//        self.footerView?.termAndConditionButton.addTarget(self, action: #selector(self.acceptTermConditionAction), for: .touchUpInside)
        self.footerView?.signupButton.addTarget(self, action: #selector(self.signupAction), for: .touchUpInside)
        self.footerView?.signinButton.addTarget(self, action: #selector(self.signinAction), for: .touchUpInside)
    }
    
    func setTitleLabel() {
        /*================ Sign up title Label Design======================*/
        self.titleLabel.font = self.titleLabel.font.withSize(16)
        self.titleLabel.textColor =  UIColor(red: 0, green: 0, blue: 0, alpha: 0.5)
        self.titleLabel.text = "Sign up for a new account!"
//        self.titleLabel.setLetterSpacing(value: 0.5)
    }
    
    func addingObserver() {
        /*--------- Observers -------------*/
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    func removingObserver() {
        NotificationCenter.default.removeObserver(self, name:UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
//    func acceptTermConditionAction() {
//        let url = NSURL(string: TERM_CONDITIONS_LINK)!
//        if UIApplication.shared.canOpenURL(url as URL) == true {
//            UIApplication.shared.openURL(url as URL)
//        }
//    }
    
//    func showCountryPicker() {
//        self.view.endEditing(true)
//        var countryArray = [String]()
//        for locale in NSLocale.locales() {
//            countryArray.append(locale.countryName)
//            self.countryCodeAndCountryName[locale.countryName] = locale.countryCode
//        }
//        guard countryArray.count > 0 else {
//            Singleton.sharedInstance.showErrorMessage(error: ERROR_MESSAGE.NO_DATA_FOUND, isError: .error)
//            return
//        }
//        self.drowDownWithSearch = TemplateController()
//        self.drowDownWithSearch.itemArray = countryArray
//        self.drowDownWithSearch.placeholderValue = TEXT.COUNTRY
//        self.drowDownWithSearch.delegate = self
//        self.drowDownWithSearch.modalPresentationStyle = .overCurrentContext
//        self.removingObserver()
//        self.present(self.drowDownWithSearch, animated: false, completion: nil)
//    }
    
    @objc func signupAction() {
        self.view.endEditing(true)
        if self.checkValidation() == true {
            self.sendSignupRequestToServer()
        }
    }
    
    func sendSignupRequestToServer() {
//        ActivityIndicator.sharedInstance.showActivityIndicator()
        var params:[String:Any] = ["role": 0]
        params["name"] = self.signupVCModel.username
        params["email"] = self.signupVCModel.useremail
        params["phone"] = self.signupVCModel.userPhone
        params["gender"] = "male"
        params["password"] = self.signupVCModel.password
        
        print(params)
        Networking.sharedInstance.commonServerCall(apiName: "sign_up", params: params as [String : AnyObject], httpMethod: "POST") { (isSucceeded, response) in
            DispatchQueue.main.async {
                print(response)
                if isSucceeded == true {
                    if let status = response["status"] as? Int {
                        switch status {
                        case STATUS_CODES.SHOW_DATA:
                            UserDefaults.standard.set(false, forKey: USER_DEFAULT.isSessionExpire)
                            UserDefaults.standard.set(self.signupVCModel.useremail, forKey: USER_DEFAULT.userId)
                            TookanTracker.shared.createSession(userID:self.signupVCModel.useremail, isUINeeded: false, navigationController:self.navigationController!)
                            break
                        case STATUS_CODES.INVALID_ACCESS_TOKEN:
                            UIAlertView(title: "", message: response["message"] as! String, delegate: nil, cancelButtonTitle: "OK").show()
                            print(response["message"] as? String ?? "somthingWrong")
                            break
                        default:
                            UIAlertView(title: "", message: response["message"] as! String, delegate: nil, cancelButtonTitle: "OK").show()
                            break
                        }
                    }
                } else {
                    print(response["message"] as? String ?? "somthingWrong")
                }
            }
        }
        
//        params["device_token"] = Singleton.sharedInstance.getDeviceToken()
//        NetworkingHelper.sharedInstance.commonServerCall(apiName: API_NAME.fleet_signup, params: params as [String : AnyObject]?, httpMethod: HTTP_METHOD.POST) { (isSucceeded, response) in
//            DispatchQueue.main.async {
//                ActivityIndicator.sharedInstance.hideActivityIndicator()
//                if isSucceeded == true {
//                    if let data = response["data"] as? [String:Any] {
//                        if let fleetInfo = data["fleet_info"] as? [String:Any] {
//                            Singleton.sharedInstance.fleetDetails = FleetInfoDetails(json: fleetInfo as NSDictionary)
//                        } else {
//                            Singleton.sharedInstance.fleetDetails = FleetInfoDetails(json: [:])
//                            Singleton.sharedInstance.fleetDetails.registrationStatus = DRIVER_STATE.otp_pending.rawValue
//                        }
//
//                        if let accessToken = data["access_token"] as? String {
//                            if let registration_status = data["registration_status"] as? String {
//                                Singleton.sharedInstance.fleetDetails.registrationStatus = Int(registration_status)!
//                            } else if let registration_status = data["registration_status"] as? Int {
//                                Singleton.sharedInstance.fleetDetails.registrationStatus = registration_status
//                            }
//                            UserDefaults.standard.set(accessToken, forKey: USER_DEFAULT.accessToken)
//                            let driverState = DRIVER_STATE(rawValue: Singleton.sharedInstance.fleetDetails.registrationStatus!)
//                            switch driverState! {
//                            case DRIVER_STATE.acknowledged:
//                                UserDefaults.standard.set(Singleton.sharedInstance.getVersion(), forKey: USER_DEFAULT.appVersion)
//                                Singleton.sharedInstance.gotoHomeStoryboard()
//                            case DRIVER_STATE.otp_pending:
//                                self.gotoOTPController()
//                            default:
//                                self.gotoVerificationStateController()
//                                break
//                            }
//                        }
//                    }
//                } else {
//                    Singleton.sharedInstance.showErrorMessage(error: (response["message"] as? String)!, isError: .error)
//                }
//            }
//        }
    }
    
//    func gotoOTPController() {
//        let controller  = self.storyboard?.instantiateViewController(withIdentifier:STORYBOARD_ID.otpController) as! OTPController
//        self.navigationController?.pushViewController(controller, animated: true)
//    }
    
//    func gotoVerificationStateController() {
//        let controller  = self.storyboard?.instantiateViewController(withIdentifier:STORYBOARD_ID.verificationStateController) as! VerificationStateController
//        self.navigationController?.pushViewController(controller, animated: true)
//    }
    
    func validateEmail(_ candidate: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,6}"
        return NSPredicate(format: "SELF MATCHES %@", emailRegex).evaluate(with: candidate)
    }
    
    func checkValidation() -> Bool {
        guard self.signupVCModel.username.count > 0 else {
            UIAlertView(title: "", message: "Please enter name", delegate: nil, cancelButtonTitle: "OK").show()
            return false
        }
        
        guard self.validateEmail(self.signupVCModel.useremail) == true else {
            UIAlertView(title: "", message: "Please enter valid Email", delegate: nil, cancelButtonTitle: "OK").show()
            return false
        }
        
        let lengthOfNumber = self.signupVCModel.userPhone.count
        guard lengthOfNumber >= 8 && lengthOfNumber <= 16  else {
            UIAlertView(title: "", message: "Please enter valid Phone Number", delegate: nil, cancelButtonTitle: "OK").show()
            return false
        }
        
        guard self.signupVCModel.password.count >= 6 else {
            UIAlertView(title: "", message: "Password must contain atleast 6 characters", delegate: nil, cancelButtonTitle: "OK").show()
            return false
        }
        
//        guard self.signupVCModel.password == self.signupVCModel.confirmPassword else {
//            UIAlertView(title: "", message: ", delegate: nil, cancelButtonTitle: "OK").show()
//            return false
//        }
        
        return true
        
    }
    
    @objc func signinAction() {
        _ = self.navigationController?.popViewController(animated: true)
    }
    
    @objc func keyboardWillShow(_ notification : Foundation.Notification){
        let value: NSValue = (notification as NSNotification).userInfo![UIResponder.keyboardFrameEndUserInfoKey] as! NSValue
//        Singleton.sharedInstance.keyboardSize = value.cgRectValue.size
        let keyboardSize = value.cgRectValue.size
        self.bottomConstraint.constant = keyboardSize.height
    }
    
    @objc func keyboardWillHide(_ notification: Foundation.Notification) {
        self.bottomConstraint.constant = 0
    }
}


//MARK: TemplateControllerDelegate Methods
//extension SignupViewController:TemplateControllerDelegate {
//    func selectedValue(value: String, tag:Int, isDirectDismiss: Bool) {
//        if isDirectDismiss == false {
//            var selectedCountryCode = ""
//            if let locale = self.countryCodeAndCountryName[value] as? String {
//                if dialingCode[locale] != nil {
//                    self.selectedLocale = locale
//                    selectedCountryCode = "+\(dialingCode[self.selectedLocale]!)"
//                } else {
//                    selectedCountryCode = "+1"
//                }
//            } else {
//                selectedCountryCode = "+1"
//            }
//
//            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2, execute: {
//                if let cell = self.signupTable.cellForRow(at: IndexPath(row: 2, section: 0)) as? SignupCell {
//                    cell.countryField.text = selectedCountryCode
//                    self.signupVCModel.countryCode = selectedCountryCode
//                    cell.signupField.becomeFirstResponder()
//                }
//            })
//        }
//
//        self.addingObserver()
//        self.drowDownWithSearch = nil
//    }
//}

//MARK: UITableViewDelegates
extension SignupViewController:UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 4
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SignupCell") as! SignupCell
        cell.signupField.tag = indexPath.row
        cell.signupField.delegate = self
        cell.signupField.text = ""
        let fieldType = SIGNUP_FIELD(rawValue: indexPath.row)
        switch fieldType! {
        case .name:
            cell.setNameField()
            cell.signupField.text = self.signupVCModel.username
        case .email:
            cell.setEmailField()
            cell.signupField.text = self.signupVCModel.useremail
        case .phone:
            cell.countryField.tag = 99
            cell.countryField.delegate = self
            cell.setPhoneField()
            
//            if(self.selectedLocale.length > 0) {
//                if dialingCode[self.selectedLocale] != nil {
//                    cell.countryField.text = "+\(dialingCode[self.selectedLocale]!)"
//                } else {
//                    cell.countryField.text = "+1"
//                    self.selectedLocale = "US"
//                }
//            } else {
//                cell.countryField.text = "+1"
//                self.selectedLocale = "US"
//            }
            self.signupVCModel.countryCode = cell.countryField.text!
            cell.signupField.text = self.signupVCModel.userPhone
        case .password:
            cell.setPasswordField()
            cell.signupField.text = self.signupVCModel.password
//        case .confirmPassword:
//            cell.setConfirmPasswordField()
//            cell.signupField.text = self.signupVCModel.confirmPassword
//        case .country:
//            cell.countryField.text = self.signupVCModel.countryCode
//            break
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
    }
}

//extension SignupViewController:KeyboardDelegate {
//    func nextFromKeyboard(_ nextField: AnyObject) {
//        let textField = nextField as! UITextField
//        let fieldType = SIGNUP_FIELD(rawValue: textField.tag)
//        switch(fieldType!) {
//        case .name, .email, .phone, .password:
//            self.signupTable.scrollToRow(at: IndexPath(row: textField.tag + 1, section: 0), at: .bottom, animated: true)
//            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2, execute: {
//                if let cell = self.signupTable.cellForRow(at: IndexPath(row: textField.tag + 1, section: 0)) as? SignupCell {
//                    cell.signupField.becomeFirstResponder()
//                }
//            })
//            break
//        case .confirmPassword:
//            break
//        case .country:
//            break
//      }
//    }
//
//    func prevFromKeyboard(_ prevField: AnyObject) {
//        let textField = prevField as! UITextField
//        let fieldType = SIGNUP_FIELD(rawValue: textField.tag)
//        switch(fieldType!) {
//        case .name:
//
//            break
//        case .confirmPassword, .email, .phone, .password:
//            self.signupTable.scrollToRow(at: IndexPath(row: textField.tag - 1, section: 0), at: .bottom, animated: true)
//           DispatchQueue.main.asyncAfter(deadline: .now() + 0.2, execute: {
//                if let cell = self.signupTable.cellForRow(at: IndexPath(row: textField.tag - 1, section: 0)) as? SignupCell {
//                    cell.signupField.becomeFirstResponder()
//                }
//           })
//            break
//        case .country:
//            break
//        }
//
//    }
//
//    func doneFromKeyboard() {
//        self.view.endEditing(true)
//    }
//}

extension SignupViewController:UITextFieldDelegate {
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
//        textField.inputAccessoryView = self.keyboardToolbar
//        self.keyboardToolbar.currentTextField = textField
//        let fieldType = SIGNUP_FIELD(rawValue: textField.tag)
//        if fieldType == SIGNUP_FIELD.country {
//            self.showCountryPicker()
            return true
        }
        
    
    
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        let fieldType = SIGNUP_FIELD(rawValue: textField.tag)
        switch(fieldType!) {
        case .name:
            self.signupVCModel.username = (textField.text)!
            break
        case .email:
            self.signupVCModel.useremail = (textField.text)!
            break
        case .phone:
            self.signupVCModel.userPhone = (textField.text)!
            break
        case .password:
            self.signupVCModel.password = (textField.text)!
            break
//        case .confirmPassword:
//            self.signupVCModel.confirmPassword = (textField.text)!
//            break
//        case .country:
//            self.signupVCModel.countryCode = (textField.text)!
//            break
//        }
    }
}
}
