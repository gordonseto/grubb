//
//  DraggableViewBackground.swift
//  TinderSwipeCardsSwift
//
//

import Foundation
import UIKit
import GeoFire
import FirebaseDatabase
import FirebaseStorage

protocol DraggableViewBackgroundDelegate: class {
    func onCardTapped(sender: Food)
    func onRestartTapped()
    func onCardSwiped(key: String)
    func onCardSwipedRight(food: Food)
}

final class DraggableViewBackground: UIView, DraggableViewDelegate {
    var exampleCardLabels: [String]!
    var allCards: [DraggableView]!
    
    let MAX_BUFFER_SIZE = 5
    var CARD_HEIGHT: CGFloat!
    var CARD_WIDTH: CGFloat!
    let CARD_TAG = 9
    
    var cardsLoadedIndex: Int!
    var loadedCards: [DraggableView]!
    var menuButton: UIButton!
    var messageButton: UIButton!
    var checkButton: UIButton!
    var xButton: UIButton!
    
    var loadingLabel: UILabel!
    var activityIndicator: UIActivityIndicatorView!
    var noDishes: UILabel!
    
    var food = [Food]()
    weak var delegate: DraggableViewBackgroundDelegate!
    
    let CARD_OFFSET: CGFloat = 5
    let SIZE_OFFSET: CGFloat = 10
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        let screenSize: CGRect = UIScreen.mainScreen().bounds
        let screenWidth = screenSize.width
        let screenHeight = screenSize.height
        
        CARD_HEIGHT = screenHeight * 0.65
        CARD_WIDTH = screenWidth * 0.95
        
        super.layoutSubviews()
        self.setupView()
        
