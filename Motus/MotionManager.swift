//
//  MotionManager.swift
//  Motus
//
//  Created by Jeff Fermon on 3/20/16.
//  Copyright © 2016 Jeff Fermon. All rights reserved.
//

import Foundation
import CoreMotion

protocol MotionManagerDelegate {
    func gotAccelerometerUpdate(orientation:CMAccelerometerData)
}

class MotionManager {
    //MARK: public variables
    static let sharedInstance = MotionManager()
    var delegate:MotionManagerDelegate?
    var updateInterval:NSTimeInterval {
        set { cmmotionmanager.accelerometerUpdateInterval = newValue }
        get { return cmmotionmanager.accelerometerUpdateInterval }
    }
    
    //MARK: private variables
    private let cmmotionmanager = CMMotionManager()
    private(set) var currentOrientation:CMAccelerometerData?
    
    //MARK: Constructors
    init() {
        cmmotionmanager.accelerometerUpdateInterval = NSTimeInterval(1)
    }
    
    convenience init(updateInterval:NSTimeInterval){
        self.init()
        cmmotionmanager.accelerometerUpdateInterval = updateInterval
    }
    
    deinit {
        stopUpdates()
        currentOrientation = nil
        delegate = nil
    }
    
    //MARK: Update Functions
    func startUpdates() -> Bool {
        if cmmotionmanager.accelerometerAvailable  {
            let handler:CMAccelerometerHandler = {
                (data: CMAccelerometerData?, error: NSError?) -> Void in
                self.currentOrientation = data!
                self.delegate!.gotAccelerometerUpdate(self.currentOrientation!)
            }
            print("startMotionUpdates - Started motion updates")
            cmmotionmanager.accelerometerUpdateInterval = NSTimeInterval(1)
            cmmotionmanager.startAccelerometerUpdatesToQueue(NSOperationQueue(), withHandler: handler)
        } else {
            print("startMotionUpdates - Accelorometer unavailable")
        }
        usleep(100)
        return cmmotionmanager.accelerometerActive
    }

    func getUpdate() -> CMAccelerometerData {
        if (cmmotionmanager.accelerometerData == nil) {
            return CMAccelerometerData()
        }
        return cmmotionmanager.accelerometerData!
    }
    
    func stopUpdates() {
        if cmmotionmanager.accelerometerActive {
            cmmotionmanager.stopAccelerometerUpdates()
        }
    }
    
}
