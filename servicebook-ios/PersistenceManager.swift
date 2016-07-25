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
        Spine.setLogLevel(.Debug, forDomain: .Spine)
        Spine.setLogLevel(.Debug, forDomain: .Networking)
        Spine.setLogLevel(.Debug, forDomain: .Serializing)
        
        baseUrl = NSURL(string: "https://servicebook-api.herokuapp.com/")
        spine = Spine(baseURL: baseUrl)
        spine.serializer.keyFormatter = AsIsKeyFormatter()
        registerResources()
        
        setUser("christopher.e.williamson@gmail.com")
    }
    
    func registerResources() {
        spine.registerResource(Event)
        spine.registerResource(User)
        spine.registerResource(Comment)
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
    
    func addComment(text: String, event: Event, user: User) -> Future<[Resource], NSError> {
        
        let promise = Promise<[Resource], NSError>()

        let commentsPath: String = "https://servicebook-api.herokuapp.com/event/\(event.id!)/comments"
        let request: NSMutableURLRequest = NSMutableURLRequest(URL: NSURL(string: commentsPath)!)
                
        request.HTTPMethod = "POST"
        let bodyString="{" +
            "   \"data\": [" +
            "       {" +
            "           \"type\": \"comment\"," +
            "           \"attributes\": {" +
            "               \"text\": \"\(text)\"" +
            "           }," +
            "           \"relationships\": {" +
            "               \"user\": {" +
            "                   \"data\": { \"type\": \"user\", \"id\": \"\(user.id!)\" }" +
            "               }," +
            "               \"event\": {" +
            "                   \"data\": { \"type\": \"event\", \"id\": \"\(event.id!)\" }" +
            "               }" +
            "           }" +
            "       }]}"
        
        let body = bodyString.dataUsingEncoding(NSUTF8StringEncoding)
        
        request.timeoutInterval = 60
        request.HTTPBody=body
        request.HTTPShouldHandleCookies=false
        request.setValue("application/vnd.api+json", forHTTPHeaderField: "Content-Type")

        
        let session = NSURLSession.sharedSession()

        let task = session.dataTaskWithRequest(request) {
            (
            let data, let response, let error) in
            
            guard let _:NSData = data, let _:NSURLResponse = response  where error == nil else {
                promise.failure(error!)
                return
            }
            
            do {
                let comments = try self.spine.serializer.deserializeData(data!)
                promise.success(comments.data ?? [])
            } catch let error as NSError {
                promise.failure(error)
            }
        }
        task.resume()
        
        return promise.future
    }
 
    func getComments(event: Event) -> Future<[Resource], NSError> {
        
        let promise = Promise<[Resource], NSError>()
        
        let commentsPath: String = "https://servicebook-api.herokuapp.com/event/\(event.id!)/comments?include=user"
        let request: NSMutableURLRequest = NSMutableURLRequest(URL: NSURL(string: commentsPath)!)
        
        request.HTTPMethod = "GET"
        request.timeoutInterval = 60
        request.HTTPShouldHandleCookies=false
        request.setValue("application/vnd.api+json", forHTTPHeaderField: "Content-Type")
        
        let session = NSURLSession.sharedSession()
        
        let task = session.dataTaskWithRequest(request) {
            (
            let data, let response, let error) in
            
            guard let _:NSData = data, let _:NSURLResponse = response  where error == nil else {
                promise.failure(error!)
                return
            }
            do {
                let comments = try self.spine.serializer.deserializeData(data!)
                promise.success(comments.data ?? [])
            } catch let error as NSError {
                promise.failure(error)
            }
        }
        task.resume()
        
        return promise.future
    }

}