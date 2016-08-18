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
    
    override class var resourceType: ResourceType {
        return "image"
    }
    
    override class var fields: [Field] {
        return fieldsFromDictionary([
            "url": Attribute(),
            "user": ToOneRelationship(User)
            ])
    }
}