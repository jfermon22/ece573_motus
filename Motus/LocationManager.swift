//
//  LocationManager.swift
//  Motus
//
//  Created by Jeff Fermon on 3/14/16.
//  Copyright © 2016 Jeff Fermon. All rights reserved.
//

import Foundation
import CoreLocation

protocol LocationManagerDelegate {
    func didUpdateCurrentLocation(location:CLLocation)
    func failedToUpdateLocation (error: NSError)
}


class LocationManager:NSObject, CLLocationManagerDelegate  {
    var cllocationManager:CLLocationManager?
    var currentLocation:CLLocation?
    var delegate:LocationManagerDelegate?
    
    convenience init(accuracy:CLLocationAccuracy, distanceFilter:CLLocationDistance){
        self.init()
        cllocationManager?.desiredAccuracy = accuracy
        cllocationManager?.distanceFilter = distanceFilter
    }
    
    override init() {
        super.init()
        cllocationManager = CLLocationManager()
        cllocationManager?.delegate = self
    }
    
    func startUpdatingLocation() {
        if CLLocationManager.authorizationStatus() == .NotDetermined {
            cllocationManager?.requestWhenInUseAuthorization()
            //cllocationManager?.requestAlwaysAuthorization()
        }
        
        cllocationManager?.startUpdatingLocation()
    }
    
    func stopUpdatingLocation() {
        cllocationManager?.stopUpdatingLocation()
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]){
        let location: AnyObject? = (locations as NSArray).lastObject
        currentLocation = location as? CLLocation
        delegate!.didUpdateCurrentLocation(currentLocation!)
    }
    
    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        delegate!.failedToUpdateLocation(error)
    }

}

