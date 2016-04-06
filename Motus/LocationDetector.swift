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
    var minMoveDistance:CLLocationDistance {
        set { _minMoveDistance = ( newValue / FEET_PER_METER ) }
        get { return _minMoveDistance }
    }
    var accuracy:CLLocationAccuracy {
        set { locationManager.accuracy = newValue }
        get { return locationManager.accuracy }
    }
    var distanceFilter:CLLocationAccuracy {
        set { locationManager.distanceFilter = newValue }
        get { return locationManager.distanceFilter }
    }
    var isWaiting = false
    
    //MARK: private members
    private var locationManager = LocationManager.sharedInstance
    private var waitSem = dispatch_semaphore_create(0)
    private(set) var initialLocation:CLLocation?
    var currentLocation:CLLocation? {
        get{return locationManager.currentLocation}
    }
    private var _minMoveDistance:CLLocationDistance = 20 // meters in 20 feet
    
    //MARK: Constructors
    init() {
        locationManager.distanceFilter = kCLDistanceFilterNone
        locationManager.delegate = self
    }
    
    deinit {
        stop()
        initialLocation = nil
    }
    
    //MARK: Update Methods
    func start() -> Bool {
        return locationManager.startUpdatingLocation()
    }
    
    func stop() {
        locationManager.stopUpdatingLocation()
        dispatch_semaphore_signal(waitSem)
    }
    
    func startMonitoringForRegion(region: CLRegion) -> Bool {
        print("LocationDetector::startMonitoringRegion - start monitoring for region")
        return locationManager.startMonitoringForRegion(region)
    }
    
    func stopForMonitoringRegion(region: CLRegion) {
        locationManager.stopMonitoringForRegion(region)
    }

    //MARK: LocationManagerDelegate Protocol Functions
    func gotLocationUpdate(location:CLLocation){
        
        delegate!.gotLocationUpdate(currentLocation!)
        
        //if no one is waiting to see if we moved then just return
        guard isWaiting else { return }
        
        let horz = currentLocation?.horizontalAccuracy
        let vert = currentLocation?.verticalAccuracy
        let isAccuracyCalibrated = ( horz > vert ) ? (horz <= 15) : (vert <= 15)
        let isAccuracyValid = (horz >= 0 && vert >= 0)
        let isSpeedValid = currentLocation?.speed >= 0
        
        //verify that our latest update dated is valid, and accurate enough
        guard isAccuracyValid && isSpeedValid && isAccuracyCalibrated else {
             print ("isAccuracyCalibrated:\(isAccuracyCalibrated) isAccuracyValid:\(isAccuracyValid)   isSpeedValid:\(isSpeedValid)")
            //readings have become invalid resetting 0
            initialLocation = nil
            return
        }
        
        //if initialLocation is nil, then set it and move on
        //no need to check distance because it will be 0
        if (initialLocation == nil) {
            print("initial location set")
                initialLocation = currentLocation
        }
        else if( didDeviceMoveMinimum() ) {
            dispatch_semaphore_signal(waitSem)
        }
        
    }
    
    func failedToUpdateLocation (error: NSError)
    {
        print("Failed to Update Location : \(error.description)")
    }
    
    func didEnterRegion(region: CLRegion) {
          dispatch_semaphore_signal(waitSem)
    }

    func didExitRegion(region: CLRegion) {
        print("Device exited region")
          dispatch_semaphore_signal(waitSem)
    }

    
    //MARK: Wait methods
    func waitTilDeviceMove(distance:CLLocationDistance){
        waitTilDeviceMove(distance, timeout: DISPATCH_TIME_FOREVER)
    }
    
    func waitTilDeviceMove(distance:CLLocationDistance, timeout: UInt64) -> Bool{
        isWaiting = true
        waitSem = dispatch_semaphore_create(0)
        initialLocation = nil
        
        minMoveDistance = distance
        
        //timeout in nanoseconds
        let timeoutNs = Int64(timeout) * Int64(NSEC_PER_SEC)
        let time = dispatch_time(DISPATCH_TIME_NOW, timeoutNs )
        let deviceMoved = dispatch_semaphore_wait(waitSem, time ) == 0
        
        isWaiting = false
        
        return deviceMoved
    }
    
    func waitTilDeviceExitRegion (radius: CLLocationDistance,
                                  identifier: String)
    {
        isWaiting = true
        waitSem = dispatch_semaphore_create(0)
        let region = CLCircularRegion(center: (locationManager.currentLocation?.coordinate)!, radius: radius, identifier: identifier)
        region.notifyOnExit = true
        if startMonitoringForRegion(region) {
            dispatch_semaphore_wait(waitSem, DISPATCH_TIME_FOREVER )
        }
    }
    
    private func didDeviceMoveMinimum() -> Bool {
        
        let distance = currentLocation!.distanceFromLocation(initialLocation!)
        
        print("distance: \(distance) +- \((currentLocation?.horizontalAccuracy > currentLocation?.verticalAccuracy) ? currentLocation?.horizontalAccuracy : currentLocation?.verticalAccuracy)")
        return distance > minMoveDistance
    }
}