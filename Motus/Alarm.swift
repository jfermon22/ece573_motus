//
//  Alarm.swift
//  Motus
//
//  Created by Jeff Fermon on 2/28/16.
//  Copyright © 2016 Jeff Fermon. All rights reserved.
//

import Foundation

class Alarm {
    var time:NSDate!
    var sound:String!
    var soundPath:String!
    var task:Task!
    var isSet:Bool
    var soundPlayer:SoundPlayer!
    var timeToCompleteTask:NSInteger!
    init (time:NSDate, sound:String, task:Task, isSet:Bool){
        self.time = time
        self.sound = sound
        self.task = task
        self.isSet = isSet;
        self.soundPath = NSBundle.mainBundle().resourcePath! + "/Sounds/"
        self.timeToCompleteTask = 60
    }
    
    func testSound(sound: String) {
        soundPlayer = SoundPlayer(sound: soundPath + sound )
        soundPlayer.setNumberOfLoops(0)
        soundPlayer.play()
    }
    
    func triggerAlarm(){
        soundPlayer = SoundPlayer(sound: soundPath + sound )
        soundPlayer.setNumberOfLoops(-1)
        soundPlayer.play()
    }
    
    func stopAlarm(){
        soundPlayer.stop()
    }
}