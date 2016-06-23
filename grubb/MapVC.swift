//
//  MapVC.swift
//  grubb
//
//  Created by Gordon Seto on 2016-06-22.
//  Copyright © 2016 grubapp. All rights reserved.
//

import UIKit
import MapKit
import GoogleMaps

class MapVC: UIViewController, MKMapViewDelegate {

    @IBOutlet weak var map: MKMapView!
    @IBOutlet weak var radiusLabel: UILabel!
    @IBOutlet weak var radiusSlider: UISlider!
    @IBOutlet weak var searchButton: UIButton!
    
    let locationManager = CLLocationManager()
    
    var regionRadius: CLLocationDistance = 7000
    var circle: MKOverlay?
    var currentLocation: CLLocationCoordinate2D?
    
    var titleLogo: UILabel!
    var backButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if let searchRadius = NSUserDefaults.standardUserDefaults().objectForKey("SEARCH_RADIUS") {
            radiusLabel.text = "Search Radius: \(Int(searchRadius as! NSNumber)/1000)km"
            radiusSlider.value = Float(Int(searchRadius as! NSNumber)/1000)
        } else {
            radiusLabel.text = "Search Radius: \(Int(DEFAULT_SEARCH_RADIUS))km"
            radiusSlider.value = Float(DEFAULT_SEARCH_RADIUS)
        }
        
        titleLogo = UILabel(frame: CGRectMake(0, 0, UIScreen.mainScreen().bounds.size.width * 0.8, 40))
        titleLogo.center = CGPointMake(UIScreen.mainScreen().bounds.size.width/2, 35)
        titleLogo.text = "Your Location"
        titleLogo.textAlignment = .Center
        titleLogo.font = UIFont(name: "HelveticaNeue-Bold", size: 17)
        titleLogo.textColor = UIColor.darkGrayColor()
        titleLogo.minimumScaleFactor = 0.8
        self.view.addSubview(titleLogo)
        
        let peekButton = UIButton(frame: CGRectMake(0, 0, 30, 30))
        peekButton.center = CGPointMake(UIScreen.mainScreen().bounds.size.width - 23, 40)
        peekButton.setImage(UIImage(named: "noun_293383_cc"), forState: UIControlState.Normal)
        peekButton.addTarget(self, action: #selector(onPeekButtonTapped), forControlEvents: .TouchUpInside)
        self.view.addSubview(peekButton)
        
        searchButton.layer.cornerRadius = 4.0
        
        map.delegate = self
        
        self.navigationController?.navigationBarHidden = true
        
        if let searchRadius = NSUserDefaults.standardUserDefaults().objectForKey("SEARCH_RADIUS") {
            print(searchRadius as! NSNumber)
            regionRadius = CLLocationDistance(searchRadius as! NSNumber)
        } else {
            regionRadius = DEFAULT_SEARCH_RADIUS
        }
        
        locationAuthStatus()
    }
    
    func locationAuthStatus() {
        if CLLocationManager.authorizationStatus() == .AuthorizedWhenInUse {
            map.showsUserLocation = true
        } else {
            locationManager.requestWhenInUseAuthorization()
        }
    }
    
    func centerMapOnLocation(location: CLLocation){
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(location.coordinate, regionRadius * 2, regionRadius * 2)
        map.setRegion(coordinateRegion, animated: false)
    }
    
    func mapView(mapView: MKMapView, didUpdateUserLocation userLocation: MKUserLocation) {
        if let loc = userLocation.location {
            centerMapOnLocation(loc)
            if let loc: CLLocation! = loc {
                if let circle = circle {
                    self.map.removeOverlay(circle)
                }
                currentLocation = loc.coordinate
                circle = MKCircle(centerCoordinate: currentLocation!, radius: regionRadius)
                self.map.addOverlay(circle!)
                print(currentLocation)
            }
        }
    }
    
    func mapView(mapView: MKMapView, rendererForOverlay overlay: MKOverlay) -> MKOverlayRenderer {
        if let overlay = overlay as? MKCircle {
            let circleRenderer = MKCircleRenderer(circle: overlay)
            circleRenderer.fillColor = UIColor.blueColor()
            circleRenderer.alpha = 0.1
            return circleRenderer
        } else {
            return MKOverlayRenderer()
        }
    }
    
    @IBAction func onSliderChanged(sender: UISlider) {
        var sliderValue = Int(sender.value)
        self.radiusLabel.text = "Search Radius: \(sliderValue)km"
        changeMapRadius(sliderValue)
    }
    
    func changeMapRadius(sliderValue: Int){
        if Double(sliderValue) * 1000 != regionRadius {
            regionRadius = Double(sliderValue) * 1000
            if let currentLoc = currentLocation {
                let coordinateRegion = MKCoordinateRegionMakeWithDistance(currentLoc, regionRadius * 2, regionRadius * 2)
                map.setRegion(coordinateRegion, animated: true)
                if let circle = circle {
                    self.map.removeOverlay(circle)
                }
                circle = MKCircle(centerCoordinate: currentLocation!, radius: regionRadius)
                self.map.addOverlay(circle!)
                NSUserDefaults.standardUserDefaults().setObject(regionRadius, forKey: "SEARCH_RADIUS")
                NSUserDefaults.standardUserDefaults().synchronize()
            }
        }
    }
    @IBAction func onSearchPressed(sender: AnyObject) {
        if currentLocation != nil {
            self.performSegueWithIdentifier("showCardsVC", sender: nil)
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showCardsVC" {
            if let destinationVC = segue.destinationViewController as? ViewController {
                destinationVC.center = CLLocation(latitude: currentLocation!.latitude, longitude: currentLocation!.longitude)
            }
        }
    }
    
    func onPeekButtonTapped(){
        let autocompleteController = GMSAutocompleteViewController()
        autocompleteController.delegate = self
        self.presentViewController(autocompleteController, animated: true, completion: nil)
    }
    
    func peekLocation(place: GMSPlace){
        map.showsUserLocation = false
        self.titleLogo.text = place.name
        currentLocation = place.coordinate
        centerMapOnLocation(CLLocation(latitude: currentLocation!.latitude, longitude: currentLocation!.longitude))
        if let circle = circle {
            self.map.removeOverlay(circle)
        }
        circle = MKCircle(centerCoordinate: currentLocation!, radius: regionRadius)
        self.map.addOverlay(circle!)
        
        backButton = UIButton(frame: CGRectMake(8, 27, 22, 22))
        backButton.setImage(UIImage(named: "noun_26915_cc"), forState: UIControlState.Normal)
        backButton.addTarget(self, action: #selector(onBackButtonTapped), forControlEvents: .TouchUpInside)
        self.view.addSubview(backButton)
    }
    
    func onBackButtonTapped(){
        stopPeekLocation()
    }
    
    func stopPeekLocation(){
        map.showsUserLocation = true
        self.titleLogo.text = "Your Location"
        backButton.removeFromSuperview()
    }
    
}

extension MapVC: GMSAutocompleteViewControllerDelegate {
    func viewController(viewController: GMSAutocompleteViewController, didAutocompleteWithPlace place: GMSPlace) {
        peekLocation(place)
        self.dismissViewControllerAnimated(true, completion: nil)
        
    }
    
    func viewController(viewController: GMSAutocompleteViewController, didFailAutocompleteWithError error: NSError) {
        print("Error: ", error.description)
    }
    
    func wasCancelled(viewController: GMSAutocompleteViewController) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
}
