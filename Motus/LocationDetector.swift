//
//  LocationDetector.swift
//  Motus
//
//  Created by Jeff Fermon on 2/28/16.
//  Copyright © 2016 Jeff Fermon. All rights reserved.
//

import Foundation
import CoreLocation
import CoreMotion

let FEET_PER_METER = 3.28084
let LOCATION_PRECISION = 10.0

protocol LocationDetectorDelegate {
    func gotLocationUpdate(location:CLLocation)
    func gotMotionActivityUpdate(activity:CMMotionActivity)
    func IsCalibrating()
    func CalibrationComplete()
}

class LocationDetector: LocationManagerDelegate, MotionActivityManagerDelegate {
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
    var isCalibrating = false
    
    //MARK: private members
    private var locationManager = LocationManager.sharedInstance
    private var motionActivityManager = MotionActivityManager.sharedInstance
    private var waitSem = dispatch_semaphore_create(0)
    private(set) var initialLocation:CLLocation? {
        set {
            if _initialLocation == nil && newValue != nil {
                hasBecomeMobileSinceIntialLocationSet = false
            }
            _initialLocation = newValue
        }
        get { return _initialLocation }
    }
    private var _minMoveDistance:CLLocationDistance = 20 // meters in 20 feet
    private var bestAccuracy:CLLocationAccuracy?
    private var hasBecomeMobileSinceIntialLocationSet = false
    private var _initialLocation:CLLocation?
    
    //MARK: read-only memberts
    var currentLocation:CLLocation? {
        get { return locationManager.currentLocation }
    }
    var currentActivity:CMMotionActivity? {
        get{ return motionActivityManager.currentActivity }
    }
    
    var latestReadingAccuracy:CLLocationAccuracy? {
        get {
            let vertAcc = currentLocation?.verticalAccuracy
            let horzAcc = currentLocation?.horizontalAccuracy
            return ( vertAcc > horzAcc ) ? vertAcc : horzAcc
        }
    }
    
    //MARK: Constructors
    init() {
        locationManager.distanceFilter = kCLDistanceFilterNone
        locationManager.delegate = self
        motionActivityManager.delegate = self
    }
    
    deinit {
        stop()
        initialLocation = nil
    }
    
    //MARK: Update Methods
    func start() -> Bool {
        motionActivityManager.startUpdates()
        return locationManager.startUpdatingLocation()
    }
    
    func stop() {
        locationManager.stopUpdatingLocation()
        motionActivityManager.stopUpdates()
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
        let isPreciseEnough = latestReadingAccuracy <= LOCATION_PRECISION
        let isAccuracyValid = ( horz >= 0 && vert >= 0 )
        let isSpeedValid = currentLocation?.speed >= 0
        let isDataStale = currentLocation?.timestamp.timeIntervalSinceNow > 1
        
        //verify that our latest updated value is valid, and accurate enough
        guard isAccuracyValid && isSpeedValid && isPreciseEnough && !isDataStale else {
            //print ("isPreciseEnough:\(isPreciseEnough) isAccuracyValid:\(isAccuracyValid) isSpeedValid:\(isSpeedValid) isDataStale:\(isDataStale)")
            if !isAccuracyValid {
                print( "Accuracy is +- \(latestReadingAccuracy)")
            }
            //readings have become invalid resetting 0
            initialLocation = nil
            
            //fires delegate method to alert receiver that location is recalibrating
            if !isCalibrating {
                print("calling IsCalibrating")
                isCalibrating = true
                delegate?.IsCalibrating()
            }
            return
        }
        
        //fires delegate method to alert receiver that device is not calibrating
        if isCalibrating {
            isCalibrating = false
            print("calling CalibrationComplete")
            delegate?.CalibrationComplete()
        }
        
        //if initialLocation is nil, then set it and move on
        //no need to check distance because it will be 0
        if (initialLocation == nil  ||  latestReadingAccuracy < bestAccuracy ) {
            print("initial location set")
            initialLocation = currentLocation
            bestAccuracy = latestReadingAccuracy
        } else if( didDeviceMoveMinimum() ) {
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
    
    //MARK: MotionActivityManagerDelegate Protocol Functions
    func gotMotionActivityUpdate(motionActivity:CMMotionActivity){
        //check if the user has started walking since we set the initial location
        //if they have not check if they are currently stationary
        //if they are not then check that the confidence is medium or greater
        // if these al pass set variable true
        let noActivity = !motionActivity.stationary &&
            !motionActivity.automotive &&
            !motionActivity.cycling &&
            !motionActivity.running &&
            !motionActivity.walking &&
            !motionActivity.unknown
        
        guard !noActivity else {
            print("Received blank motion activity")
            return
        }
        
        if !hasBecomeMobileSinceIntialLocationSet &&
        !motionActivity.stationary &&
        (motionActivity.confidence == .Medium || motionActivity.confidence == .High ) {
            hasBecomeMobileSinceIntialLocationSet = true
        }
        delegate?.gotMotionActivityUpdate(motionActivity)
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
        if hasBecomeMobileSinceIntialLocationSet {
            let distance = currentLocation!.distanceFromLocation(initialLocation!)
            print("distance: \(distance) +- \(latestReadingAccuracy)")
            return distance > minMoveDistance
        } else {
            print("didDeviceMoveMinimum::has not begun moving since initialLocationSet")
            return false
        }
    }
}