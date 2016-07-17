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

    @IBOutlet weak var navigationBar: UINavigationBar!
    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var location: UILabel!
    @IBOutlet weak var time: UILabel!
    @IBOutlet weak var details: UILabel!
    @IBOutlet weak var mapView: MKMapView!
    
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

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func back(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: {})
    }
    
    @IBAction func edit(sender: AnyObject) {
        let vc = storyboard?.instantiateViewControllerWithIdentifier("EventEditViewController") as! EventEditViewController
        
        vc.event = event
        vc.activityVC = activityVC
        vc.eventVC = self
        
        presentViewController(vc, animated: true, completion: nil)
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
                self.mapView.setRegion(coordinateRegion, animated: true)
                
                
                let anotation = MKPointAnnotation()
                anotation.coordinate = (placemark.location?.coordinate)!
                self.mapView.addAnnotation(anotation)
            }
        }
    }
}