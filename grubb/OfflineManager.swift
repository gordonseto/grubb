//
//  OfflineManager.swift
//  grubb
//
//  Created by Gordon Seto on 2016-07-08.
//  Copyright © 2016 grubbapp. All rights reserved.
//

import Foundation

class OfflineManager {
    
    var queuedLikes: [LikesManager] = []
    
    static let sharedInstance = OfflineManager()
    private init() {}
}