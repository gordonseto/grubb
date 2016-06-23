//
//  ViewController.swift
//  grubb
//
//  Created by Gordon Seto on 2016-06-17.
//  Copyright © 2016 grubbapp. All rights reserved.
//

import UIKit
import FirebaseDatabase
import GeoFire
import AZDropdownMenu
import GoogleMaps

class ViewController: UIViewController, DraggableViewBackgroundDelegate, UITextFieldDelegate, CLLocationManagerDelegate {
    
    var food = [Food]()
    var searchedFood = [Food]()
    var filteredFood = [Food]()
    var draggableBackground: DraggableViewBackground!
    
    var filterLayer: UIView!
    var menu: AZDropdownMenu!
    var filter = ""
    
    var search: searchField!
    
    let locationManager = CLLocationManager()
    var geofire: GeoFire!
    var center: CLLocation!
    var radius = DEFAULT_SEARCH_RADIUS
    var previousCenter: CLLocation?
    
    var circleQuery: GFCircleQuery!
    var queryHandle: UInt!
    var keyExited: UInt!
    
    var totalCardsRetrieved = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.

        draggableBackground = DraggableViewBackground(frame: self.view.frame)
        self.view.addSubview(draggableBackground)
        draggableBackground.delegate = self
        
        let navigationLayer = UIView(frame: CGRectMake(0, 0, self.view.frame.size.width, 70))
        navigationLayer.backgroundColor = UIColor.whiteColor()
        self.view.addSubview(navigationLayer)
        
        search = searchField(frame: CGRectMake(8, 30, self.view.frame.size.width * 0.8, 30))
        search.delegate = self
        self.view.addSubview(search)
        
        let filterButton = UIButton(frame: CGRectMake(self.view.frame.size.width - 50, 25, 40, 40))
        filterButton.setImage(UIImage(named: "filterButton"), forState: UIControlState.Normal)
        filterButton.addTarget(self, action: #selector(onFilterTapped), forControlEvents: .TouchUpInside)
        self.view.addSubview(filterButton)
        
        filterLayer = UIView(frame: CGRectMake(0, 71, self.view.frame.size.width, 70))
        filterLayer.backgroundColor = UIColor.clearColor()
        self.view.addSubview(filterLayer)
        let filterTitles = ["", "Breakfast", "Lunch", "Dinner", "Dessert", "All Dishes"]
        menu = AZDropdownMenu(titles: filterTitles)
        menu.shouldDismissMenuOnDrag = true
        menu.itemFontColor = UIColor.darkGrayColor()
        menu.itemFontName = "HelveticaNeue-Bold"
        menu.itemFontSize = 17
        menu.itemAlignment = .Center
        menu.menuSeparatorStyle = .None
        menu.cellTapHandler = { [weak self] (indexPath: NSIndexPath) -> Void in
            if indexPath.row != 0 {
                self!.filterSelected(indexPath.row)
            }
        }
        
        getUsersLocation()
    }
    
    override func viewDidAppear(animated: Bool) {
        print(radius)
        if let searchRadius = NSUserDefaults.standardUserDefaults().objectForKey("SEARCH_RADIUS") {
            print(searchRadius as! NSNumber)
            var newRadius = Double(Int(searchRadius as! NSNumber)/1000)
            if radius != newRadius {
                radius = newRadius
                if center == nil {
                    getUsersLocation()
                } else {
                    food = []
                    draggableBackground.clearCards()
                    queryDishes(draggableBackground, center: center, radius: radius)
                }
            }
        } else {
            radius = DEFAULT_SEARCH_RADIUS
        }
    }
    
    func queryDishes(draggableBackground: DraggableViewBackground, center: CLLocation, radius: Double){
        var cardIndex = 0
        var cardsRetrieved = 0
        
        let firebase = FIRDatabase.database().reference()
        let geofireRef = firebase.child("geolocations")
        geofire = GeoFire(firebaseRef: geofireRef)

        circleQuery = geofire.queryAtLocation(center, withRadius: radius)

        queryHandle = circleQuery.observeEventType(.KeyEntered, withBlock: { (key: String!, location: CLLocation!) in
            //print("Key '\(key)' entered the search area and is at location '\(location)'")
            cardsRetrieved++
            
            firebase.child("posts").child(key).observeSingleEventOfType(.Value, withBlock: { (snapshot) in
                let name = snapshot.value!["name"] as! String
                let price = snapshot.value!["price"] as! Double
                let restaurant = snapshot.value!["restaurant"] as! String
                let categoryArray = snapshot.value!["categoryArray"] as! [String]
                let geolocation = location
                let search_key = "\(name.lowercaseString) \(restaurant.lowercaseString) \(restaurant.stringByReplacingOccurrencesOfString("'", withString: "").lowercaseString)"
                
                let newFood = Food(key: key, name: name, restaurant: restaurant, price: price, categoryArray: categoryArray, geolocation: geolocation, search_key: search_key)
                self.food.append(newFood)
                print(newFood.restaurant)
                
                //draggableBackground.addToCards(cardIndex, newFood: newFood)
                cardIndex++
                
                if cardIndex == self.totalCardsRetrieved {
                    self.doneRetrievingCards()
                }
                
            }) { (error) in
                print(error.localizedDescription)
            }
        })
        
        circleQuery.observeReadyWithBlock({
            self.totalCardsRetrieved = cardsRetrieved
        })
        
        keyExited = circleQuery.observeEventType(.KeyExited, withBlock: { (key: String!, location: CLLocation!) in
            print("Key '\(key)' has exited and is at location '\(location)'")
        })
    }
    
