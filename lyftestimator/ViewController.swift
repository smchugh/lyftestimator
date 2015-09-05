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
    @IBOutlet weak var modeView: UISegmentedControl!
    @IBOutlet weak var pinTypeView: UISegmentedControl!
    @IBOutlet weak var buttonCenterUser: UIButton!
    @IBOutlet weak var buttonEstimate: UIButton!
    
    let regionRadius: CLLocationDistance = 1000
    var originPin: MKAnnotationView!
    var destinationPin: MKAnnotationView!
    var activePin: MKAnnotationView!
    var currentUserLocation: CLLocation!
    
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
        
        pinTypeView.addTarget(self, action: "pinTypeChanged:", forControlEvents: UIControlEvents.ValueChanged)
        buttonCenterUser.addTarget(self, action: "centerMapOnUser:", forControlEvents: UIControlEvents.TouchUpInside)
        buttonEstimate.addTarget(self, action: "estimateLyft:", forControlEvents: UIControlEvents.TouchUpInside)
        
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
        let locationData = notification.userInfo as! Dictionary<String, AnyObject>
        
        let location = CLLocation(
            latitude: locationData["lat"] as! Double,
            longitude: locationData["lng"] as! Double
        )
        
        currentUserLocation = location
        
        if locationData["firstLocation"] as! Bool {
            
            centerMapOnLocation(location)
        
            mapView.showsUserLocation = true
        
            let originPin = PinLocation(
                title: "Test Title",
                address: "Test Subtitle",
                pinType: PinLocation.TYPE_ORIGIN,
                coordinate: location.coordinate
            )
        
            mapView.addAnnotation(originPin)

        }
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
            if identifier == PinLocation.TYPE_ORIGIN {
                originPin = pinView
            } else {
                destinationPin = pinView
            }
            activePin = pinView
            return pinView
        }
        return nil
    }
    
    func updatePin(recognizer: UITapGestureRecognizer) {
        let touchLocation:CGPoint = recognizer.locationInView(mapView)
        let newCoordinate = mapView.convertPoint(touchLocation, toCoordinateFromView: mapView)
        let newAnnotation = activePin.annotation as! PinLocation
        newAnnotation.coordinate = newCoordinate
        activePin.annotation = newAnnotation
    }
    
    func pinTypeChanged(segment: UISegmentedControl) {
        let pinType = segment.titleForSegmentAtIndex(segment.selectedSegmentIndex)?.lowercaseString
        
        let newActivePin = pinType == PinLocation.TYPE_ORIGIN ? originPin : destinationPin
        if newActivePin == nil {
            let newPin = PinLocation(
                title: "Test Title",
                address: "Test Subtitle",
                pinType: pinType!,
                coordinate: mapView.centerCoordinate
            )
            
            mapView.addAnnotation(newPin)
        } else {
            activePin = newActivePin
        }
        
    }
    
    func centerMapOnUser(button: UIButton) {
        centerMapOnLocation(currentUserLocation)
    }
    
    func estimateLyft(button: UIButton) {
        
        let userInfo = [
            "originLat": originPin.annotation.coordinate.latitude.description,
            "originLng": originPin.annotation.coordinate.longitude.description,
            "destinationLat": destinationPin.annotation.coordinate.latitude.description,
            "destinationLng": destinationPin.annotation.coordinate.longitude.description,
            "rideType": LyftService.RIDE_TYPE_LYFT
        ]
        
        NSNotificationCenter.defaultCenter().postNotificationName("LOCATIONS_UPDATED",
            object: nil,
            userInfo: userInfo)
    }
    
}

