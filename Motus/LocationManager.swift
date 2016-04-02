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
}

protocol LocationManagerDelegate {
    func gotLocationUpdate(location:CLLocation)
    func failedToUpdateLocation (error: NSError)
}


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
    
    //MARK: Constructors
    override init() {
        super.init()
        cllocationManager.desiredAccuracy = kCLLocationAccuracyBest
        cllocationManager.distanceFilter = 5
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
        }
        usleep(1000)
        authStatus = CLLocationManager.authorizationStatus()
        
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
    }
    
    func stopUpdatingLocation() {
        cllocationManager.stopUpdatingLocation()
    }
    
    //MARK: CLLocationManagerDelegate Protocol Functions
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]){
        let location: AnyObject? = (locations as NSArray).lastObject
        currentLocation = location as? CLLocation
        delegate!.gotLocationUpdate(currentLocation!)
    }
    
    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        delegate!.failedToUpdateLocation(error)
    }

}