    func doneRetrievingCards() {
        queryFood()
    }
    
    func onCardTapped(sender: Food){
        performSegueWithIdentifier("itemVCFromHome", sender: sender)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "itemVCFromHome" {
            if let destinationVC = segue.destinationViewController as? itemVC {
                if let item = sender as? Food {
                    destinationVC.food = item
                }
            }
        }
    }
    
    func onFilterTapped(){
        menu.showMenuFromView(self.view)
    }
    
    func filterSelected(index: Int){
        switch(index) {
        case 0:
            break
        case 1:
            filter = "Breakfast"
        case 2:
            filter = "Lunch"
        case 3:
            filter = "Dinner"
        case 4:
            filter = "Dessert"
        case 5:
            filter = ""
        default:
            filter = ""
        }
        let delay = 0.5 * Double(NSEC_PER_SEC)
        let time = dispatch_time(DISPATCH_TIME_NOW, Int64(delay))
        dispatch_after(time, dispatch_get_main_queue()) {
            self.queryFood()
        }
    }
    
    func onRestartTapped(){
        queryFood()
    }
    
    func textField(textField: UITextField,shouldChangeCharactersInRange range: NSRange,replacementString string: String) -> Bool
    {
        if string == "\n" {
            textField.resignFirstResponder()
            return false
        }
        return true
    }
    
    func textFieldDidEndEditing(textField: UITextField) {
        queryFood()
    }

    func searchFood(search: String){
        if search == "" {
            searchedFood = food
            print("loading food array")
        } else {
            searchedFood = food.filter({$0.search_key.rangeOfString(search) != nil})
        }
        if filter == "" {
            filteredFood = searchedFood
        } else {
            filteredFood = searchedFood.filter({$0.categoryArray.indexOf(filter) != nil})
        }
        shuffleFood(filteredFood)
    }
    
    func queryFood(){
        let query = search.text!.lowercaseString
        searchFood(query)
    }
    
    func shuffleFood(foodArray: [Food]){
        var foodArray = shuffleArray(foodArray)
        draggableBackground.loadDeckOfCards(foodArray)
    }
    
    func shuffleArray<T>(array: Array<T>) -> Array<T>
    {
        var array = array
        for var index = array.count - 1; index > 0; index--
        {
            // Random int from 0 to index-1
            var j = Int(arc4random_uniform(UInt32(index-1)))
            
            // Swap two array elements
            // Notice '&' required as swap uses 'inout' parameters
            swap(&array[index], &array[j])
        }
        return array
    }
    
    func getUsersLocation(){
        self.locationManager.requestWhenInUseAuthorization()
        
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.distanceFilter = MOVE_DISTANCE
            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            locationManager.startUpdatingLocation()
        }
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        previousCenter = center
        if let location = manager.location {
            if let prevLocation = previousCenter {
                print("distance: \(location.distanceFromLocation(prevLocation))")
                if location.distanceFromLocation(prevLocation) < MOVE_DISTANCE {
                    return
                }
            }
            food = []
            draggableBackground.clearCards()
            var coordinate:CLLocationCoordinate2D = location.coordinate
            print("LOCATION \(coordinate.latitude), \(coordinate.longitude)")
            center = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
            queryDishes(draggableBackground, center: center, radius: radius)
        }
    }
}

extension UIViewController {
    func hideKeyboardWhenTappedAround() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: "dismissKeyboard")
        view.addGestureRecognizer(tap)
    }
    
    func dismissKeyboard() {
        view.endEditing(true)
    }
    
    func showErrorAlert(title: String, msg: String) {
        let alert = UIAlertController(title: title, message: msg, preferredStyle: .Alert)
        let action = UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: nil)
        alert.addAction(action)
        presentViewController(alert, animated: true, completion: nil)
    }
}

    