//
//  servicebook_iosTests.swift
//  servicebook-iosTests
//
//  Created by Christopher Williamson on 4/21/16.
//  Copyright © 2016 Christopher Williamson. All rights reserved.
//

import Foundation
import XCTest
import Spine
import BrightFutures
import Result

@testable import servicebook_ios

class servicebook_iosTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testEventCRUD() {
        let pm: PersistenceManager = PersistenceManager.sharedInstance
        
        //build event
        var event:Event = Event()
        event.name = "My Event"
        event.address = "123 My Street"
        event.city = "My City"
        event.state = "State"
        event.country = "USA"
        event.owner = pm.user
        
        //create
        pm.save(event).onSuccess{ e1 in
            event = e1 as! Event
            XCTAssertNotNil(event.id)
            
            //update
            event.name = "My Updated Event"
            pm.save(e1).onSuccess { e2 in
                event = e2 as! Event
                XCTAssertEqual(event.name, "My Updated Event")
                
                //getEvents
                pm.getEvents().onSuccess { events in
                    XCTAssertGreaterThan(events.count, 0)
                    
                    //Delete
                    pm.delete(event).onSuccess {
                        XCTAssertTrue(true)
                    }.onFailure { error in
                        XCTFail()
                    }
                    
                }.onFailure { error in
                    XCTFail()
                }
                
            }.onFailure { error in
                XCTFail()
            }
        
        }.onFailure { error in
            XCTFail()
        }
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measureBlock {
            // Put the code you want to measure the time of here.
        }
    }
    
}
