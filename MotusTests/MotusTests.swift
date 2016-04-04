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
    var scvc:SoundChooserViewController!
    var navvc:UINavigationController!
    
    
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
        
        asvc.soundButton.sendActionsForControlEvents(UIControlEvents.TouchUpInside)
        navvc = asvc.lastSegue?.destinationViewController as! UINavigationController
        let _ = navvc.view
        navvc.viewDidLoad()
        
        scvc = navvc.viewControllers[0] as! SoundChooserViewController
        let _ = scvc.view
        scvc.viewDidLoad()

    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testCurrentTimeShown(){

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
    
    /*func testSetNewAlarmButtonTriggerSegue(){
        mvc.newAlarmButton.sendActionsForControlEvents(UIControlEvents.TouchUpInside)
        XCTAssertEqual(mvc.lastCalledSegue, "CreateNewAlarmSegue")
        
    }*/
    
    func testUserCanSetTime(){
        let date = NSDate()
        asvc.timePicker.setDate(date, animated: false)
        let dateString = TimeFunctions.formatTimeForDisplay(date)
        asvc.alarmConfirmButton.sendActionsForControlEvents(UIControlEvents.TouchUpInside)
        mvc.viewWillAppear(true)
        XCTAssertEqual(dateString, mvc.currentAlarmLabel.text)
    }
    
    /*func testSetButtonTriggerSegue(){
        asvc.alarmConfirmButton.sendActionsForControlEvents(UIControlEvents.TouchUpInside)
        XCTAssertEqual(mvc.lastCalledSegue, "AsPrepareForUnwind")
        
    }*/
    
    func testSoundPlayContinuousWhenTrggered() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        let alarm = Alarm(time: NSDate(), sound: "Apex", task: .LOCATION, isSet: true)
        XCTAssertNotNil(alarm)
        alarm.triggerAlarm()
        XCTAssertTrue(alarm.soundPlayer.IsPlaying())
        XCTAssertEqual(alarm.soundPlayer.getNumberOfLoops(), -1)
        alarm.stopAlarm()
    }
    
    func testUserCanSelectSound(){
        asvc.soundButton.sendActionsForControlEvents(UIControlEvents.TouchUpInside)
        usleep(10000)
        let index = NSIndexPath(forItem: 3, inSection: 0)
        scvc.tableView.selectRowAtIndexPath(index , animated: false, scrollPosition: UITableViewScrollPosition.Middle)
        scvc.tableView(scvc.tableView, didSelectRowAtIndexPath: index);
        let cell = scvc.tableView(scvc.tableView, cellForRowAtIndexPath:index)
    
        XCTAssertEqual(cell.textLabel?.text, scvc.alarm.sound)
        
    }
    
   // func testPerformanceExample() {
   //     // This is an example of a performance test case.
   //     self.measureBlock {
   //         // Put the code you want to measure the time of here.
   //     }
   // }
    
}
