//
//  PinLocation.swift
//  lyftestimator
//
//  Created by Steve McHugh on 9/2/15.
//  Copyright (c) 2015 chugs. All rights reserved.
//

import MapKit

class PinLocation: NSObject, MKAnnotation {
    static let TYPE_ORIGIN = "origin"
    static let TYPE_DESTINATION = "destination"
    
    let title: String
    let address: String
    let pinType: String
    var coordinate: CLLocationCoordinate2D
    
    init(title: String, address: String, pinType: String, coordinate: CLLocationCoordinate2D) {
        self.title = title
        self.address = address
        self.pinType = pinType
        self.coordinate = coordinate
        
        super.init()
    }
    
    var subtitle: String {
        return address
    }

}