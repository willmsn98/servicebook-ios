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

import Cloudinary

class PersistenceManager {
    
    static let sharedInstance = PersistenceManager()
    
    var spine: Spine!
    var baseUrl: NSURL!
    var user: User!
    
    init() {
        Spine.setLogLevel(.Error, forDomain: .Spine)
        Spine.setLogLevel(.Error, forDomain: .Networking)
        Spine.setLogLevel(.Error, forDomain: .Serializing)
        
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
        spine.registerResource(Image)

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
    
    func getEvents() -> Future<[Event], SpineError> {
        let promise = Promise<[Event], SpineError>()
        spine.findAll(Event).onSuccess { resources, meta, jsonapi in
            if let events = resources.resources as? [Event] {
                promise.success(events)
            }
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
    
    func addComment(text: String, event: Event, user: User) -> Future<Resource, NSError> {
        
        let promise = Promise<Resource, NSError>()

        let commentsPath: String = "https://servicebook-api.herokuapp.com/comment"
        let request: NSMutableURLRequest = NSMutableURLRequest(URL: NSURL(string: commentsPath)!)
        
        request.HTTPMethod = "POST"
        
        let comment:NSMutableDictionary = NSMutableDictionary()
        comment["type"] = "comment"
        comment["attributes"] = ["text" : text]
        
        let userObj:NSMutableDictionary = NSMutableDictionary()
        userObj["type"] = "user"
        userObj["id"] = user.id
        
        let eventObj:NSMutableDictionary = NSMutableDictionary()
        eventObj["type"] = "event"
        eventObj["id"] = event.id

        let relationships:NSMutableDictionary = NSMutableDictionary()
        relationships["user"] = ["data": userObj]
        relationships["event"] = ["data": eventObj]
        
        comment["relationships"] = relationships

        let body:NSMutableDictionary! = ["data": [comment]]
        
        var requestBody:NSData?
        do {
            requestBody = try NSJSONSerialization.dataWithJSONObject(body, options: NSJSONWritingOptions.PrettyPrinted)
        }catch let error as NSError{
            print(error.description)
        }
        
        request.timeoutInterval = 60
        request.HTTPBody=requestBody
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
                if let comment = comments.data?[0] {
                    promise.success(comment)
                } else {
                    print("Error saving comment")
                }
            } catch let error as NSError {
                promise.failure(error)
            }
        }
        task.resume()
        
        return promise.future
    }
    
    func getComments(event: Event) -> Future<[Comment], NSError> {
        
        let promise = Promise<[Comment], NSError>()
        
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
                promise.success(comments.data as? [Comment] ?? [])
            } catch let error as NSError {
                promise.failure(error)
            }
        }
        task.resume()
        
        return promise.future
    }
    
    func getImages(event: Event) -> Future<[Resource], NSError> {
        
        let promise = Promise<[Resource], NSError>()
        
        let commentsPath: String = "https://servicebook-api.herokuapp.com/event/\(event.id!)/images"
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
                let images = try self.spine.serializer.deserializeData(data!)
                promise.success(images.data ?? [])
            } catch let error as NSError {
                promise.failure(error)
            }
        }
        task.resume()
        
        return promise.future
    }
    
    func addImage(url: String, comment: Comment?, event: Event, user:User) -> Future<Resource, NSError> {
        
        let promise = Promise<Resource, NSError>()
        
        let commentsPath: String = "https://servicebook-api.herokuapp.com/image"
        let request: NSMutableURLRequest = NSMutableURLRequest(URL: NSURL(string: commentsPath)!)
        
        request.HTTPMethod = "POST"
        
        let image:NSMutableDictionary = NSMutableDictionary()
        image["type"] = "image"
        image["attributes"] = ["url" : url]
        
        let relationships:NSMutableDictionary = NSMutableDictionary()

        let userObj:NSMutableDictionary = NSMutableDictionary()
        userObj["type"] = "user"
        userObj["id"] = user.id
        relationships["user"] = ["data": userObj]
        
        let eventObj:NSMutableDictionary = NSMutableDictionary()
        eventObj["type"] = "event"
        eventObj["id"] = event.id
        relationships["event"] = ["data": eventObj]
        
        if let commentId = comment?.id {
            let commentObj:NSMutableDictionary = NSMutableDictionary()
            commentObj["type"] = "comment"
            commentObj["id"] = commentId
            relationships["comment"] = ["data": commentObj]
        }
        
        image["relationships"] = relationships
        
        let body:NSMutableDictionary! = ["data": [image]]
        
        var requestBody:NSData?
        do {
            requestBody = try NSJSONSerialization.dataWithJSONObject(body, options: NSJSONWritingOptions.PrettyPrinted)
        }catch let error as NSError{
            print(error.description)
        }
        
        request.timeoutInterval = 60
        request.HTTPBody=requestBody
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
                let images = try self.spine.serializer.deserializeData(data!)
                if let image = images.data?[0] {
                    promise.success(image)
                } else {
                    print("Error saving image")
                }
            } catch let error as NSError {
                promise.failure(error)
            }
        }
        task.resume()
        
        return promise.future
    }
    

    func uploadImage(image: UIImage, onCompletion: (status: Bool, url: String?) -> Void) {
        
        let cloudinary_url = "cloudinary://267883694991746:HqdoshPbLeMiLvVxv2CaRCf2w_w@hzzpiohnf"
        let clouder = CLCloudinary(url:cloudinary_url)
        let forUpload = UIImagePNGRepresentation(image)
        let uploader:CLUploader = CLUploader(clouder, delegate: nil)
        uploader.upload(forUpload, options: nil,
                        withCompletion: { (dataDir, error, code, contect) in
                            if code < 400 {
                                onCompletion(status: true,url: dataDir["url"] as? String ?? "")
                            }else{
                                onCompletion(status: false,url:"")
                                
                            }
        }) { (bytesSent, totalBytesSent, totalBytesExpectedToWrite, context) in
            print(bytesSent)
        }
    }

}