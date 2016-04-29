//
//  TaskChooserViewController.swift
//  Motus
//
//  Created by Jeff Fermon on 4/28/16.
//  Copyright © 2016 Jeff Fermon. All rights reserved.
//

import UIKit

class TaskChooserViewController: UITableViewController {

    var alarm:Alarm!
    var tasksNames:[String]?
    var tasksDict:[String:Task] = [Task.GetText(.LOCATION):.LOCATION, Task.GetText(.GESTURE):.GESTURE]


    var currentlySelected:NSIndexPath?
    
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        populateArray()
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        //print("cell for row at index called: \(indexPath.row) section: \(indexPath.section)")
        let cell = tableView.dequeueReusableCellWithIdentifier("basic", forIndexPath: indexPath)
        let name = tasksNames![indexPath.row];
        cell.textLabel!.text = name;
        if alarm.task == tasksDict[name] {
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
        return tasksDict.count;
    }
    
    func populateArray() {
        //tasks = alarm.sounds
        tasksNames = [String]()
        for (taskName, enumVal) in tasksDict {
            tasksNames?.append(taskName)
        }

    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if let _ = currentlySelected {
            let previouslySelectedCell = tableView.cellForRowAtIndexPath(currentlySelected!)
            previouslySelectedCell?.accessoryType = UITableViewCellAccessoryType.None
        }
        
        let newSelectedCell = tableView.cellForRowAtIndexPath(indexPath)
        newSelectedCell?.accessoryType = UITableViewCellAccessoryType.Checkmark
        alarm.task = tasksDict[(newSelectedCell?.textLabel?.text)!]
        
        currentlySelected = indexPath
    }

}
