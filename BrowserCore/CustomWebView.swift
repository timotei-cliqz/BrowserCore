//
//  CustomWebView.swift
//  BrowserCore
//
//  Created by Tim Palade on 1/5/18.
//  Copyright © 2018 Tim Palade. All rights reserved.
//

import UIKit

let LoadProgressNotification = Notification.Name(rawValue: "LoadProgressNotification")

class CustomWebView: UIWebView {
    
    let internalProgressChangedNotification = "WebProgressEstimateChangedNotification"
    
    var removeProgressObserversOnDeinit: ((UIWebView) -> Void)?
    
    var progress: WebViewProgress?
    fileprivate var _estimatedProgress: Double = 0
    var estimatedProgress: Double {
        get {
            return _estimatedProgress
        }
        
        set {
            debugPrint("estimated progress \(newValue)")
            _estimatedProgress = newValue
            NotificationCenter.default.post(name: LoadProgressNotification, object: nil, userInfo: ["progress": newValue])
        }
    }
    
    override var isLoading: Bool {
        get {
            return estimatedProgress > 0 && estimatedProgress < 0.99
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.delegate = self
        
        progress = WebViewProgress(parent: self)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        self.removeProgressObserversOnDeinit?(self)
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
    
    override func reload() {
        progress?.setProgress(0.3)
        URLCache.shared.removeAllCachedResponses()
        URLCache.shared.diskCapacity = 0
        URLCache.shared.memoryCapacity = 0
        
        super.reload()
    }
    
    override func stopLoading() {
        super.stopLoading()
        self.progress?.reset()
    }
    
}

//MARK: - Progress
extension CustomWebView {
    
    @objc func internalProgressNotification(_ notification: Notification) {
        if let prog = notification.userInfo?["WebProgressEstimatedProgressKey"] as? Double {
            debugPrint("progress - \(prog)")
            if prog > 0.99 {
                loadingCompleted()
                debugPrint("loading done")
                return
            }
            
            if prog > self.estimatedProgress || prog == 0.0 || prog == 0.99 {
                //progress?.setProgress(prog)
            }
        }
    }
    
    func loadingCompleted() {
        
    }
}

extension CustomWebView: UIWebViewDelegate {
    
    func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        
//        if url.host == "itunes.apple.com" {
//            progress?.completeProgress()
//            return false
//        }
        
        return true
    }
    
    func webViewDidStartLoad(_ webView: UIWebView) {
        //progress?.webViewDidStartLoad()
    }
    
    func webViewDidFinishLoad(_ webView: UIWebView) {
        let readyState = stringByEvaluatingJavaScript(from: "document.readyState.toLowerCase()")
        //progress?.webViewDidFinishLoad(readyState)
    }
    
    func webView(_ webView: UIWebView, didFailLoadWithError error: Error) {
        //progress?.didFailLoadWithError()
    }
}
