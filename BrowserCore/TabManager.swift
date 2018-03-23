//
//  TabManager.swift
//  BrowserCore
//
//  Created by Tim Palade on 1/23/18.
//  Copyright © 2018 Tim Palade. All rights reserved.
//

import UIKit
import WebKit

let TabSelectedNotification = Notification.Name("TabSelectedNotification")

class TabManager: NSObject {
    
    static let shared = TabManager()
    
    //typealias Tab = CustomWKWebView
    
    var tabs: [CustomWKWebView] = []
    
    weak var selectedTab: CustomWKWebView? = nil
    
    // A WKWebViewConfiguration used for normal tabs
    lazy fileprivate var normalConfiguration: WKWebViewConfiguration = {
        let configuration = WKWebViewConfiguration()
        configuration.processPool = WKProcessPool()
        configuration.preferences.javaScriptCanOpenWindowsAutomatically = true
        configuration.userContentController.add(URLInterceptor.shared, name: "cliqzTrackingProtection")
        configuration.userContentController.add(URLInterceptor.shared, name: "cliqzTrackingProtectionPostLoad")
        return configuration
    }()
    
    // A WKWebViewConfiguration used for private mode tabs
    lazy fileprivate var privateConfiguration: WKWebViewConfiguration = {
        let configuration = WKWebViewConfiguration()
        configuration.processPool = WKProcessPool()
        configuration.preferences.javaScriptCanOpenWindowsAutomatically = false
        configuration.websiteDataStore = WKWebsiteDataStore.nonPersistent()
        configuration.userContentController.add(URLInterceptor.shared, name: "cliqzTrackingProtection")
        configuration.userContentController.add(URLInterceptor.shared, name: "cliqzTrackingProtectionPostLoad")
        return configuration
    }()
    
    override init() {
        super.init()
    }
    
    func selectTab(tab: CustomWKWebView) {
        selectedTab = tab
        NotificationCenter.default.post(name: TabSelectedNotification, object: self, userInfo: ["tab": tab])
    }
    
    func addTab(privateTab: Bool) -> CustomWKWebView {
        
        let tab: CustomWKWebView
        
        if privateTab {
            tab = CustomWKWebView(frame: CGRect.zero, configuration: privateConfiguration)
        }
        else {
            tab = CustomWKWebView(frame: CGRect.zero, configuration: normalConfiguration)
        }
        
        self.tabs.append(tab)
        return tab
    }
    
    func removeTab(tab: CustomWKWebView) {
        
        var index = 0
        
        for _tab in tabs {
            if _tab == tab {
                tab.snp.removeConstraints()
                tab.removeFromSuperview()
                tab.prepareDeinit()
                tabs.remove(at: index)
                break
            }
            index += 1
        }
        
    }
}
