//
//  TaskChooserViewController.swift
//  Motus
//
//  Created by Jeff Fermon on 4/28/16.
//  Copyright © 2016 Jeff Fermon. All rights reserved.
//

import UIKit

class TaskChooserViewController: UITableViewController {
    //MARK: Public members
    var alarm:Alarm!
    var tasksNames:[String]?
    var tasksDict:[String:Task] = [Task.GetText(.LOCATION):.LOCATION, Task.GetText(.GESTURE):.GESTURE]
    private(set) var currentlySelected:NSIndexPath?
    
    //MARK: View Controller methods
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tasksNames = [String]()
        for (taskName, _) in tasksDict {
            tasksNames?.append(taskName)
        }
    }
    
    //MARK: TableViewController Methods
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        //Get the current cell being created
        let cell = tableView.dequeueReusableCellWithIdentifier("basic", forIndexPath: indexPath)
        
        //set cell text to name of sound
        let name = tasksNames![indexPath.row];
        cell.textLabel!.text = name;
        
        //if the current alarm task is the cell we are creating,
        //then set cell to checked. If not set it to unchecked
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
        return tasksDict.count;
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
        alarm.task = tasksDict[(newSelectedCell?.textLabel?.text)!]
        
        //set currently selected
        currentlySelected = indexPath
    }

}
