//
//  AlarmTriggeredViewController.swift
//  Motus
//
//  Created by Jeff Fermon on 2/21/16.
//  Copyright © 2016 Jeff Fermon. All rights reserved.
//

import UIKit
import CoreLocation
import CoreMotion


enum AlarmTriggeredStates {
    case TRIGGER_ALARM
    case WAITING_FOR_ALARM_KILL
    case WAITING_FOR_TASK_COMPLETE
    case TASK_COMPLETE
}
enum AlarmTriggeredErrorType:ErrorType {
    case ACCEL_UNAVAIL
}

let MOVE_DISTANCE_FEET = 20.0

class AlarmTriggeredViewController: UIViewController, LocationDetectorDelegate,GestureDetectorDelegate {
    
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
    
    //FIXME: Test Labels
    @IBOutlet var locationTestDataLabel: UILabel!
    @IBOutlet var activityTestDataLabel: UILabel!
    @IBOutlet var pedometerTestDataLabel: UILabel!
    
    
    //MARK: ViewController Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //if test mode then make debug fields viewable
        if TEST_MODE {
            locationTestDataLabel.text = ""
            activityTestDataLabel.text = ""
            pedometerTestDataLabel.text = ""
            //locationTestDataLabel.hidden = false
            activityTestDataLabel.hidden = false
            pedometerTestDataLabel.hidden = false
        }
        
        //set time left to complete task
        timeToCompleteTask = alarm.timeToCompleteTask
        
        // inits state to trigger alamr
        state = .TRIGGER_ALARM
        
        // hide activity indicator
        showActivityIndicator(false)
        
        //initi our detector objects based on the task assigned to the device
        switch alarm.task! {
        case .LOCATION:
            //initialize location detector object
            if locationDetector == nil {
                locationDetector = LocationDetector()
                locationDetector.delegate = self
                locationDetector.distanceFilter = kCLDistanceFilterNone
                guard locationDetector!.start() else {
                    //if detector fails to start then present UIAlert to request permission
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
            break
            
        case .GESTURE:
            //initialize location detector object
            if gestureDetector == nil {
                gestureDetector = GestureDetector(uiview: self.view)
                gestureDetector.delegate = self
            }
            break
        default:
            break
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
        //launch the state machine in a new thread
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            self.runStateMachine()
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        //cleanup the detector classes if they are initialized
        if motionDetector != nil {
            motionDetector!.stop()
            motionDetector = nil
        }
        if locationDetector != nil {
            locationDetector!.stop()
            locationDetector = nil
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK:State Methods
    func runStateMachine(){
        
        while state != AlarmTriggeredStates.TASK_COMPLETE {
            //print("runStateMachine: state: \(state)")
            switch state! {
            case .TRIGGER_ALARM:
                //trigger the alarm then move to next state
                triggerAlarm()
                state = .WAITING_FOR_ALARM_KILL
                break;
            case .WAITING_FOR_ALARM_KILL:
                //wait infinitely for the alarm to be killed.
                //Once function returns, move to next state
                waitForAlarmKilled()
                state = .WAITING_FOR_TASK_COMPLETE
                break;
            case .WAITING_FOR_TASK_COMPLETE:
                //call waitForTaskComplete. 
                //if it returns true, the task was completed in time 
                //successfully and we return to main menu
                //If it returns false. we retrigger the alarm
                state = waitForTaskComplete() ? .TASK_COMPLETE : .TRIGGER_ALARM
                break;
            case .TASK_COMPLETE:
                //included for completeness
                print("exiting")
                break;
            }
            usleep(100000)
        }
        
        performSegueWithIdentifier("UnwindAlarmTriggeredToMain", sender: self)
    }
    
    //helper function to trigger the alarm
    func triggerAlarm(){
        alarm.triggerAlarm()
        resetView()
    }
    
    //helper function that waits until motion is detected to turn off alarm
    func waitForAlarmKilled() {
        do {
            try waitForMotion()
            
            alarm.stopAlarm()
            
        } catch _ {
            // if waitForMotion throws it is because we dont have permission to access motion data
            // Present popup to user to alert them of situation
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
            //Code will wait until pop up is killed
            dispatch_semaphore_wait(waitSem, DISPATCH_TIME_FOREVER)
        }
    }
    
    // helper function to handle waiting for the device to move
    func waitForMotion() throws {
        
        //if we fail to start updates, throw exception
        guard motionDetector!.start()
            else { throw AlarmTriggeredErrorType.ACCEL_UNAVAIL }
        
        motionDetector!.waitTilDeviceMove()
        
        // Once device moves, stop updates
        motionDetector!.stop()
    }
    
    
    
    func waitForTaskComplete() -> Bool {
        
        var taskIsComplete = false
        
        //call function to update label that tells user what to 
        // do to permanently silence alarm
        setTaskLabel()
        
        //print("waiting for task complete")
        switch alarm.task! {
        case .LOCATION:
            taskIsComplete = locationDetector!.waitTilDeviceMove(MOVE_DISTANCE_FEET, timeout: alarm.timeToCompleteTask )
            break
        /*case .MOTION:
            motionDetector!.start()
            motionDetector!.waitTilDeviceMove()
            taskIsComplete = motionDetector!.deviceMoved
            break*/
        case .GESTURE:
            taskIsComplete = gestureDetector.waitTilUserSatisfyRequests(alarm.timeToCompleteTask)
            break
        }
        
        //print ("taskiscomplete=\(taskIsComplete)")
        return taskIsComplete
    }
    
    //Helper function to update instruction label for task
    func setTaskLabel(){
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)) {
            dispatch_async(dispatch_get_main_queue()) {
                self.instructionsLabel.text = "To Permanently Silence Alarm"
                self.currentTaskLabel.hidden = false
                switch self.alarm.task! {
                case .LOCATION:
                    self.currentTaskLabel.text = String(format: "Move %.00f ft.",  MOVE_DISTANCE_FEET )
                    break;
                /*case .MOTION:
                    self.currentTaskLabel.text = "Complete Ten Arm Circles"
                    break;*/
                case .GESTURE:
                    self.currentTaskLabel.text = "Waiting..."
                    break;
                }
            }
        }
    }
    
    //Helper function to reset labels on screen
    func resetView(){
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0)) {
            dispatch_async(dispatch_get_main_queue()) {
                self.timeToCompleteTask = self.alarm.timeToCompleteTask
                self.instructionsLabel.text = "Move to Momentarily Silence Alarm"
                self.currentTaskLabel.hidden = true
            }
        }
    }
    
