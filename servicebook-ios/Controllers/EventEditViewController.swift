//
//  EventViewController.swift
//  servicebook-ios
//
//  Created by Christopher Williamson on 4/26/16.
//  Copyright © 2016 Christopher Williamson. All rights reserved.
//

import Foundation

import UIKit
import CoreLocation

class EventEditViewController: UIViewController {
    

    @IBOutlet weak var navigationBar: UINavigationBar!
    @IBOutlet weak var name: UITextField!
    @IBOutlet weak var details: UITextView!
    @IBOutlet weak var organization: UITextField!
    @IBOutlet weak var startTime: UITextField!
    @IBOutlet weak var endTime: UITextField!
    @IBOutlet weak var address: UITextField!
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
            address.text = event.address
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

        let coder = CLGeocoder()
        coder.geocodeAddressString(address.text!) { (placemarks, error) -> Void in
            
            if let firstPlacemark = placemarks?[0] {
                //set location
                self.event.country = firstPlacemark.country
                self.event.state = firstPlacemark.administrativeArea
                self.event.city = firstPlacemark.locality

                //build event
                self.event.name = self.name.text
                self.event.details = self.details.text
                self.event.address = self.address.text
                
                if !self.edit {
                    self.event.owner = pm.user
                }
                
                //store data
                pm.save(self.event)
            
                if(self.activityVC == nil) {
                    let vc = self.presentingViewController as!  UITabBarController
                    self.activityVC  = vc.selectedViewController as! ActivityViewController
                }
                
                //update tableview
                if self.edit {
                    self.activityVC.updateEvent(self.event)
                    self.eventVC.event = self.event
                } else {
                    self.activityVC.addEvent(self.event)
                }
                
                self.dismissViewControllerAnimated(true, completion: {})

            }
        }
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