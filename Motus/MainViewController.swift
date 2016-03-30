//
//  ViewController.swift
//  Motus
//
//  Created by Jeff Fermon on 2/2/16.
//  Copyright © 2016 Jeff Fermon. All rights reserved.
//

import UIKit

class MainViewController: UIViewController {

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
    //MARK: Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        if alarm == nil {
            alarm = Alarm(time: NSDate(), sound: "Apex", task: Task.LOCATION, isSet:false)
        }
        
        timer = NSTimer.scheduledTimerWithTimeInterval(1.0,
            target: self,
            selector: #selector(MainViewController.updateTime),
            userInfo: nil,
            repeats: true)
        updateTime(true)
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
        } else {
            alarmStatusLabel.text = "No Alarm Set"
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
                atvc.countDownActive = false
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

