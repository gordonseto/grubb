//
//  CameraVC.swift
//  grubb
//
//  Created by Gordon Seto on 2016-06-17.
//  Copyright © 2016 grubapp. All rights reserved.
//

import UIKit
import Fusuma

class CameraVC: UIViewController, FusumaDelegate {
    
    var cameraIsCancelled: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        prefersStatusBarHidden()
        
    }

    override func viewDidAppear(animated: Bool) {
        if cameraIsCancelled == false {
            let fusuma = FusumaViewController()
            fusuma.delegate = self
            fusuma.hasVideo = false
            self.presentViewController(fusuma, animated: true, completion: nil)
            cameraIsCancelled = true
        }
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    func fusumaImageSelected(image: UIImage) {
        return
    }
    
    func fusumaVideoCompleted(withFileURL fileURL: NSURL) {
        return
    }
    
    func fusumaDismissedWithImage(image: UIImage) {
        performSegueWithIdentifier("newPostVC", sender: image)
        return
    }
    
    func fusumaCameraRollUnauthorized() {
        return
    }
    
    func fusumaClosed() {
        postingCanceled()
    }
    
    func postingCanceled() {
        if let tabBarController = self.tabBarController {
            tabBarController.selectedIndex = 0
            cameraIsCancelled = false
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "newPostVC" {
            if let destinationVC = segue.destinationViewController as? newPostVC {
                if let image = sender as? UIImage {
                    destinationVC.image = image
                    cameraIsCancelled = false
                }
            }
        }
    }
}


