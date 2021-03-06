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
import Batch
import Onboard
import SloppySwiper

final class ViewController: UIViewController, DraggableViewBackgroundDelegate, UITextFieldDelegate, itemVCDelegate {
    
    var food = [Food]()
    var searchedFood = [Food]()
    var filteredFood = [Food]()
    var draggableBackground: DraggableViewBackground!
    
    var filterLayer: UIView!
    var menu: AZDropdownMenu!
    var filter = ""
    
    var search: searchField!
    
    var geofire: GeoFire!
    var center: CLLocation!
    var radius = DEFAULT_SEARCH_RADIUS
    
    var circleQuery: GFCircleQuery!
    var queryHandle: UInt!
    var keyExited: UInt!
    
    var totalCardsRetrieved = 0
    
    var uid: String!
    var firebase: FIRDatabaseReference!
    
    var swiped: [String: AnyObject]!
    var swipedInThisSession: [String: AnyObject]!
    
    var userLikes = [String: AnyObject]()
    
    var swiper: SloppySwiper!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.hideKeyboardWhenTappedAround()
        
        if let navigationcontroller = self.navigationController {
            swiper = SloppySwiper(navigationController: navigationcontroller)
            navigationcontroller.delegate = swiper
        }
        
        draggableBackground = DraggableViewBackground(frame: self.view.frame)
        self.view.addSubview(draggableBackground)
        draggableBackground.delegate = self
        
        let navigationLayer = UIView(frame: CGRectMake(0, 0, self.view.frame.size.width, 70))
        navigationLayer.backgroundColor = UIColor.whiteColor()
        self.view.addSubview(navigationLayer)
        
        let backButton = UIButton(frame: CGRectMake(8, 22, 30, 30))
        backButton.setImage(UIImage(named: "backButton"), forState: UIControlState.Normal)
        backButton.addTarget(self, action: #selector(onBackButtonTapped), forControlEvents: .TouchUpInside)
        self.view.addSubview(backButton)
        
        search = searchField(frame: CGRectMake(40, 35, self.view.frame.size.width * 0.75, 30))
        search.center = CGPoint(x: self.view.frame.size.width/2 + 18, y: 38)
        search.delegate = self
        self.view.addSubview(search)
        
        /*
        let filterButton = UIButton(frame: CGRectMake(self.view.frame.size.width - 38, 25, 25, 25))
        filterButton.setImage(UIImage(named: "filterButton"), forState: UIControlState.Normal)
        filterButton.addTarget(self, action: #selector(onFilterTapped), forControlEvents: .TouchUpInside)
        filterButton.imageView!.contentMode = UIViewContentMode.ScaleAspectFit
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
        */
        
        if let uid = NSUserDefaults.standardUserDefaults().objectForKey("USER_UID") as? String {
            self.uid = uid
        }
        
        firebase = FIRDatabase.database().reference()
        swipedInThisSession = [String:AnyObject]()
        
        print(center)
        print(radius)
        if let searchRadius = NSUserDefaults.standardUserDefaults().objectForKey("SEARCH_RADIUS") {
            print(searchRadius as! NSNumber)
            var newRadius = Double(Int(searchRadius as! NSNumber)/1000)
            radius = newRadius
            food = []
            draggableBackground.clearCards()
            queryDishes(draggableBackground, center: center, radius: radius)
        } else {
            radius = DEFAULT_SEARCH_RADIUS
        }
        
        self.navigationController!.interactivePopGestureRecognizer!.delegate = nil;
    }
    
    override func viewDidAppear(animated: Bool) {
        dismissNotifications()
    }
    
