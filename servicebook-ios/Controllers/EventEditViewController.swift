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
    

    @IBOutlet weak var name: UITextField!
    @IBOutlet weak var details: UITextView!
    @IBOutlet weak var organization: UITextField!
    @IBOutlet weak var startTime: UITextField!
    @IBOutlet weak var endTime: UITextField!
    @IBOutlet weak var address: UITextField!
    @IBOutlet weak var deleteButton: UIButton!
    
    var activityVC: ActivityViewController!
    var eventVC: EventViewController!
    var event: Event!
    var edit = false
    
    let dateFormatter = NSDateFormatter()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        name.borderStyle = UITextBorderStyle.RoundedRect
        
        dateFormatter.dateFormat = "EEEE, MMMM d, YYYY h:mm a"

        let startTimeDatePicker: UIDatePicker = UIDatePicker()
        startTimeDatePicker.addTarget(self, action:#selector(EventEditViewController.updateStartTime(_:)), forControlEvents: UIControlEvents.ValueChanged)
        startTime.inputView = startTimeDatePicker
        
        let endTimeDatePicker: UIDatePicker = UIDatePicker()
        endTimeDatePicker.addTarget(self, action:#selector(EventEditViewController.updateEndTime(_:)), forControlEvents: UIControlEvents.ValueChanged)
        endTime.inputView = endTimeDatePicker
        
        //editing
        if(event != nil) {
            
            //setup UI
            self.navigationItem.title = "Edit Event"
            self.navigationItem.rightBarButtonItem?.title = "Save"
            deleteButton.hidden = false
            edit = true

            //setup data
            name.text = event.name
            details.text = event.details
            address.text = event.address
            if let startTime = event.startTime {
                self.startTime.text = dateFormatter.stringFromDate(startTime)
            }
            if let endTime = event.endTime {
                self.endTime.text = dateFormatter.stringFromDate(endTime)
            }
        } else {
            event = Event()
            deleteButton.hidden = true
        }

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
                    let n: Int! = self.navigationController?.viewControllers.count
                    self.activityVC = self.navigationController?.viewControllers[n-2] as! ActivityViewController
                }
                
                //update tableview
                if self.edit {
                    self.activityVC.updateEvent(self.event)
                    self.eventVC.event = self.event
                } else {
                    self.activityVC.addEvent(self.event)
                }
                
                self.navigationController?.popViewControllerAnimated(true)

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
    
    func updateStartTime(sender: UIDatePicker) {
        self.startTime.text = dateFormatter.stringFromDate(sender.date)
        self.event.startTime = sender.date
    }
    
    func updateEndTime(sender: UIDatePicker) {
        self.endTime.text = dateFormatter.stringFromDate(sender.date)
        self.event.endTime = sender.date
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        super.touchesBegan(touches, withEvent: event)
        self.view.endEditing(true)
    }
    
}