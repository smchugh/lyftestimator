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
    var originPin: PinLocation!
    var destinationPin: PinLocation!
    var activePin: PinLocation!
    var currentUserLocation: CLLocation!
    var activeMode: String!
    
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
        
        NSNotificationCenter.defaultCenter().addObserver(self,
            selector: "rideTypesUpdated:",
            name: "RIDE_TYPES_UPDATED",
            object: nil
        )
        
        mapView.delegate = self

        var tapRecognizer = UITapGestureRecognizer(target: self, action: "updatePin:")
        mapView.addGestureRecognizer(tapRecognizer)
        
        pinTypeView.addTarget(self, action: "pinTypeChanged:", forControlEvents: UIControlEvents.ValueChanged)
        buttonCenterUser.addTarget(self, action: "centerMapOnUser:", forControlEvents: UIControlEvents.TouchUpInside)
        buttonEstimate.addTarget(self, action: "estimateLyft:", forControlEvents: UIControlEvents.TouchUpInside)
        modeView.addTarget(self, action: "selectMode:", forControlEvents: UIControlEvents.ValueChanged)
        
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
        
        NSLog("ViewController: pickupEtaUpdated: pickupEtaData \(pickupEtaData)")
    }
    
    func rideEstimateUpdated(notification:NSNotification) -> Void {
        let rideEstimateData = notification.userInfo as! Dictionary<String, AnyObject>
        
        println(getSelectedModeFromTitle())
        println(rideEstimateData)
        
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
        
        NSLog("ViewController: rideEstimateUpdated: rideEstimateData \(rideEstimateData)")
    }
    
    func rideTypesUpdated(notification:NSNotification) -> Void {
        let rideTypesData = notification.userInfo as! Dictionary<String, AnyObject>
        
        let rideTypes = rideTypesData["rideTypes"] as! [String]
        
        modeView.removeAllSegments()
        
        var activeModeIndex = 0
        for rideType in rideTypes {
            let segmentTitle = getTitleForRideType(rideType)
            let segmentIndex = modeView.numberOfSegments
            if activeMode != nil && segmentTitle.lowercaseString == activeMode {
                activeModeIndex = segmentIndex
            }
            modeView.insertSegmentWithTitle(getTitleForRideType(rideType), atIndex: modeView.numberOfSegments, animated: false)
        }
        
        modeView.selectedSegmentIndex = activeModeIndex
        
        NSLog("ViewController: rideTypesUpdated: rideTypesData \(rideTypesData)")
    }
    
    func getTitleForRideType(rideType: String) -> String {
        switch rideType {
            case LyftService.RIDE_TYPE_LYFT:
                return "Lyft"
            case LyftService.RIDE_TYPE_LINE:
                return "Line"
            case LyftService.RIDE_TYPE_PLUS:
                return "Plus"
            default:
                if rideType.rangeOfString("lyft_") == nil {
                    return rideType.capitalizedString
                } else {
                    return rideType.stringByReplacingOccurrencesOfString("lyft_", withString: "").capitalizedString
                }
        }
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
        
            originPin = PinLocation(
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
                originPin = pinView.annotation as! PinLocation
                updateModes(annotation.coordinate)
            } else {
                destinationPin = pinView.annotation as! PinLocation
            }
            activePin = pinView.annotation as! PinLocation
            return pinView
        }
        return nil
    }
    
    func updatePin(recognizer: UITapGestureRecognizer) {
        let touchLocation:CGPoint = recognizer.locationInView(mapView)
        let newCoordinate = mapView.convertPoint(touchLocation, toCoordinateFromView: mapView)
        activePin!.coordinate = newCoordinate
        
        // Force refresh of map view
        mapView.centerCoordinate = mapView.centerCoordinate
        
        if activePin!.pinType == PinLocation.TYPE_ORIGIN {
            updateModes(newCoordinate)
        }
        
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
        
        if destinationPin == nil {
            let newPin = PinLocation(
                title: "Test Title",
                address: "Test Subtitle",
                pinType: PinLocation.TYPE_DESTINATION,
                coordinate: mapView.centerCoordinate
            )
            
            mapView.addAnnotation(newPin)
            pinTypeView.selectedSegmentIndex = 1
            return
        }
        
        let userInfo = [
            "originLat": originPin.coordinate.latitude.description,
            "originLng": originPin.coordinate.longitude.description,
            "destinationLat": destinationPin.coordinate.latitude.description,
            "destinationLng": destinationPin.coordinate.longitude.description,
            "rideType": getSelectedModeFromTitle()
        ]
        
        NSNotificationCenter.defaultCenter().postNotificationName("LOCATIONS_UPDATED",
            object: nil,
            userInfo: userInfo)
        
        hideResultsViews()
    }
    
    func updateModes(coordinate: CLLocationCoordinate2D) {
        
        let userInfo = [
            "lat": coordinate.latitude.description,
            "lng": coordinate.longitude.description
        ]
        
        NSNotificationCenter.defaultCenter().postNotificationName("ORIGIN_UPDATED",
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
    
    func selectMode(segment: UISegmentedControl) {
        activeMode = segment.titleForSegmentAtIndex(segment.selectedSegmentIndex)?.lowercaseString
        
        hideResultsViews()
    }
    
}

