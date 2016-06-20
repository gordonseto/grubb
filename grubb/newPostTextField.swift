//
//  newPostTextField.swift
//  grubb
//
//  Created by Gordon Seto on 2016-06-20.
//  Copyright © 2016 grubapp. All rights reserved.
//

import UIKit

class newPostTextField: UITextField {

    override func awakeFromNib() {
        
    self.attributedPlaceholder = NSAttributedString(string: "Name of the dish", attributes: [NSForegroundColorAttributeName: UIColor.whiteColor()])
        
    }
}
