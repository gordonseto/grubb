
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
    
    var food = [Food]()
    let screenWidth = UIScreen.mainScreen().bounds.size.width
    let numOfCells: CGFloat = 3
    
    override func viewDidLoad() {
        super.viewDidLoad()

        collection.delegate = self
        collection.dataSource = self
        
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
     
    }
    
    override func viewDidAppear(animated: Bool) {
        getLikedFood()
    }
    
    func getLikedFood(){
        food = []
        if let uid = NSUserDefaults.standardUserDefaults().objectForKey("USER_UID") as? String {
            let firebase = FIRDatabase.database().reference()
            firebase.child("users").child(uid).child("likes").observeEventType(.ChildAdded, withBlock: { (snapshot) -> Void in
                let newFood = snapshot.value as? NSNumber
                if newFood == 1 {
                    self.addToFoodArray(snapshot.key)
                }
            })
            firebase.child("users").child(uid).child("likes").observeEventType(.ChildRemoved, withBlock: { (snapshot) -> Void in

            })
        }
    }
    
    func addToFoodArray(key: String){
        print(key)
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
       return UICollectionViewCell()
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
       // let item = food[indexPath.row]
        //performSegueWithIdentifier("itemVC", sender: item)
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 0
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
