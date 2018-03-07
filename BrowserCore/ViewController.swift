//
//  ViewController.swift
//  BrowserCore
//
//  Created by Tim Palade on 1/5/18.
//  Copyright © 2018 Tim Palade. All rights reserved.
//

import UIKit

//This is an important extension
extension Array {
    func isIndexValid(index: Int) -> Bool {
        return index >= 0 && index < self.count
    }
}

class ViewController: UIViewController {
    
    let urlBar = URLBar()
    let toolBar = CIToolBarView()
    let webViewContainer = WebViewContainer()
    let progressBar = ProgressBar()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        setUpComponent()
        setStyling()
        setConstraints()
    }
    
    func setUpComponent() {
        urlBar.delegate = self
        
        addChildViewController(webViewContainer)
        
        view.addSubview(urlBar)
        view.addSubview(webViewContainer.view)
        view.addSubview(toolBar)
        view.addSubview(progressBar)
        
        toolBar.delegate = self
        toolBar.backButton.isEnabled = false
        toolBar.forwardButton.isEnabled = false
        
        progressBar.alpha = 0.0
        progressBar.setProgress(progress: 0.0)
        
        urlBar.textField.text = webViewContainer.url()?.absoluteString ?? "https://"
        
        NotificationCenter.default.addObserver(self, selector: #selector(loadProgressUpdate), name: LoadProgressNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(canGoForwardUpdate), name: CanGoForwardNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(canGoBackUpdate), name: CanGoBackNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(newUrlNotification), name: NewURLNotification, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(tabChanged), name: TabSelectedNotification, object: nil)
    }
    
    func setStyling() {
        
    }
    
    func setConstraints() {
        urlBar.snp.makeConstraints { (make) in
            make.top.equalTo(self.view.snp.topMargin)
            make.left.right.equalToSuperview()
            make.height.equalTo(44)
        }
        
        toolBar.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.bottom.equalTo(self.view.snp.bottomMargin)
            make.height.equalTo(50)
        }
        
        webViewContainer.view.snp.remakeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.top.equalTo(urlBar.snp.bottom)
            make.bottom.equalTo(toolBar.snp.top)
        }
        
        progressBar.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.top.equalTo(urlBar.snp.bottom)
            make.height.equalTo(4)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
}

//Tab
extension ViewController {
    @objc func tabChanged(_ notification: Notification) {
        if let _ = TabManager.shared.selectedTab {
            self.progressBar.setProgress(progress: 0.0)
            self.progressBar.alpha = 0.0
            self.toolBar.backButton.isEnabled = webViewContainer.canGoBack()
            self.toolBar.forwardButton.isEnabled = webViewContainer.canGoForward()
            self.urlBar.textField.text = webViewContainer.url() != nil ? webViewContainer.url()?.absoluteString : "https://"
        }
    }
}

//progress
extension ViewController {
    @objc func loadProgressUpdate(_ notification: Notification) {
        if let p = notification.userInfo?["progress"] as? Double, let tab = notification.object as? CustomWKWebView, tab == TabManager.shared.selectedTab {
            UIView.animate(withDuration: 0.1, animations: {

                if p != 1.0  && p != 0.0 {
                    self.progressBar.alpha = 1.0
                }
                
                self.progressBar.setProgress(progress: Float(p))
                self.view.layoutIfNeeded()
            }, completion: { (finished) in
                if p == 1.0 {
                    UIView.animate(withDuration: 0.8, animations: {
                        self.progressBar.alpha = 0.0
                        self.view.layoutIfNeeded()
                    })
                }
            })
        }
    }
}

extension ViewController {
    
    @objc func canGoForwardUpdate(_ notification: Notification) {
        if let value = notification.userInfo?["value"] as? Bool, let tab = notification.object as? CustomWKWebView, tab == TabManager.shared.selectedTab {
            debugPrint("canGoForward - \(value)")
            toolBar.forwardButton.isEnabled = value
        }
    }
    @objc func canGoBackUpdate(_ notification: Notification) {
        if let value = notification.userInfo?["value"] as? Bool, let tab = notification.object as? CustomWKWebView, tab == TabManager.shared.selectedTab {
            debugPrint("canGoBack - \(value)")
            toolBar.backButton.isEnabled = value
        }
    }
    
    @objc func newUrlNotification(_ notification: Notification) {
        if let url = notification.userInfo?["url"] as? URL, let tab = notification.object as? CustomWKWebView, tab == TabManager.shared.selectedTab {
            self.urlBar.textField.text = url.absoluteString
        }
    }
}

extension ViewController: URLBarDelegate {
    func urlBackPressed() {
        
    }
    
    func urlClearPressed(){
        
    }
    
    func urlSearchPressed() {
        
    }
    
    func urlSearchTextChanged() {
        
    }
    
    func urlReturnPressed() {
        if let url_str = self.urlBar.textField.text, let url = URIFixup.getURL(url_str) {
            let request = URLRequest(url: url)
            self.webViewContainer.load(request: request)
            self.urlBar.textField.resignFirstResponder()
        }
    }
}

extension ViewController: CIToolBarDelegate {
    func backPressed() {
        self.webViewContainer.goBack()
    }
    
    func forwardPressed() {
        self.webViewContainer.goForward()
    }
    
    func middlePressed() {
        let tab = TabManager.shared.addTab(privateTab: false)
        TabManager.shared.selectTab(tab: tab)
    }
    
    func sharePressed() {
        let tabOverview = TabOverview()
        self.present(tabOverview, animated: true, completion: nil)
    }
    
    func tabsPressed() {
        let historyController = HistoryController()
        historyController.delegate = self
        self.present(historyController, animated: true, completion: nil)
    }
}

extension ViewController: HistoryControllerDelegate {
    func didPressUrl(url: URL) {
        self.webViewContainer.load(request: URLRequest(url: url))
    }
}