        self.allCards = []
        self.loadedCards = []
        self.cardsLoadedIndex = 0
        
    }
    
    
    func addToCards(cardIndex: Int, newFood: Food) -> Void {
        let draggableView = DraggableView(frame: CGRectMake((self.frame.size.width - CARD_WIDTH)/2 + SIZE_OFFSET/2, (self.frame.size.height - CARD_HEIGHT)/2 - 20, CARD_WIDTH - SIZE_OFFSET, CARD_HEIGHT))
        draggableView.food = newFood
        draggableView.name.text = newFood.name
        draggableView.price.text = String.localizedStringWithFormat("$%.2f", newFood.price)
        draggableView.restaurant.text = newFood.restaurant
        draggableView.delegate = self
        draggableView.tag = CARD_TAG
        draggableView.userInteractionEnabled = false
        allCards.append(draggableView)

        let numLoadedCardsCap = allCards.count > MAX_BUFFER_SIZE ? MAX_BUFFER_SIZE : allCards.count
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
        
        if card.food.foodImage == nil || card.foodImage.image == UIImage(named: "reloadImage") {
            card.foodImage.image = nil
            childRef.dataWithMaxSize(1 * 1024 * 1024, completion: { (data, error) in
                if (error != nil){
                    print(error.debugDescription)
                    card.failedToLoad = true
                    card.foodImage.image = UIImage(named: "reloadImage")
                } else {
                    let foodImage: UIImage! = UIImage(data: data!)
                    card.food.foodImage = foodImage
                    card.foodImage.image = foodImage
                    print("loaded \(card.food.restaurant)'s image")
                    card.failedToLoad = false
            }
            })
        } else {
            card.foodImage.image = card.food.foodImage
        }
    }
    
    func loadDeckOfCards(deckOfCards: [Food]){
        let subViews = self.subviews
        for subView in subViews {
            if subView.tag == CARD_TAG {
                subView.removeFromSuperview()
            }
        }
        allCards = []
        loadedCards = []
        cardsLoadedIndex = 0
        for var i = 0; i < deckOfCards.count; i++ {
            addToCards(i, newFood: deckOfCards[i])
        }
        if loadedCards.count > 0 {
            loadedCards[0].userInteractionEnabled = true
            loadedCards[0].frame = CGRectMake((self.frame.size.width - CARD_WIDTH)/2, (self.frame.size.height - CARD_HEIGHT)/2 - 20, CARD_WIDTH, CARD_HEIGHT)
            loadedCards[0].center.y -= CARD_OFFSET
            loadedCards[0].adjustView()
        }
        stopLoadingAnimation()
    }
    
    func clearCards(){
        allCards = []
        loadedCards = []
        cardsLoadedIndex = 0
        let subViews = self.subviews
        for subView in subViews {
            if subView.tag == CARD_TAG {
                subView.removeFromSuperview()
            }
        }
    }
    
    func setupView() -> Void {
        //self.backgroundColor = UIColor(red: 0.92, green: 0.93, blue: 0.95, alpha: 1)
        self.backgroundColor = UIColor.whiteColor()
        
        xButton = UIButton(frame: CGRectMake((self.frame.size.width - CARD_WIDTH)/2 + 78, self.frame.size.height/2 + CARD_HEIGHT/2 + 2, 28, 28))
        xButton.setImage(UIImage(named: "noButton"), forState: UIControlState.Normal)
        xButton.addTarget(self, action: "swipeLeft", forControlEvents: UIControlEvents.TouchUpInside)
        
        checkButton = UIButton(frame: CGRectMake(self.frame.size.width/2 + CARD_WIDTH/2 - 120, self.frame.size.height/2 + CARD_HEIGHT/2, 140/4, 128/4))
        checkButton.setImage(UIImage(named: "yesButton"), forState: UIControlState.Normal)
        checkButton.addTarget(self, action: "swipeRight", forControlEvents: UIControlEvents.TouchUpInside)
        
        self.addSubview(xButton)
        self.addSubview(checkButton)
        
        startLoadingAnimation()
        
    }
    
    func startLoadingAnimation(){
        activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.Gray)
        activityIndicator.frame = CGRect(x: 0, y: 0, width: 50, height: 50)
        activityIndicator.center = CGPointMake(UIScreen.mainScreen().bounds.size.width/2 - 32, UIScreen.mainScreen().bounds.size.height/2 - 30)
        activityIndicator.startAnimating()
        self.addSubview(activityIndicator)
        
        loadingLabel = UILabel(frame: CGRectMake(0, 0, 100, 30))
        loadingLabel.center = CGPointMake(UIScreen.mainScreen().bounds.size.width/2 + 32, UIScreen.mainScreen().bounds.size.height/2 - 30)
        loadingLabel.text = "Loading..."
        loadingLabel.textColor = UIColor.grayColor()
        self.addSubview(loadingLabel)
    }
    
    func stopLoadingAnimation(){
        activityIndicator.removeFromSuperview()
        loadingLabel.removeFromSuperview()
    }
    
    func displayNoDishes(){
        noDishes = UILabel(frame: CGRectMake(0, 0, 220, 120))
        noDishes.center = CGPointMake(UIScreen.mainScreen().bounds.size.width/2, UIScreen.mainScreen().bounds.size.height/2 - 30)
        noDishes.textAlignment = NSTextAlignment.Center
        noDishes.numberOfLines = 4
        noDishes.font = UIFont(name: "HelveticaNeue", size: 15)
        noDishes.text = "There are no new dishes here. Try searching another area or posting your own."
        noDishes.textColor = UIColor.grayColor()
        self.addSubview(noDishes)
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
        cardSwiped(card)
    }
    
    func cardSwipedRight(card: UIView) -> Void {
        delegate?.onCardSwipedRight(loadedCards[0].food)
        cardSwiped(card)
    }
    
    func cardSwiped(card: UIView){
        delegate?.onCardSwiped(loadedCards[0].food.key)
        loadedCards.removeAtIndex(0)
        if loadedCards.count > 0 {
            loadedCards[0].userInteractionEnabled = true
        }
        displayNextCards()
    }
    
    func displayNextCards(){
        if cardsLoadedIndex < allCards.count {
            loadedCards.append(allCards[cardsLoadedIndex])
            loadCardImage(allCards[cardsLoadedIndex])
            cardsLoadedIndex = cardsLoadedIndex + 1
            self.insertSubview(loadedCards[MAX_BUFFER_SIZE - 1], belowSubview: loadedCards[MAX_BUFFER_SIZE - 2])
        }
    }
    
    func onCardTapped(card: DraggableView){
        if card.foodImage.image == UIImage(named: "reloadImage") {
            for card in loadedCards {
                if card.failedToLoad == true {
                    loadCardImage(card)
                }
            }
        } else {
            delegate?.onCardTapped(card.food)
        }
    }
    
    func onRestartTapped(){
        delegate?.onRestartTapped()
    }
    
    func onCardBeingSwiped(distance: CGFloat) {
        let cardOrigin = (self.frame.size.height - CARD_HEIGHT)/2 + CARD_HEIGHT/2 - 20
        if loadedCards.count > 1 {
            loadedCards[1].frame = CGRectMake((self.frame.size.width - CARD_WIDTH)/2 + SIZE_OFFSET/2 - (min(abs(distance)/5, SIZE_OFFSET))/2, (self.frame.size.height - CARD_HEIGHT)/2 - 20, CARD_WIDTH - SIZE_OFFSET + min(abs(distance)/5, SIZE_OFFSET), CARD_HEIGHT)
            loadedCards[1].adjustView()
            loadedCards[1].center.y = cardOrigin - min(abs(distance)/10, CARD_OFFSET)
        }
    }
    
    func cardClicked() {
        let cardOrigin = (self.frame.size.height - CARD_HEIGHT)/2 + CARD_HEIGHT/2 - 20
        if loadedCards.count > 1 {
            loadedCards[1].frame = CGRectMake((self.frame.size.width - CARD_WIDTH)/2, (self.frame.size.height - CARD_HEIGHT)/2 - 20, CARD_WIDTH, CARD_HEIGHT)
            loadedCards[1].adjustView()
            loadedCards[1].center.y = cardOrigin - self.CARD_OFFSET
        }
    }
    
    func swipeRight() -> Void {
        if loadedCards.count <= 0 {
            return
        }
        let dragView: DraggableView = loadedCards[0]
        dragView.rightClickAction()
    }
    
    func swipeLeft() -> Void {
        if loadedCards.count <= 0 {
            return
        }
        let dragView: DraggableView = loadedCards[0]
        dragView.leftClickAction()
    }
    
}