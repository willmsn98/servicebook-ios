//
//  EventViewController.swift
//  servicebook-ios
//
//  Created by Christopher Williamson on 7/9/16.
//  Copyright © 2016 Christopher Williamson. All rights reserved.
//

import Foundation
import UIKit
import MapKit
import CoreLocation

class EventViewController: UIViewController {

    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var location: UIButton!
    @IBOutlet weak var time: UILabel!

    @IBOutlet weak var details: UILabel!
    @IBOutlet weak var moreDetailsButton: UIButton!
    @IBOutlet weak var detailsHeight: NSLayoutConstraint!

    
    @IBOutlet weak var mapView: MKMapView!

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var imageViewHeight: NSLayoutConstraint!
    
    @IBOutlet weak var writeSomething: UITextField!
    @IBOutlet weak var commentSpacerHeight: NSLayoutConstraint!
    @IBOutlet weak var commentUser: UILabel!
    @IBOutlet weak var comment: UILabel!
    
    
    var event: Event!
    var activityVC: ActivityViewController!
    
    let startDateFormatter = NSDateFormatter()
    let endDateFormatter = NSDateFormatter()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        startDateFormatter.dateFormat = "EEEE, MMMM d, YYYY h:mm a"
        endDateFormatter.dateFormat = "h:mm a"
        
        update()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        update()
    }
    
    // Function for editing event
    
    @IBAction func edit(sender: AnyObject) {
        guard let vc = storyboard?.instantiateViewControllerWithIdentifier("EventEditViewController") as? EventEditViewController else {
            return
        }
        
        vc.event = event
        vc.activityVC = activityVC
        vc.eventVC = self
        
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    // Function for launching comment view
    
    @IBAction func writeSomething(sender: AnyObject) {
        
        // Deselect after click
        dispatch_async(dispatch_get_main_queue(), {
            self.writeSomething.enabled = false
        })
        
        guard let vc = storyboard?.instantiateViewControllerWithIdentifier("EventCommentViewController") as? EventCommentViewController else {
            return
        }
        
        vc.event = event
        vc.activityVC = activityVC
        vc.eventVC = self
                
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    // Function for loading data into the view
    
    func update() {
        name.text = event.name
        
        details.text = event.details
        if event.details == "" {
            detailsHeight.constant = 0
            moreDetailsButton.hidden = true
        }
        
        location.setTitle(event.address, forState: UIControlState.Normal)
        if let startTime = event.startTime {
            time.text = startDateFormatter.stringFromDate(startTime)
            if let endTime = event.endTime {
                time.text = String(format: "%@ - %@", startDateFormatter.stringFromDate(startTime), endDateFormatter.stringFromDate(endTime))
            }
        }
        
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
        self.loadImage()
        self.loadComments()
        
        dispatch_async(dispatch_get_main_queue(), {
            self.writeSomething.enabled = true
        })
    }
    
    func loadComments() {
        let pm = PersistenceManager.sharedInstance
        pm.getComments(event).onSuccess { comments in
            if comments.count > 0 {
                if comments[0].text != nil && comments[0].text != "", let text = comments[0].text {
                    self.comment.text = text
                    self.comment.sizeToFit()
                    self.commentUser.sizeToFit()
                    self.commentUser.text = "\(comments[0].user?.firstName ?? "") \(comments[0].user?.lastName ?? "")"
                    self.commentSpacerHeight.constant = 8
                } else {
                    self.commentUser.text = ""
                    self.comment.text = ""
                }
            }
        }.onFailure { error in
            print(error)
        }
    }
    
    @IBAction func showMoreDetails(sender: AnyObject) {
        
        //This mixture seems to work the best, but don't think it works all the time.
        //Seems like should be able to do this in like three lines of code...
        
        self.details.sizeToFit()
        self.detailsHeight.constant = self.details.frame.height
        self.moreDetailsButton.hidden = true
        
        dispatch_async(dispatch_get_main_queue(), {
            self.details.text = self.event.details
            self.details.sizeToFit()
            self.details.hidden = false
            self.details.backgroundColor = UIColor.whiteColor()
        })
    }
    
    func loadImage() {
        let pm = PersistenceManager.sharedInstance
        pm.getImages(event).onSuccess { images in
                
            if images.count > 0, let image:Image = images[0] as? Image, let imageUrl = image.url {
                    
                // make sure we are using https - required by iOS
                if let url = NSURL(string: imageUrl.stringByReplacingOccurrencesOfString("http:", withString: "https:")) {
                    //load image
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        self.imageView.af_setImageWithURL(url, completion: { response in
                            if let imageSize  = response.result.value?.size {
                                
                                //set height
                                self.imageViewHeight.constant = self.computeHeight(imageSize)
                                self.imageViewHeight.priority = 999
                                
                            } else {
                                print("Image not loaded.")
                            }
                        })
                    })
                } else {
                    print("Invalid URL")
                }
            }
            // if no images then set height to disappear
            else {
                self.imageViewHeight.constant = 1
                self.imageView.hidden = true
            }
        }.onFailure { error in
                print(error)
        }
    }
    
    func computeHeight(imageSize: CGSize) -> CGFloat {
        let ratio = imageSize.height/imageSize.width
        let screenSize: CGRect = UIScreen.mainScreen().bounds
        return screenSize.width * ratio
    }
    
    @IBAction func showMap(sender: AnyObject) {
        if mapView.annotations.count > 0 {
            let coordinates = mapView.annotations[0].coordinate
            let regionDistance:CLLocationDistance = 1000
            let regionSpan = MKCoordinateRegionMakeWithDistance(coordinates, regionDistance, regionDistance)
            let options = [
                MKLaunchOptionsMapCenterKey: NSValue(MKCoordinate: regionSpan.center),
                MKLaunchOptionsMapSpanKey: NSValue(MKCoordinateSpan: regionSpan.span)
            ]
            let placemark = MKPlacemark(coordinate: coordinates, addressDictionary: nil)
            let mapItem = MKMapItem(placemark: placemark)
            mapItem.name = "\(self.event.address ?? "")"
            mapItem.openInMapsWithLaunchOptions(options)
        }
    }
}