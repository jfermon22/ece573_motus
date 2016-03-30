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
    case WAITING_FOR_ALARM_KILL
    case WAITING_FOR_TASK_COMPLETE
    case TASK_COMPLETE
}
enum AlarmTriggeredErrorType:ErrorType {
    case ACCEL_UNAVAIL
}

class AlarmTriggeredViewController: UIViewController {
    
    @IBOutlet var currentTimeLabel: UILabel!
    @IBOutlet var currentTaskLabel: UILabel!
    @IBOutlet var timeToCompleteTaskLabel: UILabel!
    
    var alarm:Alarm!
    var timeToCompleteTask:UInt64!
    var timer:NSTimer!
    var countDownActive:Bool!
    var state:AlarmTriggeredStates!
    
    var motionDetector:MotionDetector!
    var locationDetector:LocationDetector!
    var gestureDetector:GestureDetector!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        timeToCompleteTask = alarm.timeToCompleteTask
        state = .TRIGGER_ALARM        // Do any additional setup after loading the view.
        if locationDetector == nil {
            locationDetector = LocationDetector()
        }
        
        if motionDetector == nil {
            motionDetector = MotionDetector()
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        updateTime()
        timer = NSTimer.scheduledTimerWithTimeInterval(1.0,
                                                       target: self,
                                                       selector: #selector(AlarmTriggeredViewController.updateTime),
                                                       userInfo: nil,
                                                       repeats: true)
         runStateMachine()
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
                state = .WAITING_FOR_ALARM_KILL
                break;
            case .WAITING_FOR_ALARM_KILL:
                waitForAlarmKilled()
                state = .WAITING_FOR_TASK_COMPLETE
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
    }
    
    func waitForAlarmKilled() {
        do {
            try waitForMotion()
            
            alarm.stopAlarm()
            
            setTaskLabel()
            
        } catch _ {
            let alertController = UIAlertController(title: "Error", message: "Motion Data Unavalable.\nClick to silence alarm", preferredStyle: .Alert)
            
            let OKAction = UIAlertAction(title: "OK", style: .Default) {
                (action) in
                self.alarm.stopAlarm()
            }
            
            alertController.addAction(OKAction)
    
            presentViewController(alertController, animated: true, completion: nil)
        }
    }


    func waitForMotion() throws {
        
        guard motionDetector!.start()
            else { throw AlarmTriggeredErrorType.ACCEL_UNAVAIL }
        
        motionDetector!.waitTilDeviceMove()

        motionDetector!.stop()
        
    }
    
    func waitForTaskComplete(){
        var taskIsComplete = false
        
        print("waiting for task complete")
        switch alarm.task! {
        case .LOCATION:
            locationDetector!.start()
            locationDetector!.waitTilDeviceMove(20,timeout: timeToCompleteTask)
            taskIsComplete = locationDetector!.deviceMovedMinimum
            break
        case .MOTION:
            motionDetector!.start()
            motionDetector!.waitTilDeviceMove()
            taskIsComplete = motionDetector!.deviceMoved
            break
        case .GESTURE:
            break
            
        }
        
        if taskIsComplete {
            state = .TASK_COMPLETE
        } else  {
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