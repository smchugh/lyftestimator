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
    @IBOutlet weak var rideResultsView: UILabel!
    @IBOutlet weak var etaResultsView: UILabel!
    
    let regionRadius: CLLocationDistance = 1000
    var originPin: MKAnnotationView!
    var destinationPin: MKAnnotationView!
    var activePin: MKAnnotationView!
    var currentUserLocation: CLLocation!
    
    override func viewDidLoad() {
        hideResultsViews()
        
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
        
        let modeData = pickupEtaData[getSelectedModeFromTitle()] as! Dictionary<String, Int>
        
        let etaPickup = modeData["eta"]!
        let etaString = etaPickup > 60 ? "\(Int(etaPickup / 60)) min" : "\(etaPickup) sec"
        
        etaResultsView.text = " Pickup ETA: \(etaString)"
        etaResultsView.hidden = false
        
        // var pickupEtas = pickupEtaData as? Dictionary<String, Dictionary<String, AnyObject?>>
        NSLog("ViewController: pickupEtaUpdated: pickupEtaData \(pickupEtaData)")
    }
    
    func rideEstimateUpdated(notification:NSNotification) -> Void {
        let rideEstimateData = notification.userInfo as! Dictionary<String, AnyObject>
        
        let modeData = rideEstimateData[getSelectedModeFromTitle()] as! Dictionary<String, AnyObject>
        
        let primeTimeMultiplier = modeData["current_prime_time_percent_multiplier"] as! Int
        let minCostCents = modeData["estimated_cost_cents_min"] as! Int
        let maxCostCents = modeData["estimated_cost_cents_max"] as! Int
        let distanceMiles = modeData["estimated_distance_miles"] as! Double
        let etaDestination = modeData["estimated_duration_seconds"] as! Int
        
        var currancyFormatter = NSNumberFormatter()
        currancyFormatter.numberStyle = .CurrencyStyle
        let minCostString = currancyFormatter.stringFromNumber(minCostCents / 100)
        let maxCostString = currancyFormatter.stringFromNumber(maxCostCents / 100)
        
        let distanceString = NSString(format: "%.2f miles", distanceMiles)
        let costString = minCostString == maxCostString ? minCostString : "\(minCostString!) - \(maxCostString!)"
        let etaString = etaDestination > 60 ? "\(Int(etaDestination / 60)) min" : "\(etaDestination) sec"
        
        rideResultsView.text = " Cost: \(costString!) \n Distance: \(distanceString) \n Dest. ETA: \(etaString)"
        rideResultsView.numberOfLines = 0
        rideResultsView.lineBreakMode = NSLineBreakMode.ByWordWrapping
        rideResultsView.hidden = false
        
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
        
        hideResultsViews()
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
        
        hideResultsViews()
    }
    
    func getSelectedModeFromTitle () -> String! {
        let title = modeView.titleForSegmentAtIndex(modeView.selectedSegmentIndex)!.lowercaseString
        return title == LyftService.RIDE_TYPE_LYFT ? title : "\(LyftService.RIDE_TYPE_LYFT)_\(title)"
    }
    
    func hideResultsViews() {
        etaResultsView.hidden = true
        rideResultsView.hidden = true
    }
    
}

