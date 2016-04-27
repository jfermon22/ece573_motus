//
//  AlarmSetViewController.swift
//  Motus
//
//  Created by Jeff Fermon on 2/3/16.
//  Copyright © 2016 Jeff Fermon. All rights reserved.
//

import UIKit

class AlarmSetViewController: UIViewController {
    
    @IBOutlet var timePicker: UIDatePicker!
    @IBOutlet var soundButton: UIButton!
    var alarm:Alarm!
    @IBOutlet var alarmConfirmButton: UIButton!
    var lastSegue:UIStoryboardSegue?
    
    var lastCalledSegue:String?

    
    override func viewDidLoad() {
        super.viewDidLoad()
        soundButton.setTitle(alarm.sound, forState: .Normal)
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        lastSegue = segue
        if segue.identifier == "SelectSoundSegue"
        {
            if let navController = segue.destinationViewController as? UINavigationController {
                if let soundVC = navController.viewControllers[0] as? SoundChooserViewController{
                    soundVC.alarm = alarm
                }
            }
        }
    }
    
    @IBAction func prepareForUnwind(segue:UIStoryboardSegue) {
        lastSegue=segue
        lastCalledSegue = segue.identifier
        if let soundVC = segue.sourceViewController as? SoundChooserViewController {
            alarm = soundVC.alarm
            soundButton.setTitle(alarm.sound, forState: .Normal)
        }
        
        if alarm.IsPlaying {
            alarm.stopAlarm()
        }
        
    }



    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
