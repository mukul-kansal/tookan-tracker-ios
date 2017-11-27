//
//  SplashController.swift
//  Tracker
//
//  Created by cl-macmini-45 on 29/09/16.
//  Copyright © 2016 clicklabs. All rights reserved.
//

import UIKit

class SplashController: UIViewController {

    @IBOutlet weak var tookanLogo: UIImageView!
    @IBOutlet weak var poweredLabel: UILabel!
    @IBOutlet weak var logo: UIImageView!
    @IBOutlet weak var trackerLabel: UILabel!
    override func viewDidLoad() {
        super.viewDidLoad()
        poweredLabel.textColor = UIColor().poweredColor
        trackerLabel.textColor = UIColor().trackerColor
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    


}
