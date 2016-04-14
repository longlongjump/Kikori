//
//  KikoriTests.swift
//  KikoriTests
//
//  Created by eugene on 4/4/16.
//  Copyright © 2016 Eugene Ovchynnykov. All rights reserved.
//

import XCTest
import Nimble
import Alamofire
import OHHTTPStubs
@testable import Kikori

class KikoriTests: XCTestCase {
    
    override func setUp() {
        
        NSURLSessionConfiguration.defaultSessionConfiguration()
        
        super.setUp()
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    
    func testCanInitWithRequest() {
        let req = NSURLRequest(URL: NSURL(string: "http://google.com")!)
        expect(Kikori.canInitWithRequest(req)) == true
    }
    
    func testCanInitWithRequestRecursiveFail() {
        let req = NSMutableURLRequest(URL: NSURL(string: "http://google.com")!)
        NSURLProtocol.setProperty(true, forKey: Kikori.RecursiveRequestKey, inRequest: req)
        expect(Kikori.canInitWithRequest(req)) == false
    }
    
    func testAFRequest() {
        Kikori.register()
        
        var data: NSData? = nil
        var error: ErrorType? = nil
        request(.GET, "http://google.com").responseData { res in
            switch res.result {
            case let .Success(val):
                data = val
            case let .Failure(err):
                error = err
            }
        }

        expect(error).toEventually(beNil())
        expect(data?.length ?? 0).toEventually(beGreaterThan(1))
    }
    
    func testAFPostRequest() {
        Kikori.register()
        
        var data: NSData? = nil
        var error: ErrorType? = nil
        let params = ["foo": "bar"]
        request(.POST, "https://httpbin.org/post", parameters: params).responseData { res in
            switch res.result {
            case let .Success(val):
                data = val
            case let .Failure(err):
                error = err
            }
        }
        
        expect(error).toEventually(beNil())
        expect(data?.length ?? 0).toEventually(beGreaterThan(1))
    }
    
    
    func testStubRequest() {
        Kikori.register()

        var runned = false
        let responseData = "hello".dataUsingEncoding(NSUTF8StringEncoding)!
        stub(isHost("google.com")) { _ in
            runned = true
            return OHHTTPStubsResponse(data: responseData, statusCode: 200, headers: nil)
        }
        
        var data: NSData? = nil
        var error: ErrorType? = nil
        request(.GET, "http://google.com").responseData { res in
            switch res.result {
            case let .Success(val):
                data = val
            case let .Failure(err):
                error = err
            }
        }
        
        expect(error).toEventually(beNil())
        expect(data?.length ?? 0).toEventually(beGreaterThan(1))
        expect(runned) == true
    }
    
    func testUploadRequest() {
        let config = Kikori.defaultSessionConfiguration
        let session = NSURLSession(configuration: config)
        
        
        var error: ErrorType? = nil
        var completed = false
        let req = NSMutableURLRequest(URL: NSURL(string: "https://httpbin.org/post")!)
        req.HTTPMethod = "POST"
        
        let reqData = "helloworld".dataUsingEncoding(NSUTF8StringEncoding)!
        let task = session.uploadTaskWithRequest(req, fromData: reqData) { (resData, res, err) in
            error = err
            completed = true
        }
        
        task.resume()
        
        expect(error).toEventually(beNil())
        expect(completed).toEventually(beTrue())
    }
    
}
