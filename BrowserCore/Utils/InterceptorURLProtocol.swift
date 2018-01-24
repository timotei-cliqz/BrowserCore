//
//  InterceptorURLProtocol.swift
//  BrowserCore
//
//  Created by Tim Palade on 1/17/18.
//  Copyright © 2018 Tim Palade. All rights reserved.
//

import Foundation

class InterceptorURLProtocol: URLProtocol {
    
    static var count = 0
    
    override class func canInit(with request: URLRequest) -> Bool {
        debugPrint("request -- \(String(describing: request))")
        return false
    }
    
    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }
    
    override class func requestIsCacheEquivalent(_ a: URLRequest, to b: URLRequest) -> Bool {
        return super.requestIsCacheEquivalent(a, to: b)
    }
    
    override func startLoading() {
        returnEmptyResponse()
    }
    override func stopLoading() {
        //super.stopLoading()
    }
    
    // MARK: Private helper methods
    fileprivate func returnEmptyResponse() {
        // To block the load nicely, return an empty result to the client.
        // Nice => UIWebView's isLoading property gets set to false
        // Not nice => isLoading stays true while page waits for blocked items that never arrive
        
        guard let url = request.url else { return }
        let response = URLResponse(url: url, mimeType: "text/html", expectedContentLength: 1, textEncodingName: "utf-8")
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Data())
        client?.urlProtocolDidFinishLoading(self)
    }
    
}

