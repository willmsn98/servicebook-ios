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
    
    init() {
        Spine.setLogLevel(.Debug, forDomain: .Spine)
        Spine.setLogLevel(.Debug, forDomain: .Networking)
        Spine.setLogLevel(.Debug, forDomain: .Serializing)
        
        url = NSURL(string: "https://servicebook-api.herokuapp.com/")
        
        spine = Spine(baseURL: url)
        registerResources()        
    }
    
    func registerResources() {
        spine.registerResource(Event)
    }
    
    func initTestData() {
        let event: Event = Event()
        event.name = "iOS Test"
        event.address = "100 My Street"
        event.city = "City"
        event.state = "AA"
        event.country = "USA"
        //event.startTime = "1:00PM"
        //event.endTime = "3:00PM"
        save(event)
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
}