    func queryDishes(draggableBackground: DraggableViewBackground, center: CLLocation, radius: Double){
        var cardIndex = 0
        var cardsRetrieved = 0
        
        let firebase = FIRDatabase.database().reference()
        let geofireRef = firebase.child("geolocations")
        geofire = GeoFire(firebaseRef: geofireRef)
        
        firebase.child("users").child(uid).observeSingleEventOfType(.Value, withBlock: { (snapshot) in
            if let onlySwipedSetting = NSUserDefaults.standardUserDefaults().objectForKey("ONLY_SWIPED_SETTING") as? Bool {
                if onlySwipedSetting {
                    self.parseSwiped(snapshot)
                } else {
                    self.swiped = [String:AnyObject]()
                }
            } else {
                self.parseSwiped(snapshot)
            }
            
 
            if let userLikes = snapshot.value!["likes"] as? [String: AnyObject] {
                self.userLikes = userLikes
            } else {
                self.userLikes = [String:AnyObject]()
            }
            
            self.circleQuery = self.geofire.queryAtLocation(center, withRadius: radius)

            self.queryHandle = self.circleQuery.observeEventType(.KeyEntered, withBlock: { (key: String!, location: CLLocation!) in
                
                if self.swiped[key] == nil {
                    //print("Key '\(key)' entered the search area and is at location '\(location)'")
                    cardsRetrieved++
            
                    firebase.child("posts").child(key).observeSingleEventOfType(.Value, withBlock: { (snapshot) in
                        let name = snapshot.value!["name"] as! String
                        let price = snapshot.value!["price"] as! Double
                        let restaurant = snapshot.value!["restaurant"] as! String
                        let categoryArray = snapshot.value!["categoryArray"] as! [String]
                        let geolocation = location
                        let search_key = "\(name.lowercaseString) \(restaurant.lowercaseString) \(restaurant.stringByReplacingOccurrencesOfString("'", withString: "").lowercaseString)"
                        let author = snapshot.value!["author"] as! String
                
                        let newFood = Food(key: key, name: name, restaurant: restaurant, price: price, categoryArray: categoryArray, geolocation: geolocation, search_key: search_key, author: author)
                        self.food.append(newFood)
                        print(newFood.restaurant)
                        print("NAME: \(newFood.name)")
                        //draggableBackground.addToCards(cardIndex, newFood: newFood)
                        cardIndex++
                
                        if cardIndex == self.totalCardsRetrieved {
                            self.doneRetrievingCards()
                        }
                    }) { (error) in
                        print(error.localizedDescription)
                    }
                } else {
                    print("\(key) has been swiped")
                }
            })
        
            self.circleQuery.observeReadyWithBlock({
                self.totalCardsRetrieved = cardsRetrieved
                if self.totalCardsRetrieved == 0 {
                    draggableBackground.stopLoadingAnimation()
                    draggableBackground.displayNoDishes()
                } else {
                    if let noDishes = draggableBackground.noDishes {
                        noDishes.removeFromSuperview()
                    }
                }
            })
        
            self.keyExited = self.circleQuery.observeEventType(.KeyExited, withBlock: { (key: String!, location: CLLocation!) in
                print("Key '\(key)' has exited and is at location '\(location)'")
            })
            
        }) { (error) in
            print(error.localizedDescription)
        }
    }
    
