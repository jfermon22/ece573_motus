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
    private var calibrateSem = dispatch_semaphore_create(0)
    private(set) var initialLocation:CLLocation?
    private(set) var currentLocation:CLLocation?
    private(set) var deviceMovedMinimum = false
    private var isCalibrating = false;
    private var updatesReceived = 0
    
    //MARK: Constructors
    init() {
        locationManager.accuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 1
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
        isCalibrating = true
        updatesReceived = 0
        do {
            try locationManager.startUpdatingLocation()
        } catch _ {
            return false
        }
        
        let iscalib = didCalibrate()
        print("CALIBRATED = \(iscalib)")
        isCalibrating = false
        
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
        
        if !isCalibrating {
            deviceMovedMinimum = didDeviceMoveMinimum()
        
            if(deviceMovedMinimum)
            {
                dispatch_semaphore_signal(waitSem)
            }
        } else {
            let deviceDistance = currentLocation?.distanceFromLocation(initialLocation!)
            print("calibration distance: \(deviceDistance)")
            if ( initialLocation != currentLocation && deviceDistance < 10 && updatesReceived > 2){
                print("Posting calibration sem")
                dispatch_semaphore_signal(calibrateSem)
            } 
            initialLocation = currentLocation
        }
        updatesReceived += 1
    }
    
    func failedToUpdateLocation (error: NSError)
    {
        print("Failed to Update Location : \(error.description)")
    }
    
    private func didCalibrate() -> Bool {
        calibrateSem = dispatch_semaphore_create(0)
        
        let timeoutNs = Int64(15) * Int64(NSEC_PER_SEC)
        let time = dispatch_time(DISPATCH_TIME_NOW, timeoutNs )
        return dispatch_semaphore_wait(calibrateSem, time ) == 0

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