//
//  SessionDetailView.swift
//  Tracker
//
//  Created by cl-macmini-45 on 06/10/16.
//  Copyright © 2016 clicklabs. All rights reserved.
//

import UIKit

protocol SessionViewDelegate {
    func dismissSessionView()
    func delegateStartTracking(sessionId:String)
}

@objcMembers class SessionDetailView: UIView, UITextFieldDelegate {
    
    @IBOutlet weak var popupBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var alertPopupView: UIView!
    @IBOutlet weak var startButton: UIButton!
    @IBOutlet weak var buttonBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var trackingField: UITextField!
    let buttonHeight:CGFloat = 58
    let bottomMarginForButton:CGFloat = 25
    let bottomMarginForView:CGFloat = 96
    let alertpopupHeight:CGFloat = 150
    var delegate:SessionViewDelegate!
    var isKeypadOpen = false
    
    func setLayerAndCornerRadius() {
        startButton.layer.cornerRadius = buttonHeight/2
        alertPopupView.layer.cornerRadius = 12
        alertPopupView.alpha = 0.0
    }
    
    func setSessionView() {
        self.setLayerAndCornerRadius()
        self.startAnimation()
        self.trackingField.delegate = self
        /*-------------- UITapGesture -----------*/
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.backgroundTouch))
        tap.numberOfTapsRequired = 1
        self.addGestureRecognizer(tap)
        /*---------------------------------------*/
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillShow(_:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillHide(_:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    func startAnimation() {
        self.setNeedsUpdateConstraints()
        UIView.animate(withDuration: 0.2, delay: 0.0, options: UIViewAnimationOptions.curveEaseIn, animations: { () -> Void in
            self.startButton.transform = CGAffineTransform(translationX: 0, y: -(self.bottomMarginForButton + self.buttonHeight))
            }, completion: { void in
                UIView.animate(withDuration: 1.0, delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: 2.0, options: UIViewAnimationOptions(), animations: { () -> Void in
                    self.alertPopupView.alpha = 1.0
                    self.alertPopupView.transform = CGAffineTransform(translationX: 0, y: -(self.alertpopupHeight + self.bottomMarginForView))
                    }, completion: nil)
        })
    }
    
    func backgroundTouch() {
        if(isKeypadOpen == false) {
            UIView.animate(withDuration: 0.3, delay: 0.0, options: UIViewAnimationOptions.curveEaseOut, animations: { () -> Void in
                self.alertPopupView.transform = CGAffineTransform.identity
                self.alertPopupView.alpha = 0.0
                }, completion: { finished in
                    UIView.animate(withDuration: 0.3, delay: 0.0, options: UIViewAnimationOptions.curveEaseOut, animations: { () -> Void in
                        self.startButton.transform = CGAffineTransform.identity
                        }, completion: { finished in
                            self.removeKeypadObserver()
                            self.delegate.dismissSessionView()
                    })
            })
        } else {
            self.endEditing(true)
            self.isKeypadOpen = false
        }
    }
    
    func removeKeypadObserver() {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    
    @IBAction func startTrackingAction(_ sender: AnyObject) {
        self.startTracking()
    }
    
    func startTracking() {
        guard trackingField.text?.trimText != "" else {
            return 
        }
        
        if isKeypadOpen == true {
            self.endEditing(true)
            self.isKeypadOpen = false
        }
        
        UIView.animate(withDuration: 0.3, delay: 0.0, options: UIViewAnimationOptions.curveEaseOut, animations: { () -> Void in
            self.alertPopupView.transform = CGAffineTransform.identity
            self.alertPopupView.alpha = 0.0
            }, completion: { finished in
                UIView.animate(withDuration: 0.3, delay: 0.0, options: UIViewAnimationOptions.curveEaseOut, animations: { () -> Void in
                    self.startButton.transform = CGAffineTransform.identity
                    }, completion: { finished in
                        self.removeKeypadObserver()
                        self.delegate.delegateStartTracking(sessionId: (self.trackingField.text?.trimText)!)
                })
        })
    }
    
    
    //MARK: UITextFieldDelegate
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.startTracking()
        return true
    }
    
    
    //MARK: Keyboard Functions
    func keyboardWillShow(_ notification : Foundation.Notification){
        //        let info = notification.userInfo
        let value: NSValue = (notification as NSNotification).userInfo![UIKeyboardFrameEndUserInfoKey] as! NSValue //info.value(forKey: UIKeyboardFrameEndUserInfoKey) as! NSValue
        let duration = (notification as NSNotification).userInfo![UIKeyboardAnimationDurationUserInfoKey] as! Double
        let curve = (notification as NSNotification).userInfo![UIKeyboardAnimationCurveUserInfoKey] as! UInt
        
        let keyboardSize: CGSize = value.cgRectValue.size
        popupBottomConstraint.constant = popupBottomConstraint.constant + keyboardSize.height
        buttonBottomConstraint.constant = buttonBottomConstraint.constant + keyboardSize.height
        self.setNeedsUpdateConstraints()
        self.isKeypadOpen = true
        UIView.animate(withDuration: duration, delay: 0.0, options: UIViewAnimationOptions(rawValue: curve), animations: { () -> Void in
            self.layoutIfNeeded()
            }, completion: { void in
        })
    }
    
    func keyboardWillHide(_ notification: Foundation.Notification) {
        self.isKeypadOpen = false
        let duration = (notification as NSNotification).userInfo![UIKeyboardAnimationDurationUserInfoKey] as! Double
        let curve = (notification as NSNotification).userInfo![UIKeyboardAnimationCurveUserInfoKey] as! UInt
        popupBottomConstraint.constant = -alertpopupHeight
        buttonBottomConstraint.constant = -buttonHeight
        self.setNeedsUpdateConstraints()
        UIView.animate(withDuration: duration, delay: 0.0, options: UIViewAnimationOptions(rawValue: curve), animations: { () -> Void in
            self.layoutIfNeeded()
            }, completion: nil)
    }

}