    func parseSwiped(snapshot: FIRDataSnapshot){
        if let swiped = snapshot.value!["swiped"] as? [String: AnyObject] {
            self.swiped = swiped
            print(self.swiped)
            print(self.swiped.count)
        } else {
            self.swiped = [String:AnyObject]()
        }
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
                    destinationVC.delegate = self
                    destinationVC.food = item
                    destinationVC.searchLocation = center
                    destinationVC.fromHome = true
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
        var foodArray = foodArray
        print(swipedInThisSession)
        for (key, time) in swipedInThisSession {
            foodArray = foodArray.filter({$0.key != key})
        }
        
        foodArray = shuffleArray(foodArray)
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
    
    func onBackButtonTapped(){
        if let navController = self.navigationController {
            navController.popViewControllerAnimated(true)
        }
    }
    
    func onCardSwiped(key: String) {
        let time = NSDate().timeIntervalSince1970
        firebase.child("users").child(uid).child("swiped").child(key).setValue(time)
        swipedInThisSession[key] = true
    }
    
    func onCardSwipedRight(food: Food){
        if userLikes[food.key] == nil {
            let likesManager = LikesManager(uid: uid, key: food.key, author: food.author, name: food.name)
            likesManager.likePost()
        } else {
            let time = NSDate().timeIntervalSince1970
            firebase.child("users").child(uid).child("likes").child(food.key).setValue(time)
        }
    }
    
    func onFoodLiked(){
        let delay = 0.4 * Double(NSEC_PER_SEC)
        let time = dispatch_time(DISPATCH_TIME_NOW, Int64(delay))
        dispatch_after(time, dispatch_get_main_queue()) {
            self.draggableBackground.loadedCards[0].rightClickAction()
        }
    }
    
    func removeFromUserLikes(key: String){
        self.userLikes[key] = nil
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
    
    func dismissNotifications(){
        let firebase = FIRDatabase.database().reference()
        if let uid = NSUserDefaults.standardUserDefaults().objectForKey("USER_UID") as? String  {
            firebase.child("users").child(uid).child("notifications").setValue(0)
            UIApplication.sharedApplication().cancelAllLocalNotifications()
            BatchPush.dismissNotifications()
            NSUserDefaults.standardUserDefaults().setObject(0, forKey: "NOTIFICATIONS")
        }
    }
    
    func generateOnboardingVC() -> OnboardingViewController {
        let screenSize: CGRect = UIScreen.mainScreen().bounds
        let firstPage = OnboardingContentViewController(title: "", body: "", image: UIImage(named: "onBoarding-1"), buttonText: "") { () -> Void in
            // do something here when users press the button, like ask for location services permissions, register for push notifications, connect to social media, or finish the onboarding process
        }
        firstPage.iconWidth = screenSize.width
        firstPage.iconHeight = screenSize.height
        firstPage.topPadding = 20
        
        let secondPage = OnboardingContentViewController(title: "", body: "", image: UIImage(named: "onBoarding-2"), buttonText: "") { () -> Void in
            // do something here when users press the button, like ask for location services permissions, register for push notifications, connect to social media, or finish the onboarding process
        }
        secondPage.iconWidth = screenSize.width
        secondPage.iconHeight = screenSize.height
        secondPage.topPadding = 20
        
        let thirdPage = OnboardingContentViewController(title: "", body: "", image: UIImage(named: "onBoarding-3"), buttonText: "") { () -> Void in
            // do something here when users press the button, like ask for location services permissions, register for push notifications, connect to social media, or finish the onboarding process
        }
        thirdPage.iconWidth = screenSize.width
        thirdPage.iconHeight = screenSize.height
        thirdPage.topPadding = 20
        
        let fourthPage = OnboardingContentViewController(title: "", body: "", image: UIImage(named: "onBoarding-6"), buttonText: "") { () -> Void in
            // do something here when users press the button, like ask for location services permissions, register for push notifications, connect to social media, or finish the onboarding process
        }
        fourthPage.iconWidth = screenSize.width
        fourthPage.iconHeight = screenSize.height
        fourthPage.topPadding = 20
        
        let fifthPage = OnboardingContentViewController(title: "", body: "", image: UIImage(named: "onBoarding-4"), buttonText: "") { () -> Void in
            // do something here when users press the button, like ask for location services permissions, register for push notifications, connect to social media, or finish the onboarding process
        }
        fifthPage.iconWidth = screenSize.width
        fifthPage.iconHeight = screenSize.height
        fifthPage.topPadding = 20
        
        let sixthPage = OnboardingContentViewController(title: "", body: "", image: UIImage(named:"grubbWhite"), buttonText: "Get Started") { () -> Void in
            NSUserDefaults.standardUserDefaults().setObject(true, forKey: "HAS_ONBOARDED")
            self.dismissViewControllerAnimated(true, completion: nil)
        }
        
        sixthPage.iconImageView.contentMode = UIViewContentMode.ScaleAspectFit
        sixthPage.iconWidth = 200
        sixthPage.iconHeight = 200
        sixthPage.topPadding = screenSize.height*0.25
        sixthPage.iconImageView.userInteractionEnabled = true
        let tapGestureRecognizer = UITapGestureRecognizer(target:self, action:Selector("iconTapped"))
        sixthPage.iconImageView.addGestureRecognizer(tapGestureRecognizer)
        
        sixthPage.actionButton.titleLabel!.font = UIFont(name:"HelveticaNeue-Bold", size: 30)
        /*
        fifthPage.actionButton.setTitleColor(UIColor(red: 77.0/255.0, green: 207.0/255.0, blue: 207.0/255.0, alpha: 1.0), forState: .Normal)
        fifthPage.actionButton.layer.borderColor = UIColor.whiteColor().CGColor
        fifthPage.actionButton.layer.borderWidth = 4.0
        fifthPage.actionButton.layer.cornerRadius = 10.0
        fifthPage.actionButton.layer.backgroundColor = UIColor.whiteColor().CGColor
         */
        sixthPage.bottomPadding = screenSize.height*0.3
        
        let onboardingVC = OnboardingViewController(backgroundImage: UIImage(named: "onBoardBackground"), contents: [firstPage, secondPage, thirdPage, fourthPage, fifthPage, sixthPage])
        onboardingVC.shouldMaskBackground = false
        
        return onboardingVC
    }
    
    func iconTapped(){
        print("hi")
        NSUserDefaults.standardUserDefaults().setObject(true, forKey: "HAS_ONBOARDED")
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
}

    