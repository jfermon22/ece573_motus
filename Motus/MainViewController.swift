//
//  ViewController.swift
//  Motus
//
//  Created by Jeff Fermon on 2/2/16.
//  Copyright © 2016 Jeff Fermon. All rights reserved.
//

import UIKit

let TEST_MODE =  false

class MainViewController: UIViewController, BatteryMonitorDelegate {
    
    //MARK: members
    
    @IBOutlet var currentTimeLabel: UILabel!
    @IBOutlet var alarmStatusLabel: UILabel!
    @IBOutlet var currentAlarmLabel: UILabel!
    @IBOutlet var newAlarmButton: UIButton!
    var lastCalledSegue:String?
    var lastSegue:UIStoryboardSegue?
    var alarm:Alarm!
    var lastReadTime:String?
    var timer:NSTimer!
    let batteryMonitor = BatteryMonitor()
    
    
    //warning this is just for test. Remove button for final
    @IBAction func testAlarmButtonPressed(sender: UIButton) {
        alarm.time = NSDate()
        print("alarm TRIGGERED from test button \(alarm.time!)")
        performSegueWithIdentifier("AlarmTriggered", sender: self)
        
    }
    
    //MARK: Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        if TEST_MODE {
            
        }
        
        if alarm == nil {
            alarm = Alarm(time: NSDate(), sound: "Apex", task: Task.GESTURE, isSet:false)
        }
        
        timer = NSTimer.scheduledTimerWithTimeInterval(1.0,
                                                       target: self,
                                                       selector: #selector(MainViewController.updateTime),
                                                       userInfo: nil,
                                                       repeats: true)
        updateTime(true)
        
        batteryMonitor.delegate = self
    }
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        lastReadTime = nil
        updateTime(true)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        alarmStatusLabel.enabled = alarm.isSet
        currentAlarmLabel.hidden = !alarm.isSet
        if alarm.isSet {
            alarmStatusLabel.text = "Alarm Set"
            UIApplication.sharedApplication().idleTimerDisabled = true
            batteryMonitor.enable()
            if alarm.isSet {
                presentUnpluggedWarning()
            }
        } else {
            alarmStatusLabel.text = "No Alarm Set"
            UIApplication.sharedApplication().idleTimerDisabled = false
            //batteryMonitor.disable()
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func updateTime(skipTriggerCheck:Bool = false){
        //set clock to current time
        currentTimeLabel.text = TimeFunctions.formatTimeForDisplay(NSDate())
        
        if alarmShouldTrigger() && !skipTriggerCheck {
            alarm.isSet = false
            print("alarm TRIGGERED at \(alarm.time!)")
            performSegueWithIdentifier("AlarmTriggered", sender: self)
        }
        
        lastReadTime = currentTimeLabel.text
    }
    
    func alarmShouldTrigger() -> Bool {
        if let _ = lastReadTime {
            return ( alarm.isSet &&
                currentTimeLabel.text == currentAlarmLabel!.text &&
                currentTimeLabel.text != lastReadTime )
        } else {
            return false
        }
    }
    
    func batteryStateChanged(state: UIDeviceBatteryState) {
        switch batteryMonitor.state {
        case .Charging:
            guard let _ = self.presentedViewController as? UIAlertController else { return }
            self.dismissViewControllerAnimated(false, completion: nil)
            break
        case .Unplugged:
            guard alarm.isSet else { return }
            presentUnpluggedWarning()
            break
        default:
            break
        }
    }
    
    func presentUnpluggedWarning() {
        guard  batteryMonitor.state == .Unplugged  else { return }
        let alertController = UIAlertController(title: "Warning", message: "Device needs to be plugged in when alarm is set", preferredStyle: .Alert)
        
        let OKAction = UIAlertAction(title: "OK", style: .Default) {
            (action) in
        }
        
        alertController.addAction(OKAction)
        
        self.presentViewController(alertController, animated: true, completion: nil)
    }
    
    //MARK: Segue Methods
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        lastCalledSegue = segue.identifier
        lastSegue = segue
        if segue.identifier == "CreateNewAlarmSegue"
        {
            if let asvc = segue.destinationViewController as? AlarmSetViewController{
                asvc.alarm = alarm
            }
        }
        else if segue.identifier == "AlarmTriggered"
        {
            if let atvc = segue.destinationViewController as? AlarmTriggeredViewController {
                atvc.alarm = alarm
                //atvc.countDownActive = false
            }
        }
    }
    
    @IBAction func prepareForUnwind(segue:UIStoryboardSegue) {
        lastCalledSegue = segue.identifier
        if let vc = segue.sourceViewController as? AlarmSetViewController {
            alarm = vc.alarm
            alarm.time = vc.timePicker.date
            currentAlarmLabel.text = TimeFunctions.formatTimeForDisplay( alarm.time! );
            alarm.isSet = true;
        }
        else if let vc = segue.sourceViewController as? AlarmTriggeredViewController {
            alarm = vc.alarm
            alarm.isSet = false;
        }
        
    }
    
}

