//
//  itemVC.swift
//  grubb
//
//  Created by Gordon Seto on 2016-06-17.
//  Copyright © 2016 grubapp. All rights reserved.
//

import UIKit

class itemVC: UIViewController {

    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var descLabel: UITextView!
    @IBOutlet weak var foodImage: UIImageView!
    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var saveImage: UIImageView!
    @IBOutlet weak var priceLabel: UILabel!
    @IBOutlet weak var restaurantLabel: UILabel!
    @IBOutlet weak var ratingImage: UIImageView!
    @IBOutlet weak var openNowLabel: UILabel!
    
    var food: Food!
    
    override func viewDidLoad() {
        super.viewDidLoad()


    }

    @IBAction func backButtonPressed(sender: AnyObject) {
        dismissViewControllerAnimated(true, completion: nil)
    }

}
