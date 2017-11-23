//
//  SliderButton.swift
//  CustomSliderButton
//
//  Created by Rakesh Kumar on 12/29/15.
//  Copyright © 2015 Click Labs. All rights reserved.
//

import UIKit

protocol SliderDelegate {
    func sliderRequest()
    func sliderShare()
    func isAllowForSliding(_ sliderButton:UIView) -> Bool
}

class SliderButton: UIView, UIGestureRecognizerDelegate {

    enum PAN_GESTURE_DIRECTION {
        case right
        case left
        case center
    }
    @IBOutlet weak var sliderView: UIView!
    @IBOutlet weak var rightLabel: UILabel!
    @IBOutlet weak var leftLabel: UILabel!
    @IBOutlet weak var thumbImageView: UIImageView!
    @IBOutlet weak var leadingConstantOfThumbImageView: NSLayoutConstraint!
    
//    @IBOutlet var rightShimmerView: FBShimmeringView!
//    @IBOutlet var leftShimmerView: FBShimmeringView!
    var delegate:SliderDelegate!
    var leftSliderText:String!
    var rightSliderText:String!
    var direction:Int!
    var marginForThumbImageView:CGFloat!
    var BLUE_COLOR = UIColor(red: 152/255, green: 153/255, blue: 156/255, alpha: 1.0)//COLOR.themeSecondForegroundColor
    var isSliding = false
    let sliderViewHeight:CGFloat = 45
    let thumbImageViewWidth:CGFloat = 66
    let leftMarginForSliderView:CGFloat = 5
    var centerConstantValue:CGFloat = 0
    var slideLimitFromLeft:CGFloat = 0
    var slideLimitFromRight:CGFloat = 0
    var scaleValue:CGFloat = 10
    
