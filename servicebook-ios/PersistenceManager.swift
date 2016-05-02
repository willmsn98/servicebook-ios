//
//  PersistenceManager.swift
//  servicebook-ios
//
//  Created by Christopher Williamson on 4/26/16.
//  Copyright © 2016 Christopher Williamson. All rights reserved.
//

import Foundation

import Spine
import BrightFutures

class PersistenceManager {
    
    static let sharedInstance = PersistenceManager()
    
    var spine: Spine!
    var baseUrl: NSURL!
    var user: User!
    
    init() {
        Spine.setLogLevel(.Warning, forDomain: .Spine)
        Spine.setLogLevel(.Warning, forDomain: .Networking)
        Spine.setLogLevel(.Warning, forDomain: .Serializing)
        
        baseUrl = NSURL(string: "https://servicebook-api.herokuapp.com/")
        spine = Spine(baseURL: baseUrl)
        registerResources()
        
        setUser("christopher.e.williamson@gmail.com")
    }
    
    func registerResources() {
        spine.registerResource(Event)
        spine.registerResource(User)
    }
    
    func save(resource: Resource) -> Future<Resource, SpineError> {
        let promise = Promise<Resource, SpineError>()
        spine.save(resource).onSuccess { resource in
            promise.success(resource)
        }.onFailure { error in
            promise.failure(error)
            print("Saving failed: \(error)")
        }
        return promise.future
    }
    
    func getEvents() -> Future<ResourceCollection, SpineError> {
        let promise = Promise<ResourceCollection, SpineError>()
        spine.findAll(Event).onSuccess { resources, meta, jsonapi in
                promise.success(resources)
            }.onFailure { error in
                promise.failure(error)
                print("Fetching failed: \(error)")
            }
        return promise.future
    }
    
    func delete(resource: Resource) -> Future<Void, SpineError> {
        let promise = Promise<Void, SpineError>()
        spine.delete(resource).onSuccess {
                promise.success()
                print("Deleting success")
            }.onFailure { error in
                promise.failure(error)
                print("Deleting failed: \(error)")
            }
        return promise.future
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