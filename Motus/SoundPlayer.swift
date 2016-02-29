//
//  SoundPlayer.swift
//  Motus
//
//  Created by Jeff Fermon on 2/28/16.
//  Copyright © 2016 Jeff Fermon. All rights reserved.
//

import Foundation
import AVFoundation

class SoundPlayer {
    
    var audioPlayer:AVAudioPlayer?
    var soundPath:NSURL?
    
    init (sound: String){
        soundPath = NSURL(fileURLWithPath: String( "\(NSBundle.mainBundle().pathForResource(sound, ofType: "m4r")!)"))
        try! audioPlayer = AVAudioPlayer(contentsOfURL: soundPath!, fileTypeHint: nil)
        audioPlayer!.numberOfLoops = -1
        audioPlayer!.prepareToPlay()
        
    }
    
    // Trigger the sound effect when the player grabs the coin
    func play() {
        audioPlayer!.play()
    }
    
    func stop() {
        audioPlayer!.stop()
    }
    
    func IsPlaying() -> Bool {
        return audioPlayer!.playing
    }

    
}