    override func awakeFromNib() {
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(SliderButton.valueChanged(_:)))
        panGesture.delegate = self
        thumbImageView.addGestureRecognizer(panGesture)
//        leftShimmerView.contentView = leftLabel
//        leftShimmerView.isShimmering = true
//        leftShimmerView.shimmeringPauseDuration = 0.1
//        leftShimmerView.shimmeringAnimationOpacity = 1.0
//        leftShimmerView.shimmeringOpacity = 0.2
//        leftShimmerView.shimmeringSpeed = 30
//        leftShimmerView.shimmeringHighlightLength = 0.5
//        leftShimmerView.shimmeringDirection = FBShimmerDirection.left
//        leftShimmerView.shimmeringBeginFadeDuration = 0.1
//        leftShimmerView.shimmeringEndFadeDuration = 0.4
//        
//        rightShimmerView.contentView = rightLabel
//        rightShimmerView.isShimmering = true
//        rightShimmerView.shimmeringPauseDuration = 0.1
//        rightShimmerView.shimmeringAnimationOpacity = 1.0
//        rightShimmerView.shimmeringOpacity = 0.2
//        rightShimmerView.shimmeringSpeed = 30
//        rightShimmerView.shimmeringHighlightLength = 0.5
//        rightShimmerView.shimmeringDirection = FBShimmerDirection.right
//        rightShimmerView.shimmeringBeginFadeDuration = 0.1
//        rightShimmerView.shimmeringEndFadeDuration = 0.4
        
    }
    
    func setSliderButtonWith(_ marginForThumb:CGFloat, directionForButton:PAN_GESTURE_DIRECTION, rightSlideText:String, leftSlideText:String) {
        marginForThumbImageView = marginForThumb
        direction = directionForButton.hashValue
        leftSliderText = leftSlideText
        rightSliderText = rightSlideText
        leftLabel.text = leftSlideText
        rightLabel.text = rightSlideText
        self.slideLimitFromRight = self.frame.width - self.thumbImageViewWidth - marginForThumbImageView * 2//self.frame.width - self.thumbImageView.frame.width - marginForThumbImageView * 2
        self.centerConstantValue = (self.frame.width / 2) - (self.thumbImageViewWidth / 2) //- leftMarginForSliderView
        self.slideLimitFromLeft = marginForThumbImageView + leftMarginForSliderView
        setCornerRadiusForView()
        
        switch(direction) {
        case PAN_GESTURE_DIRECTION.left.hashValue:
            setLeftDirectionSlider()
            break
        case PAN_GESTURE_DIRECTION.right.hashValue:
            setRightDirectionSlider()
            break
        case PAN_GESTURE_DIRECTION.center.hashValue:
            self.setCenterPointSlider()
            break
        default:
            break
        }
    }
    
    
    
    func setCornerRadiusForView() {//Here we set corner radius and border color of self
        self.sliderView.layer.cornerRadius = sliderViewHeight / 2
        self.sliderView.layer.borderColor = BLUE_COLOR.cgColor
        self.sliderView.layer.borderWidth = 1.0
    }
    
    func backToOriginalPosition() {
        thumbImageView.transform = CGAffineTransform.identity
        leftLabel.alpha = 1
        rightLabel.alpha = 1
        isSliding = false
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if touches.first != nil {
            let touch = touches.first!
            if touch.view == thumbImageView {
                UIView.animate(withDuration: 1.0, delay: 0, usingSpringWithDamping: 0.2, initialSpringVelocity: 6.0, options: UIViewAnimationOptions.allowUserInteraction, animations: {
                    self.thumbImageView.transform = CGAffineTransform(scaleX: 1.3, y: 1.3)
                    }, completion: nil)
            }
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if touches.first != nil {
            let touch = touches.first!
            if touch.view == thumbImageView {
                UIView.animate(withDuration: 1.0, delay: 0, usingSpringWithDamping: 0.2, initialSpringVelocity: 6.0, options: UIViewAnimationOptions.allowUserInteraction, animations: {
                    self.thumbImageView.transform = CGAffineTransform.identity
                    }, completion: nil)
            }
        }
    }
    
    @objc func valueChanged(_ pan:UIPanGestureRecognizer) {
        let translation  = pan.translation(in: pan.view?.superview)
        var theTransform = pan.view?.transform
        

        switch(direction) {
        case PAN_GESTURE_DIRECTION.right.hashValue:
            if(delegate.isAllowForSliding(self) == false) {
                return
            }
            if(pan.state == UIGestureRecognizerState.changed) {
                isSliding = true
                if(translation.x > 0 && translation.x < self.sliderView.frame.width - self.thumbImageView.frame.width - marginForThumbImageView * 2) {
                    theTransform?.tx = translation.x
                    pan.view?.transform = theTransform!
                    leftLabel.alpha = 1 - (translation.x / (self.sliderView.frame.width - self.thumbImageView.frame.width - marginForThumbImageView))
                    rightLabel.alpha = 1 - (translation.x / (self.sliderView.frame.width - self.thumbImageView.frame.width - marginForThumbImageView))
                }
            } else if(pan.state == UIGestureRecognizerState.ended) {
                
                if(thumbImageView.frame.origin.x <= self.sliderView.frame.width * 0.4) {
                    UIView.animate(withDuration: 0.1, animations: {
                        self.thumbImageView.transform = CGAffineTransform.identity
                        self.leftLabel.alpha = 1
                        self.rightLabel.alpha = 1
                        self.isSliding = false
                    })
                } else if(thumbImageView.frame.origin.x > self.sliderView.frame.width * 0.4) {
                   UIView.animate(withDuration: 0.1, animations: {
                    self.leftLabel.alpha = 0
                    self.rightLabel.alpha = 0
                    //self.setLeftDirectionSlider()
                    theTransform?.tx = self.sliderView.frame.width - self.thumbImageView.frame.width - self.marginForThumbImageView * 2
                    self.thumbImageView.transform = theTransform!
                    }, completion: { finished in
                        self.delegate.sliderRequest()
                   })
                }
            }
            break
            
        case PAN_GESTURE_DIRECTION.left.hashValue:
            if(delegate.isAllowForSliding(self) == false) {
                return
            }
            let pointXLimit = -(self.sliderView.frame.width - self.thumbImageView.frame.width - marginForThumbImageView * 2)
            if(pan.state == UIGestureRecognizerState.changed) {
                isSliding = true
                if(translation.x > pointXLimit && translation.x < 0) {
                    theTransform?.tx =  translation.x
                    pan.view?.transform = theTransform!
                    self.leftLabel.alpha = 1 - (-translation.x / (self.sliderView.frame.width - self.thumbImageView.frame.width - marginForThumbImageView))
                    self.rightLabel.alpha = 1 - (-translation.x / (self.sliderView.frame.width - self.thumbImageView.frame.width - marginForThumbImageView))
                }
            } else if(pan.state == UIGestureRecognizerState.ended) {
                if(thumbImageView.frame.origin.x <= marginForThumbImageView * 25)
                {
                    UIView.animate(withDuration: 0.1, animations: {
                        self.leftLabel.alpha = 0
                        self.rightLabel.alpha = 0
                        theTransform?.tx = pointXLimit
                        self.thumbImageView.transform = theTransform!
                        }, completion: { (void) in
                            self.delegate.sliderShare()
                    })
                    //self.setRightDirectionSlider()
                } else {
                    UIView.animate(withDuration: 0.1, animations: {
                        self.leftLabel.alpha = 1
                        self.rightLabel.alpha = 1
                        self.thumbImageView.transform = CGAffineTransform.identity
                        self.isSliding = false
                    })
                }
            }
            break
            
        case PAN_GESTURE_DIRECTION.center.hashValue:
            if(delegate.isAllowForSliding(self) == false) {
                return
            }
            if(pan.state == UIGestureRecognizerState.changed) {
                isSliding = true
                print(translation.x)
                print(self.centerConstantValue)
                print(self.slideLimitFromRight)
                print(self.slideLimitFromLeft)
                if(translation.x > 0 && translation.x < self.centerConstantValue - self.scaleValue) {
                    theTransform?.tx = translation.x
                    pan.view?.transform = theTransform!
                    rightLabel.alpha = 1 - (translation.x / self.centerConstantValue)
                } else if(translation.x > -self.centerConstantValue + scaleValue && translation.x < 0) {
                    theTransform?.tx =  translation.x
                    pan.view?.transform = theTransform!
                    self.leftLabel.alpha = 1 - (-translation.x / self.centerConstantValue)
                }
            } else if(pan.state == UIGestureRecognizerState.ended) {
                print(thumbImageView.frame.origin.x)
                print(self.slideLimitFromRight * 0.8)
                
                if(thumbImageView.frame.origin.x > self.slideLimitFromLeft * 10 && thumbImageView.frame.origin.x < self.centerConstantValue) {
                    UIView.animate(withDuration: 0.1, animations: {
                        self.thumbImageView.transform = CGAffineTransform.identity
                        self.leftLabel.alpha = 1
                        self.isSliding = false
                    })
                } else if(thumbImageView.frame.origin.x <= self.slideLimitFromRight * 0.8 && thumbImageView.frame.origin.x >= self.centerConstantValue) {
                    UIView.animate(withDuration: 0.1, animations: {
                        self.thumbImageView.transform = CGAffineTransform.identity
                        self.rightLabel.alpha = 1
                        self.isSliding = false
                    })
                } else if(thumbImageView.frame.origin.x > self.slideLimitFromRight * 0.8) {
                    UIView.animate(withDuration: 0.1, animations: {
                        self.rightLabel.alpha = 0
                        theTransform?.tx = self.centerConstantValue
                        self.thumbImageView.transform = theTransform!
                        }, completion: { finished in
                            self.delegate.sliderRequest()
                    })
                } else if(thumbImageView.frame.origin.x < self.slideLimitFromLeft * 10) {
                    UIView.animate(withDuration: 0.1, animations: {
                        self.leftLabel.alpha = 0
                        theTransform?.tx = -self.centerConstantValue
                        self.thumbImageView.transform = theTransform!
                        }, completion: { finished in
                            self.delegate.sliderShare()
                    })
                }
            }
            break
        default:
            break
        }
    }
    
    func setRightDirectionSlider() {
        self.isSliding = false
        self.leadingConstantOfThumbImageView.constant = self.marginForThumbImageView
        self.thumbImageView.transform = CGAffineTransform.identity

        UIView.animate(withDuration: 0.3) { () -> Void in
            self.direction = PAN_GESTURE_DIRECTION.right.hashValue
            self.thumbImageView.image = UIImage(named: "thumb")
            self.sliderView.backgroundColor = self.BLUE_COLOR
            self.leftLabel.alpha = 1
            self.rightLabel.alpha = 1
        }
    }
    
    func setLeftDirectionSlider() {
        self.isSliding = false
        self.leadingConstantOfThumbImageView.constant = self.sliderView.frame.width - (self.thumbImageView.image?.size.width)! - self.marginForThumbImageView
        self.thumbImageView.transform = CGAffineTransform.identity

        UIView.animate(withDuration: 0.3) { () -> Void in
            self.direction = PAN_GESTURE_DIRECTION.left.hashValue
            self.thumbImageView.image = UIImage(named: "thumb")
            self.sliderView.backgroundColor = UIColor.white
        }
    }
    
    func setCenterPointSlider() {
        self.isSliding = false
        self.leadingConstantOfThumbImageView.constant = self.centerConstantValue
        self.thumbImageView.transform = CGAffineTransform.identity
        
        UIView.animate(withDuration: 0.3) { () -> Void in
            self.direction = PAN_GESTURE_DIRECTION.center.hashValue
            self.thumbImageView.image = UIImage(named: "thumb")
            self.sliderView.backgroundColor = self.BLUE_COLOR
            self.leftLabel.alpha = 1
            self.rightLabel.alpha = 1
        }
    }
    

}
