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
    var activePin: MKAnnotationView!
    
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

        var tapRecognizer = UITapGestureRecognizer(target: self, action: "updatePin:")
        mapView.addGestureRecognizer(tapRecognizer)
        
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
            var pinView: MKPinAnnotationView
            if let dequeuedView = mapView.dequeueReusableAnnotationViewWithIdentifier(identifier) as? MKPinAnnotationView {
                dequeuedView.annotation = annotation
                pinView = dequeuedView
            } else {
                pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                pinView.pinColor = identifier == PinLocation.TYPE_ORIGIN ? .Green : .Red
                pinView.draggable = true
            }
            self.activePin = pinView
            return pinView
        }
        return nil
    }
    
    func updatePin(recognizer: UITapGestureRecognizer) {
        let touchLocation:CGPoint = recognizer.locationInView(mapView)
        let newCoordinate = mapView.convertPoint(touchLocation, toCoordinateFromView: mapView)
        let newAnnotation = self.activePin.annotation as! PinLocation
        newAnnotation.coordinate = newCoordinate
        self.activePin.annotation = newAnnotation
    }
    
}

