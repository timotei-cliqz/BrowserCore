//
//  InterceptorURLProtocol.swift
//  Client
//
//  Created by Mahmoud Adam on 8/12/16.
//  Copyright © 2016 Mozilla. All rights reserved.
//

import UIKit
import WebKit

class WebViewToUAMapper {
    static fileprivate let idToWebview = NSMapTable<AnyObject, AnyObject>(keyOptions: NSPointerFunctions.Options(), valueOptions:  NSPointerFunctions.Options.weakMemory)//NSMapTable(keyOptions: NSPointerFunctions.Options(), valueOptions: .weakMemory)
    
    static func setId(_ uniqueId: Int, webView: WKWebView) {
        objc_sync_enter(self)
        defer { objc_sync_exit(self) }
        idToWebview.setObject(webView, forKey: uniqueId as AnyObject)
    }
    
    static func removeWebViewWithId(_ uniqueId: Int) {
        objc_sync_enter(self)
        defer { objc_sync_exit(self) }
        idToWebview.removeObject(forKey: uniqueId as AnyObject)
    }
    
    static func idToWebView(_ uniqueId: Int?) -> WKWebView? {
        return idToWebview.object(forKey: uniqueId as AnyObject) as? WKWebView
    }
    
    static func userAgentToWebview(_ userAgent: String?) -> WKWebView? {
        // synchronize code from this point on.
        objc_sync_enter(self)
        defer { objc_sync_exit(self) }
        
        guard let userAgent = userAgent else { return nil }
        guard let loc = userAgent.range(of: "_id/") else {
            // the first created webview doesn't have this id set (see webviewBuiltinUserAgent to explain)
            return idToWebview.object(forKey: 1 as AnyObject) as? WKWebView
        }
        let keyString = userAgent.substring(with: loc.upperBound..<userAgent.index(loc.upperBound,offsetBy:6))
        guard let key = Int(keyString) else { return nil }
        return idToWebview.object(forKey: key as AnyObject) as? WKWebView
    }
}


public extension String {
    public func contains(_ other: String) -> Bool {
        // rangeOfString returns nil if other is empty, destroying the analogy with (ordered) sets.
        if other.isEmpty {
            return true
        }
        return self.range(of: other) != nil
    }
    
    public func startsWith(_ other: String) -> Bool {
        // rangeOfString returns nil if other is empty, destroying the analogy with (ordered) sets.
        if other.isEmpty {
            return true
        }
        if let range = self.range(of: other,
                                          options: NSString.CompareOptions.anchored) {
            return range.lowerBound == self.startIndex
        }
        return false
    }
    
    public func endsWith(_ other: String) -> Bool {
        // rangeOfString returns nil if other is empty, destroying the analogy with (ordered) sets.
        if other.isEmpty {
            return true
        }
        if let range = self.range(of: other,
                                          options: [NSString.CompareOptions.anchored, NSString.CompareOptions.backwards]) {
            return range.upperBound == self.endIndex
        }
        return false
    }
    
//    func escape() -> String {
//        let raw: NSString = self as NSString
//        let str = CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,
//                                                          raw,
//                                                          "[]." as CFString,":/?&=;+!@#$()',*" as CFString,
//                                                          CFStringConvertNSStringEncodingToEncoding(String.Encoding.utf8))
//        return str as String
//    }
//    
//    func unescape() -> String {
//        let raw: NSString = self as NSString
//        let str = CFURLCreateStringByReplacingPercentEscapes(kCFAllocatorDefault, raw, "[]." as CFString)
//        return String(str)
//    }
    
    /**
     Ellipsizes a String only if it's longer than `maxLength`
     
     "ABCDEF".ellipsize(4)
     // "AB…EF"
     
     :param: maxLength The maximum length of the String.
     
     :returns: A String with `maxLength` characters or less
     */
    func ellipsize( _ maxLength: Int) -> String {
        if (maxLength >= 2) && (self.characters.count > maxLength) {
            let index1 = self.characters.index(self.startIndex, offsetBy: (maxLength + 1) / 2) // `+ 1` has the same effect as an int ceil
            let index2 = self.characters.index(self.endIndex, offsetBy: maxLength / -2)
            
            return self.substring(to: index1) + "…\u{2060}" + self.substring(from: index2)
        }
        return self
    }
    
    fileprivate var stringWithAdditionalEscaping: String {
        return self.replacingOccurrences(of: "|", with: "%7C", options: NSString.CompareOptions(), range: nil)
    }
    
    public var asURL: URL? {
        // Firefox and NSURL disagree about the valid contents of a URL.
        // Let's escape | for them.
        // We'd love to use one of the more sophisticated CFURL* or NSString.* functions, but
        // none seem to be quite suitable.
        return URL(string: self) ??
            URL(string: self.stringWithAdditionalEscaping)
    }
    
    /// Returns a new string made by removing the leading String characters contained
    /// in a given character set.
    public func stringByTrimmingLeadingCharactersInSet(_ set: CharacterSet) -> String {
        var trimmed = self
        while trimmed.rangeOfCharacter(from: set)?.lowerBound == trimmed.startIndex {
            trimmed.remove(at: trimmed.startIndex)
        }
        return trimmed
    }
}



class InterceptorURLProtocol: URLProtocol {
    
    static let customURLProtocolHandledKey = "customURLProtocolHandledKey"
    static let excludeUrlPrefixes = ["https://lookback.io/api", "http://localhost"]
    
    //MARK: - NSURLProtocol handling
    override class func canInit(with request: URLRequest) -> Bool {
        print("Intercepted Request: \(String(describing: request.description))")//\(request) -- \(String(describing: request.allHTTPHeaderFields?.debugDescription)) -- 
        
//        guard (
//            URLProtocol.property(forKey: customURLProtocolHandledKey, in: request) == nil
//             && request.mainDocumentURL != nil) else {
//            return false
//        }
//        guard isExcludedUrl(request.url) == false else {
//            return false
//        }
//        guard BlockedRequestsCache.sharedInstance.hasRequest(request) == false else {
//            return true
//        }
//        
//        if Engine.sharedInstance.getWebRequest().shouldBlockRequest(request) == true {
//            
//            BlockedRequestsCache.sharedInstance.addBlockedRequest(request)
//            
//            return true
//        }
        
        return false
        
    }
    
    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }
    
    override class func requestIsCacheEquivalent(_ a: URLRequest, to b: URLRequest) -> Bool {
        return super.requestIsCacheEquivalent(a, to: b)
    }
    
    override func startLoading() {
        BlockedRequestsCache.sharedInstance.removeBlockedRequest(self.request)
        returnEmptyResponse()
    }
    override func stopLoading() {
    
    }
    
    
    //MARK: - private helper methods
    class func isExcludedUrl(_ url: URL?) -> Bool {
        if let scheme = url?.scheme, !scheme.startsWith("http") {
            return true
        }

        if let urlString = url?.absoluteString {
            for prefix in excludeUrlPrefixes {
                if urlString.startsWith(prefix) {
                    return true
                }
            }
        }
        
        return false
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


