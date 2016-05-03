//
//  Alarm.swift
//  Motus
//
//  Created by Jeff Fermon on 2/28/16.
//  Copyright © 2016 Jeff Fermon. All rights reserved.
//

import Foundation
import AudioToolbox

let RANDOM_TUNE = "Random"

class Alarm {
    //MARK: Public Members
    var time:NSDate!
    var sound:String!
    var sounds = [String]()
    var soundPath:String!
    var task = Task.LOCATION
    var isSet:Bool
    var timeToCompleteTask:UInt64!
    var IsPlaying:Bool{
        get{return soundPlayer.IsPlaying()}
    }
    
    //MARK: Private Members
    private(set) var soundPlayer = SoundPlayer.sharedInstance
    
    //MARK: Constructor
    init (time:NSDate, sound:String, task:Task, isSet:Bool){
        self.time = time
        self.sound = sound
        self.task = task
        self.isSet = isSet;
        self.soundPath = NSBundle.mainBundle().resourcePath! + "/Sounds/"
        populateSoundNames()
        soundPlayer.setSound(soundPath + sound)
        self.timeToCompleteTask = 60
    }
    
    
    func testSound(sound: String) {
        soundPlayer.setSound(soundPath + sound)
        soundPlayer.setNumberOfLoops(0)
        try! soundPlayer.play()
    }
    
    func triggerAlarm(){
        //set isRandom to change alarm back to random after triggering
        let soundIsRandom = (sound == RANDOM_TUNE )
        while sound == RANDOM_TUNE {
            //while sound is random, get random indexs until we pick sound that's not "Random"
            let randomIndex = Int(arc4random_uniform(UInt32(sounds.count)))
            sound = sounds[randomIndex]
        }
        
        //set the path to the sound
        soundPlayer.setSound(soundPath + sound)
        
        //set loops to infinite
        soundPlayer.setNumberOfLoops(-1)
        
        //play sound
        try! soundPlayer.play()
        
        //vibrate device
        AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
        
        if soundIsRandom {
            //if sound was random, change it back
            sound = RANDOM_TUNE
        }
    }
    
    func stopAlarm(){
        soundPlayer.stop()
    }
    
    //helper function to get all the available sound names and create an array from them
    private func populateSoundNames(){
        let fileManager = NSFileManager.defaultManager()
        
        //populate all filnames to a temporary array
        let tempArray = try! fileManager.contentsOfDirectoryAtPath(soundPath)
        
        for curSound in tempArray {
            //remove .m4r from all sound names
            sounds.append(curSound.stringByReplacingOccurrencesOfString(".m4r", withString: ""))
        }
        
        //add "Random" to list of choices
        sounds.append(RANDOM_TUNE)
        
        //sort the sounds
        sounds = sounds.sort()
    }
}