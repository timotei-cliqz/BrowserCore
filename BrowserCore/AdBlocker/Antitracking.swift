//
//  AdBlocker.swift
//  BrowserCore
//
//  Created by Tim Palade on 2/13/18.
//  Copyright © 2018 Tim Palade. All rights reserved.
//

import UIKit

class Antitracking: NSObject {
    
    static let shared = Antitracking()
    
    override init() {
        super.init()
    }
    
    func enable(on webView: CustomWKWebView) {
        debugPrint("Enabling Antitracking")
        
        webView.isAntiTrackingOn = true
        
        GhosteryBlockListHelper().getBlockLists { lists in
            DispatchQueue.main.async {
                webView.configuration.userContentController.removeAllContentRuleLists()
                lists.forEach(webView.configuration.userContentController.add)
                debugPrint("Antitracking done")
            }
        }
    }
    
    func disable(on webView: CustomWKWebView) {
        debugPrint("Disabling Antitracking")
        webView.isAntiTrackingOn = false
        webView.configuration.userContentController.removeAllContentRuleLists()
    }
    
}
