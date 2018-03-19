//
//  URLInterceptor.swift
//  BrowserCore
//
//  Created by Tim Palade on 3/19/18.
//  Copyright © 2018 Tim Palade. All rights reserved.
//

import WebKit

class URLInterceptor: NSObject {
    static let shared = URLInterceptor()
}

extension URLInterceptor: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        
        guard let body = message.body as? [String: String], let urlString = body["url"], let pageUrl = body["location"] else { return }
        
        guard var components = URLComponents(string: urlString) else { return }
        components.scheme = "http"
        guard let url = components.url else { return }
        
        let timestamp = Date().timeIntervalSince1970
        
        if let pageURL = URL(string: pageUrl) {
            let _ = TrackerList.instance.isTracker(url, pageUrl: pageURL, timestamp: timestamp)
        }
    }
}
