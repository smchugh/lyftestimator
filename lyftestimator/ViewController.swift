//
//  ViewController.swift
//  lyftestimator
//
//  Created by Steve McHugh on 8/31/15.
//  Copyright (c) 2015 chugs. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

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

}

