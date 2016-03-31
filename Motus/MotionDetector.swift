//
//  MotionDetector.swift
//  Motus
//
//  Created by Jeff Fermon on 2/28/16.
//  Copyright © 2016 Jeff Fermon. All rights reserved.
//

import Foundation
import CoreMotion

let DEVICE_MOTIONLESS_THRESHOLD = 0.01

class MotionDetector : MotionManagerDelegate {
    var motionManager:MotionManager?
    let waitSem:dispatch_semaphore_t
    var currentOrientation:CMAccelerometerData?
    var initialOrientation:CMAccelerometerData?
    var updateInterval:NSTimeInterval?
    var deviceMoved:Bool

    init() {
        updateInterval = NSTimeInterval(0.1)
        motionManager = MotionManager.sharedInstance
        motionManager?.setUpdateInterval(updateInterval!)
        waitSem = dispatch_semaphore_create(0)
        deviceMoved = false
        motionManager!.delegate = self
    }

    
    func waitTilDeviceMove(){
        dispatch_semaphore_wait(waitSem, DISPATCH_TIME_FOREVER)
        
    }
    
    func waitTilDeviceMove(timeout: dispatch_time_t){
        let timeoutInSecs = timeout * 1000000000
        dispatch_semaphore_wait(waitSem, timeoutInSecs )
    }
    
    func start() -> Bool {
        deviceMoved = false
        initialOrientation = nil
        currentOrientation = nil
        return (motionManager?.startMotionUpdates())!
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
        deviceMoved = deviceInMotion()
        //print( "motion update: x:\(currentAccel?.x) y:\(currentAccel?.y) z\(currentAccel?.z)")
        if(deviceMoved)
        {
            dispatch_semaphore_signal(waitSem)
        }

    }
    
    
    func didDeviceMove() -> Bool {
        return deviceMoved
    }
    
    private func deviceInMotion()-> Bool
    {
        let accel1 = initialOrientation!.acceleration
        let accel2 = currentOrientation!.acceleration
        let diffx = abs(accel1.x - accel2.x)
        let diffy = abs(accel1.y - accel2.y)
        let diffz = abs(accel1.y - accel2.y)
        let absAccel = sqrt( diffx * diffx + diffy * diffy + diffz * diffz)
        print("absdiff = \(absAccel)")
        return absAccel > DEVICE_MOTIONLESS_THRESHOLD
    }
}
