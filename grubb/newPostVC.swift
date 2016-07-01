//
//  newPostVC.swift
//  grubb
//
//  Created by Gordon Seto on 2016-06-19.
//  Copyright © 2016 grubbapp. All rights reserved.
//

import UIKit
import FirebaseDatabase
import GoogleMaps
import GeoFire
import FirebaseStorage

class newPostVC: UIViewController, UITextViewDelegate, UITextFieldDelegate {

    @IBOutlet weak var foodImage: UIImageView!
    @IBOutlet weak var nameInput: UITextView!
    @IBOutlet weak var locationButton: UIButton!
    @IBOutlet weak var priceInput: UITextField!
    @IBOutlet weak var shareButton: UIButton!
    @IBOutlet weak var progressBar: UIProgressView!
    @IBOutlet weak var breakfastButton: categoryButton!
    @IBOutlet weak var lunchButton: categoryButton!
    @IBOutlet weak var dinnerButton: categoryButton!
    @IBOutlet weak var dessertButton: categoryButton!
    
    var firebase: FIRDatabaseReference!
    var restaurant: String!
    var coordinate: CLLocationCoordinate2D!
    var image: UIImage?
    var categoryArray = [String]()
    var numLikes: Int = 0
    
    var priceInputIsEditing: Bool = false
    
    var editMode = false
    var food: Food!
    
    let TEXTVIEW_PLACEHOLDER = " Name of the dish"
    let MAX_TEXT = 80
    let MAX_DIGITS = 6
    
    let LATITUDE_BOUND = 0.015
    let LONGITUDE_BOUND = 0.035
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        prefersStatusBarHidden()
        self.hideKeyboardWhenTappedAround()
        
        firebase = FIRDatabase.database().reference()
        
        nameInput.delegate = self
        priceInput.delegate = self
        
