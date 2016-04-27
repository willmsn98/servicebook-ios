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
    

    @IBOutlet weak var name: UITextField!
    @IBOutlet weak var organization: UITextField!
    @IBOutlet weak var startTime: UITextField!
    @IBOutlet weak var endTime: UITextField!
    @IBOutlet weak var streetAddress: UITextField!
    @IBOutlet weak var city: UITextField!
    @IBOutlet weak var state: UITextField!
    @IBOutlet weak var country: UITextField!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func cancel(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: {})
    }
    
    @IBAction func create(sender: AnyObject) {
        
        let event: Event = Event()
        event.name = name.text
        event.address = streetAddress.text
        event.city = city.text
        event.state = state.text
        event.country = country.text
        
        let pm: PersistenceManager = PersistenceManager.sharedInstance
        pm.save(event)
        
        self.dismissViewControllerAnimated(true, completion: {})
        
    }
}