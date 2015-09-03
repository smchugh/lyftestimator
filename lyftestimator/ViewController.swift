//
//  ViewController.swift
//  lyftestimator
//
//  Created by Steve McHugh on 8/31/15.
//  Copyright (c) 2015 chugs. All rights reserved.
//

import UIKit
import MapKit

class ViewController: UIViewController, MKMapViewDelegate {

    @IBOutlet weak var mapView: MKMapView!
    let regionRadius: CLLocationDistance = 1000
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NSNotificationCenter.defaultCenter().addObserver(self,
            selector: "pickupEtaUpdated:",
            name: "PICKUP_ETA_UPDATED",
            object: nil
        )
        
        NSNotificationCenter.defaultCenter().addObserver(self,
            selector: "rideEstimateUpdated:",
            name: "RIDE_ESTIMATE_UPDATED",
            object: nil
        )
        
        NSNotificationCenter.defaultCenter().addObserver(self,
            selector: "locationFound:",
            name: "LOCATION_FOUND",
            object: nil
        )
        
        mapView.delegate = self
        
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func pickupEtaUpdated(notification:NSNotification) -> Void {
        let pickupEtaData = notification.userInfo as! Dictionary<String, AnyObject>
        
        // var pickupEtas = pickupEtaData as? Dictionary<String, Dictionary<String, AnyObject?>>
        NSLog("ViewController: pickupEtaUpdated: pickupEtaData \(pickupEtaData)")
    }
    
    func rideEstimateUpdated(notification:NSNotification) -> Void {
        let rideEstimateData = notification.userInfo as! Dictionary<String, AnyObject>
        
        // var rideEstimates = rideEstimateData as? Dictionary<String, Dictionary<String, AnyObject?>>
        NSLog("ViewController: rideEstimateUpdated: rideEstimateData \(rideEstimateData)")
    }
    
    func locationFound(notification:NSNotification) -> Void {
        let locationData = notification.userInfo as! Dictionary<String, Double>
        
        let location = CLLocation(
            latitude: locationData["lat"]!,
            longitude: locationData["lng"]!
        )
        
        self.centerMapOnLocation(location)
        
        mapView.showsUserLocation = true
        
        let originPin = PinLocation(
            title: "Test Title",
            address: "Test Subtitle",
            pinType: PinLocation.TYPE_ORIGIN,
            coordinate: location.coordinate
        )
        
        mapView.addAnnotation(originPin)
    }
    
    func centerMapOnLocation(location: CLLocation) {
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(location.coordinate,
            regionRadius * 2.0, regionRadius * 2.0
        )
        mapView.setRegion(coordinateRegion, animated: true)
    }
    
    func mapView(mapView: MKMapView!, viewForAnnotation annotation: MKAnnotation!) -> MKAnnotationView! {
        if let annotation = annotation as? PinLocation {
            let identifier = annotation.pinType
            var view: MKPinAnnotationView
            if let dequeuedView = mapView.dequeueReusableAnnotationViewWithIdentifier(identifier) as? MKPinAnnotationView {
                dequeuedView.annotation = annotation
                view = dequeuedView
            } else {
                view = MKPinAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                view.pinColor = identifier == PinLocation.TYPE_ORIGIN ? .Green : .Red
                view.draggable = true
            }
            return view
        }
        return nil
    }
}

