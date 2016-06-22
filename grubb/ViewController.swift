//
//  ViewController.swift
//  grubb
//
//  Created by Gordon Seto on 2016-06-17.
//  Copyright © 2016 grubapp. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.

        let draggableBackground: DraggableViewBackground = DraggableViewBackground(frame: self.view.frame)
        self.view.addSubview(draggableBackground)
        /*
        let searchView: UIView = UIView(frame: CGRectMake(0, 0, self.view.frame.size.width, 55))
        searchView.backgroundColor = UIColor.whiteColor()
        self.view.addSubview(searchView)
        */
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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