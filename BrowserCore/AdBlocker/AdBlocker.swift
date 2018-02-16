//
//  AdBlocker.swift
//  BrowserCore
//
//  Created by Tim Palade on 2/13/18.
//  Copyright © 2018 Tim Palade. All rights reserved.
//

import UIKit

class AdBlocker {
    unowned let webView: CustomWKWebView
    
    init(webView: CustomWKWebView) {
        self.webView = webView
    }
    
    func enable() {
        debugPrint("Enabling AdBlocker")
        ContentBlockerHelper.shared.getBlockLists { lists in
            debugPrint("lists - Done")
            DispatchQueue.main.async {
                debugPrint("adding the blocklists to the webView")
                self.webView.configuration.userContentController.removeAllContentRuleLists()
                lists.forEach(self.webView.configuration.userContentController.add)
            }
        }
    }
    
    func disable() {
        self.webView.configuration.userContentController.removeAllContentRuleLists()
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
