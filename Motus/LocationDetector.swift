//
//  LocationDetector.swift
//  Motus
//
//  Created by Jeff Fermon on 2/28/16.
//  Copyright © 2016 Jeff Fermon. All rights reserved.
//

import Foundation
import CoreLocation

let FEET_PER_METER = 3.28084

class LocationDetector: LocationManagerDelegate {
    //MARK: public members
    var minMoveDistance:CLLocationDistance = 30 // meters in 20 feet
    var accuracy:CLLocationAccuracy {
        set { locationManager.accuracy = newValue }
        get { return locationManager.accuracy }
    }
    var distanceFilter:CLLocationAccuracy {
        set { locationManager.distanceFilter = newValue }
        get { return locationManager.distanceFilter }
    }
    
    //MARK: private members
    private var locationManager = LocationManager.sharedInstance
    private var waitSem = dispatch_semaphore_create(0)
    private(set) var initialLocation:CLLocation?
    private(set) var currentLocation:CLLocation?
    private(set) var deviceMovedMinimum = false
    
    //MARK: Constructors
    init() {
        locationManager.accuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 10
        locationManager.delegate = self
    }
    
    deinit {
        stop()
        currentLocation = nil
        initialLocation = nil
    }
    
    //MARK: Update Methods
    func start() -> Bool {
        deviceMovedMinimum = false
        initialLocation = nil
        currentLocation = nil
        do {
            try locationManager.startUpdatingLocation()
        } catch _ {
            return false
        }
        return true
    }
    
    func stop() {
        locationManager.stopUpdatingLocation()
        dispatch_semaphore_signal(waitSem)
    }
    
    func gotLocationUpdate(location:CLLocation){
        if initialLocation == nil {
            initialLocation = location
        }
        
        currentLocation = location
        
        deviceMovedMinimum = didDeviceMoveMinimum()
        
        if(deviceMovedMinimum)
        {
            dispatch_semaphore_signal(waitSem)
        }
    }
    
    func failedToUpdateLocation (error: NSError)
    {
        print("Failed to Update Location : \(error.description)")
    }
    
    //MARK: Wait methods
    func waitTilDeviceMove(feet:CLLocationDistance){
        waitSem = dispatch_semaphore_create(0)
        
        //convert to meters
        minMoveDistance = ( feet / FEET_PER_METER )
        dispatch_semaphore_wait(waitSem, DISPATCH_TIME_FOREVER)
    }
    
    func waitTilDeviceMove(feet:CLLocationDistance, timeout: UInt64) -> Bool{
        waitSem = dispatch_semaphore_create(0)
        
        //convert to meters
        minMoveDistance = ( feet / FEET_PER_METER )
        
        //timeout in nanoseconds
        let timeoutNs = Int64(timeout) * Int64(NSEC_PER_SEC)
        let time = dispatch_time(DISPATCH_TIME_NOW, timeoutNs )
        return dispatch_semaphore_wait(waitSem, time ) == 0
    }
    
    private func didDeviceMoveMinimum() -> Bool {
        
        let distance = currentLocation!.distanceFromLocation(initialLocation!)
        
        print("distance: \(distance)")
        return distance > minMoveDistance
    }
}