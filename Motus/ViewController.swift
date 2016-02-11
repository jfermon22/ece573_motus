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
    
    //MARK: Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "CreateNewAlarmSegue"
        {
            if let _ = segue.destinationViewController as? AlarmSetViewController{
                print("button was pressed huzzah!")
            }
        }
        
        print("button was pressed")
    }


}

