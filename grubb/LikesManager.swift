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
    
    private var notifications: Int = 1
    
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
        firebase.child("posts").child(_key).runTransactionBlock({ (currentData: FIRMutableData) -> FIRTransactionResult in
            if var post = currentData.value as? [String: AnyObject] {
                var likes = post["likes"] as? Int ?? 0
                print("likes")
                likes += 1
                print("adding like to \(self.key)")
                post["likes"] = likes
                print("likes after: \(post["likes"])")
                currentData.value = post
                print(likes)
                return FIRTransactionResult.successWithValue(currentData)
            }
            return FIRTransactionResult.successWithValue(currentData)
            }, andCompletionBlock: { (error, committed, snapshot) in
                if let error = error {
                    print(error.localizedDescription)
                    print("TRANSACTION FAILED!")
                } else {
                    self.firebase.child("users").child(self._uid).child("likes").child(self._key).setValue(time)
                }
            })
        if uid != _author {
            firebase.child("users").child(self._author).runTransactionBlock({ (currentData: FIRMutableData) -> FIRTransactionResult in
                    if var user = currentData.value as? [String: AnyObject] {
                        var notifications = user["notifications"] as? Int ?? 0
                        notifications += 1
                        self.notifications = notifications
                        user["notifications"] = notifications
                        currentData.value = user
                        print(notifications)
                        return FIRTransactionResult.successWithValue(currentData)
                    }
                    return FIRTransactionResult.successWithValue(currentData)
                    }, andCompletionBlock: { (error, committed, snapshot) in
                        if let error = error {
                            //print(error.localizedDescription)
                            print("TRANSACTION FAILED!")
                        } else {
                            self.sendLikeNotification(self.notifications)
                        }
            })
        }
    }
    
    func unlikePost(){
        firebase.child("posts").child(_key).runTransactionBlock({ (currentData: FIRMutableData) -> FIRTransactionResult in
            if var post = currentData.value as? [String: AnyObject] {
                var likes = post["likes"] as? Int ?? 0
                print("removing like from \(self.key)")
                likes -= 1
                post["likes"] = likes
                currentData.value = post
                
                return FIRTransactionResult.successWithValue(currentData)
            }
            return FIRTransactionResult.successWithValue(currentData)
            }, andCompletionBlock: { (error, committed, snapshot) in
                if let error = error {
                    print(error.localizedDescription)
                } else {
                    self.firebase.child("users").child(self._uid).child("likes").child(self._key).setValue(nil)
            }
        })
    }
    
    func sendLikeNotification(notifications: Int){
        if let pushClient = BatchClientPush(apiKey: BATCH_API_KEY, restKey: BATCH_REST_KEY) {
            
            pushClient.sandbox = false
            pushClient.customPayload = ["aps": ["badge": notifications, "sound": NSNull(), "content-available": 1]]
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