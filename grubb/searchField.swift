//
//  searchField.swift
//  grubb
//
//  Created by Gordon Seto on 2016-06-21.
//  Copyright © 2016 grubapp. All rights reserved.
//

import UIKit

class searchField: UITextField {

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.placeholder = "Search"
        self.backgroundColor = UIColor(red: 0.92, green: 0.93, blue: 0.95, alpha: 1)
        self.font = UIFont(name:"HelveticaNeue", size: 14.0)
        self.layer.cornerRadius = 5.0
        self.autocorrectionType = UITextAutocorrectionType.No
        self.keyboardType = UIKeyboardType.Default
        self.returnKeyType = UIReturnKeyType.Search
        self.clearButtonMode = UITextFieldViewMode.WhileEditing
        self.contentVerticalAlignment = UIControlContentVerticalAlignment.Center
        
        let paddingView = UIView(frame: CGRectMake(0, 0, 15, self.frame.height))
        self.leftView = paddingView
        self.leftViewMode = UITextFieldViewMode.Always
    }

}
