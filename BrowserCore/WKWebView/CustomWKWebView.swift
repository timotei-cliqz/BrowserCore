//
//  CustomWKWebView.swift
//  BrowserCore
//
//  Created by Tim Palade on 1/17/18.
//  Copyright © 2018 Tim Palade. All rights reserved.
//

import UIKit
import WebKit

let LoadProgressNotification = Notification.Name(rawValue: "LoadProgressNotification")
let CanGoBackNotification = Notification.Name("CanGoBackNotification")
let CanGoForwardNotification = Notification.Name("CanGoForwardNotification")
let NewURLNotification = Notification.Name("NewURLNotification")

class CustomWKWebView: WKWebView {
    
    var _last_url_string = ""
    
    let KVOEstimatedProgress = "estimatedProgress"
    let KVOCanGoBack = "canGoBack"
    let KVOCanGoForward = "canGoForward"
    let KVOUrl = "url" //this does not work, use NSKeyValueObservation instead
    let KVOBackForward = "backForwardList"
    
    var urlObservation: NSKeyValueObservation?
    
    fileprivate var internalHistory: WebViewHistory? = nil
    
    override init(frame: CGRect, configuration: WKWebViewConfiguration) {
    
        super.init(frame: frame, configuration: configuration)
        
        internalHistory = WebViewHistory(webView: self)
        
        self.navigationDelegate = self
        self.uiDelegate = self
        
        self.addObserver(self, forKeyPath: KVOEstimatedProgress, options: .new, context: nil)
        self.addObserver(self, forKeyPath: KVOCanGoBack, options: .new, context: nil)
        self.addObserver(self, forKeyPath: KVOCanGoForward, options: .new, context: nil)
        
        urlObservation = self.observe(\.url, changeHandler: {[unowned self] (webView, change) in
            if let url = webView.url, url.absoluteString != self._last_url_string {
                NotificationCenter.default.post(name: NewURLNotification, object: self, userInfo: ["url": url])
                self._last_url_string = url.absoluteString
                self.internalHistory?.urlChanged()
            }
        })
        
        let timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(updateInternalHistory(_:)), userInfo: nil, repeats: true)
        timer.fire()
    }
    
    @objc func updateInternalHistory(_ sender: Any) {
        DispatchQueue.main.async {
            self.internalHistory?.update()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        self.removeObserver(self, forKeyPath: KVOEstimatedProgress, context: nil)
        self.removeObserver(self, forKeyPath: KVOCanGoBack, context: nil)
        self.removeObserver(self, forKeyPath: KVOCanGoForward, context: nil)
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        //debugPrint(change ?? "")
        
        if keyPath == KVOEstimatedProgress {
            if let progress = change?[NSKeyValueChangeKey.newKey] as? Double {
                NotificationCenter.default.post(name: LoadProgressNotification, object: nil, userInfo: ["progress": progress])
            }
        }
        else if keyPath == KVOCanGoBack {
            if let newValue = change?[NSKeyValueChangeKey.newKey] as? Bool {
                NotificationCenter.default.post(name: CanGoBackNotification, object: self, userInfo: ["value": newValue])
            }
        }
        else if keyPath == KVOCanGoForward {
            if let newValue = change?[NSKeyValueChangeKey.newKey] as? Bool {
                NotificationCenter.default.post(name: CanGoForwardNotification, object: self, userInfo: ["value": newValue])
            }
        }
    }
}

extension CustomWKWebView: WKNavigationDelegate {
    
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        debugPrint("didStartProvisionalNavigation")
    }
    
    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        debugPrint("didCommit")
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        debugPrint("didFinish -- \(String(describing: self.url))")
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        debugPrint("didFail")
    }
    
//    func webView(_ webView: WKWebView, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
//        debugPrint("did receive challenge")
//        completionHandler(.cancelAuthenticationChallenge, nil)
//    }
    
//    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
//        debugPrint("decide policy")
//        decisionHandler(.allow)
//    }
//
//    func webView(_ webView: WKWebView, didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation!) {
//        debugPrint("didReceiveServerRedirectForProvisionalNavigation")
//    }
    
}

extension CustomWKWebView: WKUIDelegate {
    
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if navigationAction.targetFrame == nil {
            webView.load(navigationAction.request)
        }
        
        return nil
    }
}
