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
import Onboard

class MapVC: UIViewController, MKMapViewDelegate, UIGestureRecognizerDelegate {

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
    var settingsButton: UIButton!
    
    var peekMode = false
    
    var mapHasBeenDragged: Bool = false
    var realLocation: CLLocationCoordinate2D?
    
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
        let titleClick = UITapGestureRecognizer(target: self, action: "onTitleTapped:")
        titleClick.delegate = self
        titleLogo.addGestureRecognizer(titleClick)
        titleLogo.userInteractionEnabled = true
        self.view.addSubview(titleLogo)
        
        settingsButton = UIButton(frame: CGRectMake(8, 22, 29, 25))
        settingsButton.setImage(UIImage(named: "settings"), forState: UIControlState.Normal)
        settingsButton.imageView!.contentMode = UIViewContentMode.ScaleAspectFit
        settingsButton.addTarget(self, action: #selector(onSettingsButtonTapped), forControlEvents: .TouchUpInside)
        settingsButton.imageEdgeInsets = UIEdgeInsetsMake(4, 4, 4, 4);
        self.view.addSubview(settingsButton)
        
        let peekButton = UIButton(frame: CGRectMake(0, 0, 30, 27))
        peekButton.center = CGPointMake(UIScreen.mainScreen().bounds.size.width - 23, 37)
        peekButton.setImage(UIImage(named: "binoculars"), forState: UIControlState.Normal)
        peekButton.imageView!.contentMode = UIViewContentMode.ScaleAspectFit
        peekButton.imageEdgeInsets = UIEdgeInsetsMake(4, 4, 4, 4);
        peekButton.addTarget(self, action: #selector(onPeekButtonTapped), forControlEvents: .TouchUpInside)
        self.view.addSubview(peekButton)
        
        searchButton.layer.cornerRadius = 4.0
        
        map.delegate = self
        
        mapHasBeenDragged = false
        let panRec = UIPanGestureRecognizer(target: self, action: "onMapDragged:")
        panRec.delegate = self
        map.addGestureRecognizer(panRec)
        
        self.navigationController?.navigationBarHidden = true
        
        if let searchRadius = NSUserDefaults.standardUserDefaults().objectForKey("SEARCH_RADIUS") {
            print(searchRadius as! NSNumber)
            regionRadius = CLLocationDistance(searchRadius as! NSNumber)
        } else {
            regionRadius = DEFAULT_SEARCH_RADIUS
        }
        
        if let hasOnboarded = NSUserDefaults.standardUserDefaults().objectForKey("HAS_ONBOARDED") {
            locationAuthStatus()
        } else {
            let onBoardVC = generateOnboardingVC()
            self.presentViewController(onBoardVC, animated: true, completion: nil)
        
            locationAuthStatus()
        }
    }
    
    func locationAuthStatus() {
        if CLLocationManager.authorizationStatus() == .AuthorizedWhenInUse {
            map.showsUserLocation = true
        } else {
            locationManager.requestWhenInUseAuthorization()
            map.showsUserLocation = true
        }
    }
    
    func centerMapOnLocation(location: CLLocation){
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(location.coordinate, regionRadius * 2, regionRadius * 2)
        map.setRegion(coordinateRegion, animated: false)
    }
    
    func mapView(mapView: MKMapView, didUpdateUserLocation userLocation: MKUserLocation) {
        if let loc = userLocation.location {
            if !mapHasBeenDragged {
                centerMapOnLocation(loc)
                if let circle = circle {
                    self.map.removeOverlay(circle)
                }
                currentLocation = loc.coordinate
                circle = MKCircle(centerCoordinate: currentLocation!, radius: regionRadius)
                self.map.addOverlay(circle!)
                print(currentLocation)
            }
            if let currentLocation = currentLocation {
                NSUserDefaults.standardUserDefaults().setObject(currentLocation.latitude, forKey: "CURRENT_LATITUDE")
                NSUserDefaults.standardUserDefaults().setObject(currentLocation.longitude, forKey: "CURRENT_LONGITUDE")
                NSUserDefaults.standardUserDefaults().synchronize()
                realLocation = currentLocation
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
    
    func onTitleTapped(gestureRecognizer: UIGestureRecognizer) {
        if let realLocation = realLocation {
            mapHasBeenDragged = false
            let center = realLocation
            setSearchLocation(center)
            centerMapOnLocation(CLLocation(latitude: center.latitude, longitude: center.longitude))
        }
    }

    func onMapDragged(gestureRecognizer: UIGestureRecognizer) {
        let center = map.centerCoordinate
            
        mapHasBeenDragged = true
        setSearchLocation(center)
    }
    
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    func onPeekButtonTapped(){
        let autocompleteController = GMSAutocompleteViewController()
        autocompleteController.delegate = self
        self.presentViewController(autocompleteController, animated: true, completion: nil)
    }
    
    func peekLocation(place: GMSPlace){
        map.showsUserLocation = false
        self.titleLogo.text = place.name
        
        realLocation = place.coordinate
        setSearchLocation(place.coordinate)
        centerMapOnLocation(CLLocation(latitude: currentLocation!.latitude, longitude: currentLocation!.longitude))
        
        backButton = UIButton(frame: CGRectMake(8, 22, 30, 30))
        backButton.setImage(UIImage(named: "backButton"), forState: UIControlState.Normal)
        backButton.addTarget(self, action: #selector(onBackButtonTapped), forControlEvents: .TouchUpInside)
        self.view.addSubview(backButton)
        
        settingsButton.removeFromSuperview()
        
        self.peekMode = true
    }
    
    func setSearchLocation(coordinate: CLLocationCoordinate2D) {
        currentLocation = coordinate
        if let circle = circle {
            self.map.removeOverlay(circle)
        }
        circle = MKCircle(centerCoordinate: currentLocation!, radius: regionRadius)
        self.map.addOverlay(circle!)
    }
    
    override func viewWillAppear(animated: Bool) {
        if !peekMode {
            self.map.showsUserLocation = true
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        self.map.showsUserLocation = false
    }
    
    func onBackButtonTapped(){
        stopPeekLocation()
    }
    
    func stopPeekLocation(){
        map.showsUserLocation = true
        self.titleLogo.text = "Your Location"
        backButton.removeFromSuperview()
        peekMode = false
        self.view.addSubview(settingsButton)
        
        guard let lat = NSUserDefaults.standardUserDefaults().objectForKey("CURRENT_LATITUDE") as? CLLocationDegrees else { return }
        guard let long = NSUserDefaults.standardUserDefaults().objectForKey("CURRENT_LONGITUDE") as? CLLocationDegrees else { return }
    
        setSearchLocation(CLLocationCoordinate2DMake(lat, long))
        centerMapOnLocation(CLLocation(latitude: lat, longitude: long))
    }
    
    func onSettingsButtonTapped(){
        performSegueWithIdentifier("settingsVC", sender: nil)
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
