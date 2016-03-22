//
//  MotionDetector.swift
//  Motus
//
//  Created by Jeff Fermon on 2/28/16.
//  Copyright © 2016 Jeff Fermon. All rights reserved.
//

import Foundation
import CoreMotion

class MotionDetector : MotionManagerDelegate {
    var motionManager:MotionManager?
    let waitSem:dispatch_semaphore_t
    var currentOrientation:CMAccelerometerData?
    var initialOrientation:CMAccelerometerData?
    var updateInterval:NSTimeInterval?
    var deviceMoved:Bool

    init() {
        updateInterval = NSTimeInterval(0.1)
        motionManager = MotionManager(updateInterval: updateInterval!)
        waitSem = dispatch_semaphore_create(0)
        deviceMoved = false
        motionManager!.delegate = self
    }

    
    func waitTilDeviceMove(){
        dispatch_semaphore_wait(waitSem, DISPATCH_TIME_FOREVER)
        
    }
    
    func start() {
        deviceMoved = false
        initialOrientation = nil
        currentOrientation = nil
        motionManager?.startMotionUpdates()
    }
    
    func stop() {
        motionManager?.stopMotionUpdates()
        dispatch_semaphore_signal(waitSem)
    }
    
    func gotAccelUpdate(orientation: CMAccelerometerData) {
        if initialOrientation == nil {
            initialOrientation = orientation
        }
        
        currentOrientation = orientation
        
        deviceMoved = initialOrientation == currentOrientation
        
        if(deviceMoved)
        {
            dispatch_semaphore_signal(waitSem)
        }

    }
    
    
    func didDeviceMove() -> Bool {
        return deviceMoved
    }
    
}
