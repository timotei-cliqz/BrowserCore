//
//  WebViewContainer.swift
//  BrowserCore
//
//  Created by Tim Palade on 1/24/18.
//  Copyright © 2018 Tim Palade. All rights reserved.
//

import UIKit

class WebViewContainer: UIViewController {
    
    fileprivate weak var currentWebView: CustomWKWebView?
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        if let tab = TabManager.shared.selectedTab {
            currentWebView = tab
        }
        else {
            //create tab and select
            let tab = TabManager.shared.addTab()
            TabManager.shared.selectTab(tab: tab)
            currentWebView = tab
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(tabChanged), name: TabSelectedNotification, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        if let webView = currentWebView {
            view.addSubview(webView)
            setWebViewConstraints()
        }
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if let tab = TabManager.shared.selectedTab {
            if tab != currentWebView {
                replaceWebView(newWebView: tab)
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    fileprivate func setWebViewConstraints() {
        currentWebView?.snp.remakeConstraints({ (make) in
            make.left.right.top.bottom.equalToSuperview()
        })
    }

}
//Public API
extension WebViewContainer {
    func load(request: URLRequest) {
        currentWebView?.load(request)
    }
    
    func goBack() {
        currentWebView?.goBack()
    }
    
    func goForward() {
        currentWebView?.goForward()
    }
    
    func url() -> URL? {
        return currentWebView?.url
    }
    
    func title() -> String? {
        return currentWebView?.title
    }
    
    func canGoBack() -> Bool {
        return currentWebView?.canGoBack ?? false
    }
    
    func canGoForward() -> Bool {
        return currentWebView?.canGoForward ?? false 
    }
}


//Change tab
extension WebViewContainer {
    
    @objc fileprivate func tabChanged(_ notification: Notification) {
        if let tab = TabManager.shared.selectedTab, tab != currentWebView {
            replaceWebView(newWebView: tab)
        }
    }
    
    fileprivate func replaceWebView(newWebView: CustomWKWebView) {
        
        currentWebView?.snp.removeConstraints()
        currentWebView?.removeFromSuperview()
        self.view.addSubview(newWebView)
        currentWebView = newWebView
        self.view.sendSubview(toBack: newWebView)
        setWebViewConstraints()
    }
    
}
