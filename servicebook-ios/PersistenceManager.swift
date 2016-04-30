//
//  PersistenceManager.swift
//  servicebook-ios
//
//  Created by Christopher Williamson on 4/26/16.
//  Copyright © 2016 Christopher Williamson. All rights reserved.
//

import Foundation

import Spine

class PersistenceManager {
    
    static let sharedInstance = PersistenceManager()
    
    var spine: Spine!
    var url: NSURL!
    var user: User!
    
    init() {
        Spine.setLogLevel(.Warning, forDomain: .Spine)
        Spine.setLogLevel(.Warning, forDomain: .Networking)
        Spine.setLogLevel(.Warning, forDomain: .Serializing)
        
        url = NSURL(string: "https://servicebook-api.herokuapp.com/")
        
        spine = Spine(baseURL: url)
        registerResources()
        
        setUser("christopher.e.williamson@gmail.com")
    }
    
    func registerResources() {
        spine.registerResource(Event)
        spine.registerResource(User)
    }
    
    func save(resource: Resource) {
        spine.save(resource).onSuccess { _ in
            print("Saving success")
        }.onFailure { error in
            print("Saving failed: \(error)")
        }
    }
    
    func getEvents(setEvents: (ResourceCollection) -> Void) {
        spine.findAll(Event).onSuccess { resources, meta, jsonapi in
                setEvents(resources)
            }.onFailure { error in
                print("Fetching failed: \(error)")
            }
    }
    
    func delete(resource: Resource) {
        spine.delete(resource).onSuccess {
                print("Deleting success")
            }.onFailure { error in
                print("Deleting failed: \(error)")
            }
    }
    
    func setUser(email: String) {
        
        var query = Query(resourceType: User.self)
        query.whereAttribute("user.email", equalTo: email)
        
        spine.find(query).onSuccess { resources, meta, jsonapi in
            if resources.count > 0 {
                self.user = resources.resources[0] as! User
            } else {
                print("No user found: \(email)")
            }
        }.onFailure { error in
            print("Fetching failed: \(error)")
        }
    }
}