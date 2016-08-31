//
//  ActivityViewController.swift
//  servicebook-ios
//
//  Created by Christopher Williamson on 4/21/16.
//  Copyright © 2016 Christopher Williamson. All rights reserved.
//

import UIKit

import Alamofire
import AlamofireImage
import FontAwesomeKit

class ActivityViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var tabItem: UITabBarItem!
    
    // event data shown in table
    var events = [Event]()
    var images:[UIImage?]!
    
    // used for knowing which row/event is being viewed, updated or deleted
    var selectedRow:NSIndexPath!
    
    let startDateFormatter = NSDateFormatter()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        startDateFormatter.dateFormat = "EEEE MMMM d, YYYY"
                
        loadEvents()
    }
    
    // Functions for loading data
    
    func loadEvents() {
        let pm = PersistenceManager.sharedInstance
        pm.getEvents().onSuccess { events in
            self.events = events
            
            //set or reset images to empty array; load images when creating cells
            self.images = [UIImage?](count:self.events.count, repeatedValue:nil)
            
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.tableView.reloadData()
            })
            
        }.onFailure { error in
            print(error)
                    
        }
    }
    
    func loadImage(event: Event, cell: EventTableViewCell, indexPath:NSIndexPath) {
        
        //if cached
        if let image = images[indexPath.row] {
            cell.icon.image = image
            cell.iconHeight.constant = self.computeHeight(image.size)
            cell.iconHeight.priority = 999
            
        }
        //if not cached go download an image
        else {
            let pm = PersistenceManager.sharedInstance
            pm.getImages(event).onSuccess { images in
            
                if images.count > 0, let image:Image = images[0] as? Image, let imageUrl = image.url {
                
                    // make sure we are using https - required by iOS
                    if let url = NSURL(string: imageUrl.stringByReplacingOccurrencesOfString("http:", withString: "https:")) {
                        //load image
                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                            cell.icon.af_setImageWithURL(url, completion: { response in
                                if let imageSize  = response.result.value?.size {
                                
                                    //cache image
                                    self.images[indexPath.row] = response.result.value
                                
                                    //set height
                                    cell.iconHeight.constant = self.computeHeight(imageSize)
                                    cell.iconHeight.priority = 999
                                
                                    //reload to change height of row
                                    self.tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.None)
                                
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
                    cell.iconHeight.constant = 1
                    cell.icon.hidden = true
                }
            }.onFailure { error in
                print(error)
            }
        }
    }
    
    func computeHeight(imageSize: CGSize) -> CGFloat {
        let ratio = imageSize.height/imageSize.width
        let screenSize: CGRect = UIScreen.mainScreen().bounds
        return screenSize.width * ratio

    }
    
    // Functions for determining table size
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return events.count
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if let image = images[indexPath.row] {
            return computeHeight(image.size) + 100
        }
        return 100
    }
    
    func tableView(tableView: UITableView, estimatedHeightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    // Function for loading data into cells
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCellWithIdentifier("EventTableViewCell", forIndexPath: indexPath) as! EventTableViewCell
        
        let event = events[indexPath.row]
        
        cell.name.text = event.name
        if let city = event.city, let state = event.state {
            cell.location.text = "\(city), \(state)"
        }
        
        if let startDate = event.startTime {
            cell.date.text = startDateFormatter.stringFromDate(startDate)
        }
        
        loadImage(event, cell:cell, indexPath: indexPath)
        
        return cell
    }
    
    // Function for launching event view
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        selectedRow = indexPath
        
        let vc = storyboard?.instantiateViewControllerWithIdentifier("EventViewController") as! EventViewController
        
        let event = events[indexPath.row]

        vc.event = event
        vc.activityVC = self
        
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    @IBAction func newEvent(sender: AnyObject) {
        let vc = storyboard?.instantiateViewControllerWithIdentifier("EventEditViewController") as! EventEditViewController
        
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    // Functions for updating table
    
    func addEvent(event:Event) {
        events.append(event)
        tableView.insertRowsAtIndexPaths([NSIndexPath(forRow: events.count-1, inSection: 0)], withRowAnimation: .Automatic)
    }
    
    func updateEvent(event:Event) {
        tableView.reloadRowsAtIndexPaths([selectedRow], withRowAnimation: .Automatic)
    }
    
    func deleteSelectedEvent() {
        events.removeAtIndex(selectedRow.row)
        tableView.deleteRowsAtIndexPaths([selectedRow], withRowAnimation: .Automatic)
    }
    
}