//
//  PedometerManager.swift
//  Motus
//
//  Created by Jeff Fermon on 4/20/16.
//  Copyright © 2016 Jeff Fermon. All rights reserved.
//

import Foundation
import CoreMotion

protocol PedometerManagerDelegate {
    func gotPedometerUpdate(data:CMPedometerData)
}

class PedometerManager {

    //MARK: public variables
    static let sharedInstance = PedometerManager()
    var delegate:PedometerManagerDelegate?
    
    //MARK: private variables
    private let cmPedometer = CMPedometer()
    private(set) var latestPedometerData:CMPedometerData?
    var isStepCountingAvailable:Bool {
        get { return CMPedometer.isStepCountingAvailable() }
    }
    var isDistanceAvailable:Bool {
        get { return CMPedometer.isDistanceAvailable() }
    }
    var isFloorCountingAvailable:Bool {
        get { return CMPedometer.isFloorCountingAvailable() }
    }
    var isPaceAvailable:Bool {
        get { return CMPedometer.isPaceAvailable() }
    }
    var isCadenceAvailable:Bool {
        get { return CMPedometer.isCadenceAvailable() }
    }
    var isAvailable:Bool {
        return self.isPaceAvailable ||
            self.isCadenceAvailable ||
            self.isDistanceAvailable ||
            self.isStepCountingAvailable ||
            self.isFloorCountingAvailable
    }
    
    //MARK: Constructors
    init() {

    }
    
    deinit {
        stopUpdates()
        latestPedometerData = nil
        delegate = nil
    }
    
    //MARK: Update Functions
    func startUpdates() -> Bool {
        var isStarted = true
        if isAvailable  {
            let handler:
                CMPedometerHandler = {
                    (data:
                    CMPedometerData?, error: NSError?) -> Void in
                self.latestPedometerData = data!
                self.delegate!.gotPedometerUpdate(self.latestPedometerData!)
            }
            print("startUpdates - Started pedometer updates")
            cmPedometer.startPedometerUpdatesFromDate(NSDate(), withHandler: handler)
        } else {
            print("startUpdates - pedometer updates unavailable")
            isStarted = false
        }
        return isStarted
    }
    
    func stopUpdates() {
            cmPedometer.stopPedometerUpdates()
    }
    
}
