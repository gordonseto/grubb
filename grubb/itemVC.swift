//
//  itemVC.swift
//  grubb
//
//  Created by Gordon Seto on 2016-06-17.
//  Copyright © 2016 grubbapp. All rights reserved.
//

import UIKit
import GoogleMaps

class itemVC: UIViewController {

    @IBOutlet weak var nameLabel: UITextView!
    @IBOutlet weak var foodImage: UIImageView!
    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var saveImage: UIImageView!
    @IBOutlet weak var priceLabel: UILabel!
    @IBOutlet weak var restaurantLabel: UILabel!
    @IBOutlet weak var ratingImage: UIImageView!
    @IBOutlet weak var openNowLabel: UILabel!
    
    var food: Food!
    var searchLocation: CLLocation!
    
    var placesClient: GMSPlacesClient?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        nameLabel.text = food.name
        foodImage.image = food.foodImage
        priceLabel.text = String.localizedStringWithFormat("$%.2f", food.price)
        restaurantLabel.text = food.restaurant
        openNowLabel.text = ""
        
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
