//
//  itemVC.swift
//  grubb
//
//  Created by Gordon Seto on 2016-06-17.
//  Copyright © 2016 grubbapp. All rights reserved.
//

import UIKit
import GoogleMaps
import FirebaseDatabase

class itemVC: UIViewController {


    @IBOutlet weak var nameLabel: UITextView!
    @IBOutlet weak var foodImage: UIImageView!
    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var saveImage: UIImageView!
    @IBOutlet weak var priceLabel: UILabel!
    @IBOutlet weak var restaurantLabel: UILabel!
    @IBOutlet weak var ratingImage: UIImageView!
    @IBOutlet weak var openNowLabel: UILabel!
    @IBOutlet weak var likeImage: UIImageView!
    
    var food: Food!
    var searchLocation: CLLocation!
    
    var placesClient: GMSPlacesClient?
    var uid: String?
    var firebase: FIRDatabaseReference!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        nameLabel.text = food.name
        foodImage.image = food.foodImage
        priceLabel.text = String.localizedStringWithFormat("$%.2f", food.price)
        restaurantLabel.text = food.restaurant
        openNowLabel.text = ""
        
        checkLikedStatus()
        
        placesClient = GMSPlacesClient()
        
    }
    
    override func viewDidAppear(animated: Bool) {
        findDistanceFromSearch()
        getPlaceDetails()
    }

    @IBAction func backButtonPressed(sender: AnyObject) {
        if let navController = self.navigationController {
            navController.popViewControllerAnimated(true)
        }
        
    }

    func checkLikedStatus(){
        if let uid = NSUserDefaults.standardUserDefaults().objectForKey("USER_UID") as? String {
            self.uid = uid
            firebase = FIRDatabase.database().reference()
            firebase.child("users").child(uid).child("likes").observeSingleEventOfType(.Value, withBlock: { (snapshot) in
                // Get user value
                if let foodLiked = snapshot.value![self.food.key] as? Double{
                    self.foodLiked()
                } else {
                    self.foodNotLiked()
                }
            }) { (error) in
                print(error.localizedDescription)
            }
        }
    }
    
    func foodLiked(){
        likeImage.image = UIImage(named: "filledHeart")
    }
    
    func foodNotLiked(){
        likeImage.image = UIImage(named: "emptyHeart")
    }
    
    @IBAction func onHeartTapped(sender: UITapGestureRecognizer) {
        print("tapped")
        if likeImage.image == UIImage(named: "emptyHeart"){
            if let uid = uid {
                foodLiked()
                let time = NSDate().timeIntervalSince1970
                self.firebase.child("users").child(uid).child("likes").child(food.key).setValue(time)
            }
            
        } else {
            if let uid = uid {
                foodNotLiked()
                self.firebase.child("users").child(uid).child("likes").child(food.key).setValue(nil)
            }
        }
    }

    
    func findDistanceFromSearch(){
        var distance = searchLocation.distanceFromLocation(food.geolocation)
        distanceLabel.text = "\(Int(distance/1000.0)) km away"
    }
    
    func getPlaceDetails(){
        placesClient!.lookUpPlaceID(food.placeID) { (place: GMSPlace?, error: NSError?) in
            if let error = error {
                print(error.localizedDescription)
                return
            }
            if let place = place {
                print(place.rating)
                var rating = round(place.rating)
                if rating <= 0 {
                    rating = 1
                }
                self.ratingImage.image = UIImage(named: "\(rating)")
            } else {
                print("No place details for \(self.food.placeID)")
            }
        }
    }
    
    @IBAction func onViewInGoogleMapsPressed(sender: AnyObject) {
            var restaurant_string = food.restaurant.stringByReplacingOccurrencesOfString(" ", withString: "+")
            restaurant_string = restaurant_string.stringByReplacingOccurrencesOfString("&", withString: "+")
            restaurant_string = restaurant_string.stringByReplacingOccurrencesOfString("?", withString: "+")
            restaurant_string = restaurant_string.stringByReplacingOccurrencesOfString("=", withString: "+")
            restaurant_string = restaurant_string.stringByReplacingOccurrencesOfString("!", withString: "+")
            restaurant_string = restaurant_string.stringByReplacingOccurrencesOfString("@", withString: "+")
            restaurant_string = restaurant_string.stringByReplacingOccurrencesOfString("$", withString: "+")
            restaurant_string = restaurant_string.stringByReplacingOccurrencesOfString("%", withString: "+")
            restaurant_string = restaurant_string.stringByReplacingOccurrencesOfString("^", withString: "+")
            restaurant_string = restaurant_string.stringByReplacingOccurrencesOfString("*", withString: "+")
            restaurant_string = restaurant_string.stringByReplacingOccurrencesOfString("'", withString: "+")
            restaurant_string = restaurant_string.stringByReplacingOccurrencesOfString("`", withString: "+")
            restaurant_string = restaurant_string.stringByReplacingOccurrencesOfString("’", withString: "+")
            print(restaurant_string)
            UIApplication.sharedApplication().openURL(NSURL(string:
                "comgooglemaps://?q=\(restaurant_string)&center=\(food.geolocation.coordinate.latitude),\(food.geolocation.coordinate.longitude)&zoom=15&views=")!)
    }

}
