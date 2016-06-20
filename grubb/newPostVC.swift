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

class newPostVC: UIViewController, UITextViewDelegate, UITextFieldDelegate {

    @IBOutlet weak var foodImage: UIImageView!
    @IBOutlet weak var nameInput: UITextView!
    @IBOutlet weak var locationButton: UIButton!
    @IBOutlet weak var priceInput: UITextField!
    
    var firebase: FIRDatabaseReference!
    var restaurant: String!
    var coordinate: CLLocationCoordinate2D!
    var image: UIImage?
    var categoryArray = [String]()
    
    var priceInputIsEditing: Bool = false
    
    let TEXTVIEW_PLACEHOLDER = " Name of the dish"
    let MAX_TEXT = 80
    let MAX_DIGITS = 6
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        prefersStatusBarHidden()
        self.hideKeyboardWhenTappedAround()
        
        firebase = FIRDatabase.database().reference()
        
        nameInput.delegate = self
        priceInput.delegate = self
        
        predictCategory()
        
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
        if nameInput.text != "" || nameInput.text != TEXTVIEW_PLACEHOLDER {
            if let price = Double(priceInput.text!) {
                if !categoryArray.isEmpty {
                    if let restaurant = restaurant {
                        if let coordinate = coordinate {
                            if let uid = NSUserDefaults.standardUserDefaults().objectForKey("USER_UID") as? String {
                                let key = firebase.child("posts").childByAutoId().key
                                let post: [String: AnyObject] = ["name": nameInput.text!, "author": uid, "price": price, "restaurant":  restaurant, "categoryArray": categoryArray]
                                firebase.child("posts").child(key).setValue(post)
                                print(post)
                                print(coordinate)
                                performSegueWithIdentifier("tabBarVC", sender: nil)
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
            tabBarVC.selectedIndex = 0
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

