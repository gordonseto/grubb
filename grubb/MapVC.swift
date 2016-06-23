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
        map.delegate = self
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
    
}
