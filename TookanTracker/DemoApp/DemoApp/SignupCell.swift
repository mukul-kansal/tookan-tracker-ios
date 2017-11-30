//
//  SignupCell.swift
//  Tookan
//
//  Created by cl-macmini-45 on 30/05/17.
//  Copyright © 2017 Click Labs. All rights reserved.
//

import UIKit

class SignupCell: UITableViewCell {

    @IBOutlet var countryField: UITextField!
    @IBOutlet var signupField: UITextField!
    @IBOutlet var leadingConstraint: NSLayoutConstraint!

    override func awakeFromNib() {
        super.awakeFromNib()
        self.signupField.textColor = UIColor.black
        self.signupField.font = self.signupField.font?.withSize(16)
        
        self.countryField.textColor = UIColor.black
        self.countryField.font = self.signupField.font?.withSize(16)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    
    func setNameField() {
        self.signupField.placeholder = "Your name"
        self.signupField.keyboardType = UIKeyboardType.default
        self.signupField.autocapitalizationType = .sentences
        self.signupField.isSecureTextEntry = false
        self.leadingConstraint.constant = 0.0
        self.countryField.isHidden = true
    }
    
    func setEmailField() {
        self.signupField.placeholder = "Your email"
        self.signupField.keyboardType = UIKeyboardType.emailAddress
        self.signupField.autocapitalizationType = .none
        self.signupField.isSecureTextEntry = false
        self.leadingConstraint.constant = 0.0
        self.countryField.isHidden = true
    }
    
    func setPhoneField() {
        self.signupField.placeholder = "Your phone no"
        self.signupField.keyboardType = UIKeyboardType.phonePad
        self.signupField.autocapitalizationType = .none
        self.signupField.isSecureTextEntry = false
        self.leadingConstraint.constant = 0.0
        self.countryField.isHidden = true
//        self.countryField.placeholder = "+1"
        
//        self.countryField.rightViewMode = UITextFieldViewMode.always
//        let imageView = UIImageView(image: #imageLiteral(resourceName: "smallDownArrow"))
//        self.countryField.rightView = imageView
    }
    
    func setPasswordField() {
        self.signupField.placeholder = "Set password"
        self.signupField.keyboardType = UIKeyboardType.default
        self.signupField.autocapitalizationType = .none
        self.signupField.isSecureTextEntry = true
        self.leadingConstraint.constant = 0.0
        self.countryField.isHidden = true
    }
    
    func setConfirmPasswordField() {
        self.signupField.placeholder = "Confirm password"
        self.signupField.keyboardType = UIKeyboardType.default
        self.signupField.autocapitalizationType = .none
        self.signupField.isSecureTextEntry = true
        self.leadingConstraint.constant = 0.0
        self.countryField.isHidden = true
    }
}
