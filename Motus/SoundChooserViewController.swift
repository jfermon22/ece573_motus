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
    var selectedSound:String!
    var resourcePath:String!
    var currentlySelected:NSIndexPath?
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        resourcePath = NSBundle.mainBundle().resourcePath! + "/Sounds/"
        populateArray()
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        //print("cell for row at index called: \(indexPath.row) section: \(indexPath.section)")
        let cell = tableView.dequeueReusableCellWithIdentifier("basic", forIndexPath: indexPath)
        let name = sounds?[indexPath.row];
        cell.textLabel!.text = name;
        if selectedSound == name {
            cell.accessoryType = UITableViewCellAccessoryType.Checkmark
            currentlySelected = indexPath;
        }
        else
        {
            cell.accessoryType = UITableViewCellAccessoryType.None;
        }
        return cell
    }
    
    func setViewSelectedSound(newSound:String){
        selectedSound = newSound
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        //print("num of rows called: \(sounds!.count) in sectrion: \(section)")
        return sounds!.count;
    }
    
    func populateArray() {
        //print("populate array called")
        let fileManager = NSFileManager.defaultManager()
        let tempArray = try! fileManager.contentsOfDirectoryAtPath(resourcePath!)
        sounds = [String]()
        for curSound in tempArray {
            sounds?.append(curSound.stringByReplacingOccurrencesOfString(".m4r", withString: ""))
        }
        sounds?.append("Random")
        sounds = sounds!.sort()
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if let _ = currentlySelected {
            let previouslySelectedCell = tableView.cellForRowAtIndexPath(currentlySelected!)
             previouslySelectedCell?.accessoryType = UITableViewCellAccessoryType.None
        }
       
        let newSelectedCell = tableView.cellForRowAtIndexPath(indexPath)
        newSelectedCell?.accessoryType = UITableViewCellAccessoryType.Checkmark
        selectedSound = newSelectedCell?.textLabel?.text
        
        currentlySelected = indexPath
        
        if (newSelectedCell?.textLabel?.text != "Random" ){
            let soundPlayer = SoundPlayer(sound: resourcePath + selectedSound + ".m4r")
            soundPlayer.setNumberOfLoops(0)
            soundPlayer.play()
        }
    }

}
