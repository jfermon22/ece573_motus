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

protocol LocationDetectorDelegate {
    func gotLocationUpdate(location:CLLocation)
}

class LocationDetector: LocationManagerDelegate {
    //MARK: public members
    var delegate:LocationDetectorDelegate?
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
    
    //MARK: Constructors
    init() {
        locationManager.delegate = self
    }
    
    deinit {
        stop()
        currentLocation = nil
        initialLocation = nil
    }
    
    //MARK: Update Methods
    func start() -> Bool {
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
        
        delegate!.gotLocationUpdate(currentLocation!)
        
        let horz = currentLocation?.horizontalAccuracy
        let vert = currentLocation?.verticalAccuracy
        let greaterAccuracy = ( horz > vert ) ? horz : vert
        let lesserAccuracy = ( horz < vert ) ? horz : vert
        //print ("Desc,\(currentLocation?.description)")
        //print ("lesser:\(lesserAccuracy)   greater:\(greaterAccuracy)   speed:\(currentLocation?.speed)")
        if lesserAccuracy >= 0 &&
            greaterAccuracy <= 10  &&
            currentLocation?.speed >= 0 {
            if(didDeviceMoveMinimum()){
                dispatch_semaphore_signal(waitSem)
            }
        } else {
            initialLocation = nil
        }
        
    }
    
    func failedToUpdateLocation (error: NSError)
    {
        print("Failed to Update Location : \(error.description)")
    }
    
    //MARK: Wait methods
    func waitTilDeviceMove(feet:CLLocationDistance){
        waitSem = dispatch_semaphore_create(0)
        initialLocation = nil
        
        //convert to meters
        minMoveDistance = ( feet / FEET_PER_METER )
        dispatch_semaphore_wait(waitSem, DISPATCH_TIME_FOREVER)
    }
    
    func waitTilDeviceMove(feet:CLLocationDistance, timeout: UInt64) -> Bool{
        waitSem = dispatch_semaphore_create(0)
        initialLocation = nil
        
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