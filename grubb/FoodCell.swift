//
//  FoodCell.swift
//  grubb
//
//  Created by Gordon Seto on 2016-06-17.
//  Copyright © 2016 grubbapp. All rights reserved.
//

import UIKit
import FirebaseStorage

class FoodCell: UICollectionViewCell {

    @IBOutlet weak var foodImage: UIImageView!
    
    required init?(coder aDecoder: NSCoder){
        super.init(coder: aDecoder)
        
        
    }
    
    func configureCell(foodPrev: foodPreview) {
        let image: UIImage? = foodPrev.foodImage
        foodImage.image = image
    }
}
