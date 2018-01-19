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
    let webView = CustomWKWebView()
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
        
        view.addSubview(urlBar)
        view.addSubview(webView)
        view.addSubview(toolBar)
        view.addSubview(progressBar)
        
        toolBar.delegate = self
        toolBar.backButton.isEnabled = false
        toolBar.forwardButton.isEnabled = false
        
        progressBar.alpha = 0.0
        progressBar.setProgress(progress: 0.0)
        
        urlBar.textField.text = "https://www.google.de"
        
        NotificationCenter.default.addObserver(self, selector: #selector(loadProgressUpdate), name: LoadProgressNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(canGoForwardUpdate), name: CanGoForwardNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(canGoBackUpdate), name: CanGoBackNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(newUrlNotification), name: NewURLNotification, object: nil)
    }
    
    func setStyling() {
        
    }
    
    func setConstraints() {
        urlBar.snp.makeConstraints { (make) in
            make.top.left.right.equalToSuperview()
            make.height.equalTo(64)
        }
        
        toolBar.snp.makeConstraints { (make) in
            make.left.right.bottom.equalToSuperview()
            make.height.equalTo(50)
        }
        
        webView.snp.makeConstraints { (make) in
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

//progress
extension ViewController {
    @objc func loadProgressUpdate(_ notification: Notification) {
        if let p = notification.userInfo?["progress"] as? Double {
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
        if let value = notification.userInfo?["value"] as? Bool{
            //debugPrint("canGoForward - \(value)")
            toolBar.forwardButton.isEnabled = value
        }
    }
    @objc func canGoBackUpdate(_ notification: Notification) {
        if let value = notification.userInfo?["value"] as? Bool {
            //debugPrint("canGoBack - \(value)")
            toolBar.backButton.isEnabled = value
        }
    }
    
    @objc func newUrlNotification(_ notification: Notification) {
        if let url = notification.userInfo?["url"] as? URL {
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
        if let url_str = self.urlBar.textField.text, let url = URL(string: url_str) {
            let request = URLRequest(url: url)
            self.webView.load(request)
            self.urlBar.textField.resignFirstResponder()
        }
    }
}

extension ViewController: CIToolBarDelegate {
    func backPressed() {
        self.webView.goBack()
    }
    
    func forwardPressed() {
        self.webView.goForward()
    }
    
    func middlePressed() {
        
    }
    
    func sharePressed() {
        
    }
    
    func tabsPressed() {
        let historyController = HistoryController()
        self.present(historyController, animated: true, completion: nil)
    }
}

