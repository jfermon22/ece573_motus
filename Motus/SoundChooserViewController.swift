//
//  SoundChooserViewController.swift
//  Motus
//
//  Created by Jeff Fermon on 2/28/16.
//  Copyright © 2016 Jeff Fermon. All rights reserved.
//

import UIKit

class SoundChooserViewController: UITableViewController {
    
    var sounds:[String]?
    
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        populateArray()
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("basic", forIndexPath: indexPath)
        let name = sounds?[indexPath.row];
        cell.textLabel!.text = name;
        return cell
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sounds!.count;
    }
    
    func populateArray() {
        let fileManager = NSFileManager.defaultManager()
        let resourcepath = NSBundle.mainBundle().resourcePath
        sounds = try! fileManager.contentsOfDirectoryAtPath(resourcepath! + "/Sounds")
        
        for (index, sound) in sounds!.enumerate() {
           sounds![index] = sound.stringByReplacingOccurrencesOfString(".m4r", withString: "")
        }
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // Return the number of sections.
        return 1
    }
}
