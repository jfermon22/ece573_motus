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
    func gotAccelUpdate(orientation:CMAccelerometerData)
}

class MotionManager {
    static let sharedInstance = MotionManager()
    let cmmotionmanager = CMMotionManager()
    var currentOrientation:CMAccelerometerData?
    var initialOrientation:CMAccelerometerData?
    var delegate:MotionManagerDelegate?
    
    private init() {
        cmmotionmanager.accelerometerUpdateInterval = NSTimeInterval(1)
    }
    
    deinit {
        if cmmotionmanager.accelerometerActive {
            stopMotionUpdates()
        }
        currentOrientation = nil
        delegate = nil
    }
    
    func setUpdateInterval(updateInterval:NSTimeInterval){
        cmmotionmanager.accelerometerUpdateInterval = updateInterval
    }
    
    func startMotionUpdates() -> Bool {
        if cmmotionmanager.accelerometerAvailable  {
            let handler:CMAccelerometerHandler = {
                (data: CMAccelerometerData?, error: NSError?) -> Void in
                self.currentOrientation = data!
                self.delegate!.gotAccelUpdate(self.currentOrientation!)
            }
            print("startMotionUpdates - Started motion updates")
            cmmotionmanager.accelerometerUpdateInterval = NSTimeInterval(1)
            cmmotionmanager.startAccelerometerUpdatesToQueue(NSOperationQueue(), withHandler: handler)
        }
        else {
            print("startMotionUpdates - Accelorometer unavailable")
        }
        
        return cmmotionmanager.accelerometerActive
    }

    func getMotionUpdate() -> CMAccelerometerData {
        if (cmmotionmanager.accelerometerData == nil) {
            return CMAccelerometerData()
        }
        return cmmotionmanager.accelerometerData!
    }
    
    
    func stopMotionUpdates() {
        cmmotionmanager.stopAccelerometerUpdates()
    }
    
}
