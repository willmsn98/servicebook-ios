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
        print("oy")
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        print("hey")
        return events.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        print("here")
        
        let cellIdentifier = "EventTableViewCell"
    
        let cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier, forIndexPath: indexPath) as! EventTableViewCell
        
        let event = events[indexPath.row] as! Event
        cell.name.text = event.name
        cell.location.text = "\(event.city), \(event.state)"
        
        return cell
    }
    
    
}