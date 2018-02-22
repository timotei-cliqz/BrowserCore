//
//  AdBlocker.swift
//  BrowserCore
//
//  Created by Tim Palade on 2/13/18.
//  Copyright © 2018 Tim Palade. All rights reserved.
//

import UIKit

class AdBlocker: NSObject {
    
    static let shared = AdBlocker()
    
    override init() {
        super.init()
    }
    
    func enable(on webView: CustomWKWebView) {
        debugPrint("Enabling AdBlocker")
        ContentBlockerHelper.shared.getBlockLists { lists in
            debugPrint("lists - Done")
            DispatchQueue.main.async {
                debugPrint("adding the blocklists to the webView")
                webView.configuration.userContentController.removeAllContentRuleLists()
                lists.forEach(webView.configuration.userContentController.add)
            }
        }
        setupUserScripts(on: webView)
    }
    
    func disable(on webView: CustomWKWebView) {
        webView.configuration.userContentController.removeAllContentRuleLists()
        webView.configuration.userContentController.removeAllUserScripts()
    }
    
    fileprivate func setupUserScripts(on webView: CustomWKWebView) {

        let source = try! String(contentsOf: Bundle.main.url(forResource: "preload", withExtension: "js")!)
        let script = WKUserScript(source: source, injectionTime: .atDocumentStart, forMainFrameOnly: true)
        webView.configuration.userContentController.addUserScript(script)
        
        let source2 = try! String(contentsOf: Bundle.main.url(forResource: "postload", withExtension: "js")!)
        let script2 = WKUserScript(source: source2, injectionTime: .atDocumentEnd, forMainFrameOnly: false)
        webView.configuration.userContentController.addUserScript(script2)
    }
}

extension AdBlocker: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        
        guard let body = message.body as? [String: String], let urlString = body["url"], let pageUrl = body["location"] else { return }
        
        guard var components = URLComponents(string: urlString) else { return }
        components.scheme = "http"
        guard let url = components.url else { return }
        
        //here: check if it is blocked.
        //debugPrint("page = \(page)")
        let timestamp = Date().timeIntervalSince1970
        //TODO: Maybe 2 tabs are loading requests at the same time. This works with the assumption that there is only one tab loading at one time.
        //Added code in TabManager that makes sure this assumption holds.

        if let pageURL = URL(string: pageUrl) {
            let _ = TrackerList.instance.isTracker(url, pageUrl: pageURL, timestamp: timestamp)
        }
        
        let array = TrackerList.instance.detectedTrackersForPage(pageUrl).map({ (app) -> String in
            return app.name
        })
        debugPrint("urlString = \(urlString)")
        debugPrint("mainDocURL = \(pageUrl) | trackers = \(array) | count = \(array.count)")
        
    }
}


/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import WebKit

class ContentBlockerHelper {
    static let shared = ContentBlockerHelper()
    
    var handler: (([WKContentRuleList]) -> Void)? = nil
    
    func reload() {
        guard let handler = handler else { return }
        getBlockLists(callback: handler)
    }
    
    func getBlockLists(callback: @escaping ([WKContentRuleList]) -> Void) {
        let enabledList = ["ghostery_content_blocker"]
        var returnList = [WKContentRuleList]()
        let dispatchGroup = DispatchGroup()
        let listStore = WKContentRuleListStore.default()
        
        for list in enabledList {
            dispatchGroup.enter()
            
            listStore?.lookUpContentRuleList(forIdentifier: list) { (ruleList, error) in
                if let ruleList = ruleList {
                    returnList.append(ruleList)
                    dispatchGroup.leave()
                } else {
                    ContentBlockerHelper.compileItem(item: list) { ruleList in
                        returnList.append(ruleList)
                        dispatchGroup.leave()
                    }
                }
            }
        }
        
        dispatchGroup.notify(queue: .global()) {
            callback(returnList)
        }
    }
    
    private static func compileItem(item: String, callback: @escaping (WKContentRuleList) -> Void) {
        let path = Bundle.main.path(forResource: item, ofType: "json")!
        guard let jsonFileContent = try? String(contentsOfFile: path, encoding: String.Encoding.utf8) else { fatalError("Rule list for \(item) doesn't exist!") }
        debugPrint(item)
        WKContentRuleListStore.default().compileContentRuleList(forIdentifier: item, encodedContentRuleList: jsonFileContent) { (ruleList, error) in
            guard let ruleList = ruleList else { fatalError("problem compiling \(item)") }
            callback(ruleList)
        }
    }
}
