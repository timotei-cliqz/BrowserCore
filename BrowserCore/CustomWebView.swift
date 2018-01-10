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

class CustomWebView: UIWebView {
    
    //Possible notifications of interest - DataDetectorsUIDidFinishURLificationNotification
    
    fileprivate var _last_canGoBack: Bool = false
    fileprivate var _last_canGoForward: Bool = false
    
    var timer: Timer = Timer()
    
    lazy var backForwardList: WebViewBackForwardList = { return WebViewBackForwardList.init(webView: self) }()
    
    let internalProgressChangedNotification = "WebProgressEstimateChangedNotification"
    let historyItemsAddedNotification = "WebHistoryItemsAddedNotification"
    
    override var canGoBack: Bool {
        return self.backForwardList.backCount() ?? 0 > 0
    }
    
    override var canGoForward: Bool {
        return self.backForwardList.forwardCount() ?? 0 > 0
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.delegate = self
        
        NotificationCenter.default.addObserver(self, selector: #selector(historyAdded), name: NSNotification.Name(rawValue: historyItemsAddedNotification), object: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func historyAdded(_ notification: Notification) {
        //debugPrint("history added - \(notification)")
        if let historyItems = notification.userInfo?["WebHistoryItems"] as? NSArray {
            for item in historyItems {
                let i = item as AnyObject
                if let url = i.value(forKey: "URL") as? NSURL {
                    debugPrint("history added:\nurl = \(url) | backCount = \(String(describing: self.backForwardList.backCount())) | forwCount =\(String(describing: self.backForwardList.forwardCount()))")
                }
            }
            self.broadcastWebViewValues()
        }
    }
    
}

//MARK: - Method overrides
extension CustomWebView {
    
    override func loadRequest(_ request: URLRequest) {
        
        guard let internalWebView = value(forKeyPath: "documentView.webView") else { return }
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: internalProgressChangedNotification), object: internalWebView)
        NotificationCenter.default.addObserver(self, selector: #selector(internalProgressNotification), name: NSNotification.Name(rawValue: internalProgressChangedNotification), object: internalWebView)
        
        super.loadRequest(request)
    }
    
}

//MARK: - Progress
extension CustomWebView {
    
    @objc func internalProgressNotification(_ notification: Notification) {
        if let prog = notification.userInfo?["WebProgressEstimatedProgressKey"] as? Double {
            //debugPrint("progress - \(prog)")
            NotificationCenter.default.post(name: LoadProgressNotification, object: nil, userInfo: ["progress": prog])
        }
    }

}

extension CustomWebView: UIWebViewDelegate {
    
    func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        broadcastWebViewValues()
        return true
    }
    
    func webViewDidStartLoad(_ webView: UIWebView) {
        broadcastWebViewValues()
    }
    
    func webViewDidFinishLoad(_ webView: UIWebView) {
        broadcastWebViewValues()
    }
    
    func webView(_ webView: UIWebView, didFailLoadWithError error: Error) {
        broadcastWebViewValues()
    }
    
    func broadcastWebViewValues() {
        //if self.canGoForward != _last_canGoForward {
            NotificationCenter.default.post(name: CanGoForwardNotification, object: nil, userInfo: ["value": self.canGoForward])
            _last_canGoForward = self.canGoForward
        //}
        
        //if self.canGoBack != _last_canGoBack {
            NotificationCenter.default.post(name: CanGoBackNotification, object: nil, userInfo: ["value": self.canGoBack])
            _last_canGoBack = self.canGoBack
        //}
    }
}
