//
//  ViewController.swift
//  BrowserCore
//
//  Created by Tim Palade on 1/5/18.
//  Copyright © 2018 Tim Palade. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    let urlBar = URLBar()
    let webView = CustomWebView()
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
        view.addSubview(progressBar)
        
        progressBar.alpha = 0.0
        progressBar.setProgress(progress: 0.0)
        
        urlBar.textField.text = "https://www.thestar.com"
        
        NotificationCenter.default.addObserver(self, selector: #selector(loadProgressUpdate), name: LoadProgressNotification, object: nil)
    }
    
    func setStyling() {
        
    }
    
    func setConstraints() {
        urlBar.snp.makeConstraints { (make) in
            make.top.left.right.equalToSuperview()
            make.height.equalTo(64)
        }
        
        webView.snp.makeConstraints { (make) in
            make.left.right.bottom.equalToSuperview()
            make.top.equalTo(urlBar.snp.bottom)
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
            self.webView.loadRequest(request)
            self.urlBar.textField.resignFirstResponder()
        }
    }
}

