//
//  Food.swift
//  grubb
//
//  Created by Gordon Seto on 2016-06-17.
//  Copyright © 2016 grubapp. All rights reserved.
//

import Foundation
import MapKit

class Food {

    private var _id: String!
    private var _name: String!
    private var _desc: String!
    private var _category: [String]!
    private var _price: Int!
    private var _restaurant: String!
    private var _geolocation: CLLocation!
    private var _imageUrl: String!
    var foodImage: UIImage?
    
    var name: String {
        return _name
    }
    
    var desc: String {
        return _desc
    }
    
    var category: [String] {
        return _category
    }
    
    var price: Int {
        return _price
    }
    
    var restaurant: String {
        return _restaurant
    }
    
    var geolocation: CLLocation {
        return _geolocation
    }
    
    var imageUrl: String {
        return _imageUrl
    }
    
    
    
    init(name: String){
        _name = name
        _imageUrl = "http://res.cloudinary.com/gordonseto/image/upload/v1465232634/trnorlc6ihzqjcngyybx.jpg"
        _desc = "\(_name)'s default description for a food item"
        _category = ["breakfast", "lunch", "dinner", "dessert"]
        _price = 21
        _restaurant = "Mucho Burrito"
        _geolocation = CLLocation(latitude: 51.128735, longitude: -114.196981)
    }
}