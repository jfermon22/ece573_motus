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
    
    var timer:NSTimer!
    //MARK: Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        alarm = Alarm(time: NSDate(), sound: "Random", task: Task.LOCATION, isSet:false)
        updateTime()
                // Do any additional setup after loading the view, typically from a nib.
        timer = NSTimer.scheduledTimerWithTimeInterval(1.0,
            target: self,
            selector: Selector("updateTime"),
            userInfo: nil,
            repeats: true)
    }
    
    override func viewWillAppear(animated: Bool) {
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
    
    func updateTime(){
        currentTimeLabel.text = TimeFunctions.formatTimeForDisplay(NSDate())
        
        if alarmShouldTrigger() {
            alarm.isSet = false
            print("alarm TRIGGERED at \(alarm.time!)")
            performSegueWithIdentifier("AlarmTriggered", sender: nil)
        }
    }
    
    func alarmShouldTrigger() -> Bool {
        return ( alarm.isSet && currentTimeLabel.text == currentAlarmLabel!.text )
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
        if let vc = segue.sourceViewController as? AlarmTriggeredViewController {
            alarm = vc.alarm
            alarm.isSet = false;
        }
        
    }

}

