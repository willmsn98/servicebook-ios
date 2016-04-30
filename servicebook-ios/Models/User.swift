//
//  User.swift
//  servicebook-ios
//
//  Created by Christopher Williamson on 4/29/16.
//  Copyright © 2016 Christopher Williamson. All rights reserved.
//

import Foundation

import Spine

// Resource class
class User: Resource {
    var firstName: String?
    var lastName: String?
    var city: String?
    var state: String?
    var country: String?
    var email: String?
    var phone: String?
    
    override class var resourceType: ResourceType {
        return "user"
    }
    
    override class var fields: [Field] {
        return fieldsFromDictionary([
            "firstName": Attribute(),
            "lastName": Attribute(),
            "city": Attribute(),
            "state": Attribute(),
            "country": Attribute(),
            "user.email": Attribute(),
            "phone": Attribute()
            ])
    }
}