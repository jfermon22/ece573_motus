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
    //MARK: public members
    var updateInterval = NSTimeInterval(0.1)

    //MARK: private members
    private var motionManager = MotionManager.sharedInstance
    private var waitSem = dispatch_semaphore_create(0)
    private(set) var currentOrientation:CMAccelerometerData?
    private(set) var initialOrientation:CMAccelerometerData?
    private(set) var deviceMoved =  false
   
    //MARK: Constructors
    init() {
        motionManager.updateInterval = updateInterval
        motionManager.delegate = self
    }
    
    deinit {
        stop()
        currentOrientation = nil
        initialOrientation = nil
    }
    
    //MARK: Update Methods
    func start() -> Bool {
        deviceMoved = false
        initialOrientation = nil
        currentOrientation = nil
        return motionManager.startUpdates()
    }
    
    func stop() {
        motionManager.stopUpdates()
        dispatch_semaphore_signal(waitSem)
    }
    
    func gotAccelUpdate(orientation: CMAccelerometerData) {
        if initialOrientation == nil {
            initialOrientation = orientation
        }
        
        currentOrientation = orientation
        
        deviceMoved = deviceInMotion()
        
        if(deviceMoved){
            dispatch_semaphore_signal(waitSem)
        }
    }

    //MARK: Wait methods
    func waitTilDeviceMove(){
        waitSem = dispatch_semaphore_create(0)
        dispatch_semaphore_wait(waitSem, DISPATCH_TIME_FOREVER)
        
    }
    
    func waitTilDeviceMove(timeout: UInt64){
        waitSem = dispatch_semaphore_create(0)
        //timeout is in nanosecs
        let timeoutNs = Int64(timeout) * Int64(NSEC_PER_SEC)
        let time = dispatch_time(DISPATCH_TIME_NOW, timeoutNs )
        dispatch_semaphore_wait(waitSem, time )
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
        let motionMagnitude = sqrt( pow(diffx,2) + pow(diffy,2) + pow(diffz,2) )
        //print("motionMagnitude: \(motionMagnitude)")
        return motionMagnitude > DEVICE_MOTIONLESS_THRESHOLD
    }
}
