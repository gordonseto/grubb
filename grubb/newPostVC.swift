//
//  newPostVC.swift
//  grubb
//
//  Created by Gordon Seto on 2016-06-19.
//  Copyright © 2016 grubapp. All rights reserved.
//

import UIKit
import FirebaseDatabase
import GoogleMaps

class newPostVC: UIViewController {

    @IBOutlet weak var foodImage: UIImageView!
    @IBOutlet weak var nameInput: UITextField!
    @IBOutlet weak var locationButton: UIButton!
    
    var firebase: FIRDatabaseReference!
    var restaurant: String!
    var coordinate: CLLocationCoordinate2D!
    var image: UIImage?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.hideKeyboardWhenTappedAround()
        
        firebase = FIRDatabase.database().reference()
        
    }
    
    override func viewDidAppear(animated: Bool) {
        foodImage.image = image!
        
        if restaurant != nil {
            locationButton.setTitle(restaurant, forState: .Normal)
        }
    }
    
    func postingCanceled() {
        if let tabBarController = self.tabBarController {
            foodImage.image = nil
            tabBarController.selectedIndex = 0
        }
    }
    
    @IBAction func onSubmitPressed(sender: AnyObject) {
        if nameInput.text != "" {
            if let uid = NSUserDefaults.standardUserDefaults().objectForKey("USER_UID") as? String {
                let key = firebase.child("posts").childByAutoId().key
                let post = ["name": nameInput.text!, "author": uid]
                firebase.child("posts").child(key).setValue(post)
            }
        }
    }
    
    @IBAction func onCancelPressed(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func onLocationPressed(sender: AnyObject){
        let autocompleteController = GMSAutocompleteViewController()
        autocompleteController.delegate = self
        self.presentViewController(autocompleteController, animated: true, completion: nil)
    }
}


extension newPostVC: GMSAutocompleteViewControllerDelegate {
    func viewController(viewController: GMSAutocompleteViewController, didAutocompleteWithPlace place: GMSPlace) {
        print("Place name: ", place.name)
        print("Place coordinates: ", place.coordinate)
        restaurant = place.name
        coordinate = place.coordinate
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func viewController(viewController: GMSAutocompleteViewController, didFailAutocompleteWithError error: NSError) {
        print("Error: ", error.description)
    }
    
    func wasCancelled(viewController: GMSAutocompleteViewController) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
}

