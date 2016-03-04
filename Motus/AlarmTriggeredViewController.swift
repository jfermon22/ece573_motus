//
//  AlarmTriggeredViewController.swift
//  Motus
//
//  Created by Jeff Fermon on 2/21/16.
//  Copyright © 2016 Jeff Fermon. All rights reserved.
//

import UIKit

enum AlarmTriggeredStates {
    case TRIGGER_ALARM
    case WAITING_FOR_MOTION
    case WAITING_FOR_TASK_COMPLETE
    case TASK_COMPLETE
}


class AlarmTriggeredViewController: UIViewController {

    @IBOutlet var currentTimeLabel: UILabel!
    @IBOutlet var currentTaskLabel: UILabel!
    @IBOutlet var timeToCompleteTaskLabel: UILabel!
    
    var alarm:Alarm!
    var timeToCompleteTask:NSInteger!
    var timer:NSTimer!
    var countDownActive:Bool!
    var state:AlarmTriggeredStates!
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        runStateMachine()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        timeToCompleteTask = alarm.timeToCompleteTask
        state = .TRIGGER_ALARM
        updateTime()
        timer = NSTimer.scheduledTimerWithTimeInterval(1.0,
            target: self,
            selector: Selector("updateTime"),
            userInfo: nil,
            repeats: true)
        // Do any additional setup after loading the view.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func runStateMachine(){
        while state != AlarmTriggeredStates.TASK_COMPLETE {
            print("runStateMachine: state: \(state)")
            switch state! {
            case .TRIGGER_ALARM:
                triggerAlarm()
                break;
            case .WAITING_FOR_MOTION:
                waitForMotion()
                break;
            case .WAITING_FOR_TASK_COMPLETE:
                waitForTaskComplete()
                break;
            case .TASK_COMPLETE:
                print("exiting")
                break;
            }
            usleep(100000)
        }
    }
    
    func triggerAlarm(){
        alarm.triggerAlarm()
        state = .WAITING_FOR_MOTION
    }
    
    func waitForMotion(){
        var motionDetected = false
        
        if !motionDetected {
            print("waiting for motion")
            sleep(1)
            motionDetected = true
        }
        
        if motionDetected {
            state = .WAITING_FOR_TASK_COMPLETE
            alarm.stopAlarm()
            setTaskLabel()
        }
        
    }
    
    func waitForTaskComplete(){
        var taskIsComplete = false
        
        if !taskIsComplete && timeToCompleteTask != 0 {
            print("waiting for task complete")
            sleep(1)
        }
        
        if taskIsComplete {
            state = .TASK_COMPLETE
        } else if timeToCompleteTask == 0 {
            state = .TRIGGER_ALARM
        }
    }
    
    func setTaskLabel(){
        switch alarm.task! {
        case .LOCATION:
            currentTaskLabel.text = "Move 20-ft."
            break;
        case .MOTION:
            currentTaskLabel.text = "Complete Ten Arm Circles"
            break;
        case .GESTURE:
            currentTaskLabel.text = "Swipe up"
            break;
        }
    }
    
    func updateTime(){
        currentTimeLabel.text = TimeFunctions.formatTimeForDisplay(NSDate())
        timeToCompleteTaskLabel.text = "\(timeToCompleteTask!)"
        if state == .WAITING_FOR_TASK_COMPLETE {
            timeToCompleteTaskLabel.text = "\(--timeToCompleteTask!)"
        }
    }
    
}