//
//  WebRequest.swift
//  Client
//
//  Created by Sam Macbeth on 21/02/2017.
//  Copyright © 2017 Mozilla. All rights reserved.
//

import Foundation
import React

@objc(WebRequest)
open class WebRequest : RCTEventEmitter {
    
    var tabs = NSMapTable<AnyObject, AnyObject>.strongToWeakObjects()
    var requestSerial = 0
    var blockingResponses = [Int: NSDictionary]()
    var lockSemaphore: DispatchSemaphore = DispatchSemaphore(value: 0)
    var ready = false
    
    public override init() {
        super.init()
        URLProtocol.registerClass(InterceptorURLProtocol.self)
    }
    
    open override static func moduleName() -> String! {
        return "WebRequest"
    }
    
    override open func supportedEvents() -> [String]! {
        return ["webRequest"]
    }
    
    func shouldBlockRequest(_ request: URLRequest) -> Bool {

        let requestInfo = getRequestInfo(request)
        
        let response = Engine.sharedInstance.getBridge().callAction("webRequest", args: [requestInfo as AnyObject])
        if let blockResponse = response["result"] as? NSDictionary, blockResponse.count > 0 {
            print("xxxxx -> block \(request) -- \(String(describing: request.httpBody))")
            NotificationCenter.default.post(name: Notification.Name(rawValue: "NSNotificationBlockedRequest"), object: nil)
            return true
        }
        
        return false
    }
    
    func newTabCreated(_ tabId: Int, webView: UIView) {
        tabs.setObject(webView, forKey: NSNumber(value: tabId as Int))
    }
    
    @objc(isWindowActive:resolve:reject:)
    func isWindowActive(_ tabId: NSNumber, resolve: RCTPromiseResolveBlock, reject: RCTPromiseRejectBlock) -> Void {
        let active = isTabActive(tabId.intValue)
        resolve(active)
    }
    
    
    //MARK: - Private Methods
    fileprivate func isTabActive(_ tabId: Int) -> Bool {
        return tabs.object(forKey: tabId as AnyObject) != nil
    }
    
    fileprivate func getRequestInfo(_ request: URLRequest) -> [String: AnyObject] {
        let requestId = requestSerial;
        requestSerial += 1;
        let url = request.url?.absoluteString
        let userAgent = request.allHTTPHeaderFields?["User-Agent"]
        
        let isMainDocument = request.url == request.mainDocumentURL
        let tabId = getTabId(userAgent)
        let isPrivate = false
        let originUrl = request.mainDocumentURL?.absoluteString
        
        var requestInfo = [String: AnyObject]()
        requestInfo["id"] = requestId as AnyObject
        requestInfo["url"] = url as AnyObject
        requestInfo["method"] = request.httpMethod as AnyObject
        requestInfo["tabId"] = tabId as AnyObject
        requestInfo["parentFrameId"] = -1 as AnyObject
        // TODO: frameId how to calculate
        requestInfo["frameId"] = tabId as AnyObject
        requestInfo["isPrivate"] = isPrivate as AnyObject
        requestInfo["originUrl"] = originUrl as AnyObject
        let contentPolicyType = ContentPolicyDetector.sharedInstance.getContentPolicy(request, isMainDocument: isMainDocument)
        requestInfo["type"] = contentPolicyType as AnyObject;
        requestInfo["source"] = originUrl as AnyObject;
        
        requestInfo["requestHeaders"] = request.allHTTPHeaderFields as AnyObject
        return requestInfo
    }
    
    open class func generateUniqueUserAgent(_ baseUserAgent: String, tabId: Int) -> String {
        let uniqueUserAgent = baseUserAgent + String(format:" _id/%06d", tabId)
        return uniqueUserAgent
    }
    
    fileprivate func getTabId(_ userAgent: String?) -> Int? {
        guard let userAgent = userAgent else { return nil }
        guard let loc = userAgent.range(of: "_id/") else {
            // the first created webview doesn't have the id, because at this point there is no way to get the user agent automatically
            return 1
        }
        let tabIdString = userAgent.substring(with: loc.upperBound..<userAgent.index(loc.upperBound, offsetBy:6))//loc.endIndex.advancedBy(6)
        guard let tabId = Int(tabIdString) else { return nil }
        return tabId
    }
    
    fileprivate func toJSONString(_ anyObject: AnyObject) -> String? {
        do {
            if JSONSerialization.isValidJSONObject(anyObject) {
                let jsonData = try JSONSerialization.data(withJSONObject: anyObject, options: JSONSerialization.WritingOptions(rawValue: 0))
                let jsonString = String(data:jsonData, encoding: String.Encoding.utf8)!
                return jsonString
            } else {
                print("[toJSONString] the following object is not valid JSON: \(anyObject)")
            }
        } catch let error as NSError {
            print("[toJSONString] JSON conversion of: \(anyObject) \n failed with error: \(error)")
        }
        return nil
    }
    
}
