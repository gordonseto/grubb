//
//  foodPreview.swift
//  grubb
//
//  Created by Gordon Seto on 2016-06-24.
//  Copyright © 2016 grubapp. All rights reserved.
//

import Foundation
import UIKit
import FirebaseStorage

class foodPreview {
    private var _key: String!
    var foodImage: UIImage?
    
    var key: String {
        get {
            return _key
        }
        set {
            _key = key
        }
    }
    
    init(key: String){
        _key = key
    }
}