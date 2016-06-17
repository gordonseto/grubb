//
//  CameraVC.swift
//  grubb
//
//  Created by Gordon Seto on 2016-06-17.
//  Copyright © 2016 grubapp. All rights reserved.
//

import UIKit
import Fusuma

class CameraVC: UIViewController, FusumaDelegate{

    @IBOutlet weak var foodImage: UIImageView!
    
    var cameraIsCancelled: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func viewDidAppear(animated: Bool) {
        if foodImage.image == nil && cameraIsCancelled == false {
            let fusuma = FusumaViewController()
            fusuma.delegate = self
            fusuma.hasVideo = false
            self.presentViewController(fusuma, animated: true, completion: nil)
            cameraIsCancelled = true
        }
    }
    
    func fusumaImageSelected(image: UIImage) {
        foodImage.image = image
        return
    }
    
    func fusumaVideoCompleted(withFileURL fileURL: NSURL) {
        return
    }
    
    func fusumaDismissedWithImage(image: UIImage) {
        return
    }
    
    func fusumaCameraRollUnauthorized() {
        return
    }
    
    func fusumaClosed() {
        postingCanceled()
    }
    
    @IBAction func onCameraCancelPressed(sender: AnyObject) {
        postingCanceled()
    }
    
    func postingCanceled() {
        if let tabBarController = self.tabBarController {
            foodImage.image = nil
            tabBarController.selectedIndex = 0
            cameraIsCancelled = false
        }
    }
}
