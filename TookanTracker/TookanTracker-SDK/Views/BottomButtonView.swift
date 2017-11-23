//
//  BottomButtonView.swift
//  Tookan
//
//  Created by Rakesh Kumar on 12/31/15.
//  Copyright © 2015 Click Labs. All rights reserved.
//

import UIKit
protocol BottomButtonDelegate {
    func dismissComplete()
    func sliderShareAction()
    func sliderRequestAction()
    func stopSharingOrTracking()
}

class BottomButtonView: UIView, SliderDelegate {

    @IBOutlet weak var acitivityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var pleaseWaitLabel: UILabel!
    @IBOutlet weak var dividerView: UIView!
    @IBOutlet weak var stopButton: UIButton!
    var delegate:BottomButtonDelegate!
    var sliderRequestShareButton:SliderButton!
    var leftMargin:CGFloat = 0
    var sliderHeight:CGFloat = 66
    var bottomMargin:CGFloat = 15
    let stopButtonHeight:CGFloat = 50

    override func awakeFromNib() {
        pleaseWaitLabel.text = "Please wait..."
    }
    
    func setView(_ acceptButtonTitle:String, rejectButtonTitle:String, stopButtonTitle:String, sliderType:Bool) {
       setLayerAndBorder()
        if(sliderType == true) {
            self.stopButton.isHidden = true
            self.pleaseWaitLabel.isHidden = true
            setSliderButton(acceptButtonTitle, rejectText: rejectButtonTitle)
        } else {
            if(self.sliderRequestShareButton != nil) {
                self.sliderRequestShareButton.isHidden = true
            }
            self.stopButton.isHidden = false
            self.stopButton.setTitle(acceptButtonTitle, for: UIControlState())
        }
    }
    
    func setLayerAndBorder() {
        self.stopButton.setTitleColor(UIColor().stopButtonTitleColor, for: UIControlState())
        self.stopButton.backgroundColor = UIColor().stopButtonColor
        self.stopButton.layer.cornerRadius = stopButtonHeight / 2
    }
    
    //MARK:
    func setSliderButton(_ acceptText:String,rejectText:String) {
        if(sliderRequestShareButton == nil) {
            sliderRequestShareButton = UINib(nibName: "SliderButton", bundle: frameworkBundle).instantiate(withOwner: self, options: nil)[0] as! SliderButton
            sliderRequestShareButton.delegate = self
        } else {
            sliderRequestShareButton.isHidden = false
        }
        sliderRequestShareButton.frame = CGRect(x: leftMargin, y: self.frame.height - sliderHeight - bottomMargin , width: self.frame.width - leftMargin*2 , height: sliderHeight)
        sliderRequestShareButton.setSliderButtonWith(0, directionForButton: SliderButton.PAN_GESTURE_DIRECTION.center, rightSlideText: acceptText, leftSlideText: rejectText)
        self.addSubview(sliderRequestShareButton)
    }
    
    //MARK: Button Action
    @IBAction func stopAction(_ sender: AnyObject) {
        delegate.stopSharingOrTracking()
    }
    
    //MARK: Slider Delegate Methods
    func sliderRequest() {
        delegate.sliderRequestAction()
    }
    
    func sliderShare() {
        print("Share")
        delegate.sliderShareAction()
    }
    
    func isAllowForSliding(_ sliderButton: UIView) -> Bool {
        return true
    }

}

