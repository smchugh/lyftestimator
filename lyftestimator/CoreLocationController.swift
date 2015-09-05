//
//  CoreLocationController.swift
//  lyftestimator
//
//  Created by Steve McHugh on 9/1/15.
//  Copyright (c) 2015 chugs. All rights reserved.
//

import Foundation
import CoreLocation

class CoreLocationController : NSObject, CLLocationManagerDelegate {
    
    var locationManager:CLLocationManager = CLLocationManager()
    var locationFound:Bool?
    
    override init() {
        super.init()
        
        self.locationFound = false
        
        self.locationManager.delegate = self
        self.locationManager.distanceFilter  = 10
        self.locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        self.locationManager.requestWhenInUseAuthorization()
    }
    
    func locationManager(manager: CLLocationManager!, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        println("didChangeAuthorizationStatus")
        
        switch status {
            case .NotDetermined:
                println(".NotDetermined")
                break
            
            case .AuthorizedWhenInUse:
                println(".AuthorizedWhenInUse")
                self.locationManager.startUpdatingLocation()
                break
            
            case .Denied:
                println(".Denied")
                break
            
            default:
                println("Unhandled authorization status")
                break
        }
    }
    
    func locationManager(manager: CLLocationManager!, didUpdateLocations locations: [AnyObject]!) {
        let location = locations.last as! CLLocation
        
        let userInfo = [
            "lat": location.coordinate.latitude,
            "lng": location.coordinate.longitude,
            "firstLocation": !self.locationFound!
        ] as Dictionary<String, AnyObject>
            
        NSNotificationCenter.defaultCenter().postNotificationName("LOCATION_FOUND",
            object: nil,
            userInfo: userInfo
        )
            
        self.locationFound = true
    }
}