        if editMode{
            initializeEditMode()
        } else {
            predictCategory()
        }
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("keyboardWillShow:"), name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("keyboardWillHide:"), name: UIKeyboardWillHideNotification, object: nil)
        
        
    }
    
    override func viewDidAppear(animated: Bool) {
        
        foodImage.image = image!
        foodImage.clipsToBounds = true
        
        if restaurant != nil {
            locationButton.setTitle(restaurant, forState: .Normal)
        }
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    func textViewDidBeginEditing(textView: UITextView) {
        if nameInput.text == TEXTVIEW_PLACEHOLDER {
            nameInput.text = ""
        }
    }
    
    func textViewDidEndEditing(textView: UITextView) {
        if textView.text.isEmpty {
            textView.text = TEXTVIEW_PLACEHOLDER
        }
    }
    
    func textView(textView: UITextView, shouldChangeTextInRange range: NSRange, replacementText text: String) -> Bool {
        let maxtext: Int = MAX_TEXT
        //If the text is larger than the maxtext, the return is false
        if text == "\n" {
            textView.resignFirstResponder()
            return false
        }
        return textView.text.characters.count + (text.characters.count - range.length) <= maxtext
    }
    
    @IBAction func onSharePressed(sender: AnyObject) {
        savePostToDatabase()
    }
    
    func savePostToDatabase(){
        if nameInput.text != "" || nameInput.text != TEXTVIEW_PLACEHOLDER {
            if let price = Double(priceInput.text!) {
                if !categoryArray.isEmpty {
                    if let restaurant = restaurant {
                        if let coordinate = coordinate {
                            if let uid = NSUserDefaults.standardUserDefaults().objectForKey("USER_UID") as? String {
                                if let img = foodImage.image {
                                    shareButton.enabled = false
                                    progressBar.hidden = false
                                    breakfastButton.enabled = false
                                    lunchButton.enabled = false
                                    dinnerButton.enabled = false
                                    dessertButton.enabled = false
                                    
                                    var key: String
                                    if editMode {
                                        key = self.food.key
                                    } else {
                                        key = firebase.child("posts").childByAutoId().key
                                    }
                                    
                                    let storage = FIRStorage.storage()
                                    let storageRef = storage.referenceForURL(FIREBASE_STORAGE)
                                    let imagesRef = storageRef.child("images")
                                    let childRef = imagesRef.child(key)
                                    let imgData: NSData = UIImageJPEGRepresentation(img, 1)!
                                    
                                    let uploadTask = childRef.putData(imgData, metadata: nil) { metadata, error in
                                        if (error != nil) {
                                            print(error.debugDescription)
                                            self.showErrorAlert("Oops! There was an error sharing your dish.", msg: "Please make sure you have an internet connection.")
                                            self.shareButton.enabled = true
                                        } else {
                                            let post: [String: AnyObject] = ["name": self.nameInput.text!.lowercaseString.capitalizedString, "author": uid, "price": price, "restaurant":  restaurant, "categoryArray": self.categoryArray, "likes": self.numLikes]
                                            
                                            self.firebase.child("posts").child(key).setValue(post)
                                            let seconds = NSDate().timeIntervalSince1970
                                            self.firebase.child("users").child(uid).child("posts").child(key).setValue(seconds)
                                            
                                            let geoFire = GeoFire(firebaseRef: self.firebase.child("geolocations"))
                                            geoFire.setLocation(CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude), forKey: key)
                                            
                                            print(post)
                                            print(coordinate)
                                            self.shareButton.enabled = true
                                            
                                            let delay = 1.0 * Double(NSEC_PER_SEC)
                                            let time = dispatch_time(DISPATCH_TIME_NOW, Int64(delay))
                                            dispatch_after(time, dispatch_get_main_queue()) {
                                                self.performSegueWithIdentifier("tabBarVC", sender: nil)
                                            }
                                        }
                                    }
                                    
                                    uploadTask.observeStatus(.Progress) { snapshot in
                                        // Upload reported progress
                                        if let progress = snapshot.progress {
                                            let percentComplete = 100.0 * Double(progress.completedUnitCount) / Double(progress.totalUnitCount)
                                            self.progressBar.setProgress(Float(percentComplete), animated: true)
                                        }
                                    }
                                    
                                    
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    @IBAction func onCancelPressed(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func onLocationPressed(sender: AnyObject){
        let autocompleteController = GMSAutocompleteViewController()
        autocompleteController.delegate = self
        if let currentLatitude = NSUserDefaults.standardUserDefaults().objectForKey("CURRENT_LATITUDE") as? Double {
            if let currentLongitude = NSUserDefaults.standardUserDefaults().objectForKey("CURRENT_LONGITUDE") as? Double {
                let neBoundsCorner = CLLocationCoordinate2D(latitude: currentLatitude + LATITUDE_BOUND,
                                                            longitude: currentLongitude - LONGITUDE_BOUND)
                let swBoundsCorner = CLLocationCoordinate2D(latitude: currentLatitude - LATITUDE_BOUND,
                                                            longitude: currentLongitude + LONGITUDE_BOUND)
                let bounds = GMSCoordinateBounds(coordinate: neBoundsCorner,
                                                 coordinate: swBoundsCorner)
                autocompleteController.autocompleteBounds = bounds
            }
        }
        self.presentViewController(autocompleteController, animated: true, completion: nil)
    }
    
    func textFieldDidBeginEditing(textField: UITextField) {
        priceInputIsEditing = true
    }
    
    func textFieldDidEndEditing(textField: UITextField) {
        priceInputIsEditing = false
    }
    
    
    
    func textField(textField: UITextField,shouldChangeCharactersInRange range: NSRange,replacementString string: String) -> Bool
    {
        let newCharacters = NSCharacterSet(charactersInString: string)
        let boolIsNumber = NSCharacterSet.decimalDigitCharacterSet().isSupersetOfSet(newCharacters)
        
        //limit characters to digits and one decimal point
        if boolIsNumber == true {
            //limit characters to 6
            guard let text = textField.text else { return true }
            let newLength = text.characters.count + string.characters.count - range.length
            if newLength > 6 {
                return false
            }
            return true
        } else {
            //close keyboard if 'done' is pressed
            if string == "\n" {
                textField.resignFirstResponder()
                return false
            }
            //limit characters to digits and one decimal point
            if string == "." {
                let countdots = textField.text!.componentsSeparatedByString(".").count - 1
                if countdots == 0 {
                    return true
                } else {
                    if countdots > 0 && string == "." {
                        return false
                    } else {
                        return true
                    }
                }
            } else {
                return false
            }
        }
    }
    
    // push view up when keyboard is blocking price input
    func keyboardWillShow(notification: NSNotification) {
        if priceInputIsEditing {
            if let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.CGRectValue() {
                self.view.frame.origin.y -= keyboardSize.height
            }
        }
    }
    
    func keyboardWillHide(notification: NSNotification) {
        if priceInputIsEditing {
            if let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.CGRectValue() {
                self.view.frame.origin.y += keyboardSize.height
            }
        }
    }
    
    func predictCategory(){
        let hour = Int(NSCalendar.currentCalendar().component(.Hour, fromDate: NSDate()))
        
        var tag: Int
        print(hour)
        if hour >= 4 && hour < 12 {
            categoryArray = ["Breakfast"]
            tag = 1
        }
        else if hour >= 12 && hour < 17 {
            categoryArray = ["Lunch"]
            tag = 2
        }
        else if hour >= 17 && hour < 22 {
            categoryArray = ["Dinner"]
            tag = 3
        } else {
            categoryArray = ["Dessert"]
            tag = 4
        }
        let button = self.view.viewWithTag(tag) as! UIButton
        highlightButton(button)
    }

    @IBAction func onCategoryTapped(sender: UIButton){
        if let category = sender.titleLabel!.text {
            if categoryArray.contains(category) {
                categoryArray = categoryArray.filter {$0 != category}
                print(categoryArray)
                deselectButton(sender)
            } else {
                highlightButton(sender)
                categoryArray.append(category)
                print(categoryArray)
            }
        }
    }
    
    func deselectButton(button: UIButton){
        button.backgroundColor = UIColor.clearColor()
        button.setTitleColor(UIColor.whiteColor(), forState: .Normal)
    }
    
    func highlightButton(button: UIButton){
        button.backgroundColor = UIColor.whiteColor()
        button.setTitleColor(UIColor.darkGrayColor(), forState: .Normal)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if(segue.identifier == "tabBarVC"){
            let tabBarVC = segue.destinationViewController as! UITabBarController
            tabBarVC.selectedIndex = 1
        }
    }
    
    func initializeEditMode(){
        restaurant = food.restaurant
        coordinate = food.geolocation.coordinate
        image = food.foodImage
        foodImage.image = image
        foodImage.clipsToBounds = true
        categoryArray = food.categoryArray
        nameInput.text = food.name
        priceInput.text = String.localizedStringWithFormat("%.2f", food.price)
        
        highlightCategoryButtons()
    }
    
    func highlightCategoryButtons(){
        for var i = 0; i < categoryArray.count; i++ {
            var tag: Int
            var category = categoryArray[i]
            if category == "Breakfast" {
                tag = 1
            } else if category == "Lunch" {
                tag = 2
            } else if category == "Dinner" {
                tag = 3
            } else {
                tag = 4
            }
            let button = self.view.viewWithTag(tag) as! UIButton
            highlightButton(button)
        }
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

