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

class Result: Codable {
    var url: String?
}

class BeyovaNetTests: XCTestCase {
    
    var client: Client!
    
    override func setUp() {
        super.setUp()
        client = Client(baseURL: "https://httpbin.org")
        client.loggers.append { (request, response, start, data, error) in
            
        }
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testPostForVoid() {
        let expect = expectation(description: "finish")
        let user = User()
        user.name = "John"
        user.age = 10
        client.request(relativeURL: "post", method: .post,parameters: [:], object: user, tokenReqiured: false) { (result: Client._Void?, error) in
            XCTAssertNil(error)
            expect.fulfill()
        }
        waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testPost() {
        let expect = expectation(description: "finish")
        let user = User()
        user.name = "John"
        user.age = 10
        client.request(relativeURL: "post", method: .post,parameters: [:], object: user, tokenReqiured: false) { (result: Result?, error) in
            XCTAssertNil(error)
            XCTAssertNotNil(result?.url)
            expect.fulfill()
        }
        waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testCancelAll() {
        var expects: [XCTestExpectation] = []
        for i in 0..<10 {
            expects.append(expectation(description: "call \(i)"))
            client.request(relativeURL: "delay/10", method: .get, parameters: [:], tokenReqiured: false) { (error) in
                if let err = error {
                    print(err)
                }
                expects[i].fulfill()
            }
        }
        Thread.sleep(forTimeInterval: 1)
        client.cancelAll()
        waitForExpectations(timeout: 10, handler: nil)
    }
}
