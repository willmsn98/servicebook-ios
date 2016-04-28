//
//  ActivityViewController.swift
//  servicebook-ios
//
//  Created by Christopher Williamson on 4/21/16.
//  Copyright © 2016 Christopher Williamson. All rights reserved.
//

import UIKit
import Spine

class ActivityViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var tableView: UITableView!
    
    var events = [Resource]()
    
    var selectedRow:NSIndexPath!

    override func viewDidLoad() {
        super.viewDidLoad()
        loadEvents()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    func loadEvents() {
        let pm = PersistenceManager.sharedInstance
        pm.getEvents { (resources) in
            self.events = resources.resources
            
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.tableView.reloadData()
            })
        }
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return events.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cellIdentifier = "EventTableViewCell"
    
        let cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier, forIndexPath: indexPath) as! EventTableViewCell
        
        let event = events[indexPath.row] as! Event
        cell.name.text = event.name
        cell.location.text = "\(event.city), \(event.state)"
        
        return cell
    }
    
    func tableView(tableView: UITableView!, didSelectRowAtIndexPath indexPath: NSIndexPath!) {
        
        selectedRow = indexPath
        
        let vc = storyboard?.instantiateViewControllerWithIdentifier("EventEditViewController") as! EventEditViewController
        
        let event = events[indexPath.row] as! Event
        vc.event = event
        
        presentViewController(vc, animated: true, completion: nil)
    }
    
    func addEvent(event:Event) {
        events.append(event)
        tableView.insertRowsAtIndexPaths([NSIndexPath(forRow: events.count-1, inSection: 0)], withRowAnimation: .Automatic)
    }
    
    func updateEvent(event:Event) {
        tableView.reloadRowsAtIndexPaths([selectedRow], withRowAnimation: .Automatic)
    }
    
    func deleteSelectedEvent() {
        events.removeAtIndex(selectedRow.row)
        tableView.deleteRowsAtIndexPaths([selectedRow], withRowAnimation: .Automatic)
    }
    
}