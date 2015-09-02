//
//  LyftService.swift
//  lyftestimator
//
//  Created by Steve McHugh on 8/31/15.
//  Copyright (c) 2015 chugs. All rights reserved.
//

import Foundation
import Alamofire

class LyftService : NSObject {
    
    let apiUrl = "https://public-api.lyft.com"
    let authWaitSeconds = 1.0
    
    var authenticated: Bool?
    var accessToken: String?
    var tokenExpiration: Int?
    
    override init() {
        super.init()
        
        self.authenticated = false
        self.authenticate()
        
        NSNotificationCenter.defaultCenter().addObserver(self,
            selector: "locationsUpdated:",
            name: "LOCATIONS_UPDATED",
            object: nil
        )
    }
    
    func authenticate() -> Void {
        let endPoint = "\(apiUrl)/oauth/token"
        
        let clientId      = valueForAPIKey(keyname: "LYFT_API_CLIENT_ID")
        let clientSecret  = valueForAPIKey(keyname: "LYFT_API_CLIENT_SECRET")
        let credentialData    = "\(clientId):\(clientSecret)".dataUsingEncoding(NSUTF8StringEncoding)!
        let base64Credentials = credentialData.base64EncodedStringWithOptions(nil)
        
        let headers = [
            "Authorization": "Basic \(base64Credentials)",
            "Content-Type": "application/json;charset=UTF-8"
        ]
        
        let parameters = [
            "grant_type": "client_credentials"
        ]
        
        Alamofire.request(.POST, endPoint, headers: headers, parameters: parameters, encoding: .JSON)
            .validate()
            .responseJSON { _, response, JSON, error in
                if response?.statusCode == 200 {
                    let jsonResponse = JSON as! NSDictionary
                    if jsonResponse.count > 0 && jsonResponse.valueForKey("access_token") != nil {
                        self.accessToken = jsonResponse.valueForKey("access_token") as? String
                        self.tokenExpiration = (jsonResponse.valueForKey("expires_in") as! Int) + Int(NSDate().timeIntervalSince1970)
                        self.authenticated = true
                        NSLog("LyftService: authenticate: Received new access token form Lyft expiring at \(NSDate(timeIntervalSince1970: Double(self.tokenExpiration!)))")
                        
                    } else {
                        NSLog("LyftService: authenticate: Unexpected response from Lyft: \(JSON as! NSDictionary)")
                    }
                } else {
                    let jsonResponse = JSON as! NSDictionary
                    let errorKey = jsonResponse.valueForKey("error") as! String
                    let errorDescription = jsonResponse.valueForKey("error_description") as! String
                    NSLog("LyftService: authenticate: ERROR: \(response?.statusCode): \(error?.description)")
                    NSLog("LyftService: authenticate: LyftAuthError: \(errorKey) \(errorDescription)")
                }
            }
    }
    
    func locationsUpdated(notification:NSNotification) -> Void {
        let userInfo = notification.userInfo as! Dictionary<String,String>
        
        NSLog("LyftService: locationsUpdated: Locations updated \(userInfo)")
        
        if !self.authenticated! {
            NSLog("LyftService: locationsUpdated: Not yet authenticated, trying again")
            self.authenticate()
            NSTimer.scheduledTimerWithTimeInterval(authWaitSeconds,
                target: self, selector: "locationsUpdated:", userInfo: userInfo, repeats: false
            )
            return
        }
        
        let originLat      = userInfo["originLat"]!
        let originLng      = userInfo["originLng"]!
        let destinationLat = userInfo["destinationLat"]!
        let destinationLng = userInfo["destinationLng"]!
        let rideType       = userInfo["rideType"]
        
        self.getPickupEtaData(
            originLat,
            originLng:originLng,
            rideType:rideType
        )
        self.getRideEstimateData(
            originLat,
            originLng:originLng,
            destinationLat:destinationLat,
            destinationLng:destinationLng,
            rideType:rideType
        )
    }
    
