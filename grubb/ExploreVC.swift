
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
import Batch

class ExploreVC: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UISearchBarDelegate {

    @IBOutlet weak var collection: UICollectionView!
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    
    var likedFoodPreviews = [foodPreview]()
    var myFoodPreviews = [foodPreview]()
    let screenWidth = UIScreen.mainScreen().bounds.size.width
    let numOfCells: CGFloat = 3
    var displayMode = 0
    let LIKED_MODE = 0
    let MYFOOD_MODE = 1
    
    var imagesRef: FIRStorageReference?
    
    var loadingLabel: UILabel!
    var activityIndicator: UIActivityIndicatorView!
    
    var refreshControl: UIRefreshControl!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        collection.delegate = self
        collection.dataSource = self
        
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        
        self.navigationController?.navigationBarHidden = true
        
        refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: Selector("refreshView:"), forControlEvents: UIControlEvents.ValueChanged)
        refreshControl.tintColor = UIColor.lightGrayColor()
        self.collection.addSubview(refreshControl)
        self.collection.scrollEnabled = true
        self.collection.alwaysBounceVertical = true
     
        getLikedandMyFood()
        
        let storage = FIRStorage.storage()
        let storageRef = storage.referenceForURL(FIREBASE_STORAGE)
        imagesRef = storageRef.child("images")
        
        displayMode = segmentedControl.selectedSegmentIndex
        
        startLoadingAnimation()
        
    }
    
    override func viewDidAppear(animated: Bool) {
        print(likedFoodPreviews.count)
        print(myFoodPreviews.count)
        
        UIApplication.sharedApplication().cancelAllLocalNotifications()
        BatchPush.dismissNotifications()
    }
    
    func getLikedandMyFood(){
        likedFoodPreviews = []
        myFoodPreviews = []
        if let uid = NSUserDefaults.standardUserDefaults().objectForKey("USER_UID") as? String {
            let firebase = FIRDatabase.database().reference()
            firebase.child("users").child(uid).child("likes").queryOrderedByValue().observeEventType(.ChildAdded, withBlock: { (snapshot) -> Void in
                if let newFood = snapshot.value as? NSNumber {
                    self.addToFoodPreviewArray(snapshot.key, arrayName: "likedFoods")
                }
            })
            firebase.child("users").child(uid).child("likes").observeEventType(.ChildRemoved, withBlock: {(snapshot) -> Void in
                self.removeFromFoodPreviewArray(snapshot.key, arrayName: "likedFoods")
            })
            firebase.child("users").child(uid).child("likes").observeEventType(.ChildChanged, withBlock: {(snapshot) -> Void in
                self.removeFromFoodPreviewArray(snapshot.key, arrayName: "likedFoods")
                self.addToFoodPreviewArray(snapshot.key, arrayName: "likedFoods")
            })
            firebase.child("users").child(uid).child("posts").queryOrderedByValue().observeEventType(.ChildAdded, withBlock: { (snapshot) -> Void in
                if let newFood = snapshot.value as? NSNumber {
                    self.addToFoodPreviewArray(snapshot.key, arrayName: "myFood")
                }
            })
            firebase.child("users").child(uid).child("posts").observeEventType(.ChildRemoved, withBlock: {(snapshot) -> Void in
                self.removeFromFoodPreviewArray(snapshot.key, arrayName: "myFood")
            })
        }
    }
    
    func addToFoodPreviewArray(key: String, arrayName: String){
        var newFoodPreview = foodPreview(key: key)
        var imageLoadedByOtherArray = false
        if arrayName == "likedFoods" {
            if let checkOtherArray = self.myFoodPreviews.indexOf({$0.key == newFoodPreview.key}) {
                likedFoodPreviews.append(myFoodPreviews[checkOtherArray])
                imageLoadedByOtherArray = true
            } else {
                likedFoodPreviews.append(newFoodPreview)
            }
        } else {
            if let checkOtherArray = self.likedFoodPreviews.indexOf({$0.key == newFoodPreview.key}) {
                myFoodPreviews.append(likedFoodPreviews[checkOtherArray])
                imageLoadedByOtherArray = true
            } else {
                myFoodPreviews.append(newFoodPreview)
            }
        }
        if !imageLoadedByOtherArray {
            if let imagesRef = imagesRef {
                let childRef = imagesRef.child(key)
                childRef.dataWithMaxSize(1 * 1024 * 1024, completion: { (data, error) in
                    if (error != nil){
                        print(error.debugDescription)
                        self.stopLoadingAnimation()
                    } else {
                        let foodImage: UIImage! = UIImage(data: data!)
                        newFoodPreview.foodImage = foodImage
                        print("downloaded \(key)'s image")
                        self.collection.reloadData()
                        self.stopLoadingAnimation()
                    }
                })
            }
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
        let item: foodPreview
        
        if displayMode == LIKED_MODE {
            item = likedFoodPreviews[likedFoodPreviews.count - 1 - indexPath.row]
        } else {
            item = myFoodPreviews[myFoodPreviews.count - 1 - indexPath.row]
        }
        performSegueWithIdentifier("itemVCFromExplore", sender: item)
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
        return CGSizeMake(screenWidth / CGFloat(3.0), screenWidth / CGFloat(3.0))
    }
    
    @IBAction func onSegmentedControlChanged(sender: AnyObject) {
        displayMode = segmentedControl.selectedSegmentIndex
        collection.reloadData()
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "itemVCFromExplore" {
            if let destinationVC = segue.destinationViewController as? itemVC {
                if let item = sender as? foodPreview {
                    destinationVC.key = item.key
                    destinationVC.image = item.foodImage
                    destinationVC.fromHome = false
                }
            }
        }
    }
    
    func startLoadingAnimation(){
        activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.Gray)
        activityIndicator.frame = CGRect(x: 0, y: 0, width: 50, height: 50)
        activityIndicator.center = CGPointMake(UIScreen.mainScreen().bounds.size.width/2 - 32, UIScreen.mainScreen().bounds.size.height/2 - 90)
        activityIndicator.startAnimating()
        collection.addSubview(activityIndicator)
        
        loadingLabel = UILabel(frame: CGRectMake(0, 0, 100, 30))
        loadingLabel.center = CGPointMake(UIScreen.mainScreen().bounds.size.width/2 + 32, UIScreen.mainScreen().bounds.size.height/2 - 90)
        loadingLabel.text = "Loading..."
        loadingLabel.textColor = UIColor.grayColor()
        collection.addSubview(loadingLabel)
    }
    
    func stopLoadingAnimation(){
        activityIndicator.removeFromSuperview()
        loadingLabel.removeFromSuperview()
    }
    
    func refreshView(sender: AnyObject){
        self.collection.reloadData()
        self.refreshControl.endRefreshing()
    }

}
