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

protocol itemVCDelegate: class {
    func onFoodLiked()
}

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
    var likesManager: LikesManager!
    
    var fromHome = false
    
    weak var delegate: itemVCDelegate!
    
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
            let author = snapshot.value!["author"] as! String
            self.food = Food(key: self.key, name: name, restaurant: restaurant, price: price, categoryArray: categoryArray, geolocation: geolocation, placeID: placeID, search_key: search_key, author: author)
            
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
                self.likesManager = LikesManager(uid: uid, key: self.food.key, author: self.food.author)
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
        if let uid = uid {
            if likeImage.image == UIImage(named: "emptyHeart"){
                foodLiked()
                numLikes += 1
                updateLikesLabel(numLikes)
                if fromHome {
                    popAndAnimateSwipe()
                }
                likesManager.likePost()
            } else {
                foodNotLiked()
                numLikes -= 1
                updateLikesLabel(numLikes)
                likesManager.unlikePost()
            }
        }
    }

    func popAndAnimateSwipe(){
        let delay = 0.25 * Double(NSEC_PER_SEC)
        let time = dispatch_time(DISPATCH_TIME_NOW, Int64(delay))
        dispatch_after(time, dispatch_get_main_queue()) {
            if let navController = self.navigationController {
                navController.popViewControllerAnimated(true)
                self.delegate?.onFoodLiked()
            }
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
