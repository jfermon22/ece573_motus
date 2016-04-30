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
    //MARK: Public members
    static let sharedInstance = SoundPlayer()
    var soundPath:NSURL?
    
    //MARK: Private members
    private var audioPlayer = AVAudioPlayer()
 
    //MARK:Constructor
    private init (){}
    
    //Helper function to set the sound and prepare it to be played
    func setSound (sound: String){
        var thisSound = ""
        if !sound.hasSuffix(".m4r"){
            thisSound = sound + ".m4r"
        } else {
            thisSound = sound
        }
        soundPath = NSURL(fileURLWithPath: thisSound)
        
        //override silent switch
        try! AVAudioSession.sharedInstance().setCategory({AVAudioSessionCategoryPlayback}())
        try! AVAudioSession.sharedInstance().setActive(true)
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
        //if url is not set to path then throw
        guard audioPlayer.url != nil else { throw SoundPlayerError.URL_NIL }

        audioPlayer.play()
    }
    
    func stop() {
        //if we aren't playing just return
        guard audioPlayer.playing else { return }
            
        audioPlayer.stop()
    }
    
    func IsPlaying() -> Bool {
        return audioPlayer.playing
    }
}