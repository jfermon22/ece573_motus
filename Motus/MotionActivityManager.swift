//
//  MotionActivityManager.swift
//  Motus
//
//  Created by Jeff Fermon on 4/13/16.
//  Copyright © 2016 Jeff Fermon. All rights reserved.
//

import Foundation
import CoreMotion

protocol MotionActivityManagerDelegate {
    func gotMotionActivityUpdate(motionActivity:CMMotionActivity)
}

class MotionActivityManager: NSObject {
    //MARK: public variables
    static let sharedInstance = MotionActivityManager()
    var delegate:MotionActivityManagerDelegate?
    var isActivityAvailable:Bool {
        get { return CMMotionActivityManager.isActivityAvailable() }
    }
    
    //MARK: private variables
    private let cmMotionActivityManager = CMMotionActivityManager()
    private(set) var currentActivity:CMMotionActivity?
    
    //MARK: Constructors
    override init() {
        super.init()
        
    }
    
    deinit {
        stopUpdates()
        currentActivity = nil
        delegate = nil
    }
    
    //MARK: Update Functions
    func startUpdates() -> Bool {
        //define handler for motion activity updates
        guard isActivityAvailable else {
            print("startUpdates - activity updates unavailable")
            return false
        }
        
        let handler:CMMotionActivityHandler = {
            (data: CMMotionActivity?) -> Void in
            self.currentActivity = data!
            self.delegate!.gotMotionActivityUpdate(self.currentActivity!)
        }
        
        print("startUpdates - Started motion activity updates")
        cmMotionActivityManager.startActivityUpdatesToQueue(NSOperationQueue(), withHandler: handler)
        
        return true
    }
    
    func stopUpdates() {
        cmMotionActivityManager.stopActivityUpdates()
    }
    
}
