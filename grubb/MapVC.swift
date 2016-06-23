//
//  MapVC.swift
//  grubb
//
//  Created by Gordon Seto on 2016-06-22.
//  Copyright © 2016 grubapp. All rights reserved.
//

import UIKit
import MapKit

class MapVC: UIViewController, MKMapViewDelegate {

    @IBOutlet weak var map: MKMapView!
    @IBOutlet weak var radiusLabel: UILabel!
    @IBOutlet weak var radiusSlider: UISlider!
    @IBOutlet weak var searchButton: UIButton!
    
    let locationManager = CLLocationManager()
    
    var regionRadius: CLLocationDistance = 1000
    var circle: MKOverlay?
    var currentLocation: CLLocationCoordinate2D?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if let searchRadius = NSUserDefaults.standardUserDefaults().objectForKey("SEARCH_RADIUS") {
            radiusLabel.text = "Search Radius: \(Int(searchRadius as! NSNumber)/1000)km"
            radiusSlider.value = Float(Int(searchRadius as! NSNumber)/1000)
        } else {
            radiusLabel.text = "Search Radius: \(Int(DEFAULT_SEARCH_RADIUS))km"
            radiusSlider.value = Float(DEFAULT_SEARCH_RADIUS)
        }
        
        let titleLogo = UILabel(frame: CGRectMake(0, 0, 50, 40))
        titleLogo.center = CGPointMake(UIScreen.mainScreen().bounds.size.width/2, 35)
        titleLogo.text = "grubb"
        titleLogo.font = UIFont(name: "HelveticaNeue-Bold", size: 17)
        titleLogo.textColor = UIColor.darkGrayColor()
        self.view.addSubview(titleLogo)
        
        searchButton.layer.borderColor = UIColor.darkGrayColor().CGColor
        searchButton.layer.borderWidth = 1.0
        searchButton.layer.cornerRadius = 5.0
        
        map.delegate = self
        
        self.navigationController?.navigationBarHidden = true
    }
    
    override func viewDidAppear(animated: Bool) {
        locationAuthStatus()
    }
    
    override func viewWillDisappear(animated: Bool){
        map.showsUserLocation = false
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
    
}
