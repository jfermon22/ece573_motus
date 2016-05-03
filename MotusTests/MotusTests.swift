//
//  MotusTests.swift
//  MotusTests
//
//  Created by Jeff Fermon on 2/2/16.
//  Copyright © 2016 Jeff Fermon. All rights reserved.
//

import XCTest
import CoreMotion
@testable import Motus

class MotusTests: XCTestCase {
    var mvc:MainViewController!
    var asvc:AlarmSetViewController!
    var atvc:AlarmTriggeredViewController!
    var scvc:SoundChooserViewController!
    var tcvc:TaskChooserViewController!
    var navvc:UINavigationController!
    
    
    override func setUp() {
        super.setUp()
        let storyboard = UIStoryboard(name: "Main",
            bundle: NSBundle.mainBundle())
        
        mvc = storyboard.instantiateInitialViewController() as! MainViewController
        UIApplication.sharedApplication().keyWindow!.rootViewController = mvc
        let _ = mvc.view
        mvc.viewDidLoad()
        
        mvc.performSegueWithIdentifier("AlarmTriggered", sender: mvc)
        atvc = mvc.lastSegue?.destinationViewController as! AlarmTriggeredViewController
        let _ = atvc.view
        atvc.viewDidLoad()
        
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
        
        asvc.taskButton.sendActionsForControlEvents(UIControlEvents.TouchUpInside)
        navvc = asvc.lastSegue?.destinationViewController as! UINavigationController
        let _ = navvc.view
        navvc.viewDidLoad()
        
        tcvc = navvc.viewControllers[0] as! TaskChooserViewController
        let _ = tcvc.view
        tcvc.viewDidLoad()

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
        let alarm = Alarm(time: NSDate(), sound: "Apex", task: .LOCATION, isSet: true)
        XCTAssertNotNil(alarm)
        alarm.triggerAlarm()
        XCTAssertTrue(alarm.IsPlaying)
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
    
    func testUserCanSelectTask(){
        asvc.taskButton.sendActionsForControlEvents(UIControlEvents.TouchUpInside)
        usleep(10000)
        let index = NSIndexPath(forItem: 2, inSection: 0)
        tcvc.tableView.selectRowAtIndexPath(index , animated: false, scrollPosition: UITableViewScrollPosition.Middle)
        tcvc.tableView(tcvc.tableView, didSelectRowAtIndexPath: index);
        let cell = tcvc.tableView(tcvc.tableView, cellForRowAtIndexPath:index)
        XCTAssertEqual(cell.textLabel?.text, Task.GetText( tcvc.alarm.task))
    }
    
    func testAlarmTriggerWhenCurrentTimeEqualAlarmTime() {
        let date = NSDate()
        mvc.alarm = Alarm(time: date, sound: "Apex", task: .LOCATION, isSet: true)
        usleep(100)
        mvc.viewWillAppear(true)
        usleep(100)
        //ubtract 1 minute from time and make new time
        let unitFlags: NSCalendarUnit = [.Hour,.Minute,.Second, .Day, .Month, .Year]
        let components = NSCalendar.currentCalendar().components(unitFlags, fromDate: date)
        components.minute = components.minute - 1
        let calendar = NSCalendar(calendarIdentifier: NSCalendarIdentifierGregorian)
        let oneMinuteEarlierDate = calendar!.dateFromComponents(components)
        mvc.lastReadTime = TimeFunctions.formatTimeForDisplay(oneMinuteEarlierDate!)
        XCTAssert(mvc.alarmShouldTrigger())
    }
    
    func testUSerHasOneMinuteToCompleteTask() {
        atvc.viewDidLoad()
        atvc.viewDidAppear(true)
        XCTAssertEqual(atvc.timeToCompleteTask, 60)
    }
    
    
   // func testPerformanceExample() {
   //     // This is an example of a performance test case.
   //     self.measureBlock {
   //         // Put the code you want to measure the time of here.
   //     }
   // }
    
}
