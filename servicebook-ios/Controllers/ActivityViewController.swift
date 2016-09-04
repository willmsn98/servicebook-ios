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
            cell.iconHeight.constant = image.size.height * image.scale
        }
        //if not cached go download an image
        else {
            let pm = PersistenceManager.sharedInstance
            pm.getImages(event).onSuccess { images in
            
                if images.count > 0, let image:Image = images[0] as? Image, let imageUrl = image.url {
                    
                    let fileName = (imageUrl as NSString).lastPathComponent
                    let screenWidth = Int(UIScreen.mainScreen().bounds.size.width)
                    let url = "https://res.cloudinary.com/hzzpiohnf/image/upload/c_scale,w_\(screenWidth)/v1472620103/\(fileName)"
                    if let url = NSURL(string: url) {
                        
                        //load image
                        cell.icon.af_setImageWithURL(url, completion: { response in
                            if let imageSize  = response.result.value?.size,
                            let imageScale = response.result.value?.scale{
                                
                                //cache image
                                self.images[indexPath.row] = response.result.value
                                
                                dispatch_async(dispatch_get_main_queue(), { () -> Void in

                                    //set height
                                    cell.iconHeight.constant = imageSize.height * imageScale
                                
                                    //reload to change height of row
                                    self.tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.None)
                                })
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
                    cell.iconHeight.constant = 1
                    cell.icon.hidden = true
                }
            }.onFailure { error in
                print(error)
            }
        }
    }
    
    // Functions for determining table size
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return events.count
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if let image = images[indexPath.row] {
            return image.size.height * image.scale + 100
        }
        return 100
    }
    
    func tableView(tableView: UITableView, estimatedHeightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    // Function for loading data into cells
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        guard let cell = tableView.dequeueReusableCellWithIdentifier("EventTableViewCell", forIndexPath: indexPath) as? EventTableViewCell else {
            return UITableViewCell()
        }
        
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
        
        guard let vc = storyboard?.instantiateViewControllerWithIdentifier("EventViewController") as? EventViewController else {
            return
        }
        
        let event = events[indexPath.row]

        vc.event = event
        vc.activityVC = self
        
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    // Function for creating new event
    
    @IBAction func newEvent(sender: AnyObject) {
        guard let vc = storyboard?.instantiateViewControllerWithIdentifier("EventEditViewController") as? EventEditViewController else {
            return
        }
        
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    // Functions for updating table
    
    func addEvent(event:Event) {
        events.append(event)
        images.append(nil)
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