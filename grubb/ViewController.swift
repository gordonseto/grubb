//
//  ViewController.swift
//  grubb
//
//  Created by Gordon Seto on 2016-06-17.
//  Copyright © 2016 grubbapp. All rights reserved.
//

import UIKit

class ViewController: UIViewController, DraggableViewBackgroundDelegate, UITextFieldDelegate {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.

        let draggableBackground: DraggableViewBackground = DraggableViewBackground(frame: self.view.frame)
        self.view.addSubview(draggableBackground)
        draggableBackground.delegate = self
        
        let navigationLayer = UIView(frame: CGRectMake(0, 0, self.view.frame.size.width, 70))
        navigationLayer.backgroundColor = UIColor.whiteColor()
        self.view.addSubview(navigationLayer)
        
        let search = searchField(frame: CGRectMake(8, 30, self.view.frame.size.width * 0.8, 30))
        search.delegate = self
        self.view.addSubview(search)
        
        let filterButton = UIButton(frame: CGRectMake(self.view.frame.size.width - 50, 25, 40, 40))
        filterButton.setImage(UIImage(named: "filterButton"), forState: UIControlState.Normal)
        self.view.addSubview(filterButton)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
    
    func textField(textField: UITextField,shouldChangeCharactersInRange range: NSRange,replacementString string: String) -> Bool
    {
        if string == "\n" {
            textField.resignFirstResponder()
            return false
        }
        return true
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

    