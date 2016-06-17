//
//  FoodCell.swift
//  grubb
//
//  Created by Gordon Seto on 2016-06-17.
//  Copyright © 2016 grubapp. All rights reserved.
//

import UIKit

class FoodCell: UICollectionViewCell {

    @IBOutlet weak var foodImage: UIImageView!
    var food: Food!

    func configureCell(food: Food){
        
        self.food = food
        if let url = NSURL(string: food.imageUrl){
            print(url)
            downloadImage(url)
        }
    }
    
    func downloadImage(url: NSURL){
        getDataFromUrl(url) { (data, response, error) in
            dispatch_async(dispatch_get_main_queue()) { () -> Void in
                guard let data = data where error == nil else { return }
                self.foodImage.image = UIImage(data: data)
            }
        }
    }
    
    func getDataFromUrl(url: NSURL, completion: ((data: NSData?, response: NSURLResponse?, error: NSError?) -> Void)){
        
        NSURLSession.sharedSession().dataTaskWithURL(url){ (data, response, error) in
            completion(data: data, response: response, error: error)
        }.resume()
    }

}
