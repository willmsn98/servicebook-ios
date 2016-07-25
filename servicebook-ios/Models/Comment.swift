//
//  Comment.swift
//  servicebook-ios
//
//  Created by Christopher Williamson on 7/19/16.
//  Copyright © 2016 Christopher Williamson. All rights reserved.
//

import Foundation
import Spine

class Comment: Resource {
    
    var text: String?
    var user: User?

    override class var resourceType: ResourceType {
        return "comment"
    }
    
    override class var fields: [Field] {
        return fieldsFromDictionary([
            "text": Attribute(),
            "user": ToOneRelationship(User)
            ])
    }
}
