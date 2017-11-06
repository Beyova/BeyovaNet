//
//  BeyovaNetTests.swift
//  BeyovaNetTests
//
//  Copyright © 2017 Beyova. All rights reserved.
//

import XCTest
@testable import BeyovaNet

class User: Codable {
    init() {}
    var name: String = ""
    var age: Int = 0
}

class BeyovaNetTests: XCTestCase {
    
    let client = Client(baseURL: "https://httpbin.org/post")
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testExample() {
        
        let user = User()
        user.name = "John"
        user.age = 10
        client.request(relativeURL: "/", method: HTTPMethod.post, parameters: [:], object: user, tokenReqiured: false) { (result, error) in
            
        }
    }
}
