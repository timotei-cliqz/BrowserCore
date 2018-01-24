//
//  TabManager.swift
//  BrowserCore
//
//  Created by Tim Palade on 1/23/18.
//  Copyright © 2018 Tim Palade. All rights reserved.
//

import UIKit

let TabSelectedNotification = Notification.Name("TabSelectedNotification")

class TabManager: NSObject {
    
    static let shared = TabManager()
    
    //typealias Tab = CustomWKWebView
    
    var tabs: [CustomWKWebView] = []
    
    weak var selectedTab: CustomWKWebView? = nil
    
    override init() {
        super.init()
    }
    
    func selectTab(tab: CustomWKWebView) {
        selectedTab = tab
        NotificationCenter.default.post(name: TabSelectedNotification, object: self, userInfo: ["tab": tab])
    }
    
    func addTab() -> CustomWKWebView {
        let tab = CustomWKWebView()
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
