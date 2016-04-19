//
//  Alarm.swift
//  Motus
//
//  Created by Jeff Fermon on 2/28/16.
//  Copyright © 2016 Jeff Fermon. All rights reserved.
//

import Foundation
import AudioToolbox

class Alarm {
    var time:NSDate!
    var sound:String!
    var soundPath:String!
    var task:Task!
    var isSet:Bool
    var soundPlayer:SoundPlayer!
    var timeToCompleteTask:UInt64!
    init (time:NSDate, sound:String, task:Task, isSet:Bool){
        self.time = time
        self.sound = sound
        self.task = task
        self.isSet = isSet;
        self.soundPath = NSBundle.mainBundle().resourcePath! + "/Sounds/"
        soundPlayer = SoundPlayer(sound: soundPath + sound)
        self.timeToCompleteTask = 60
    }
    
    func testSound(sound: String) {
        soundPlayer = SoundPlayer(sound: soundPath + sound )
        soundPlayer.setNumberOfLoops(0)
        try! soundPlayer.play()
    }
    
    func triggerAlarm(){
        soundPlayer = SoundPlayer(sound: soundPath + sound )
        soundPlayer.setNumberOfLoops(-1)
        try! soundPlayer.play()
        AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
    }
    
    func stopAlarm(){
        soundPlayer.stop()
    }
}