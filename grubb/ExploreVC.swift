
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
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    
    var likedFoodPreviews = [foodPreview]()
    var myFoodPreviews = [foodPreview]()
    let screenWidth = UIScreen.mainScreen().bounds.size.width
    let numOfCells: CGFloat = 3
    var displayMode = 0
    let LIKED_MODE = 0
    let MYFOOD_MODE = 0
    
    var imagesRef: FIRStorageReference?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        collection.delegate = self
        collection.dataSource = self
        
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
     
        getLikedandMyFood()
        
        let storage = FIRStorage.storage()
        let storageRef = storage.referenceForURL(FIREBASE_STORAGE)
        imagesRef = storageRef.child("images")
        
        displayMode = segmentedControl.selectedSegmentIndex
        
    }
    
    override func viewDidAppear(animated: Bool) {
        print(likedFoodPreviews.count)
        print(myFoodPreviews.count)
    }
    
    func getLikedandMyFood(){
        likedFoodPreviews = []
        myFoodPreviews = []
        if let uid = NSUserDefaults.standardUserDefaults().objectForKey("USER_UID") as? String {
            let firebase = FIRDatabase.database().reference()
            firebase.child("users").child(uid).child("likes").queryOrderedByValue().observeEventType(.ChildAdded, withBlock: { (snapshot) -> Void in
                let newFood = snapshot.value as? NSNumber
                self.addToFoodPreviewArray(snapshot.key, arrayName: "likedFoods")
            })
            firebase.child("users").child(uid).child("likes").observeEventType(.ChildRemoved, withBlock: {(snapshot) -> Void in
                self.removeFromFoodPreviewArray(snapshot.key, arrayName: "likedFoods")
            })
            firebase.child("users").child(uid).child("posts").queryOrderedByValue().observeEventType(.ChildAdded, withBlock: { (snapshot) -> Void in
                let newFood = snapshot.value as? NSNumber
                self.addToFoodPreviewArray(snapshot.key, arrayName: "myFood")
            })
            firebase.child("users").child(uid).child("posts").observeEventType(.ChildRemoved, withBlock: {(snapshot) -> Void in
                self.removeFromFoodPreviewArray(snapshot.key, arrayName: "myFood")
            })
        }
    }
    
    func addToFoodPreviewArray(key: String, arrayName: String){
        var newFoodPreview = foodPreview(key: key)
        if arrayName == "likedFoods" {
            likedFoodPreviews.append(newFoodPreview)
        } else {
            myFoodPreviews.append(newFoodPreview)
        }
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
    
    func removeFromFoodPreviewArray(key: String, arrayName: String){
        print("REMOVE \(key)")
        if arrayName == "likedFoods" {
            let foodPreviewKeys = likedFoodPreviews.map { $0.key }
            let index = foodPreviewKeys.indexOf(key)
            if index != nil {
                likedFoodPreviews.removeAtIndex(index!)
            }
        } else {
            let foodPreviewKeys = myFoodPreviews.map { $0.key }
            let index = foodPreviewKeys.indexOf(key)
            if index != nil {
                myFoodPreviews.removeAtIndex(index!)
            }
        }
        collection.reloadData()
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("FoodCell", forIndexPath: indexPath) as! FoodCell
        let foodPrev: foodPreview!
        if displayMode == LIKED_MODE {
            foodPrev = likedFoodPreviews[likedFoodPreviews.count - 1 - indexPath.row]
        }
        else {
            foodPrev = myFoodPreviews[myFoodPreviews.count - 1 - indexPath.row]
        }
        cell.configureCell(foodPrev)
        return cell
        
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        //let item = likedfoodPreviews[likedfoodPreviews.count - 1 - indexPath.row]
        //performSegueWithIdentifier("itemVC", sender: item)
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if displayMode == LIKED_MODE {
            return likedFoodPreviews.count
        } else {
            return myFoodPreviews.count
        }
    }
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        return CGSizeMake(screenWidth / 3, screenWidth / 3)
    }
    
    @IBAction func onSegmentedControlChanged(sender: AnyObject) {
        displayMode = segmentedControl.selectedSegmentIndex
        collection.reloadData()
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
