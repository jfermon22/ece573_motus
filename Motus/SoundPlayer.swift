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
        print("soundplayer path: " + sound)
        soundPath = NSURL(fileURLWithPath: sound)
        try! audioPlayer = AVAudioPlayer(contentsOfURL: soundPath!, fileTypeHint: nil)
        audioPlayer!.numberOfLoops = -1
        audioPlayer!.prepareToPlay()
        
    }
    
    func setNumberOfLoops(number:Int){
       audioPlayer!.numberOfLoops = number
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