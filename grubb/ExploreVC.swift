
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
    var downloadedFoodPreviews = [foodPreview]()
    let screenWidth = UIScreen.mainScreen().bounds.size.width
    let numOfCells: CGFloat = 3
    var displayMode = 0
    let LIKED_MODE = 0
    let MYFOOD_MODE = 1
    
    let NUM_IMAGES_LOADED = 21
    
    var imagesRef: FIRStorageReference?
    
    var loadingLabel: UILabel!
    var activityIndicator: UIActivityIndicatorView!
    
    var refreshControl: UIRefreshControl!
    
    var uid: String = ""
    
    var firebase: FIRDatabaseReference!
    
    var loadingImages: Bool = false
    var loadedFood = 0
    var previousSnapshotDict: [String: Int]?
    
    var downloadTasks = [FIRStorageDownloadTask]()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        collection.delegate = self
        collection.dataSource = self
        
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        
        firebase = FIRDatabase.database().reference()
        
        uid = NSUserDefaults.standardUserDefaults().objectForKey("USER_UID") as! String
        dismissNotifications()
        
        self.navigationController?.navigationBarHidden = true
        
        refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: Selector("refreshView:"), forControlEvents: UIControlEvents.ValueChanged)
        refreshControl.tintColor = UIColor.lightGrayColor()
        self.collection.addSubview(refreshControl)
        self.collection.scrollEnabled = true
        self.collection.alwaysBounceVertical = true
        
        let storage = FIRStorage.storage()
        let storageRef = storage.referenceForURL(FIREBASE_STORAGE)
        imagesRef = storageRef.child("images")
        
        startLoadingAnimation()
        
    }
    
    override func viewDidAppear(animated: Bool) {
        print(likedFoodPreviews.count)
        print(myFoodPreviews.count)
        
        segmentedControl.selectedSegmentIndex = displayMode
        dismissNotifications()
        
        if displayMode == LIKED_MODE {
            getLikedFood()
        } else {
            getMyFood()
        }
    
    }
    
    func getLikedFood(){
        if let uid = NSUserDefaults.standardUserDefaults().objectForKey("USER_UID") as? String {
            firebase.child("users").child(uid).child("likes").queryOrderedByValue().observeSingleEventOfType(.Value, withBlock: { (snapshot) in
                print(snapshot.value)
               
                self.parseSnapshot(snapshot, arrayName: "likes")
                
            }) { (error) in
                print(error.localizedDescription)
            }
        }
    }
    
    func getMyFood(){
        if let uid = NSUserDefaults.standardUserDefaults().objectForKey("USER_UID") as? String {
            firebase.child("users").child(uid).child("posts").queryOrderedByValue().observeSingleEventOfType(.Value, withBlock: { (snapshot) in
                
                self.parseSnapshot(snapshot, arrayName: "myFood")
                
            }) { (error) in
                print(error.localizedDescription)
            }
        }
    }
    
    func parseSnapshot(snapshot: FIRDataSnapshot, arrayName: String){
        if let snapshotDict = snapshot.value as? [String:Int] {
        
            if let previousSnapshotDict = previousSnapshotDict {
                if snapshotDict == previousSnapshotDict {
                    return
                }
            }
        
            likedFoodPreviews = []
            myFoodPreviews = []
            loadedFood = 0
            previousSnapshotDict = snapshotDict
        
            let totalKeys = Array(snapshotDict.keys).sort({snapshotDict[$0] > snapshotDict[$1]})
            print(totalKeys)
        
            print(totalKeys.count)
            for key in totalKeys {
                if arrayName == "likes" {
                    self.likedFoodPreviews.append(foodPreview(key: key))
                } else {
                    self.myFoodPreviews.append(foodPreview(key:key))
                }
            }
        
            self.collection.reloadData()
        } else {
            self.stopLoadingAnimation()
        }
    }

    func collectionView(collectionView: UICollectionView, willDisplayCell cell: UICollectionViewCell, forItemAtIndexPath indexPath: NSIndexPath) {
        print("row \(indexPath.item)")
        if indexPath.item >= loadedFood {
            if !loadingImages {
                loadingImages = true
                let delay = 0.0001 * Double(NSEC_PER_SEC)
                let time = dispatch_time(DISPATCH_TIME_NOW, Int64(delay))
                dispatch_after(time, dispatch_get_main_queue()) {
                    self.downloadNextBatch()
                }
            }
        } else {
        }
    }
    
    func downloadNextBatch() {
        loadingImages = true
        var loaded = 0
        for var i = loadedFood; i < loadedFood + NUM_IMAGES_LOADED; i++ {
            if displayMode == LIKED_MODE {
                if i < likedFoodPreviews.count {
                    downloadImage(likedFoodPreviews[i], index: i)
                    loaded++
                }
            } else {
                if i < myFoodPreviews.count {
                    downloadImage(myFoodPreviews[i], index: i)
                    loaded++
                }
            }
        }
        loadedFood += loaded
        loadingImages = false
    }
    
    func downloadImage(foodPrev: foodPreview, index: Int) {

        if let foundIndex = downloadedFoodPreviews.indexOf({$0.key == foodPrev.key}){
            foodPrev.foodImage = downloadedFoodPreviews[foundIndex].foodImage
            self.collection.reloadItemsAtIndexPaths([NSIndexPath(forRow: index, inSection: 0)])
            self.stopLoadingAnimation()
        } else {
            if let imagesRef = imagesRef {
                let childRef = imagesRef.child(foodPrev.key)
                let downloadTask = childRef.dataWithMaxSize(1 * 1024 * 1024, completion: { (data, error) in
                    if (error != nil){
                        print(error.debugDescription)
                        self.stopLoadingAnimation()
                    } else {
                        let foodImage: UIImage! = UIImage(data: data!)
                        var newDownloadedFood = foodPreview(key: foodPrev.key)
                        newDownloadedFood.foodImage = foodImage
                        self.downloadedFoodPreviews.append(newDownloadedFood)
                        foodPrev.foodImage = newDownloadedFood.foodImage
                        print("downloaded \(foodPrev.key)'s image")
                        self.collection.reloadItemsAtIndexPaths([NSIndexPath(forRow: index, inSection: 0)])
                        self.stopLoadingAnimation()
                    }
                })
                downloadTasks.append(downloadTask)
            }
        }
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("FoodCell", forIndexPath: indexPath) as! FoodCell
        let foodPrev: foodPreview!
        if displayMode == LIKED_MODE {
            foodPrev = likedFoodPreviews[indexPath.row]
        }
        else {
            foodPrev = myFoodPreviews[indexPath.row]
        }
        print("configuring \(indexPath.row) with \(foodPrev.foodImage)")
        cell.configureCell(foodPrev)
        return cell
        
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        let item: foodPreview
        
        if displayMode == LIKED_MODE {
            item = likedFoodPreviews[indexPath.row]
        } else {
            item = myFoodPreviews[indexPath.row]
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
        return CGSizeMake((screenWidth - 2) / CGFloat(3.0), (screenWidth - 2) / CGFloat(3.0))
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAtIndex section: Int) -> CGFloat {
        return 1
    }
    
    @IBAction func onSegmentedControlChanged(sender: AnyObject) {
        displayMode = segmentedControl.selectedSegmentIndex
        for downloadTask in downloadTasks {
            downloadTask.cancel()
        }
        collection.reloadData()
        if displayMode == LIKED_MODE {
            getLikedFood()
        } else {
            getMyFood()
        }
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
        
        self.refreshControl.endRefreshing()

        if displayMode == LIKED_MODE {
            getLikedFood()
        } else {
           getMyFood()
        }
        
    }

}
