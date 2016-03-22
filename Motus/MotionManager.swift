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

class MotionManager: NSObject {
    var cmmotionmanager:CMMotionManager?
    var currentOrientation:CMAccelerometerData?
    var initialOrientation:CMAccelerometerData?
    var delegate:MotionManagerDelegate?
    
    convenience init(updateInterval:NSTimeInterval){
        self.init()
        cmmotionmanager?.accelerometerUpdateInterval = updateInterval
    }
    
    override init() {
        super.init()
        cmmotionmanager = CMMotionManager()
        cmmotionmanager?.accelerometerUpdateInterval = NSTimeInterval(0.1)
    }
    
    deinit {
        if cmmotionmanager!.accelerometerActive {
            stopMotionUpdates()
        }
        cmmotionmanager = nil
        currentOrientation = nil
        delegate = nil
    }
    
    func startMotionUpdates() {
        if cmmotionmanager!.accelerometerAvailable  {
            let handler:CMAccelerometerHandler = {
                (data: CMAccelerometerData?, error: NSError?) -> Void in
                self.currentOrientation = data!
                self.delegate!.gotAccelUpdate(self.currentOrientation!)
            }
            cmmotionmanager?.startAccelerometerUpdatesToQueue(NSOperationQueue.currentQueue()!, withHandler: handler)
        }
    }
    
    
    func stopMotionUpdates() {
        cmmotionmanager?.stopAccelerometerUpdates()
    }
    
}
