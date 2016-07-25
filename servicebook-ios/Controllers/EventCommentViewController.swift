//
//  EventCommentViewController.swift
//  servicebook-ios
//
//  Created by Christopher Williamson on 7/19/16.
//  Copyright © 2016 Christopher Williamson. All rights reserved.
//

import Foundation
import UIKit
import Spine

class EventCommentViewController: UIViewController {
    
    
    @IBOutlet weak var textView: UITextView!
    
    var activityVC: ActivityViewController!
    var eventVC: EventViewController!
    var event: Event!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    @IBAction func cancel(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: {})
    }
    
    @IBAction func post(sender: AnyObject) {
                
        // update server
        let pm: PersistenceManager = PersistenceManager.sharedInstance
        pm.addComment(textView.text!, event: event, user: pm.user).onSuccess { comments in
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.eventVC.loadComments()
            })
            
            }.onFailure { error in
                print(error)
        }
        
        // update parent controllers
        self.activityVC.updateEvent(self.event)
        self.eventVC.event = self.event
    }
}
