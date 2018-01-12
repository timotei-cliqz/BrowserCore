//
//  WebViewBackForwardList.swift
//  BrowserCore
//
//  Created by Tim Palade on 1/8/18.
//  Copyright © 2018 Tim Palade. All rights reserved.
//

import Foundation

enum GeneralHistoryAction {
    case Add
    case Replace
}

enum WebViewHistoryAction {
    case Add
    case Replace
}

class WebViewBackForwardList {
    
    let historyItemsAddedNotification = "WebHistoryItemsAddedNotification"
    
    weak var webView: WebView?
    
    var internalHistoryItemCount: Int {
        var totalCount = 0
        if self.currentItem() != nil {
            totalCount = (self.backCount() ?? 0) + (self.forwardCount() ?? 0)
        }
        
        return totalCount
    }
    
    var mirroredHistory: [URL] = [] //the mirror is not 100% accurate. In case of branching the entries after the branching point are kept until they are replaced by new entries from the new branch. It does not have to for the history to be recorded correcly in the general history (maybe, not sure yet).
    
    init(webView: WebView) {
        self.webView = webView
        NotificationCenter.default.addObserver(self, selector: #selector(historyAdded), name: NSNotification.Name(rawValue: historyItemsAddedNotification), object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
}

extension WebViewBackForwardList {
    
    @objc func historyAdded(_ notification: Notification) {
        
        if let historyItems = notification.userInfo?["WebHistoryItems"] as? NSArray {
            //Assumption: Only one item in the array, always.
            
            if historyItems.count < 1 {
                return
            }
            
            if historyItems.count > 1 {
                debugPrint("Assumption does not hold. Check")
                NSException.init().raise()
            }
            
            let item = historyItems.firstObject as AnyObject
            let notification_url = item.value(forKey: "URL") as? URL
            
            updateHistory(notification_url: notification_url)
            webView?.broadcastWebViewValues()
        }
        
    }
    
    func updateHistory(notification_url : URL?) {
        guard let backCount = self.backCount(), let forwardCount = self.forwardCount(), backCount >= 0, forwardCount >= 0  else {
            return
        }
        
        let currentItemIndex = backCount
        
        debugPrint("currentItemIndex = \(currentItemIndex)")
        
        if currentItemIndex < mirroredHistory.count {
            //WebViewHistoryAction = Replace
            
            //the underlying internal history should already be updated by this time.
            //this way I can identify in which webView the change took place, by comparing the notification_url with the currentItem_url
            //if they are equal, the change took place here.
            
            //Attention: It can happen that I have the same currentItemUrl in 2 webViews, but the change takes place only in one. Then both will see this as a Replace. This may be a problem when I send a notification about the change. We run the risk of duplication, since both webViews will emit a notification. I can probably add a filter. But I will take care of it later.
            if notification_url == nil {
                //this is just a simple url update.
                modifyHistory(action: .Replace, url: self.currentItemUrl(), currentItemIndex: currentItemIndex)
            }
            else if notification_url != nil {
                if currentItemUrl() == notification_url {
                    modifyHistory(action: .Replace, url: self.currentItemUrl(), currentItemIndex: currentItemIndex)
                }
            }
            
        }
        else if currentItemIndex == mirroredHistory.count {
            //WebViewHistoryAction = Add
            //the currentItemIndex has advanced. 
            modifyHistory(action: .Add, url: self.currentItemUrl(), currentItemIndex: currentItemIndex)
        }
        else {
            debugPrint("Check updateHistory() in WebViewBackForwardList.")
        }
        
        debugPrint("internalHistory = \(mirroredHistory)")
        
    }
    
    func modifyHistory(action: WebViewHistoryAction, url: URL?, currentItemIndex: Int) {
        guard let url = url else { return }
        
        if action == .Add {
            mirroredHistory.append(url)
        }
        else if action == .Replace {
            mirroredHistory[currentItemIndex] = url
        }
        else {
            debugPrint("action not handled")
        }
        
    }
    
}

//API
extension WebViewBackForwardList {
    
    //rules:
    //1. backCount coincides with the index of the current item
    //2. backCount + forwardCount = Index of Last Item = ListCount - 1 (special case: if backCount == forwardCount == 0 then ListCount == 0 || ListCount == 1)
    
    func backCount() -> Int? {
        guard let backCount = webView?.value(forKeyPath: "documentView.webView.backForwardList.backListCount") as? NSNumber else {
            return nil
        }
        
        return backCount.intValue
    }
    
    func forwardCount() -> Int? {
        guard let forwardCount = webView?.value(forKeyPath: "documentView.webView.backForwardList.forwardListCount") as? NSNumber else {
            return nil
        }
        
        return forwardCount.intValue
    }
    
    func currentItemUrl() -> URL? {
        guard let currentUrl = webView?.value(forKeyPath: "documentView.webView.backForwardList.currentItem.URL") as? NSURL else {
            return nil
        }
        
        return currentUrl as URL?
    }
    
    func currentTitle() -> String? {
        guard let currentTitle = webView?.value(forKeyPath: "documentView.webView.backForwardList.currentItem.title") as? NSString else {
            return nil
        }
        
        return currentTitle as String
    }
    
    func currentItem() -> AnyObject? {
        return webView?.value(forKeyPath: "documentView.webView.backForwardList.currentItem") as AnyObject?
    }
    
    func internalList() -> AnyObject? {
        return webView?.value(forKeyPath: "documentView.webView.backForwardList") as AnyObject?
    }
}


//This is for reference only
//
//@objc func historyAdded(_ notification: Notification) {
//    //debugPrint("history added - \(notification)")
//    let obj = notification.object as AnyObject
//    let history = obj.value(forKeyPath: "historyPrivate") as AnyObject
//    let entries = history.value(forKey: "entriesByURL") as AnyObject
//    let list = value(forKeyPath: "documentView.webView.backForwardList") as AnyObject
//    let result = list.item(at: 0)
//    let url = result?.url


//if let historyItems = notification.userInfo?["WebHistoryItems"] as? NSArray {
//    for item in historyItems {
//        let i = item as AnyObject
//        if let url = i.value(forKey: "URL") as? NSURL, let timestamp = i.value(forKey: "lastVisitedTimeInterval") as? TimeInterval {
//            //debugPrint("history added:\nurl = \(url) | backCount = \(String(describing: self.backForwardList.backCount())) | forwCount =\(String(describing: self.backForwardList.forwardCount()))")
//            debugPrint("history added:\nurl = \(url) | timestamp = \(timestamp) | backCount = \(String(describing: self.backForwardList.backCount())) | forwCount = \(String(describing: self.backForwardList.forwardCount()))")
//        }
//    }
//
//}

