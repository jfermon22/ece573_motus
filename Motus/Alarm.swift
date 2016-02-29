//
//  Alarm.swift
//  Motus
//
//  Created by Jeff Fermon on 2/28/16.
//  Copyright © 2016 Jeff Fermon. All rights reserved.
//

import Foundation

class Alarm {
    var _time:NSDate?
    var _sound:String?
    var _task:Task?
    init (time:NSDate, sound:String, task:Task){
        _time = time
        _sound = sound
        _task = task
    }
    
}