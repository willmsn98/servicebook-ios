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
import Spine

class EventViewController: UIViewController, UITableViewDataSource {

    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var location: UILabel!
    @IBOutlet weak var time: UILabel!
    @IBOutlet weak var details: UILabel!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var commentsTableView: UITableView!

    @IBOutlet weak var imageView: UIImageView!
    
    @IBOutlet weak var imageViewHeight: NSLayoutConstraint!
    
    @IBOutlet weak var writeSomething: UITextField!
    
    @IBOutlet weak var moreDetailsButton: UIButton!
    @IBOutlet weak var detailsHeight: NSLayoutConstraint!
    
    var event: Event!
    var activityVC: ActivityViewController!
    let startDateFormatter = NSDateFormatter()
    let endDateFormatter = NSDateFormatter()
    
    var comments = [Resource]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        startDateFormatter.dateFormat = "EEEE, MMMM d, YYYY h:mm a"
        endDateFormatter.dateFormat = "h:mm a"
        
        update()
    }
    
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        writeSomething.enabled = true
        update()
    }
    
    @IBAction func back(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: {})
    }
    
    @IBAction func edit(sender: AnyObject) {
        let vc = storyboard?.instantiateViewControllerWithIdentifier("EventEditViewController") as! EventEditViewController
        
        vc.event = event
        vc.activityVC = activityVC
        vc.eventVC = self
        
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    @IBAction func writeSomething(sender: AnyObject) {
        let vc = storyboard?.instantiateViewControllerWithIdentifier("EventCommentViewController") as! EventCommentViewController
        
        vc.event = event
        vc.activityVC = activityVC
        vc.eventVC = self
        
        writeSomething.resignFirstResponder()
        
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    func update() {
        name.text = event.name
        details.text = event.details
        location.text = event.address
        if let startTime = event.startTime {
            time.text = startDateFormatter.stringFromDate(startTime)
            if let endTime = event.endTime {
                time.text = String(format: "%@ - %@", startDateFormatter.stringFromDate(startTime), endDateFormatter.stringFromDate(endTime))
            }
        }
        
        let coder = CLGeocoder()
        coder.geocodeAddressString(event.address!) { (placemarks, error) -> Void in
            
            
            if let placemark = placemarks?[0] {
                let regionRadius: CLLocationDistance = 1000
                let coordinateRegion = MKCoordinateRegionMakeWithDistance(placemark.location!.coordinate,
                                                                          regionRadius * 2.0, regionRadius * 2.0)
                self.mapView.setRegion(coordinateRegion, animated: false)
                
                
                let anotation = MKPointAnnotation()
                anotation.coordinate = (placemark.location?.coordinate)!
                self.mapView.addAnnotation(anotation)
            }
        }
        self.loadImage(event)
        //self.loadComments()
    }
    
    func loadComments() {
        let pm = PersistenceManager.sharedInstance
        pm.getComments(event).onSuccess { comments in
            self.comments = comments
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.commentsTableView.reloadData()
            })
            
            }.onFailure { error in
                print(error)
            }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {

        let cellIdentifier = "EventCommentTableViewCell"
        
        let cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier, forIndexPath: indexPath) as! EventCommentTableViewCell
        
        let comment = comments[indexPath.row] as! Comment
        cell.commentLabel.text = comment.text
        if let user = comment.user {
            cell.userLabel.text = "\(user.firstName ?? "") \(user.lastName ?? "")"
        }
        
        return cell
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return comments.count
    }
    
    @IBAction func showMoreDetails(sender: AnyObject) {
        self.details.sizeToFit()
        self.detailsHeight.constant = self.details.frame.height
        self.moreDetailsButton.hidden = true
        
        dispatch_async(dispatch_get_main_queue(), {
            self.details.sizeToFit()
        })
    }
    
    func loadImage(event: Event) {
        
        let pm = PersistenceManager.sharedInstance
        pm.getImages(event).onSuccess { images in
                
            if images.count > 0, let image:Image = images[0] as? Image, let imageUrl = image.url {
                    
                // make sure we are using https - required by iOS
                if let url = NSURL(string: imageUrl.stringByReplacingOccurrencesOfString("http:", withString: "https:")) {
                    //load image
                    self.imageView.af_setImageWithURL(url, completion: { response in
                        if let imageSize  = response.result.value?.size {
                            
                            //set height
                            self.imageViewHeight.constant = self.computeHeight(imageSize)
                            self.imageViewHeight.priority = 999
                                
                        } else {
                            print("Image not loaded.")
                        }
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
}