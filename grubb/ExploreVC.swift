
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
import FirebaseStorage

class ExploreVC: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UISearchBarDelegate {

    @IBOutlet weak var collection: UICollectionView!
    
    var likedfoodPreviews = [foodPreview]()
    let screenWidth = UIScreen.mainScreen().bounds.size.width
    let numOfCells: CGFloat = 3
    
    var imagesRef: FIRStorageReference?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        collection.delegate = self
        collection.dataSource = self
        
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
     
        getLikedFood()
        
        let storage = FIRStorage.storage()
        let storageRef = storage.referenceForURL(FIREBASE_STORAGE)
        imagesRef = storageRef.child("images")
        
    }
    
    override func viewDidAppear(animated: Bool) {
        print(likedfoodPreviews.count)
    }
    
    func getLikedFood(){
        likedfoodPreviews = []
        var queryCount = 0
        if let uid = NSUserDefaults.standardUserDefaults().objectForKey("USER_UID") as? String {
            let firebase = FIRDatabase.database().reference()
            firebase.child("users").child(uid).child("likes").queryOrderedByValue().observeEventType(.ChildAdded, withBlock: { (snapshot) -> Void in
                let newFood = snapshot.value as? NSNumber
                self.addToFoodPreviewArray(snapshot.key)
            })
            firebase.child("users").child(uid).child("likes").observeEventType(.ChildRemoved, withBlock: {(snapshot) -> Void in
                self.removeFromFoodPreviewArray(snapshot.key)
            })
        }
    }
    
    func addToFoodPreviewArray(key: String){
        var newFoodPreview = foodPreview(key: key)
        likedfoodPreviews.append(newFoodPreview)
        
        if let imagesRef = imagesRef {
            let childRef = imagesRef.child(key)
            childRef.dataWithMaxSize(1 * 1024 * 1024, completion: { (data, error) in
                if (error != nil){
                    print(error.debugDescription)
                } else {
                    let foodImage: UIImage! = UIImage(data: data!)
                    newFoodPreview.foodImage = foodImage
                    print("downloaded \(key)'s image")
                    self.collection.reloadData()
                }
            })
        }
    }
    
    func removeFromFoodPreviewArray(key: String){
        print("REMOVE \(key)")
        let foodPreviewKeys = likedfoodPreviews.map { $0.key }
        let index = foodPreviewKeys.indexOf(key)
        if index != nil {
            likedfoodPreviews.removeAtIndex(index!)
        }
        collection.reloadData()
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("FoodCell", forIndexPath: indexPath) as! FoodCell
        let foodPrev: foodPreview!
        foodPrev = likedfoodPreviews[likedfoodPreviews.count - 1 - indexPath.row]
        cell.configureCell(foodPrev)
        return cell
        
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        //let item = likedfoodPreviews[likedfoodPreviews.count - 1 - indexPath.row]
        //performSegueWithIdentifier("itemVC", sender: item)
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return likedfoodPreviews.count
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
                if let item = sender as? foodPreview {
                    
                }
            }
        }
    }

}
