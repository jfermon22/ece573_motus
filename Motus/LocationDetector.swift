//
//  LocationDetector.swift
//  Motus
//
//  Created by Jeff Fermon on 2/28/16.
//  Copyright © 2016 Jeff Fermon. All rights reserved.
//

import Foundation
import CoreLocation

class LocationDetector: LocationManagerDelegate {
    var locationManager:LocationManager?
    let waitSem:dispatch_semaphore_t
    var initialLocation:CLLocation?
    var currentLocation:CLLocation?
    var minMoveDistance:CLLocationDistance?
    var deviceMovedMinimum:Bool
    
    init() {
        locationManager = LocationManager(accuracy: kCLLocationAccuracyBest, distanceFilter: 5)
        waitSem = dispatch_semaphore_create(0)
        minMoveDistance = 20
        deviceMovedMinimum = false
        locationManager!.delegate = self
    }
    
    func waitTilDeviceMove(feet:CLLocationDistance){
         minMoveDistance = feet
         dispatch_semaphore_wait(waitSem, DISPATCH_TIME_FOREVER)
    }
    
    func waitTilDeviceMove(feet:CLLocationDistance, timeout: dispatch_time_t){
        minMoveDistance = feet
        let timeoutInSecs = timeout * 1000000000
        dispatch_semaphore_wait(waitSem, timeoutInSecs )
    }
    
    func start() {
        deviceMovedMinimum = false
        initialLocation = nil
        currentLocation = nil
        locationManager?.startUpdatingLocation()
    }
    
    func stop() {
        locationManager?.stopUpdatingLocation()
        dispatch_semaphore_signal(waitSem)
    }
    
    func didUpdateCurrentLocation(location:CLLocation){
        if initialLocation == nil {
            initialLocation = location
        }
        
        currentLocation = location
        
        let distance = currentLocation!.distanceFromLocation(initialLocation!)
        
        deviceMovedMinimum = distance > minMoveDistance!

        if(deviceMovedMinimum)
        {
            dispatch_semaphore_signal(waitSem)
        }
    }
    
    func failedToUpdateLocation (error: NSError)
    {
            print("Failed to Update Location : \(error.description)")
    }
    
    func didDeviceMoveMinimum() -> Bool {
        return deviceMovedMinimum
    }

    
}