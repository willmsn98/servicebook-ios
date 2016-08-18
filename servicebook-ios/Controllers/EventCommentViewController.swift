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
import DKImagePickerController

class EventCommentViewController: UIViewController {
    
    
    @IBOutlet weak var textView: UITextView!
    
    var activityVC: ActivityViewController!
    var eventVC: EventViewController!
    var event: Event!
    
    var image:UIImage?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    @IBAction func cancel(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: {})
    }
    
    @IBAction func post(sender: AnyObject) {
                
        // update server
        let pm: PersistenceManager = PersistenceManager.sharedInstance
        pm.addComment(textView.attributedText.string, event: event, user: pm.user).onSuccess { comment in
            if self.image != nil {
                let pm = PersistenceManager.sharedInstance
                pm.uploadImage(self.image!, onCompletion: { (status, url) in
                    if url != nil && comment is Comment {
                        pm.addImage(url!, comment: comment as! Comment, event: self.event, user: pm.user).onSuccess { image in
                            print("Saved image")
                        }
                    }
                })
            }
            
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.eventVC.loadComments()
            })
            
            }.onFailure { error in
                print(error)
        }
        
        // update parent controllers
        self.activityVC.updateEvent(self.event)
        self.eventVC.event = self.event
        
        self.dismissViewControllerAnimated(true, completion: {})

    }
    
    @IBAction func choosePicture(sender: AnyObject) {
        let pickerController = DKImagePickerController()
        pickerController.maxSelectableCount = 1
        
        pickerController.didSelectAssets = { (assets: [DKAsset]) in
            if assets.count == 1 {
                let asset = assets[0]
                asset.fetchImageWithSize(CGSize(width: 300, height: 300), completeBlock: { image, info in
                    let attachment = NSTextAttachment()
                    attachment.image = image
                    let attString = NSAttributedString(attachment: attachment)
                    self.textView.textStorage.insertAttributedString(attString, atIndex: self.textView.selectedRange.location)
                    self.image = image

                })
            }
        }
        
        self.presentViewController(pickerController, animated: true) {}
    }
    
}
