//
//  Kikori.swift
//  Kikori
//
//  Created by eugene on 4/4/16.
//  Copyright © 2016 Eugene Ovchynnykov. All rights reserved.
//

import Foundation

extension Dictionary {
    var headersDescription: String {
        let valuesArray = self.map { key, value in
            return "    \(key): \(value)"
        }
        
        return "{\n" + valuesArray.joinWithSeparator("\n") + "\n}"
    }
}

extension NSDate {
    var intervalDescription: String {
        return String(format: "[%.04f s]", -timeIntervalSinceNow)
    }
}

extension NSData {
    func stringDescriptionEncoding(encoding: NSStringEncoding) -> String? {
        do {
            let json = try NSJSONSerialization.JSONObjectWithData(self, options: .MutableContainers)
            let pretty = try NSJSONSerialization.dataWithJSONObject(json, options: .PrettyPrinted)
            
            return String(data: pretty, encoding: encoding)
            
        } catch {
            return String(data: self, encoding: encoding)
        }
    }
}

extension NSURLRequest {
    var headersDescription: String {
        let headers = allHTTPHeaderFields ?? [:]
        return headers.headersDescription
    }
    
    var pathDescription: String? {
        if
            let urlPath = URL?.absoluteString,
            let method = HTTPMethod {
            print("\(method) '\(urlPath)'")
        }
        
        return nil
    }
}


extension NSHTTPURLResponse {
    var responseEncoding: NSStringEncoding {
        guard let textEncoding = textEncodingName else { return NSUTF8StringEncoding }
        let iana = CFStringConvertIANACharSetNameToEncoding(textEncoding)
        if (iana != kCFStringEncodingInvalidId) {
            return CFStringConvertEncodingToNSStringEncoding(iana)
        }
        return NSUTF8StringEncoding
    }
}



public class Kikori: NSURLProtocol, NSURLSessionDataDelegate {
    public static let RequestBodyKey = "Kikori.RequestBodyKey"
    public static let RecursiveRequestKey = "Kikori.RecursiveRequestKey"
    
    private var dataTask: NSURLSessionDataTask?
    private var data: NSData?
    private var requestStartTime: NSDate?
    
    private var session: NSURLSession!
    
    public static var defaultLogger = KikoriLogger()
    
    private let logger: KikoriLoggerProtocol = Kikori.defaultLogger
    
    public class var defaultSessionConfiguration: NSURLSessionConfiguration {
        let config = NSURLSessionConfiguration.defaultSessionConfiguration()
        var classes = config.protocolClasses ?? []
        classes.insert(self, atIndex: 0)
        config.protocolClasses = classes
        return config
    }
    
    override init(request: NSURLRequest, cachedResponse: NSCachedURLResponse?, client: NSURLProtocolClient?) {
        super.init(request: request, cachedResponse: cachedResponse, client: client)
        
        let config = self.dynamicType.defaultSessionConfiguration
        session = NSURLSession(configuration: config, delegate: self, delegateQueue: nil)
    }
    
    override public class func canInitWithRequest(request: NSURLRequest) -> Bool {
        guard let _ = request.URL else { return false }
        
        if let _ = NSURLProtocol.propertyForKey(Kikori.RecursiveRequestKey, inRequest: request) {
            return false
        }
        
        return true
    }
    
    public class func register() {
        precondition(NSThread.isMainThread(), "call only from main thread")
        NSURLSessionConfiguration.enableKikoriForDefaultSession(true)
        NSMutableURLRequest.enableSavingHTTPBody(true)
        
        registerClass(self)
    }
    
    public class func unregister() {
        precondition(NSThread.isMainThread(), "call only from main thread")
        NSURLSessionConfiguration.enableKikoriForDefaultSession(false)
        NSMutableURLRequest.enableSavingHTTPBody(false)
        
        unregisterClass(self)
    }
    
    override public class func canonicalRequestForRequest(request: NSURLRequest) -> NSURLRequest {
        return request
    }
    
    override public func startLoading() {
        precondition(dataTask == nil, "previous task has to be ended by this time")
        
        logRequest(request)
        
        guard let newRequest = request.mutableCopy() as? NSMutableURLRequest else { return }
        NSURLProtocol.setProperty(true, forKey: Kikori.RecursiveRequestKey, inRequest: newRequest)
        
        requestStartTime = NSDate()
        
        dataTask = session.dataTaskWithRequest(newRequest)
        dataTask?.resume()
    }
    
    
    override public func stopLoading() {
        dataTask?.cancel()
    }
    
    // MARK: URLSessionDelegate
    
    public func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didReceiveData data: NSData) {
        self.data = data
        client?.URLProtocol(self, didLoadData: data)
    }
    
    
    public func URLSession(session: NSURLSession, task: NSURLSessionTask, didCompleteWithError error: NSError?) {
        if let response = task.response as? NSHTTPURLResponse {
            logResponse(response, data: self.data)
        }
        
        guard let error = error else {
            client?.URLProtocolDidFinishLoading(self)
            return
        }
        
        client?.URLProtocol(self, didFailWithError: error)
    }
    
    // MARK: Logging
    
    public func logRequest(request: NSURLRequest) {
        if let urlPath = request.pathDescription {
            print(urlPath)
        }
        
        logger.log(request.headersDescription)
        
        if let bodyData = NSURLProtocol.propertyForKey(Kikori.RequestBodyKey, inRequest: request) as? NSData ,
            let data = String(data: bodyData, encoding: NSUTF8StringEncoding) {
            logger.log(data)
        }
    }
    
    public func logResponse(response: NSHTTPURLResponse, data: NSData?) {
        if
            let path = request.URL?.absoluteString,
            let date = requestStartTime {
            logger.log("\(response.statusCode) '\(path)' \(date.intervalDescription)")
        }
        
        let headers = response.allHeaderFields ?? [:]
        
        logger.log(headers.headersDescription)
        
        if
            let data = data,
            let stringResponse = data.stringDescriptionEncoding(response.responseEncoding)
        {
            logger.log(stringResponse)
        }
    }
}
