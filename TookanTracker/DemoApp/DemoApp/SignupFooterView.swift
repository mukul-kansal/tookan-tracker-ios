//
//  SignupFooterView.swift
//  Tookan
//
//  Created by cl-macmini-45 on 30/05/17.
//  Copyright © 2017 Click Labs. All rights reserved.
//

import UIKit

class SignupFooterView: UIView {

    @IBOutlet var termAndConditionButton: UIButton!
    @IBOutlet var signupButton: UIButton!
    @IBOutlet var signinButton: UIButton!
    
    override func awakeFromNib() {
       
        /*================ Signup Button ======================*/
//        let message = NSMutableAttributedString(string: TEXT.TERM_CONDITIONS_MESSAGE, attributes: [NSForegroundColorAttributeName:COLOR.NEW_USER_COLOR, NSFontAttributeName:UIFont(name: UIFont().MontserratLight, size: FONT_SIZE.medium)!])
//
//        let termAndConditions = NSMutableAttributedString(string: " \(TEXT.TERM_CONDITIONS)", attributes: [NSForegroundColorAttributeName:COLOR.themeForegroundColor, NSFontAttributeName:UIFont(name: UIFont().MontserratLight, size: FONT_SIZE.medium)!])
        
//        message.append(termAndConditions)
//        self.termAndConditionButton.setAttributedTitle(message, for: .normal)
//        self.termAndConditionButton.titleLabel?.numberOfLines = 0
        
        /*================Setting Signup Button Design======================*/
        self.signupButton?.setTitle("Sign up", for: .normal)
        self.signupButton?.titleLabel?.font = self.signupButton.titleLabel?.font.withSize(16)
        self.signupButton.backgroundColor = UIColor(red: 70/255, green: 149/255, blue: 246/255, alpha: 1.0)
        self.signupButton.setTitleColor(UIColor.white, for: .normal)
        self.signupButton.layer.cornerRadius = 3.0
        
        /*================ Signup Button ======================*/
        let attributedTitle = NSMutableAttributedString(string: "Have an account? ", attributes: [NSAttributedString.Key.foregroundColor:UIColor(red: 153/255, green: 153/255, blue: 153/255, alpha: 1.0), NSAttributedString.Key.font:self.signinButton.titleLabel?.font.withSize(14) ?? 14])
        attributedTitle.addAttribute(NSAttributedString.Key.kern, value: CGFloat(0.5), range: NSRange(location: 0, length: attributedTitle.length))
        
        let signinTitle = NSMutableAttributedString(string: "Sign in", attributes: [NSAttributedString.Key.foregroundColor:UIColor(red: 70/255, green: 149/255, blue: 246/255, alpha: 1.0), NSAttributedString.Key.font:self.signinButton.titleLabel?.font.withSize(14) ?? 14])
        signinTitle.addAttribute(NSAttributedString.Key.kern, value: CGFloat(0.5), range: NSRange(location: 0, length: signinTitle.length))
        
        attributedTitle.append(signinTitle)
        self.signinButton.setAttributedTitle(attributedTitle, for: .normal)
    }
    
}