    func getPickupEtaData(originLat:String, originLng:String, rideType:String?) -> Void {
        let endPoint = "\(apiUrl)/v1/eta"
        
        let headers = [
            "Authorization": "Bearer \(self.accessToken!)",
            "Content-Type": "application/json;charset=UTF-8"
        ]
        
        var parameters = [
            "lat": originLat,
            "lng": originLng
        ]
        
        if rideType != nil {
            parameters["ride_type"] = rideType
        }
        
        Alamofire.request(.GET, endPoint, headers: headers, parameters: parameters)
            .validate()
            .responseJSON { _, response, JSON, error in
                if response?.statusCode == 200 {
                    let jsonResponse = JSON as! NSDictionary
                    if jsonResponse.count > 0 && jsonResponse.valueForKey("eta_estimates") != nil {
                        let estimates = jsonResponse.valueForKey("eta_estimates") as? NSArray
                        var pickupEtaData = Dictionary<String, AnyObject>()
                        if estimates != nil {
                            for estimate in estimates! {
                                let estimateData = estimate as! NSDictionary
                                let etaSeconds = estimateData["eta_seconds"] as? Int
                                if etaSeconds != nil {
                                    pickupEtaData[estimateData["ride_type"] as! String] = ["eta": etaSeconds!]
                                }
                            }
                        }
                        if pickupEtaData.count > 0 {
                            NSLog("LyftService: getPickupEta: Received eta data of \(pickupEtaData) for \(parameters)")
                            NSNotificationCenter.defaultCenter().postNotificationName("PICKUP_ETA_UPDATED",
                                object: nil,
                                userInfo: pickupEtaData
                            )
                        } else {
                            NSLog("LyftService: getPickupEta: No eta data found for \(parameters)")
                        }
                    } else {
                        NSLog("LyftService: getPickupEta: Unexpected response from Lyft: \(JSON as! NSDictionary)")
                    }
                } else {
                    let jsonResponse = JSON as? NSDictionary
                    let errorKey = jsonResponse?.valueForKey("error") as? String
                    let errorDescription = jsonResponse?.valueForKey("error_description") as? String
                    NSLog("LyftService: getPickupEta: ERROR: \(response?.statusCode): \(error?.description)")
                    NSLog("LyftService: getPickupEta: LyftError: \(errorKey) \(errorDescription)")
                }
            }
    }
    
    func getRideEstimateData(originLat:String, originLng:String, destinationLat:String, destinationLng:String, rideType:String?) -> Void {
        let endPoint = "\(apiUrl)/v1/cost"
        
        let headers = [
            "Authorization": "Bearer \(self.accessToken!)",
            "Content-Type": "application/json;charset=UTF-8"
        ]
        
        var parameters = [
            "start_lat": originLat,
            "start_lng": originLng,
            "end_lat": destinationLat,
            "end_lng": destinationLng
        ]
        
        if rideType != nil {
            parameters["ride_type"] = rideType
        }
        
        Alamofire.request(.GET, endPoint, headers: headers, parameters: parameters)
            .validate()
            .responseJSON { _, response, JSON, error in
                if response?.statusCode == 200 {
                    let jsonResponse = JSON as! NSDictionary
                    if jsonResponse.count > 0 && jsonResponse.valueForKey("cost_estimates") != nil {
                        let estimates = jsonResponse.valueForKey("cost_estimates") as? NSArray
                        var rideEstimateData = Dictionary<String, AnyObject>()
                        if estimates != nil {
                            for estimate in estimates! {
                                let estimateData = estimate as! NSDictionary
                                rideEstimateData[estimateData["ride_type"] as! String] = [
                                    "estimated_cost_cents_max": (estimateData["estimated_cost_cents_max"] as! Float),
                                    "estimated_cost_cents_min": (estimateData["estimated_cost_cents_min"] as! Float),
                                    "estimated_distance_miles": (estimateData["estimated_distance_miles"] as! Float),
                                    "current_prime_time_percent_multiplier": (estimateData["current_prime_time_percent_multiplier"] as! Int),
                                    "estimated_duration_seconds": (estimateData["estimated_duration_seconds"] as! Int)
                                ]
                            }
                        }
                        if rideEstimateData.count > 0 {
                            NSLog("LyftService: getRideEstimateData: Received ride data of \(rideEstimateData) for \(parameters)")
                            NSNotificationCenter.defaultCenter().postNotificationName("RIDE_ESTIMATE_UPDATED",
                                object: nil,
                                userInfo: rideEstimateData
                            )
                        } else {
                            NSLog("LyftService: getRideEstimateData: No ride data found for \(parameters)")
                        }
                        
                        
                    } else {
                        NSLog("LyftService: getRideEstimateData: Unexpected response from Lyft: \(JSON as! NSDictionary)")
                    }
                } else {
                    let jsonResponse = JSON as? NSDictionary
                    let errorKey = jsonResponse?.valueForKey("error") as? String
                    let errorDescription = jsonResponse?.valueForKey("error_description") as? String
                    NSLog("LyftService: getRideEstimateData: ERROR: \(response?.statusCode): \(error?.description)")
                    NSLog("LyftService: getRideEstimateData: LyftError: \(errorKey) \(errorDescription)")
                }
            }
    }
    
}
