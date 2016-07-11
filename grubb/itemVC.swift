//
//  itemVC.swift
//  grubb
//
//  Created by Gordon Seto on 2016-06-17.
//  Copyright © 2016 grubbapp. All rights reserved.
//

import UIKit
import FirebaseDatabase
import FirebaseStorage
import GeoFire

protocol itemVCDelegate: class {
    func onFoodLiked()
    func removeFromUserLikes(key: String)
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
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var moreButton: UIButton!
    
    var food: Food!
    var searchLocation: CLLocation!
    var key: String!
    var image: UIImage!
    
    var uid: String?
    var firebase: FIRDatabaseReference!
    
    var numLikes = 0
    var userLiked = false
    
    let locationManager = CLLocationManager()
    var likesManager: LikesManager!
    
    var fromHome = false
    var imagesRef: FIRStorageReference?
    
    var refreshControl: UIRefreshControl!
    
    weak var delegate: itemVCDelegate!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        locationManager.delegate = self
        
        likeImage.userInteractionEnabled = false
        
        self.navigationController!.interactivePopGestureRecognizer!.delegate = nil;
        
        moreButton.imageView!.contentMode = UIViewContentMode.ScaleAspectFit
        
        refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: Selector("refreshView:"), forControlEvents: UIControlEvents.ValueChanged)
        refreshControl.tintColor = UIColor.lightGrayColor()
        self.scrollView.addSubview(refreshControl)
        
        if food == nil {
            getFoodData()
        } else {
            self.key = food.key
            initializeView()
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        dismissNotifications()
    }
    
    func initializeView(){
        nameLabel.text = food.name
        if food.foodImage != nil {
            foodImage.image = food.foodImage
        } else {
            downloadFoodImage()
        }
        priceLabel.text = String.localizedStringWithFormat("$%.2f", food.price)
        restaurantLabel.text = food.restaurant
        
        checkLikedStatus()
        
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
            let author = snapshot.value!["author"] as! String
            self.food = Food(key: self.key, name: name, restaurant: restaurant, price: price, categoryArray: categoryArray, geolocation: geolocation, search_key: search_key, author: author)
            
            self.food.foodImage = self.image
            
            self.initializeView()
        }) { (error) in
            print(error.localizedDescription)
            if let navController = self.navigationController {
                navController.popViewControllerAnimated(true)
            }
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
                    self.userLiked = true
                } else {
                    self.foodNotLiked()
                    self.userLiked = false
                }
                self.likesManager = LikesManager(uid: uid, key: self.food.key, author: self.food.author, name: self.food.name)
                self.likeImage.userInteractionEnabled = true
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
        print(likeImage.image)
        if let uid = uid {
            if !userLiked{
                userLiked = true
                foodLiked()
                numLikes += 1
                updateLikesLabel(numLikes)
                if fromHome {
                    popAndAnimateSwipe()
                } else {
                    likesManager.likePost()
                }
            } else {
                userLiked = false
                foodNotLiked()
                numLikes -= 1
                updateLikesLabel(numLikes)
                if fromHome {
                    delegate?.removeFromUserLikes(self.food.key)
                }
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
    
    func downloadFoodImage(){
        let storage = FIRStorage.storage()
        let storageRef = storage.referenceForURL(FIREBASE_STORAGE)
        imagesRef = storageRef.child("images")
        if let imagesRef = imagesRef {
            let childRef = imagesRef.child(food.key)
            childRef.dataWithMaxSize(1 * 1024 * 1024, completion: { (data, error) in
                if (error != nil){
                    print(error.debugDescription)
                    self.foodImage.image = UIImage(named: "reloadImage")
                } else {
                    let foodImage: UIImage! = UIImage(data: data!)
                    self.food.foodImage = foodImage
                    print("downloaded \(self.food.key)'s image")
                    self.foodImage.image = foodImage
                }
            })
        }
    }
    
    @IBAction func onMoreButtonPressed(sender: AnyObject) {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)
        
        if let uid = self.uid where uid == self.food.author {
            let editAction = UIAlertAction(title: "Edit", style: .Default) { action -> Void in
            let editVC = UIStoryboard(name: "Main", bundle:nil).instantiateViewControllerWithIdentifier("newPostVC") as! newPostVC
                editVC.editMode = true
                editVC.food = self.food
                editVC.numLikes = self.numLikes
                self.presentViewController(editVC, animated: true, completion: nil)
            }
            alertController.addAction(editAction)
            let deleteAction = UIAlertAction(title: "Delete", style: .Destructive) { action -> Void in
                let alert = UIAlertController(title: "Are you sure you want to delete this dish?", message: "This will be permanent and cannot be undone.", preferredStyle: .Alert)
                let cancel = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Default) { action -> Void in
                }
                alert.addAction(cancel)
                let delete = UIAlertAction(title: "Delete", style: UIAlertActionStyle.Destructive) { action -> Void in
                    self.deletePost(self.food.key)
                }
                alert.addAction(delete)
                self.presentViewController(alert, animated: true, completion: nil)
            }
            alertController.addAction(deleteAction)
        } else {
            let reportAction = UIAlertAction(title: "Report", style: .Destructive) { action -> Void in
                let reportVC = UIStoryboard(name: "Main", bundle:nil).instantiateViewControllerWithIdentifier("ReportVC") as! ReportVC
                reportVC.key = self.food.key
                self.presentViewController(reportVC, animated: true, completion: nil)
            }
            alertController.addAction(reportAction)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
        alertController.addAction(cancelAction)
        
        presentViewController(alertController, animated: true, completion: nil)
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
    
    func refreshView(sender: AnyObject){
        if !fromHome {
            self.locationManager.startUpdatingLocation()
        } else {
            self.getFood(food.geolocation)
        }
        self.refreshControl.endRefreshing()
    }
    
    func deletePost(key: String){
        let storage = FIRStorage.storage()
        let storageRef = storage.referenceForURL(FIREBASE_STORAGE)
        let imagesRef = storageRef.child("images")
        let childRef = imagesRef.child(key)
        
        childRef.deleteWithCompletion { (error) -> Void in
            if (error != nil) {
                print(error?.localizedDescription)
            } else {
                print("deletion successful")
            }
        }
     
        firebase.child("geolocations").child(key).setValue(nil)
        firebase.child("posts").child(key).setValue(nil)
        firebase.child("users").child(self.food.author).child("posts").child(key).setValue(nil)

        firebase.child("users").queryOrderedByChild("likes/\(food.key)").queryStartingAtValue(0).observeSingleEventOfType(.Value, withBlock: { snapshot in
                print(snapshot)
                for child in snapshot.children {
                    let child = child as! FIRDataSnapshot
                    print(child.key)
                    self.firebase.child("users").child(child.key).child("likes").child(self.food.key).setValue(nil)
                }
            })
 
        if let navController = self.navigationController {
            if !fromHome {
                let exploreVC = navController.viewControllers[0] as! ExploreVC
                exploreVC.collection.reloadData()
            }
            navController.popViewControllerAnimated(true)
        }
    
 }

    @IBAction func onImageTapped(sender: UITapGestureRecognizer) {
        print("hi")
    }
 
}
