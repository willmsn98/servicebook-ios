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
import MapKit
import DKImagePickerController

class EventEditViewController: UIViewController {
    

    @IBOutlet weak var name: UITextField!
    @IBOutlet weak var details: UITextView!
    @IBOutlet weak var organization: UITextField!
    @IBOutlet weak var startTime: UITextField!
    @IBOutlet weak var endTime: UITextField!
    @IBOutlet weak var address: UITextField!
    @IBOutlet weak var deleteButton: UIButton!
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var imageViewHeight: NSLayoutConstraint!
    
    @IBOutlet weak var mapView: MKMapView!
    
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
                
                let image = self.imageView.image
                if let image = image {
                    pm.uploadImage(image, onCompletion: { (status, url) in
                        if url != nil {
                            pm.addImage(url!, comment: nil, event: self.event, user: pm.user).onSuccess { image in
                                print("Saved image")
                            }
                        }
                    })
                }
            
                if(self.activityVC == nil) {
                    let n: Int! = self.navigationController?.viewControllers.count
                    self.activityVC = self.navigationController?.viewControllers[n-2] as! ActivityViewController
                }
                
                pm.save(self.event).onSuccess { event in
                    if let event = event as? Event {
                        //update tableview
                        if self.edit {
                            self.activityVC.updateEvent(event)
                            self.eventVC.event = event
                        } else {
                            self.activityVC.addEvent(event)
                        }
                    }
                }
                
                self.navigationController?.popViewControllerAnimated(true)

            }
        }
    }
    
    @IBAction func choosePicture(sender: AnyObject) {
        let pickerController = DKImagePickerController()
        pickerController.maxSelectableCount = 1
        
        pickerController.didSelectAssets = { (assets: [DKAsset]) in
            if assets.count == 1 {
                let asset = assets[0]
                asset.fetchImageWithSize(CGSize(width: (asset.originalAsset?.pixelWidth)!, height: (asset.originalAsset?.pixelHeight)!), completeBlock: { image, info in
                    self.imageView.image = image
                    if let imageSize  = image?.size {
                        
                        //set height
                        self.imageViewHeight.constant = self.computeHeight(imageSize)
                        self.imageViewHeight.priority = 999
                        
                    } else {
                        print("Image not loaded.")
                    }
                })
            }
        }
        
        self.presentViewController(pickerController, animated: true) {}
    }
    
    func computeHeight(imageSize: CGSize) -> CGFloat {
        let ratio = imageSize.height/imageSize.width
        let screenSize: CGRect = UIScreen.mainScreen().bounds
        return screenSize.width * ratio
    }
    
    
    @IBAction func loadMap(sender: AnyObject) {
        let coder = CLGeocoder()
        if let textField = sender as? UITextField, let address = textField.text {
            coder.geocodeAddressString(address) { (placemarks, error) -> Void in
                if let location = placemarks?[0].location {
                    let regionRadius: CLLocationDistance = 1000
                    let coordinateRegion = MKCoordinateRegionMakeWithDistance(location.coordinate,
                                                                              regionRadius * 2.0, regionRadius * 2.0)
                    self.mapView.setRegion(coordinateRegion, animated: false)
                    
                    let anotation = MKPointAnnotation()
                    anotation.coordinate = (location.coordinate)
                    
                    self.mapView.addAnnotation(anotation)
                }
            }
            
        }
    }

    @IBAction func deleteEvent(sender: AnyObject) {
        
        //delete event
        let pm: PersistenceManager = PersistenceManager.sharedInstance
        pm.delete(event)
        
        activityVC.deleteSelectedEvent()
        self.navigationController?.popViewControllerAnimated(true)
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