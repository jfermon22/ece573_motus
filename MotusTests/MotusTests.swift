//
//  MotusTests.swift
//  MotusTests
//
//  Created by Jeff Fermon on 2/2/16.
//  Copyright © 2016 Jeff Fermon. All rights reserved.
//

import XCTest
@testable import Motus

class MotusTests: XCTestCase {
    var mvc:MainViewController!
    var asvc:AlarmSetViewController!
    
    
    override func setUp() {
        super.setUp()
        let storyboard = UIStoryboard(name: "Main",
            bundle: NSBundle.mainBundle())
        
        mvc = storyboard.instantiateInitialViewController() as! MainViewController
        UIApplication.sharedApplication().keyWindow!.rootViewController = mvc
        let _ = mvc.view
                mvc.viewDidLoad()
        
        mvc.newAlarmButton.sendActionsForControlEvents(UIControlEvents.TouchUpInside)
        asvc = mvc.lastSegue?.destinationViewController as! AlarmSetViewController
        let _ = asvc.view
        asvc.viewDidLoad()
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testTimeCurrentTimeShown(){

        XCTAssertEqual(mvc.currentTimeLabel.text, TimeFunctions.formatTimeForDisplay(NSDate()))
    }
    
    func testAlarmSetStatusLabelFalse(){
        mvc.alarm.isSet = false;
        mvc.viewWillAppear(true)
        XCTAssertEqual(mvc.alarmStatusLabel.text, "No Alarm Set")
    }
    
    func testAlarmSetStatusLabelTrue(){
        mvc.alarm.isSet = true;
        mvc.viewWillAppear(true)
        XCTAssertEqual(mvc.alarmStatusLabel.text, "Alarm Set")
    }
    
    func testAlarmTimeDisplayedWhenAlarmSet(){
        mvc.alarm.isSet = true;
        mvc.viewWillAppear(true)
        XCTAssertEqual(mvc.currentAlarmLabel.hidden, false)
    }
    
    func testAlarmTimeHiddenWhenAlarmNotSet(){
        mvc.alarm.isSet = false;
        mvc.viewWillAppear(true)
        XCTAssertEqual(mvc.currentAlarmLabel.hidden, true)
    }
    
    func testSetNewAlarmButtonTriggerSegue(){
        mvc.newAlarmButton.sendActionsForControlEvents(UIControlEvents.TouchUpInside)
        XCTAssertEqual(mvc.lastCalledSegue, "CreateNewAlarmSegue")
        
    }
    
    func testUserCanSetTime(){
        XCTAssertNotNil(asvc.timePicker)
        
    }
    
    func testSetButtonTriggerSegue(){
        asvc.alarmConfirmButton.sendActionsForControlEvents(UIControlEvents.TouchUpInside)
        XCTAssertEqual(mvc.lastCalledSegue, "AsPrepareForUnwind")
        
    }
    
    /*func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        let audioPlayer = SoundPlayer(sound:"Apex")
        XCTAssertNil(audioPlayer)
        audioPlayer.play();
        XCTAssertTrue(audioPlayer.IsPlaying())
        audioPlayer.stop();
    }*/
    
   // func testPerformanceExample() {
   //     // This is an example of a performance test case.
   //     self.measureBlock {
   //         // Put the code you want to measure the time of here.
   //     }
   // }
    
}
