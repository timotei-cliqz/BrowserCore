//
//  CustomWKWebView.swift
//  BrowserCore
//
//  Created by Tim Palade on 1/17/18.
//  Copyright © 2018 Tim Palade. All rights reserved.
//

import UIKit
import WebKit
import RealmSwift

let LoadProgressNotification = Notification.Name(rawValue: "LoadProgressNotification")
let CanGoBackNotification = Notification.Name("CanGoBackNotification")
let CanGoForwardNotification = Notification.Name("CanGoForwardNotification")
let NewURLNotification = Notification.Name("NewURLNotification")

class CustomWKWebView: WKWebView {
    
    fileprivate var _last_url_string = ""
    
    fileprivate let KVOEstimatedProgress = "estimatedProgress"
    fileprivate let KVOCanGoBack = "canGoBack"
    fileprivate let KVOCanGoForward = "canGoForward"
    fileprivate let KVOUrl = "url" //this does not work, use NSKeyValueObservation instead
    fileprivate let KVOBackForward = "backForwardList"
    fileprivate let KVOTitle = "title"
    
    fileprivate var urlObservation: NSKeyValueObservation?
    
    fileprivate var internalHistory: WebViewHistory? = nil
    
    var isAntiTrackingOn: Bool = false
    
    var isPrivate: Bool {
        return !self.configuration.websiteDataStore.isPersistent
    }
    
    enum CustomResponse {
        case willReload
        case willNotReload
    }
    
    override init(frame: CGRect, configuration: WKWebViewConfiguration) {
    
        super.init(frame: frame, configuration: configuration)
        
        if !self.isPrivate {
            internalHistory = WebViewHistory(webView: self)
        }
        
        self.navigationDelegate = self
        self.uiDelegate = self
        
        self.addObserver(self, forKeyPath: KVOEstimatedProgress, options: .new, context: nil)
        self.addObserver(self, forKeyPath: KVOCanGoBack, options: .new, context: nil)
        self.addObserver(self, forKeyPath: KVOCanGoForward, options: .new, context: nil)
        self.addObserver(self, forKeyPath: KVOTitle, options: .new, context: nil)
        
        urlObservation = self.observe(\.url, changeHandler: {[unowned self] (webView, change) in
            if let url = webView.url, url.absoluteString != self._last_url_string {
                //URL changed.
                debugPrint("new URL = \(url.absoluteString)")
                if self.updateAntitracking(url: url) == .willNotReload {
                    NotificationCenter.default.post(name: NewURLNotification, object: self, userInfo: ["url": url])
                    self.internalHistory?.update()
                }
                self._last_url_string = url.absoluteString
            }
        })
        
        //AdBlocker.shared.enable(on: self)
    }
    
    fileprivate func updateAntitracking(url: URL?) -> CustomResponse {
        
        guard let url = url else { return .willNotReload }
        
        debugPrint("update antitracking url = \(url.absoluteString)")
        
        let shouldAntitrack = DomainBlacklist.shouldAntitrackingBeEnabled(on: url.host)
        
        if shouldAntitrack != isAntiTrackingOn {
            if shouldAntitrack == true {
                Antitracking.shared.enable(on: self)
            } else {
                Antitracking.shared.disable(on: self)
            }
            return .willReload
        }
       
        return .willNotReload
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func prepareDeinit() {
        urlObservation?.invalidate()
        urlObservation = nil
    }
    
    deinit {
        //removal of the url observation needs some time.
        //so remove it before the webview is deinited.
        //since only the Tab Manager is supposed to have a strong reference to a webView
        //remove the urlObservation when removing the webview from the Tab Manager.
        urlObservation?.invalidate()
        urlObservation = nil
        NotificationCenter.default.removeObserver(self)
        self.removeObserver(self, forKeyPath: KVOEstimatedProgress, context: nil)
        self.removeObserver(self, forKeyPath: KVOCanGoBack, context: nil)
        self.removeObserver(self, forKeyPath: KVOCanGoForward, context: nil)
        self.removeObserver(self, forKeyPath: KVOTitle, context: nil)
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        //debugPrint(change ?? "")
        
        if keyPath == KVOEstimatedProgress {
            if let progress = change?[NSKeyValueChangeKey.newKey] as? Double {
                NotificationCenter.default.post(name: LoadProgressNotification, object: self, userInfo: ["progress": progress])
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
        else if keyPath == KVOTitle {
            if let newValue = change?[NSKeyValueChangeKey.newKey] as? String {
                internalHistory?.titleUpdated(new_title: newValue)
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
        //self.internalHistory?.update()
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        debugPrint("didFail")
    }
    
//    func webView(_ webView: WKWebView, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
//        debugPrint("did receive challenge")
//        completionHandler(.cancelAuthenticationChallenge, nil)
//    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        debugPrint("decide policy")
        
        //self.updateAntitracking(url: navigationAction.request.url)
        
        decisionHandler(.allow)
    }
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
