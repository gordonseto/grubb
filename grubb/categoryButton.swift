//
//  categoryButton.swift
//  grubb
//
//  Created by Gordon Seto on 2016-06-20.
//  Copyright © 2016 grubapp. All rights reserved.
//

import UIKit

class categoryButton: UIButton {

    override func awakeFromNib() {
        self.layer.cornerRadius = 0.5 * self.bounds.size.width
        self.clipsToBounds = true
        self.layer.borderWidth = 1
        self.layer.borderColor = UIColor.whiteColor().CGColor
    }

}
