//
//  DraggableViewBackground.swift
//  TinderSwipeCardsSwift
//
//  Created by Gao Chao on 4/30/15.
//  Copyright (c) 2015 gcweb. All rights reserved.
//

import Foundation
import UIKit
import GeoFire
import FirebaseDatabase
import FirebaseStorage

class DraggableViewBackground: UIView, DraggableViewDelegate {
    var exampleCardLabels: [String]!
    var allCards: [DraggableView]!
    
    let MAX_BUFFER_SIZE = 5
    var CARD_HEIGHT: CGFloat!
    var CARD_WIDTH: CGFloat!
    
    var cardsLoadedIndex: Int!
    var loadedCards: [DraggableView]!
    var menuButton: UIButton!
    var messageButton: UIButton!
    var checkButton: UIButton!
    var xButton: UIButton!
    
    var food = [Food]()
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        let screenSize: CGRect = UIScreen.mainScreen().bounds
        let screenWidth = screenSize.width
        let screenHeight = screenSize.height
        
        CARD_HEIGHT = screenHeight * 0.6
        CARD_WIDTH = screenWidth * 0.95
        
        super.layoutSubviews()
        self.setupView()
        
        self.allCards = []
        self.loadedCards = []
        self.cardsLoadedIndex = 0
        
        queryDishes()
    }
    
    func queryDishes(){
        var cardIndex = 0
        
        let firebase = FIRDatabase.database().reference()
        let geofireRef = firebase.child("geolocations")
        let geofire = GeoFire(firebaseRef: geofireRef)
        
        let center = CLLocation(latitude: 51.1262105, longitude: -114.2073206)
        // Query locations at [37.7832889, -122.4056973] with a radius of 600 meters
        var circleQuery = geofire.queryAtLocation(center, withRadius: 0.6)
        
        var queryHandle = circleQuery.observeEventType(.KeyEntered, withBlock: { (key: String!, location: CLLocation!) in
            print("Key '\(key)' entered the search area and is at location '\(location)'")
            
            firebase.child("posts").child(key).observeSingleEventOfType(.Value, withBlock: { (snapshot) in
                let name = snapshot.value!["name"] as! String
                let price = snapshot.value!["price"] as! Double
                let restaurant = snapshot.value!["restaurant"] as! String
                let categoryArray = snapshot.value!["categoryArray"] as! [String]
                let geolocation = location
                
                let newFood = Food(key: key, name: name, restaurant: restaurant, price: price, categoryArray: categoryArray, geolocation: geolocation)
                self.food.append(newFood)
                print(newFood.restaurant)
                
                self.addToCards(cardIndex, newFood: newFood)
                cardIndex++
                
            }) { (error) in
                print(error.localizedDescription)
            }
        })
    }
    
    func addToCards(cardIndex: Int, newFood: Food) -> Void {
        let draggableView = DraggableView(frame: CGRectMake((self.frame.size.width - CARD_WIDTH)/2, (self.frame.size.height - CARD_HEIGHT)/2 - 20, CARD_WIDTH, CARD_HEIGHT))
        draggableView.food = newFood
        draggableView.name.text = newFood.name
        draggableView.price.text = String.localizedStringWithFormat("$%.2f", newFood.price)
        draggableView.delegate = self
        allCards.append(draggableView)
    
        let numLoadedCardsCap = food.count > MAX_BUFFER_SIZE ? MAX_BUFFER_SIZE : food.count
        if cardIndex < numLoadedCardsCap {
            loadedCards.append(draggableView)
            
            loadCardImage(draggableView)
            
            if cardIndex > 0 {
                self.insertSubview(loadedCards[cardIndex], belowSubview: loadedCards[cardIndex - 1])
            } else {
                self.addSubview(loadedCards[cardIndex])
            }
            cardsLoadedIndex = cardsLoadedIndex + 1
        }
        
    }
    
    func loadCardImage(card: DraggableView){
        let storage = FIRStorage.storage()
        let storageRef = storage.referenceForURL(FIREBASE_STORAGE)
        let imagesRef = storageRef.child("images")
        let childRef = imagesRef.child(card.food.key)
        childRef.dataWithMaxSize(1 * 1024 * 1024, completion: { (data, error) in
            if (error != nil){
                print(error.debugDescription)
            } else {
                let foodImage: UIImage! = UIImage(data: data!)
                card.foodImage.image = foodImage
                print("loaded \(card.food.restaurant)'s image")
            }
        })
    }
    
    func setupView() -> Void {
        //self.backgroundColor = UIColor(red: 0.92, green: 0.93, blue: 0.95, alpha: 1)
        self.backgroundColor = UIColor.whiteColor()
        
        xButton = UIButton(frame: CGRectMake((self.frame.size.width - CARD_WIDTH)/2 + 70, self.frame.size.height/2 + CARD_HEIGHT/2 - 10, 59, 59))
        xButton.setImage(UIImage(named: "noButton"), forState: UIControlState.Normal)
        xButton.addTarget(self, action: "swipeLeft", forControlEvents: UIControlEvents.TouchUpInside)
        
        checkButton = UIButton(frame: CGRectMake(self.frame.size.width/2 + CARD_WIDTH/2 - 120, self.frame.size.height/2 + CARD_HEIGHT/2 - 10, 59, 59))
        checkButton.setImage(UIImage(named: "yesButton"), forState: UIControlState.Normal)
        checkButton.addTarget(self, action: "swipeRight", forControlEvents: UIControlEvents.TouchUpInside)
        
        self.addSubview(xButton)
        self.addSubview(checkButton)
    }
    
    func createDraggableViewWithDataAtIndex(index: NSInteger) -> DraggableView {
        let draggableView = DraggableView(frame: CGRectMake((self.frame.size.width - CARD_WIDTH)/2, (self.frame.size.height - CARD_HEIGHT)/2 - 20, CARD_WIDTH, CARD_HEIGHT))
        draggableView.name.text = food[index].name
        draggableView.delegate = self
        return draggableView
    }
    
    func loadCards() -> Void {
        if food.count > 0 {
            let numLoadedCardsCap = food.count > MAX_BUFFER_SIZE ? MAX_BUFFER_SIZE : food.count
            print("numloadedCardsCap \(numLoadedCardsCap)")
            for var i = 0; i < food.count; i++ {
                let newCard: DraggableView = self.createDraggableViewWithDataAtIndex(i)
                allCards.append(newCard)
                if i < numLoadedCardsCap {
                    loadedCards.append(newCard)
                }
            }
            
            for var i = 0; i < loadedCards.count; i++ {
                if i > 0 {
                    self.insertSubview(loadedCards[i], belowSubview: loadedCards[i - 1])
                } else {
                    self.addSubview(loadedCards[i])
                }
                cardsLoadedIndex = cardsLoadedIndex + 1
            }
        }
        print("food.count \(food.count)")
        print("allCards \(allCards.count)")
        print("loadedCards \(loadedCards.count)")
    }
    
    func cardSwipedLeft(card: UIView) -> Void {
        loadedCards.removeAtIndex(0)
        
        if cardsLoadedIndex < allCards.count {
            loadedCards.append(allCards[cardsLoadedIndex])
            loadCardImage(allCards[cardsLoadedIndex])
            cardsLoadedIndex = cardsLoadedIndex + 1
            self.insertSubview(loadedCards[MAX_BUFFER_SIZE - 1], belowSubview: loadedCards[MAX_BUFFER_SIZE - 2])
        }
    }
    
    func cardSwipedRight(card: UIView) -> Void {
        loadedCards.removeAtIndex(0)
        
        if cardsLoadedIndex < allCards.count {
            loadedCards.append(allCards[cardsLoadedIndex])
            loadCardImage(allCards[cardsLoadedIndex])
            cardsLoadedIndex = cardsLoadedIndex + 1
            self.insertSubview(loadedCards[MAX_BUFFER_SIZE - 1], belowSubview: loadedCards[MAX_BUFFER_SIZE - 2])
        }
    }
    
    func swipeRight() -> Void {
        if loadedCards.count <= 0 {
            return
        }
        let dragView: DraggableView = loadedCards[0]
        dragView.overlayView.setMode(GGOverlayViewMode.GGOverlayViewModeRight)
        UIView.animateWithDuration(0.2, animations: {
            () -> Void in
            dragView.overlayView.alpha = 1
        })
        dragView.rightClickAction()
    }
    
    func swipeLeft() -> Void {
        if loadedCards.count <= 0 {
            return
        }
        let dragView: DraggableView = loadedCards[0]
        dragView.overlayView.setMode(GGOverlayViewMode.GGOverlayViewModeLeft)
        UIView.animateWithDuration(0.2, animations: {
            () -> Void in
            dragView.overlayView.alpha = 1
        })
        dragView.leftClickAction()
    }
}