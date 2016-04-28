//
//  BatteryMonitor.swift
//  Motus
//
//  Created by Jeff Fermon on 4/27/16.
//  Copyright © 2016 Jeff Fermon. All rights reserved.
//

import UIKit

@objc protocol BatteryMonitorDelegate {
    optional func batteryLevelChanged (level: NSNumber)
    optional func batteryStateChanged (state: UIDeviceBatteryState)
}

class BatteryMonitor: NSObject {
    let device = UIDevice.currentDevice()
    var level:NSNumber {
        get {return device.batteryLevel}
    }
    var state:UIDeviceBatteryState {
        get {return device.batteryState}
    }
    var delegate: BatteryMonitorDelegate?
    var isEnabled:Bool {
        get {return device.batteryMonitoringEnabled}
    }
    
    override init() {
        super.init()
        //enable monitoring by default
        device.batteryMonitoringEnabled = true
        
        //set up notification handlers
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(BatteryMonitor.batteryLevelChanged(_:)), name: UIDeviceBatteryLevelDidChangeNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(BatteryMonitor.batteryStateChanged(_:)), name: UIDeviceBatteryStateDidChangeNotification, object: nil)
    }
    
    func enable() {
        if !isEnabled {
            device.batteryMonitoringEnabled = false
        }
    }
    
    func disable() {
        if isEnabled {
            device.batteryMonitoringEnabled = false
        }
    }
    
    func batteryLevelChanged(notification: NSNotification) {
            delegate?.batteryLevelChanged?(device.batteryLevel)
    }
    
    func batteryStateChanged(notification: NSNotification) {
            delegate?.batteryStateChanged?(device.batteryState)
    }
}
