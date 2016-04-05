//
//  LocationManager.swift
//  Motus
//
//  Created by Jeff Fermon on 3/14/16.
//  Copyright © 2016 Jeff Fermon. All rights reserved.
//

import Foundation
import CoreLocation


enum LocationManagerErrors:ErrorType {
    case NOT_DETERMINED
    case RESTRICTED
    case DENIED
    case UNCALIBRATED
}

protocol LocationManagerDelegate {
    func gotLocationUpdate(location:CLLocation)
    func failedToUpdateLocation (error: NSError)
}

//enum LocationManagerState {
//    case Idle
//    case Calibrating
//    case Active
//}


class LocationManager: NSObject, CLLocationManagerDelegate {
    //MARK: public variables
    static let sharedInstance = LocationManager()
    var delegate:LocationManagerDelegate?
    var accuracy:CLLocationAccuracy {
        set { cllocationManager.desiredAccuracy = newValue }
        get { return cllocationManager.desiredAccuracy }
    }
    var distanceFilter:CLLocationAccuracy {
        set { cllocationManager.distanceFilter = newValue }
        get { return cllocationManager.distanceFilter }
    }
    
    //MARK: private variables
    private let cllocationManager = CLLocationManager()
    private(set) var currentLocation:CLLocation?
    //private(set) var calibrated = false
    //private(set) var state = LocationManagerState.Idle
    //private var calibrateSem = dispatch_semaphore_create(0)
    
    //MARK: Constructors
    override init() {
        super.init()
        cllocationManager.desiredAccuracy = kCLLocationAccuracyBest
        cllocationManager.distanceFilter = kCLDistanceFilterNone
        cllocationManager.delegate = self
    }
    
    convenience init(accuracy:CLLocationAccuracy, distanceFilter:CLLocationDistance){
        self.init()
        cllocationManager.desiredAccuracy = accuracy
        cllocationManager.distanceFilter = distanceFilter
    }
    
    deinit {
        cllocationManager.stopUpdatingLocation()
        currentLocation = nil
        delegate = nil
    }

    //MARK: Update Methods
    func startUpdatingLocation() throws {
        
        var authStatus = CLLocationManager.authorizationStatus()
        
        if authStatus == .NotDetermined || authStatus  == .Denied {
            cllocationManager.requestWhenInUseAuthorization()
            usleep(1000)
            authStatus = CLLocationManager.authorizationStatus()
        }
        
        guard authStatus == .AuthorizedAlways || authStatus == .AuthorizedWhenInUse else {
            switch authStatus {
            case .Restricted:
                print("LocationManager::startUpdatingLocation - authorizationStatus = .Restricted")
                throw LocationManagerErrors.RESTRICTED
            case .NotDetermined:
                print("LocationManager::startUpdatingLocation - authorizationStatus = .NotDetermined")
                throw LocationManagerErrors.NOT_DETERMINED
            case .Denied:
                print("LocationManager::startUpdatingLocation - authorizationStatus = .Denied")
                throw LocationManagerErrors.DENIED
            default:
                return
            }
        }
        print("LocationManager::startUpdatingLocation - starting location manager services")
        cllocationManager.startUpdatingLocation()
        //state = .Active
    }
    
    /*func startUpdatingLocationAndCalibrate() throws {
        do {
            try startUpdatingLocation()
            if calibrate() {
                print("Device Calibrated")
            } else {
                throw LocationManagerErrors.UNCALIBRATED
            }
        } catch _ {
            throw LocationManagerErrors.UNCALIBRATED
        }
    }*/
    
   /* private func calibrate() -> Bool {
        
        state = .Calibrating
        
        calibrateSem = dispatch_semaphore_create(0)
        let timeoutNs = Int64(15) * Int64(NSEC_PER_SEC)
        let time = dispatch_time(DISPATCH_TIME_NOW, timeoutNs )
        calibrated = dispatch_semaphore_wait(calibrateSem, time ) == 0
        state = .Active
        return calibrated
    }*/
    
    
    func stopUpdatingLocation() {
        cllocationManager.stopUpdatingLocation()
        //state = .Idle
        //calibrated = false
    }
    
    //MARK: CLLocationManagerDelegate Protocol Functions
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]){
        let location: AnyObject? = (locations as NSArray).lastObject
        currentLocation = location as? CLLocation
        
        delegate!.gotLocationUpdate(currentLocation!)

        /*if state == .Calibrating {
            let horz = currentLocation?.horizontalAccuracy
            let vert = currentLocation?.verticalAccuracy
            let greaterAccuracy = ( horz > vert ) ? horz : vert
            let lesserAccuracy = ( horz < vert ) ? horz : vert
            //print ("Desc,\(currentLocation?.description)")
            //print ("lesser:\(lesserAccuracy)   greater:\(greaterAccuracy)   speed:\(currentLocation?.speed)")
            if lesserAccuracy >= 0 &&
               greaterAccuracy <= 10  &&
               currentLocation?.speed >= 0 {
                dispatch_semaphore_signal(calibrateSem)
            }
        }*/
        
    }
    
    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        delegate!.failedToUpdateLocation(error)
    }

}

