//
//  AppDelegate.swift
//  grubb
//
//  Created by Gordon Seto on 2016-06-17.
//  Copyright © 2016 grubbapp. All rights reserved.
//

import UIKit
import CoreData
import Firebase
import GoogleMaps
import Batch
import IQKeyboardManagerSwift

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.
        FIRApp.configure()
        FIRAuth.auth()?.signInAnonymouslyWithCompletion({ (user, error) in
            let uid = user!.uid
            print(uid)
            NSUserDefaults.standardUserDefaults().setObject(uid, forKey: "USER_UID")
            NSUserDefaults.standardUserDefaults().synchronize()
            
            Batch.startWithAPIKey(BATCH_API_KEY)
            BatchPush.registerForRemoteNotifications()
            BatchPush.dismissNotifications()
            
            let editor = BatchUser.editor()
            editor.setIdentifier(uid)
            editor.save() // Do not forget to save the changes!
        })
        GMSServices.provideAPIKey(GOOGLE_PLACES_API_KEY)
        
        UITabBar.appearance().tintColor = UIColor(red: 255/255.0, green: 91/255.0, blue: 83/255.0, alpha: 1.0)
        
        IQKeyboardManager.sharedManager().enable = true
        IQKeyboardManager.sharedManager().enableAutoToolbar = false
        
        /*
        let connectedRef = FIRDatabase.database().referenceWithPath(".info/connected")
        connectedRef.observeEventType(.Value, withBlock: { snapshot in
            if let connected = snapshot.value as? Bool where connected {
                print("Connected")
            } else {
                print("Not connected")
                dispatch_async(dispatch_get_main_queue()) {
                    let rootVC = self.window?.rootViewController as! UITabBarController
                    let tabBarIndex = rootVC.selectedIndex
                    let navigationController = rootVC.viewControllers![tabBarIndex] as! UINavigationController
                    let topVC = navigationController.presentedViewController
                    topVC?.showErrorAlert("Oops! Your connection appears to be offline.", msg: "Please reconnect to internet.")
                }
            }
        })
        */
        
        return true
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        BatchPush.dismissNotifications()
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
        self.saveContext()
    }

    // MARK: - Core Data stack

    lazy var applicationDocumentsDirectory: NSURL = {
        // The directory the application uses to store the Core Data store file. This code uses a directory named "grubapp.grubb" in the application's documents Application Support directory.
        let urls = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
        return urls[urls.count-1]
    }()

    lazy var managedObjectModel: NSManagedObjectModel = {
        // The managed object model for the application. This property is not optional. It is a fatal error for the application not to be able to find and load its model.
        let modelURL = NSBundle.mainBundle().URLForResource("grubb", withExtension: "momd")!
        return NSManagedObjectModel(contentsOfURL: modelURL)!
    }()

    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator = {
        // The persistent store coordinator for the application. This implementation creates and returns a coordinator, having added the store for the application to it. This property is optional since there are legitimate error conditions that could cause the creation of the store to fail.
        // Create the coordinator and store
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        let url = self.applicationDocumentsDirectory.URLByAppendingPathComponent("SingleViewCoreData.sqlite")
        var failureReason = "There was an error creating or loading the application's saved data."
        do {
            try coordinator.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: url, options: nil)
        } catch {
            // Report any error we got.
            var dict = [String: AnyObject]()
            dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data"
            dict[NSLocalizedFailureReasonErrorKey] = failureReason

            dict[NSUnderlyingErrorKey] = error as NSError
            let wrappedError = NSError(domain: "YOUR_ERROR_DOMAIN", code: 9999, userInfo: dict)
            // Replace this with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog("Unresolved error \(wrappedError), \(wrappedError.userInfo)")
            abort()
        }
        
        return coordinator
    }()

    lazy var managedObjectContext: NSManagedObjectContext = {
        // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.) This property is optional since there are legitimate error conditions that could cause the creation of the context to fail.
        let coordinator = self.persistentStoreCoordinator
        var managedObjectContext = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = coordinator
        return managedObjectContext
    }()

    // MARK: - Core Data Saving support

    func saveContext () {
        if managedObjectContext.hasChanges {
            do {
                try managedObjectContext.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                NSLog("Unresolved error \(nserror), \(nserror.userInfo)")
                abort()
            }
        }
    }
    
    func application(application: UIApplication,openURL url: NSURL,sourceApplication sourceApplication: String?,annotation annotation: AnyObject?) -> Bool {
        if url.host == nil {
            return true
        }
        
        let urlString = url.absoluteString
        let queryArray = urlString.componentsSeparatedByString("/")
        let query = queryArray[3]
        print(query as String!)
        
        let tabBarController: UITabBarController = self.window?.rootViewController as! UITabBarController
        tabBarController.selectedIndex = EXPLORE_INDEX
        let exploreNVC = tabBarController.viewControllers![EXPLORE_INDEX] as! UINavigationController
        let exploreVC = exploreNVC.viewControllers[0] as! ExploreVC
        exploreVC.displayMode = 1
        let item = foodPreview(key: query)
        UIApplication.sharedApplication().cancelAllLocalNotifications()
        exploreVC.performSegueWithIdentifier("itemVCFromExplore", sender: item)

        return true
    }

}

