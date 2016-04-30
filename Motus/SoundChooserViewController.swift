//
//  SoundChooserViewController.swift
//  Motus
//
//  Created by Jeff Fermon on 2/28/16.
//  Copyright © 2016 Jeff Fermon. All rights reserved.
//

import UIKit

class SoundChooserViewController: UITableViewController {
    //MARK: Public members
    var alarm:Alarm!
    var sounds:[String]?
    private(set) var currentlySelected:NSIndexPath?
    
    //MARK: View Controller methods
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        sounds = alarm.sounds
    }
    
    //MARK: TableViewController Methods
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        //Get the current cell being created
        let cell = tableView.dequeueReusableCellWithIdentifier("basic", forIndexPath: indexPath)
        
        //set cell text to name of sound
        let name = sounds?[indexPath.row];
        cell.textLabel!.text = name;
        
        //if the current alarm sounds is the cell we are creating,
        //then set cell to checked. If not set it to unchecked
        if alarm.sound == name {
            cell.accessoryType = UITableViewCellAccessoryType.Checkmark
            currentlySelected = indexPath;
        }
        else
        {
            cell.accessoryType = UITableViewCellAccessoryType.None;
        }
        return cell
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        //print("num of rows called: \(sounds!.count) in sectrion: \(section)")
        return sounds!.count;
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        if let _ = currentlySelected {
            // uncheck the previously selected cell
            let previouslySelectedCell = tableView.cellForRowAtIndexPath(currentlySelected!)
             previouslySelectedCell?.accessoryType = UITableViewCellAccessoryType.None
        }
       
        //get the newly seleted cell
        let newSelectedCell = tableView.cellForRowAtIndexPath(indexPath)
        
        //set cell to Checked
        newSelectedCell?.accessoryType = UITableViewCellAccessoryType.Checkmark
        
        //set alarm sound to cell text
        alarm.sound = newSelectedCell?.textLabel?.text
        
        //set currently selected
        currentlySelected = indexPath
        
        //if the new sound isn't "Random" then play the sound
        if (newSelectedCell?.textLabel?.text != "Random" ){
            alarm.testSound(alarm.sound + ".m4r")
        } else {
            alarm.stopAlarm()
        }
    }

}
