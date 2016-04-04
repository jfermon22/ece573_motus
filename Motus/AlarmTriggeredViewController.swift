//
//  AlarmTriggeredViewController.swift
//  Motus
//
//  Created by Jeff Fermon on 2/21/16.
//  Copyright © 2016 Jeff Fermon. All rights reserved.
//

import UIKit
import CoreLocation

enum AlarmTriggeredStates {
    case TRIGGER_ALARM
    case WAITING_FOR_ALARM_KILL
    case WAITING_FOR_TASK_COMPLETE
    case TASK_COMPLETE
}
enum AlarmTriggeredErrorType:ErrorType {
    case ACCEL_UNAVAIL
}

class AlarmTriggeredViewController: UIViewController, LocationDetectorDelegate {
    
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
    
    //FIXME: Just For test. remove later
    @IBOutlet var currentDistance: UILabel!
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        timeToCompleteTask = alarm.timeToCompleteTask
        state = .TRIGGER_ALARM        // Do any additional setup after loading the view.
        if locationDetector == nil {
            locationDetector = LocationDetector()
            locationDetector.delegate = self
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
        let priority = DISPATCH_QUEUE_PRIORITY_DEFAULT
        dispatch_async(dispatch_get_global_queue(priority, 0)) {
            self.runStateMachine()
        }
        
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
                if waitForTaskComplete() {
                    state = .TASK_COMPLETE
                } else  {
                    state = .TRIGGER_ALARM
                }
                break;
            case .TASK_COMPLETE:
                print("exiting")
                break;
            }
            usleep(100000)
        }
        performSegueWithIdentifier("UnwindAlarmTriggeredToMain", sender: self)
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
            let waitSem = dispatch_semaphore_create(0)
            dispatch_async(dispatch_get_main_queue()) {
                let alertController = UIAlertController(title: "Error", message: "Motion Data Unavalable.\nClick to silence alarm", preferredStyle: .Alert)
                
                
                let OKAction = UIAlertAction(title: "OK", style: .Default) {
                    (action) in
                    self.alarm.stopAlarm()
                    dispatch_semaphore_signal(waitSem)
                }
                
                alertController.addAction(OKAction)
                
                self.presentViewController(alertController, animated: true, completion: nil)
            }
            dispatch_semaphore_wait(waitSem, DISPATCH_TIME_FOREVER)
        }
    }
    
    
    func waitForMotion() throws {
        
        guard motionDetector!.start()
            else { throw AlarmTriggeredErrorType.ACCEL_UNAVAIL }
        
        motionDetector!.waitTilDeviceMove()
        
        motionDetector!.stop()
        
    }
    
    func waitForTaskComplete() -> Bool {
        var taskIsComplete = false
        
        self.timeToCompleteTask = alarm.timeToCompleteTask
        print("waiting for task complete")
        switch alarm.task! {
        case .LOCATION:
            guard locationDetector!.start() else {
                let waitSem = dispatch_semaphore_create(0)
                dispatch_async(dispatch_get_main_queue()) {
                    let alertController = UIAlertController(title: "Location Data Unavalable", message: "Enable Location permission in settings", preferredStyle: .Alert)
                    let OKAction = UIAlertAction(title: "OK", style: .Default) {
                        (action) in
                        dispatch_semaphore_signal(waitSem)
                    }
                    alertController.addAction(OKAction)
                    self.presentViewController(alertController, animated: true, completion: nil)
                }
                dispatch_semaphore_wait(waitSem, DISPATCH_TIME_FOREVER)
                return true
            }
            taskIsComplete = locationDetector!.waitTilDeviceMove(100,timeout: timeToCompleteTask)
            //NSEC_PER_SEC
            print ("taskiscomplete=\(taskIsComplete)")
            locationDetector!.stop()
            break
        case .MOTION:
            motionDetector!.start()
            motionDetector!.waitTilDeviceMove()
            taskIsComplete = motionDetector!.deviceMoved
            break
        case .GESTURE:
            break
            
        }
        return taskIsComplete
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
        let priority = DISPATCH_QUEUE_PRIORITY_HIGH
        dispatch_async(dispatch_get_global_queue(priority, 0)) {
            dispatch_async(dispatch_get_main_queue()) {
                self.currentTimeLabel.text = TimeFunctions.formatTimeForDisplay(NSDate())
                self.timeToCompleteTaskLabel.text = "\(self.timeToCompleteTask!)"
                if self.state == .WAITING_FOR_TASK_COMPLETE {
                    self.timeToCompleteTaskLabel.text = "\(--self.timeToCompleteTask!)"
                }
            }
        }
    }
    
    func gotLocationUpdate(location:CLLocation){
        currentDistance.text = "Current Distance: \(location.distanceFromLocation(locationDetector.initialLocation!))"
    }
    
    
    
}