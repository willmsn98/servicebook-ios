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
    var facebookId: String?
    
    override class var resourceType: ResourceType {
        return "user"
    }
    
    override class var fields: [Field] {
        
        var fields: [String: Field] = [
            "firstName": Attribute(),
            "lastName": Attribute(),
            "city": Attribute(),
            "state": Attribute(),
            "country": Attribute(),
            "email": Attribute(),
            "phone": Attribute(),
            "facebookId": Attribute(),
            ]
        
        //fields used for querying with Elide
        var emailAttribute = Attribute()
        emailAttribute = emailAttribute.readOnly()
        fields["user.email"] = emailAttribute
        
        var facebookIdAttribute = Attribute()
        facebookIdAttribute = facebookIdAttribute.readOnly()
        fields["user.facebookId"] = facebookIdAttribute
        
        return fieldsFromDictionary(fields)
    }
}