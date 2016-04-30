//
//  AlarmSetViewController.swift
//  Motus
//
//  Created by Jeff Fermon on 2/3/16.
//  Copyright © 2016 Jeff Fermon. All rights reserved.
//

import UIKit

class AlarmSetViewController: UIViewController {
    //MARK: Public members
    @IBOutlet var timePicker: UIDatePicker!
    @IBOutlet var soundButton: UIButton!
    @IBOutlet var alarmConfirmButton: UIButton!
    @IBOutlet var taskButton: UIButton!
    var alarm:Alarm!
    
    //MARK: Private members
    // These two members are used during unit tests
    private var lastSegue:UIStoryboardSegue?
    private var lastCalledSegue:String?
    
    //MARK: View Controller methods
    override func viewDidLoad() {
        super.viewDidLoad()
        soundButton.setTitle(alarm.sound, forState: .Normal)
        taskButton.setTitle(Task.GetText(alarm.task), forState: .Normal)
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: Segue methods
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        //set the following members for unit testing
        lastSegue = segue
        
        if segue.identifier == "SelectSoundSegue"
        {
            if let navController = segue.destinationViewController as? UINavigationController {
                if let soundVC = navController.viewControllers[0] as? SoundChooserViewController {
                    soundVC.alarm = alarm
                }
            }
        }
        else if segue.identifier == "SelectTaskSegue"
        {
            if let navController = segue.destinationViewController as? UINavigationController {
                if let taskVC = navController.viewControllers[0] as? TaskChooserViewController {
                    taskVC.alarm = alarm
                }
            }
        }
    }
    
    @IBAction func prepareForUnwind(segue:UIStoryboardSegue) {
        //set the following member for unit testing
        lastSegue=segue
        lastCalledSegue = segue.identifier
        
        if let soundVC = segue.sourceViewController as? SoundChooserViewController {
            alarm = soundVC.alarm
            soundButton.setTitle(alarm.sound, forState: .Normal)
        }
        else if let taskVC = segue.sourceViewController as? TaskChooserViewController {
            alarm = taskVC.alarm
            taskButton.setTitle(Task.GetText(alarm.task), forState: .Normal)
        }
        
        if alarm.IsPlaying {
            alarm.stopAlarm()
        }
        
    }

}
