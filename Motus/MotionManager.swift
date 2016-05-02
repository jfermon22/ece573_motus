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
        //define the handler for accelerometer updates
        if cmmotionmanager.accelerometerAvailable  {
            let handler:CMAccelerometerHandler = {
                (data: CMAccelerometerData?, error: NSError?) -> Void in
                //set currentorientation and send to delegate
                self.currentOrientation = data!
                self.delegate!.gotAccelerometerUpdate(self.currentOrientation!)
            }
            print("startMotionUpdates - Started motion updates")
            cmmotionmanager.accelerometerUpdateInterval = NSTimeInterval(1)
            cmmotionmanager.startAccelerometerUpdatesToQueue(NSOperationQueue(), withHandler: handler)
        } else {
            print("startMotionUpdates - Accelorometer unavailable")
        }
        
        //sleep to allow accelerometer time to init before we check it
        usleep(100)
        return cmmotionmanager.accelerometerActive
    }

    func getUpdate() -> CMAccelerometerData {
        guard cmmotionmanager.accelerometerData == nil else {
            //if we haven't gotten an update yet, just send canned data
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
