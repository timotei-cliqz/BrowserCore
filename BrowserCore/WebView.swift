//
//  CustomWebView.swift
//  BrowserCore
//
//  Created by Tim Palade on 1/5/18.
//  Copyright © 2018 Tim Palade. All rights reserved.
//

import UIKit
import WebKit

let LoadProgressNotification = Notification.Name(rawValue: "LoadProgressNotification")
let CanGoBackNotification = Notification.Name("CanGoBackNotification")
let CanGoForwardNotification = Notification.Name("CanGoForwardNotification")

let NewURLNotification = Notification.Name("NewURLNotification")

class WebView: UIWebView {
    
    //Possible notifications of interest - DataDetectorsUIDidFinishURLificationNotification
    
    fileprivate var _last_canGoBack: Bool = false
    fileprivate var _last_canGoForward: Bool = false
    fileprivate var _last_url_string: String = ""
    
    var timer: Timer = Timer()
    
    lazy var backForwardList: WebViewBackForwardList = { return WebViewBackForwardList.init(webView: self) }()
    
    let internalProgressChangedNotification = "WebProgressEstimateChangedNotification"
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.delegate = self
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

//MARK: - Method overrides
extension WebView {
    
    override func loadRequest(_ request: URLRequest) {
        
        guard let internalWebView = value(forKeyPath: "documentView.webView") else { return }
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: internalProgressChangedNotification), object: internalWebView)
        NotificationCenter.default.addObserver(self, selector: #selector(internalProgressNotification), name: NSNotification.Name(rawValue: internalProgressChangedNotification), object: internalWebView)
        
        super.loadRequest(request)
    }
    
}

//MARK: - Progress
extension WebView {
    
    @objc func internalProgressNotification(_ notification: Notification) {
        if let prog = notification.userInfo?["WebProgressEstimatedProgressKey"] as? Double {
            //debugPrint("progress - \(prog)")
            NotificationCenter.default.post(name: LoadProgressNotification, object: nil, userInfo: ["progress": prog])
        }
    }

}

extension WebView: UIWebViewDelegate {
    
    func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        broadcastWebViewValues()
        return true
    }
    
    func webViewDidStartLoad(_ webView: UIWebView) {
        broadcastWebViewValues()
    }
    
    func webViewDidFinishLoad(_ webView: UIWebView) {
        backForwardList.updateHistory(notification_url: nil)
        broadcastWebViewValues()
    }
    
    func webView(_ webView: UIWebView, didFailLoadWithError error: Error) {
        broadcastWebViewValues()
    }
    
    func broadcastWebViewValues() {
        if self.canGoForward != _last_canGoForward {
            NotificationCenter.default.post(name: CanGoForwardNotification, object: self, userInfo: ["value": self.canGoForward])
            _last_canGoForward = self.canGoForward
        }
        
        if self.canGoBack != _last_canGoBack {
            NotificationCenter.default.post(name: CanGoBackNotification, object: self, userInfo: ["value": self.canGoBack])
            _last_canGoBack = self.canGoBack
        }
        
        if let url = self.backForwardList.currentItemUrl()?.absoluteString, url != _last_url_string {
            NotificationCenter.default.post(name: NewURLNotification, object: self, userInfo: ["url": url])
            _last_url_string = url
        }
        
    }
}
