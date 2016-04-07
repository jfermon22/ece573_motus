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
    
    //MARK:Member Variables
    @IBOutlet var instructionsLabel: UILabel!
    @IBOutlet var currentTimeLabel: UILabel!
    @IBOutlet var currentTaskLabel: UILabel!
    @IBOutlet var timeToCompleteTaskLabel: UILabel!
    @IBOutlet var activityIndicator: UIActivityIndicatorView!
    var alarm:Alarm!
    private(set) var pauseCountdown = false
    private(set) var state:AlarmTriggeredStates!
    private var timeToCompleteTask:UInt64!
    private var motionDetector:MotionDetector!
    private var locationDetector:LocationDetector!
    private var gestureDetector:GestureDetector!
    private var timer:NSTimer!
    
    //MARK: ViewController Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        timeToCompleteTask = alarm.timeToCompleteTask
        state = .TRIGGER_ALARM        // Do any additional setup after loading the view.
        showActivityIndicator(false)
        if locationDetector == nil {
            locationDetector = LocationDetector()
            locationDetector.delegate = self
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
                return
            }
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
    
    override func viewWillDisappear(animated: Bool) {
        motionDetector!.stop()
        locationDetector!.stop()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK:State Methods
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
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0)) {
            dispatch_async(dispatch_get_main_queue()) {
                self.instructionsLabel.text = "Move to Momentarily Silence Alarm"
            }
        }
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
            taskIsComplete = locationDetector!.waitTilDeviceMove(20,timeout: timeToCompleteTask)
            //locationDetector!.waitTilDeviceExitRegion(20, identifier: "Bedroom")
            print ("taskiscomplete=\(taskIsComplete)")
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
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)) {
            dispatch_async(dispatch_get_main_queue()) {
                self.currentTimeLabel.text = TimeFunctions.formatTimeForDisplay(NSDate())
                self.timeToCompleteTaskLabel.text = "\(self.timeToCompleteTask!)"
                if self.state == .WAITING_FOR_TASK_COMPLETE && !self.pauseCountdown {
                    self.timeToCompleteTaskLabel.text = "\(--self.timeToCompleteTask!)"
                }
            }
        }
    }
    
    func gotLocationUpdate(location:CLLocation){
        var distancestr = ""
        if locationDetector.initialLocation != nil {
            let distanceFeet = location.distanceFromLocation(locationDetector.initialLocation!) * FEET_PER_METER
            let distance = 20.0 - distanceFeet
            distancestr = String(format: "Move %.00f ft.",  distance )
            if distance <= 0 {
                distancestr =  "Complete!"
            }
        }
        
        currentTaskLabel.text = distancestr
       
    }
    
    func IsCalibrating() {
        pauseCountdown = true
        let shouldShow = true
        showActivityIndicator(shouldShow)
    }
    
    func CalibrationComplete() {
        pauseCountdown = false
        let shouldShow = false
        showActivityIndicator(shouldShow)
    }
    
    func showActivityIndicator(shouldShow:Bool){
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0)) {
            dispatch_async(dispatch_get_main_queue()) {
                if shouldShow {
                    self.instructionsLabel.text = "Location Services Calibrating..."
                    self.currentTaskLabel.hidden = true
                    self.activityIndicator.startAnimating()
                } else {
                    self.instructionsLabel.text = "To Permanently Silence Alarm"
                    self.currentTaskLabel.hidden = false
                    self.activityIndicator.stopAnimating()
                }
            }
        }
    }
    
    
}