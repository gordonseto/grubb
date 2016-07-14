//
//  settingsVC.swift
//  grubb
//
//  Created by Gordon Seto on 2016-07-10.
//  Copyright © 2016 grubbapp. All rights reserved.
//

import UIKit

class settingsVC: UIViewController {

    @IBOutlet weak var swipedSwitch: UISwitch!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController!.interactivePopGestureRecognizer!.delegate = nil;
        
        swipedSwitch.onTintColor = UIColor(red: 61.0/255.0, green: 147.0/255.0, blue: 245.0/255.0, alpha: 1.0)
        
        if let onlySwipedSetting = NSUserDefaults.standardUserDefaults().objectForKey("ONLY_SWIPED_SETTING") as? Bool {
            swipedSwitch.on = onlySwipedSetting
        } else {
            NSUserDefaults.standardUserDefaults().setObject(true, forKey: "ONLY_SWIPED_SETTING")
            swipedSwitch.on = true
        }
    }

    
    @IBAction func onBackButtonPressed(sender: AnyObject) {
        if let navController = self.navigationController {
            navController.popViewControllerAnimated(true)
        } else {
            dismissViewControllerAnimated(true, completion: nil)
        }
    }
    
    @IBAction func onSwitchChanged(sender: AnyObject) {
        NSUserDefaults.standardUserDefaults().setObject(swipedSwitch.on, forKey: "ONLY_SWIPED_SETTING")
    }
    
    @IBAction func onViewTutorialPressed(sender: UITapGestureRecognizer) {
        let onboardVC = generateOnboardingVC()
        self.presentViewController(onboardVC, animated: true, completion: nil)
    }
}
