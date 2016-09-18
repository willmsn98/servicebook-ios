//
//  Image.swift
//  servicebook-ios
//
//  Created by Christopher Williamson on 8/15/16.
//  Copyright © 2016 Christopher Williamson. All rights reserved.
//

import Foundation
import Spine

class Image: Resource {
    
    var url: String?
    var user: User?
    var height:CGFloat?
    var scale:CGFloat?
    
    override class var resourceType: ResourceType {
        return "image"
    }
    
    override class var fields: [Field] {
        return fieldsFromDictionary([
            "url": Attribute(),
            "user": ToOneRelationship(User)
            ])
    }

    func getCloudURL() -> NSURL? {
        guard let imageUrl = self.url else {
            return nil
        }
        
        let fileName = (imageUrl as NSString).lastPathComponent
        let screenWidth = Int(UIScreen.mainScreen().bounds.size.width)
        let url = "https://res.cloudinary.com/hzzpiohnf/image/upload/c_scale,w_\(screenWidth)/v1472620103/\(fileName)"
        
        if let url = NSURL(string: url) {
            return url
        } else {
            print("Illegal URL for \(self.url)")
            return nil
        }
    }
}