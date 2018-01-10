//
//  WebViewBackForwardList.swift
//  BrowserCore
//
//  Created by Tim Palade on 1/8/18.
//  Copyright © 2018 Tim Palade. All rights reserved.
//

import Foundation
import WebKit

class WebViewBackForwardList {
    
    var currentIndex: Int = 0
    weak var webView: CustomWebView?
    
    init(webView: CustomWebView) {
        self.webView = webView
    }
    
    //Possible Notifications -- WebHistoryItemChanged
    
    
    //rules:
    //1. backCount coincides with the index of the current item
    //2. backCount + forwardCount = Index of Last Item = ListCount - 1 (special case: if backCount == forwardCount == 0 then ListCount == 0 || ListCount == 1)
    
    func backCount() -> Int? {
        guard let backCount = webView?.value(forKeyPath: "documentView.webView.backForwardList.backListCount") as? NSNumber else {
            return nil
        }
        
        return backCount.intValue
    }
    
    func forwardCount() -> Int? {
        guard let forwardCount = webView?.value(forKeyPath: "documentView.webView.backForwardList.forwardListCount") as? NSNumber else {
            return nil
        }
        
        return forwardCount.intValue
    }
    
    func currentItemUrl() -> String? {
        guard let currentUrl = webView?.value(forKeyPath: "documentView.webView.backForwardList.currentItem.URL") as? NSString else {
            return nil
        }
        
        return currentUrl as String
    }
    
    func currentTitle() -> String? {
        guard let currentTitle = webView?.value(forKeyPath: "documentView.webView.backForwardList.currentItem.title") as? NSString else {
            return nil
        }
        
        return currentTitle as String
    }

}
