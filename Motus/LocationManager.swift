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
    case UNKNOWN
}

protocol LocationManagerDelegate {
    func gotLocationUpdate(location:CLLocation)
    func failedToUpdateLocation (error: NSError)
    func didEnterRegion (region: CLRegion)
    func didExitRegion (region: CLRegion)
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
    var currentLocation:CLLocation? {
        get{return cllocationManager.location}
    }
    
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
        delegate = nil
    }
    
    func requestPermission() -> Bool {
        var authStatus = CLLocationManager.authorizationStatus()
        
        if authStatus == .NotDetermined || authStatus  == .Denied {
            cllocationManager.requestWhenInUseAuthorization()
            usleep(1000)
            authStatus = CLLocationManager.authorizationStatus()
        }
        
        let permissionGranted = ( authStatus == .AuthorizedAlways || authStatus == .AuthorizedWhenInUse )
        return permissionGranted
    }

    //MARK: Update Methods
    func startUpdatingLocation() -> Bool {
        
        guard requestPermission() else { return false }
        
        print("LocationManager::startUpdatingLocation - starting location manager services")
        cllocationManager.startUpdatingLocation()
        
        return true
    }
    
    func stopUpdatingLocation() {
        cllocationManager.stopUpdatingLocation()
    }
    
    func startMonitoringForRegion(region: CLRegion) -> Bool {
        
        guard requestPermission() else { return false }

        print("LocationManager::startMonitoringRegion - start monitoring for region")
        cllocationManager.startMonitoringForRegion(region)
        return true
    }
    
    func stopMonitoringForRegion(region: CLRegion) {
        cllocationManager.stopMonitoringForRegion(region)
    }
    
    //MARK: CLLocationManagerDelegate Protocol Functions
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]){
        //let location: AnyObject? = (locations as NSArray).lastObject
        //currentLocation = location as? CLLocation
        
        delegate!.gotLocationUpdate(currentLocation!)
    }
    
    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        delegate!.failedToUpdateLocation(error)
    }
    
    func locationManager( manager: CLLocationManager, didEnterRegion region: CLRegion) {
        delegate?.didEnterRegion(region)
    }

    func locationManager(manager: CLLocationManager, didExitRegion region: CLRegion) {
        delegate?.didExitRegion(region)
    }
}

