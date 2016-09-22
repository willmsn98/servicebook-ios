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
import SwiftOverlays

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
    
    let startTimeDatePicker: UIDatePicker = UIDatePicker()
    let endTimeDatePicker: UIDatePicker = UIDatePicker()

    var activityVC: ActivityViewController!
    var eventVC: EventViewController!
    var event: Event!
    var edit = false
    var updatedImage = false
    
    let dateFormatter = NSDateFormatter()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        name.borderStyle = UITextBorderStyle.RoundedRect
        
        dateFormatter.dateFormat = "EEEE, MMMM d, YYYY h:mm a"

        startTimeDatePicker.minuteInterval = 5
        startTime.inputView = startTimeDatePicker
        
        let startTimeToolBar = UIToolbar()
        startTimeToolBar.barStyle = UIBarStyle.Default
        startTimeToolBar.translucent = true
        startTimeToolBar.sizeToFit()
        
        let startTimeDoneButton = UIBarButtonItem(title: "Done", style: UIBarButtonItemStyle.Plain, target: self, action: #selector(EventEditViewController.updateStartTime(_:)))
        let spaceButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.FlexibleSpace, target: nil, action: nil)
        let cancelButton = UIBarButtonItem(title: "Cancel", style: UIBarButtonItemStyle.Plain, target: self, action: #selector(EventEditViewController.donePicker(_:)))
        
        startTimeToolBar.setItems([cancelButton, spaceButton, startTimeDoneButton], animated: false)
        startTimeToolBar.userInteractionEnabled = true
        
        startTime.inputAccessoryView = startTimeToolBar
        
        endTimeDatePicker.minuteInterval = 5
        endTime.inputView = endTimeDatePicker
        
        let endTimeToolBar = UIToolbar()
        endTimeToolBar.barStyle = UIBarStyle.Default
        endTimeToolBar.translucent = true
        endTimeToolBar.sizeToFit()
        
        let endTimeDoneButton = UIBarButtonItem(title: "Done", style: UIBarButtonItemStyle.Plain, target: self, action: #selector(EventEditViewController.updateEndTime(_:)))
        
        endTimeToolBar.setItems([endTimeDoneButton, spaceButton, endTimeDoneButton], animated: false)
        endTimeToolBar.userInteractionEnabled = true
        
        endTime.inputAccessoryView = endTimeToolBar
        
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
                self.startTimeDatePicker.date = startTime
            }
            if let endTime = event.endTime {
                self.endTime.text = dateFormatter.stringFromDate(endTime)
                self.endTimeDatePicker.date = endTime
            }
            
            self.enableControls(true)
            
            loadImage()
            loadMap()
            
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

                self.event.startTime = self.roundDate(self.startTimeDatePicker.date, interval: 5)
                self.event.endTime = self.roundDate(self.endTimeDatePicker.date, interval: 5)

                if !self.edit {
                    self.event.owner = pm.user
                }
                
                let image = self.imageView.image
                if self.updatedImage, let image = image {
                    self.enableControls(false)
                    self.showWaitOverlayWithText("Please wait...")
                    pm.uploadImage(image, onCompletion: { (status, image) in
                        if image != nil {
                            
                            self.event.primaryImage = image                            
                            pm.save(self.event).onSuccess { event in
                                self.close()
                            }
                        }
                    })
                } else {
                    pm.save(self.event).onSuccess { event in
                        self.close()
                    }
                }
            }
        }
    }
    
    func enableControls(yes:Bool) {
        self.name.enabled = yes
        self.organization.enabled = yes
        self.startTime.enabled = yes
        self.endTime.enabled = yes
        self.address.enabled = yes
        self.deleteButton.enabled = yes
        self.details.userInteractionEnabled = yes
    }
    
    func close() {
        self.updateParents()
        self.removeAllOverlays()
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    func updateParents() {
        //update tableview
        if self.edit {
            self.activityVC.updateEvent(event)
            self.eventVC.event = event
            self.eventVC.update()
        } else {
            self.activityVC.addEvent(event)
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
                        
                        self.updatedImage = true
                        
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
    
    func loadImage() {
        if let imageUrl = event.primaryImage?.getCloudURL() {
            imageView.af_setImageWithURL(imageUrl, completion: { response in
                if let image = response.result.value {
                    //set height
                    self.imageViewHeight.constant = self.computeHeight(image.size)
                    self.imageViewHeight.priority = 999
                }

            })
        }

    }
    
    func computeHeight(imageSize: CGSize) -> CGFloat {
        let ratio = imageSize.height/imageSize.width
        let screenSize: CGRect = UIScreen.mainScreen().bounds
        return screenSize.width * ratio
    }
    
    func loadMap() {
        let coder = CLGeocoder()
        if let address = event.address {
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
        
        let date = roundDate(startTimeDatePicker.date, interval: 5)
        self.startTime.text = dateFormatter.stringFromDate(date)
        
        //Add an hour and set to end time
        let calendar = NSCalendar.currentCalendar()
        if let endDate = calendar.dateByAddingUnit(
            NSCalendarUnit.Hour,
            value: 1,
            toDate: date,
            options: NSCalendarOptions(rawValue: 0)
            ) {
            self.endTimeDatePicker.date = endDate
            self.endTime.text = dateFormatter.stringFromDate(endDate)
        }
        
        startTime.resignFirstResponder()
    }
    
    func updateEndTime(sender: UIDatePicker) {
        let date = roundDate(endTimeDatePicker.date, interval: 5)
        self.endTime.text = dateFormatter.stringFromDate(date)
        endTime.resignFirstResponder()

    }

    func donePicker(sender: UIDatePicker) {
        startTime.resignFirstResponder()
        endTime.resignFirstResponder()
    }

    func roundDate(date: NSDate, interval:Int) -> NSDate{
        let calendar = NSCalendar.currentCalendar()
        var date = startTimeDatePicker.date
        
        let nextDiff = calendar.component(.Minute, fromDate: date) % interval
        date = calendar.dateByAddingUnit(.Minute, value: nextDiff * -1, toDate: date, options: []) ?? NSDate()
        
        return date
    }
}