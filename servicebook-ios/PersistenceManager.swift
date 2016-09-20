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

import FacebookCore

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
        spine.keyFormatter = AsIsKeyFormatter()
        registerResources()
        
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
        
        var query = Query(resourceType: Event.self)
        query.include("primaryImage")
        query.addAscendingOrder("startTime") // Sort on creation date
        
        spine.find(query).onSuccess { resources, meta, jsonapi in
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
    
    func setUser(facebookId: String)  -> Future<User, SpineError> {
        
        let promise = Promise<User, SpineError>()

        var query = Query(resourceType: User.self)
        query.whereAttribute("user.facebookId", equalTo: facebookId)
        
        spine.find(query).onSuccess { resources, meta, jsonapi in
            if resources.count > 0 {
                if let user = resources.resources[0] as? User {
                    self.user = user
                    promise.success(user)
                }
            } else {
                self.getFacebookUser().onSuccess(callback: { (user) in
                    let pm = PersistenceManager.sharedInstance
                    pm.save(user).onSuccess(callback: { (user:Resource) in
                        if let user = user as? User {
                            self.user = user
                            promise.success(user)
                        }
                    })
                })
            }
        }.onFailure { error in
            print("Fetching failed: \(error)")
        }
        
        return promise.future
    }
    
    func getFacebookUser() -> Future<User, SpineError> {
        
        let promise = Promise<User, SpineError>()

        let connection = GraphRequestConnection()
        connection.add(UserRequest()) { (response: NSHTTPURLResponse?,
            result: GraphRequestResult<UserRequest>) in
            
            switch result {
            case .Success(let response):
                let user = User()
                user.firstName = response.firstName
                user.lastName = response.lastName
                user.email = response.email
                user.city = response.location
                user.facebookId = response.facebookId
                
                promise.success(user)
                
            case .Failed(let errorType):
                print(errorType)
            }
        }
        connection.start()

        return promise.future
    }
    
    struct UserRequest: GraphRequestProtocol {
        struct Response: GraphResponseProtocol {
            init(rawResponse: AnyObject?) {
                if let response = rawResponse as? Dictionary<String, AnyObject> {
                    if let facebookId = response["id"] as? String {
                        self.facebookId = facebookId
                    }
                    if let firstName = response["first_name"] as? String {
                        self.firstName = firstName
                    }
                    if let lastName = response["last_name"] as? String {
                        self.lastName = lastName
                    }
                    if let email = response["email"] as? String {
                        self.email = email
                    }
                    if let location = response["location"]?["name"] as? String {
                        self.location = location
                    }
                }
            }
            
            var facebookId:String?
            var firstName:String?
            var lastName:String?
            var email:String?
            var location:String?
        }
        
        let graphPath = "me"
        let parameters: [String:AnyObject]? = ["fields":"email,first_name,last_name,location"]
        let accessToken: AccessToken? = AccessToken.current!
        let httpMethod: GraphRequestHTTPMethod = .GET
        let apiVersion = "v2.7"
    }
    
    func getFacebookImage(id:String, height:Int) -> Future<UIImage, NSError> {

        let promise = Promise<UIImage, NSError>()
        
        if let authToken = AccessToken.current?.authenticationToken {
            let url = NSURL(string: "https://graph.facebook.com/me/picture?height=100&return_ssl_resources=1&access_token=\(authToken)")
            let urlRequest = NSURLRequest(URL: url!)
            NSURLConnection.sendAsynchronousRequest(urlRequest, queue: NSOperationQueue.mainQueue()) { (response:NSURLResponse?, data:NSData?, error:NSError?) -> Void in
                
                // Display the image
                if let imageData = data,
                    let image = UIImage(data: imageData) {
                    promise.success(image)
                }
            }
        }
        
        return promise.future
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
    

    func uploadImage(image: UIImage, onCompletion: (status: Bool, image: Image?) -> Void) {
        
        let cloudinary_url = "cloudinary://267883694991746:HqdoshPbLeMiLvVxv2CaRCf2w_w@hzzpiohnf"
        let clouder = CLCloudinary(url:cloudinary_url)
        let forUpload = UIImagePNGRepresentation(image)
        let uploader:CLUploader = CLUploader(clouder, delegate: nil)
        uploader.upload(forUpload, options: nil,
                        withCompletion: { (dataDir, error, code, contect) in

                            let pm = PersistenceManager.sharedInstance
                            
                            let image = Image()
                            image.url = dataDir["url"] as? String ?? ""
                            image.user = pm.user
                            
                            pm.save(image).onSuccess { image in
                                if code < 400, let image = image as? Image {
                                    onCompletion(status: true, image: image)
                                }else{
                                    onCompletion(status: false, image:nil)
                                }
                            }

        }) { (bytesSent, totalBytesSent, totalBytesExpectedToWrite, context) in
            print(bytesSent)
        }
    }

}