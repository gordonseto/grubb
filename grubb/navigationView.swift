//
//  navigationView.swift
//  grubb
//
//  Created by Gordon Seto on 2016-06-24.
//  Copyright © 2016 grubapp. All rights reserved.
//

import UIKit

class navigationView: UIView {

    override func awakeFromNib() {
        layer.borderWidth = 1.0
        layer.borderColor = UIColor(red: SHADOW_COLOR, green: SHADOW_COLOR, blue: SHADOW_COLOR, alpha: 0.3).CGColor
    }

}
