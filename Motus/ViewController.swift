//
//  ViewController.swift
//  Motus
//
//  Created by Jeff Fermon on 2/2/16.
//  Copyright © 2016 Jeff Fermon. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    //MARK: members

    @IBOutlet var currentTimeLabel: UILabel!
    @IBOutlet var alarmStatusLabel: UILabel!
    @IBOutlet var currentAlarmLabel: UILabel!
    var alarmIsSet = false;
    var alarmSetTime:NSDate?
    
    var timer:NSTimer!
    //MARK: Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        updateTime()
        // Do any additional setup after loading the view, typically from a nib.
        timer = NSTimer.scheduledTimerWithTimeInterval(1.0,
            target: self,
            selector: Selector("updateTime"),
            userInfo: nil,
            repeats: true)
    }
    
    override func viewWillAppear(animated: Bool) {
        alarmStatusLabel.enabled = alarmIsSet
        currentAlarmLabel.hidden = !alarmIsSet
        if alarmIsSet {
            alarmStatusLabel.text = "Alarm Set"
        } else {
            alarmStatusLabel.text = "No Alarm Set"
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "CreateNewAlarmSegue"
        {
            if let _ = segue.destinationViewController as? AlarmSetViewController{
               print("showing alarm set screen")
            }
        }
        else if segue.identifier == "AlarmTriggered"
        {
            if let _ = segue.destinationViewController as? AlarmTriggeredViewController {
                print("showing alarm triggered screen")
            }
        }
    }
    
    func updateTime(){
        currentTimeLabel.text = formatTimeForDisplay(NSDate())
        
        if alarmShouldTrigger() {
            alarmIsSet = false
            print("alarm TRIGGERED at \(alarmSetTime!)")
            performSegueWithIdentifier("AlarmTriggered", sender: nil)
        }
    }
    
    func alarmShouldTrigger() -> Bool {
        return ( alarmIsSet && currentTimeLabel.text == currentAlarmLabel!.text )
    }
    
    func formatTimeForDisplay(date:NSDate) -> String {
        let formatter = NSDateFormatter()
        formatter.locale = NSLocale.currentLocale()
        formatter.timeStyle = NSDateFormatterStyle.ShortStyle
        return formatter.stringFromDate(date)
    }
    
    @IBAction func prepareForUnwind(segue:UIStoryboardSegue) {
        if let vc = segue.sourceViewController as? AlarmSetViewController {
            
            alarmSetTime = vc.timePicker.date
            
            currentAlarmLabel.text = formatTimeForDisplay( alarmSetTime! );
            
            alarmIsSet=true;
        }
        
    }

}

