//
//  Event.swift
//  servicebook-ios
//
//  Created by Christopher Williamson on 4/25/16.
//  Copyright © 2016 Christopher Williamson. All rights reserved.
//

import Foundation
import Spine

// Resource class
class Event: Resource {
    var name: String?
    var details: String?
    var address: String?
    var city: String?
    var state: String?
    var country: String?
    var startTime: NSDate?
    var endTime: NSDate?
    var owner: User?
    //var organization: Organization?
    //var comments: LinkedResourceCollection?
    //var photos: LinkedResourceCollection?
    
    override class var resourceType: ResourceType {
        return "event"
    }
    
    override class var fields: [Field] {
        return fieldsFromDictionary([
            "name": Attribute(),
            "details": Attribute(),
            "address": Attribute(),
            "city": Attribute(),
            "state": Attribute(),
            "country": Attribute(),
            "startTime": DateAttribute(),
            "endTime": DateAttribute(),
            "owner": ToOneRelationship(User)
            //"organization": ToOneRelationship(Organization),
            //"comments": ToManyRelationship(Comment)
            //"photos": ToManyRelationship(Photo)
            ])
    }
}