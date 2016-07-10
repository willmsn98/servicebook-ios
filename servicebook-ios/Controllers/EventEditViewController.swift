//
//  EventViewController.swift
//  servicebook-ios
//
//  Created by Christopher Williamson on 4/26/16.
//  Copyright © 2016 Christopher Williamson. All rights reserved.
//

import Foundation

import UIKit

class EventEditViewController: UIViewController {
    

    @IBOutlet weak var navigationBar: UINavigationBar!
    @IBOutlet weak var name: UITextField!
    @IBOutlet weak var details: UITextView!
    @IBOutlet weak var organization: UITextField!
    @IBOutlet weak var startTime: UITextField!
    @IBOutlet weak var endTime: UITextField!
    @IBOutlet weak var streetAddress: UITextField!
    @IBOutlet weak var city: UITextField!
    @IBOutlet weak var state: UITextField!
    @IBOutlet weak var country: UITextField!
    @IBOutlet weak var deleteButton: UIButton!
    @IBOutlet weak var saveButton: UIBarButtonItem!
    
    var activityVC: ActivityViewController!
    var eventVC: EventViewController!
    var event: Event!
    var edit = false
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        name.borderStyle = UITextBorderStyle.RoundedRect;
        
        //editing
        if(event != nil) {
            
            //setup UI
            navigationBar.topItem?.title = "Edit Event"
            saveButton.title = "Save"
            deleteButton.hidden = false
            edit = true

            //setup data
            name.text = event.name
            details.text = event.details
            streetAddress.text = event.address
            city.text = event.city
            state.text = event.state
            country.text = event.country
            
        } else {
            event = Event()
            deleteButton.hidden = true
        }

    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func cancel(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: {})
    }
    
    @IBAction func saveEvent(sender: AnyObject) {
        
        let pm: PersistenceManager = PersistenceManager.sharedInstance

        //build event
        event.name = name.text
        event.details = details.text
        event.address = streetAddress.text
        event.city = city.text
        event.state = state.text
        event.country = country.text
        
        if !edit {
            event.owner = pm.user
        }
        
        //store data
        pm.save(event)
        
        if(activityVC == nil) {
            let vc = self.presentingViewController as!  UITabBarController
            activityVC  = vc.selectedViewController as! ActivityViewController
        }
        
        //update tableview
        if edit {
            activityVC.updateEvent(event)
            eventVC.event = event
        } else {
            activityVC.addEvent(event)
        }
        
        self.dismissViewControllerAnimated(true, completion: {})
        
    }

    @IBAction func deleteEvent(sender: AnyObject) {
        
        //delete event
        let pm: PersistenceManager = PersistenceManager.sharedInstance
        pm.delete(event)
        
        //update tableview
        let vc = self.presentingViewController as!  UITabBarController
        let activityVC  = vc.selectedViewController as! ActivityViewController
        activityVC.deleteSelectedEvent()
        
        self.dismissViewControllerAnimated(true, completion: {})
    }

}