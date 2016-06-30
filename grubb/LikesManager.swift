//
//  likesManager.swift
//  grubb
//
//  Created by Gordon Seto on 2016-06-28.
//  Copyright © 2016 grubbapp. All rights reserved.
//

import Foundation
import FirebaseDatabase

class LikesManager {
    private var _uid: String!
    private var _key: String!
    private var _author: String!
    private var _name: String!
    
    var firebase: FIRDatabaseReference!
    
    var uid: String {
        return _uid
    }
    
    var key: String {
        return _key
    }
    
    var author: String {
        return _author
    }
    
    init(uid: String, key: String, author: String, name: String){
        _uid = uid
        _key = key
        _author = author
        _name = name
        
        firebase = FIRDatabase.database().reference()
    }
    
    func likePost(){
        let time = NSDate().timeIntervalSince1970
        firebase.child("users").child(_uid).child("likes").child(_key).setValue(time)
        firebase.child("posts").child(_key).runTransactionBlock({ (currentData: FIRMutableData) -> FIRTransactionResult in
            if var post = currentData.value as? [String: AnyObject] {
                var likes = post["likes"] as? Int ?? 0
                likes += 1
                post["likes"] = likes
                currentData.value = post
                print(likes)
                return FIRTransactionResult.successWithValue(currentData)
            }
            return FIRTransactionResult.successWithValue(currentData)
            }, andCompletionBlock: { (error, committed, snapshot) in
                if let error = error {
                    print(error.localizedDescription)
                }
        })
        sendLikeNotification()
    }
    
    func unlikePost(){
        firebase.child("users").child(_uid).child("likes").child(_key).setValue(nil)
        firebase.child("posts").child(_key).runTransactionBlock({ (currentData: FIRMutableData) -> FIRTransactionResult in
            if var post = currentData.value as? [String: AnyObject] {
                var likes = post["likes"] as? Int ?? 0
                likes -= 1
                post["likes"] = likes
                currentData.value = post
                
                return FIRTransactionResult.successWithValue(currentData)
            }
            return FIRTransactionResult.successWithValue(currentData)
            }, andCompletionBlock: { (error, committed, snapshot) in
                if let error = error {
                    print(error.localizedDescription)
                }
        })
    }
    
    func sendLikeNotification(){
        if let pushClient = BatchClientPush(apiKey: BATCH_API_KEY, restKey: BATCH_REST_KEY) {
            
            pushClient.sandbox = false
            pushClient.customPayload = ["aps": ["badge": 1, "sound": NSNull(), "content-available": 1]]
            pushClient.groupId = "likeNotifications"
            pushClient.message.title = "Grubb"
            pushClient.message.body = "Someone has liked your dish '\(_name)'"
            pushClient.recipients.customIds = [_author]
            pushClient.deeplink = "grubb://dishes/\(key)"
            
            pushClient.send { (response, error) in
                if let error = error {
                    print("Something happened while sending the push: \(response) \(error.localizedDescription)")
                } else {
                    print("Push sent \(response)")
                }
            }
            
        } else {
            print("Error while initializing BatchClientPush")
        }
    }
}