//
//  Food.swift
//  grubb
//
//  Created by Gordon Seto on 2016-06-17.
//  Copyright © 2016 grubbapp. All rights reserved.
//

import Foundation
import MapKit

class Food {

    private var _key: String!
    private var _name: String!
    private var _categoryArray: [String]!
    private var _price: Double!
    private var _restaurant: String!
    private var _geolocation: CLLocation!
    private var _imageUrl: String!
    private var _search_key: String!
    var foodImage: UIImage?
    
    var key: String {
        return _key
    }
    
    var name: String {
        return _name
    }
    
    var categoryArray: [String] {
        return _categoryArray
    }
    
    var price: Double {
        return _price
    }
    
    var restaurant: String {
        return _restaurant
    }
    
    var geolocation: CLLocation {
        return _geolocation
    }
    
    var search_key: String {
        return _search_key
    }
    
    var imageUrl: String {
        return _imageUrl
    }
    
    init(key: String, name: String, restaurant: String, price: Double, categoryArray: [String], geolocation: CLLocation, search_key: String){
        _key = key
        _name = name
        _restaurant = restaurant
        _price = price
        _categoryArray = categoryArray
        _geolocation = geolocation
        _search_key = search_key
        _imageUrl = "http://res.cloudinary.com/gordonseto/image/upload/v1465232634/trnorlc6ihzqjcngyybx.jpg"
    }
}