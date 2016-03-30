//
//  SoundPlayer.swift
//  Motus
//
//  Created by Jeff Fermon on 2/28/16.
//  Copyright © 2016 Jeff Fermon. All rights reserved.
//

import Foundation
import AVFoundation

enum SoundPlayerError: ErrorType {
    case URL_NIL
}

class SoundPlayer {
    var audioPlayer = AVAudioPlayer()
    var soundPath:NSURL?
 
    init (){
        
    }
    
    convenience init (sound: String){
        self.init()
        setSound(sound)
    }
    
    func setSound (sound: String){
        var thisSound = ""
        if !sound.hasSuffix(".m4r"){
            thisSound = sound + ".m4r"
        } else {
            thisSound = sound
        }
        soundPath = NSURL(fileURLWithPath: thisSound)
        try! audioPlayer = AVAudioPlayer(contentsOfURL: soundPath!)
        audioPlayer.numberOfLoops = -1
        audioPlayer.prepareToPlay()
    }
    
    func setNumberOfLoops(number:Int){
       audioPlayer.numberOfLoops = number
    }
    
    func getNumberOfLoops() -> Int {
        return audioPlayer.numberOfLoops
    }
    
    func play() throws {
        if audioPlayer.url != nil {
            audioPlayer.play()
        } else {
            throw SoundPlayerError.URL_NIL
        }
    }
    
    func stop() {
        if audioPlayer.playing {
            audioPlayer.stop()
        }
    }
    
    func IsPlaying() -> Bool {
        return audioPlayer.playing
    }

    
}