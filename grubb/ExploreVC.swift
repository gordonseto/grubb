
//
//  ExploreVC.swift
//  grubb
//
//  Created by Gordon Seto on 2016-06-17.
//  Copyright © 2016 grubbapp. All rights reserved.
//

import UIKit
import AVFoundation
import GeoFire
import FirebaseDatabase

class ExploreVC: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UISearchBarDelegate {

    @IBOutlet weak var collection: UICollectionView!
    @IBOutlet weak var searchBar: UISearchBar!
    
    var food = [Food]()
    let screenWidth = UIScreen.mainScreen().bounds.size.width
    let numOfCells: CGFloat = 3
    
    override func viewDidLoad() {
        super.viewDidLoad()

        collection.delegate = self
        collection.dataSource = self
        
        searchBar.delegate = self
        searchBar.returnKeyType = UIReturnKeyType.Done
        
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        
        let firebase = FIRDatabase.database().reference()
        let geofireRef = firebase.child("geolocations")
        let geofire = GeoFire(firebaseRef: geofireRef)
        
        let center = CLLocation(latitude: 51.1262105, longitude: -114.2073206)
        // Query locations at [37.7832889, -122.4056973] with a radius of 600 meters
        var circleQuery = geofire.queryAtLocation(center, withRadius: 0.6)
        
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        if let cell = collectionView.dequeueReusableCellWithReuseIdentifier("FoodCell", forIndexPath: indexPath) as? FoodCell {
            print(food[indexPath.row].name)
            cell.configureCell(food[indexPath.row])
            return cell
        } else {
            return FoodCell()
        }
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        let item = food[indexPath.row]
        performSegueWithIdentifier("itemVC", sender: item)
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return food.count
    }
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        return CGSizeMake(screenWidth / 3, screenWidth / 3)
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "itemVC" {
            if let destinationVC = segue.destinationViewController as? itemVC {
                if let item = sender as? Food {
                    destinationVC.food = item
                }
            }
        }
    }

}
