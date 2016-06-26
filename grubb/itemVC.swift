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
import GeoFire

class itemVC: UIViewController, CLLocationManagerDelegate {


    @IBOutlet weak var nameLabel: UITextView!
    @IBOutlet weak var foodImage: UIImageView!
    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var saveImage: UIImageView!
    @IBOutlet weak var priceLabel: UILabel!
    @IBOutlet weak var restaurantLabel: UILabel!
    @IBOutlet weak var likeImage: UIImageView!
    @IBOutlet weak var likesLabel: UILabel!
    
    var food: Food!
    var searchLocation: CLLocation!
    var key: String!
    var image: UIImage!
    
    var placesClient: GMSPlacesClient?
    var uid: String?
    var firebase: FIRDatabaseReference!
    
    var numLikes = 0
    
    let locationManager = CLLocationManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        locationManager.delegate = self
        
        if food == nil {
            getFoodData()
        } else {
            initializeView()
        }
    }
    
    func initializeView(){
        nameLabel.text = food.name
        foodImage.image = food.foodImage
        priceLabel.text = String.localizedStringWithFormat("$%.2f", food.price)
        restaurantLabel.text = food.restaurant
        
        checkLikedStatus()
        
        placesClient = GMSPlacesClient()
        
        findDistanceFromSearch()
    }
    
    func getFoodData(){
        foodImage.image = image
        print(key)
        locationManager.startUpdatingLocation()
    }

    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first {
            searchLocation = location
            locationManager.stopUpdatingLocation()
            
            let firebase = FIRDatabase.database().reference()
            let geofireRef = firebase.child("geolocations")
            let geofire = GeoFire(firebaseRef: geofireRef)
            
            geofire.getLocationForKey(key, withCallback: { (location, error) in
                if (error != nil) {
                    print(error.localizedDescription)
                } else if (location != nil) {
                    print(location)
                    self.getFood(location)
                } else {
                    print("GeoFire does not contain a location for \(self.key)")
                }
            })
        }
    }
    
    func getFood(location: CLLocation){
        let firebase = FIRDatabase.database().reference()
        firebase.child("posts").child(key).observeSingleEventOfType(.Value, withBlock: { (snapshot) in
            let name = snapshot.value!["name"] as! String
            let price = snapshot.value!["price"] as! Double
            let restaurant = snapshot.value!["restaurant"] as! String
            let categoryArray = snapshot.value!["categoryArray"] as! [String]
            let geolocation = location
            let search_key = "\(name.lowercaseString) \(restaurant.lowercaseString) \(restaurant.stringByReplacingOccurrencesOfString("'", withString: "").lowercaseString)"
            var placeID = snapshot.value?["placeID"] as! String
            
            self.food = Food(key: self.key, name: name, restaurant: restaurant, price: price, categoryArray: categoryArray, geolocation: geolocation, placeID: placeID, search_key: search_key)
            
            self.food.foodImage = self.image
            
            self.initializeView()
        }) { (error) in
            print(error.localizedDescription)
        }
    }
    
    @IBAction func backButtonPressed(sender: AnyObject) {
        if let navController = self.navigationController {
            navController.popViewControllerAnimated(true)
        } else {
            dismissViewControllerAnimated(true, completion: nil)
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
            firebase.child("posts").child(food.key).child("likes").observeSingleEventOfType(.Value, withBlock: { (snapshot) in
                self.numLikes = snapshot.value as? Int ?? 0
                self.updateLikesLabel(self.numLikes)
            }) { (error) in
                print(error.localizedDescription)
            }
        }
    }
    
    func updateLikesLabel(likes: Int){
        if likes == 1 {
            likesLabel.text = "\(likes) like"
        } else {
        likesLabel.text = "\(likes) likes"
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
                numLikes += 1
                updateLikesLabel(numLikes)
                let time = NSDate().timeIntervalSince1970
                self.firebase.child("users").child(uid).child("likes").child(food.key).setValue(time)
                self.firebase.child("posts").child(food.key).runTransactionBlock({ (currentData: FIRMutableData) -> FIRTransactionResult in
                    if var post = currentData.value as? [String: AnyObject] {
                        var likes = post["likes"] as? Int ?? 0
                        likes += 1
                        post["likes"] = likes
                        currentData.value = post
                        print(likes)
                        return FIRTransactionResult.successWithValue(currentData)
                    }
                    return FIRTransactionResult.successWithValue(currentData)
                }, andCompletionBlock: { (error, committed, snapshot) in
                    if let error = error {
                        print(error.localizedDescription)
                    }
                })
            }
            
        } else {
            if let uid = uid {
                foodNotLiked()
                numLikes -= 1
                updateLikesLabel(numLikes)
                self.firebase.child("users").child(uid).child("likes").child(food.key).setValue(nil)
                self.firebase.child("posts").child(food.key).runTransactionBlock({ (currentData: FIRMutableData) -> FIRTransactionResult in
                    if var post = currentData.value as? [String: AnyObject] {
                        var likes = post["likes"] as? Int ?? 0
                        likes -= 1
                        post["likes"] = likes
                        currentData.value = post
                        
                        return FIRTransactionResult.successWithValue(currentData)
                    }
                    return FIRTransactionResult.successWithValue(currentData)
                    }, andCompletionBlock: { (error, committed, snapshot) in
                        if let error = error {
                            print(error.localizedDescription)
                        }
                })
            }
        }
        if let uid = uid {
            let firebase = FIRDatabase.database().reference()
        }
    }

    
    func findDistanceFromSearch(){
        var distance = searchLocation.distanceFromLocation(food.geolocation)
        if distance < 1000 {
            distanceLabel.text = "\(Int(distance)) m away"
        } else {
            distanceLabel.text = "\(Int(distance/1000.0)) km away"
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