    //function called once per second that updates current time, 
    //and timeToConmpleteTask Labels
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
    
    //MARK: LocationDetectorDelegate Methods
    //Receives location updates
    func gotLocationUpdate(location:CLLocation){
        var distancestr = ""
        guard locationDetector != nil else { return }
        if locationDetector.initialLocation != nil {
            let distanceFeet = locationDetector.currentLocation!.distanceFromLocation(locationDetector.initialLocation!) * FEET_PER_METER
            let distance = MOVE_DISTANCE_FEET - distanceFeet
            distancestr = String(format: "Move %.00f ft.",  distance )
            if distance <= 0 {
                distancestr =  "Complete!"
            }
        } else if state == .WAITING_FOR_TASK_COMPLETE {
            distancestr = "Move \(MOVE_DISTANCE_FEET) ft."
        }
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)) {
            dispatch_async(dispatch_get_main_queue()) {
                self.currentTaskLabel.text = distancestr
                self.locationTestDataLabel.text = self.locationDetector.currentLocation?.description
                
            }
        }
    }
    
    //Receives Pedomater updates
    func gotPedometerUpdate(data:CMPedometerData) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)) {
            dispatch_async(dispatch_get_main_queue()) {
                self.pedometerTestDataLabel.text = "\(data)"
            }
        }
    }

    //Receives MotionActivity updates
    func gotMotionActivityUpdate(activity: CMMotionActivity) {
        var currentActivity = ""
        var conf:String!
        switch activity.confidence {
        case .Low:
            conf = "Low"
            break
        case .Medium:
            conf = "Medium"
            break
        case .High:
            conf = "High"
            break
        }
        currentActivity.appendContentsOf("New activity(\(conf)):")
        //var started = activity.startDate;
        if (activity.stationary){
            currentActivity.appendContentsOf("Stationary,")
        }
        if (activity.running){
            currentActivity.appendContentsOf("Running,")
        }
        if (activity.automotive){
            currentActivity.appendContentsOf("Driving,")
        }
        if (activity.walking){
            currentActivity.appendContentsOf("Walking,")
        }
        if (activity.cycling){
            currentActivity.appendContentsOf("Cycling,")
        }
        if (activity.unknown){
            currentActivity.appendContentsOf("Unknown")
        }
        
        print(currentActivity)
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)) {
            dispatch_async(dispatch_get_main_queue()) {
                if (currentActivity.rangeOfString("Stationary") != nil) {
                    currentActivity = "Get moving!\n"
                    currentActivity.appendContentsOf("Location tracking doesn't start\n")
                    currentActivity.appendContentsOf("until you start moving")
                }
                else {
                    currentActivity = "Keep Moving! Only A few feet to go!\n"
                    currentActivity.appendContentsOf("After moving, remain still\n")
                    currentActivity.appendContentsOf("It takes a few seconds to read your location")
                }
                self.activityTestDataLabel.text = currentActivity
            }
        }
    }
    
    //Receives updates from locationDetector when it is zeroing in
    //on the users location but the precision isn't good enough yet
    //Shows activity indicator
    func IsCalibrating() {
        pauseCountdown = true
        let shouldShow = true
        showActivityIndicator(shouldShow)
    }
    
    //Receives updates from locationDetector when updates are preceise enough
    //Hides activity indicator
    func CalibrationComplete() {
        pauseCountdown = false
        let shouldShow = false
        showActivityIndicator(shouldShow)
    }
    
    //Helper function for showingg activity indicator
    func showActivityIndicator(shouldShow:Bool){
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0)) {
            dispatch_async(dispatch_get_main_queue()) {
                if shouldShow {
                    self.instructionsLabel.text = "Remain Stationary. Location Services Calibrating..."
                    self.currentTaskLabel.hidden = true
                    self.activityIndicator.startAnimating()
                } else {
                    self.instructionsLabel.text = "To Permanently Silence Alarm"
                    self.currentTaskLabel.hidden = false
                    self.activityIndicator.stopAnimating()
                    self.gotLocationUpdate(CLLocation())
                }
            }
        }
    }
    
    //MARK: GestureDetectorDelegate Methods
    func gotNewGestureRequest(request: String) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)) {
            dispatch_async(dispatch_get_main_queue()) {
                self.currentTaskLabel.text =  request
            }
        }
    }
    
    
    
}