//
//  AlarmTriggeredViewController.swift
//  Motus
//
//  Created by Jeff Fermon on 2/21/16.
//  Copyright © 2016 Jeff Fermon. All rights reserved.
//

import UIKit

enum Task {
    case LOCATION
    case MOTION
    case GESTURE
};


class AlarmTriggeredViewController: UIViewController {

    @IBOutlet var currentTimeLabel: UILabel!
    @IBOutlet var currentTaskLabel: UILabel!
    @IBOutlet var timeToCompleteTaskLabel: UILabel!
    
    var timeToCompleteTask:NSInteger!
    var currentTask:Task!
    var timer:NSTimer!
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateTime()
        // Do any additional setup after loading the view, typically from a nib.
        timer = NSTimer.scheduledTimerWithTimeInterval(1.0,
            target: self,
            selector: Selector("updateTime"),
            userInfo: nil,
            repeats: true)

        
        // Do any additional setup after loading the view.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func updateTime(){
        currentTimeLabel.text = TimeFunctions.formatTimeForDisplay(NSDate())
    }
    
}