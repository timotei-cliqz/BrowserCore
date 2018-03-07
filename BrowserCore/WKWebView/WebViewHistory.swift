//
//  WebViewHistory.swift
//  BrowserCore
//
//  Created by Tim Palade on 1/17/18.
//  Copyright © 2018 Tim Palade. All rights reserved.
//

import UIKit
import WebKit

struct HistoryEntry {
    var url: URL
    var title: String
    var timestamp: Date //use this to uniquely identify an entry in the General History
}

class WebViewHistory: NSObject {
    
    fileprivate unowned var webView: WKWebView
    
    fileprivate var _last_forward_count = 0
    
    fileprivate var internalList: [HistoryEntry] = []
    
    fileprivate let updateQueue = OperationQueue()
    
    fileprivate var backCount: Int {
        return self.webView.backForwardList.backList.count
    }
    
    fileprivate var forwardCount: Int {
        return self.webView.backForwardList.forwardList.count
    }
    
    init(webView: WKWebView) {
        self.webView = webView
        super.init()
        updateQueue.name = "Update Queue"
        updateQueue.maxConcurrentOperationCount = 1
        updateQueue.underlyingQueue = DispatchQueue.main
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func titleUpdated(new_title: String) {
        guard let currentItem = webView.backForwardList.currentItem, currentItem.title == new_title else { return }
        let currentIndex = backCount
        guard internalList.isIndexValid(index: currentIndex) else { return }
        modifyHistory(action: .Replace, item: currentItem, currentIndex: currentIndex)
    }

    func update() {
        assert(Thread.isMainThread)
        
        guard let currentItem = webView.backForwardList.currentItem else { return }
        
        //I want to execute code only when the webview is updated.
        //currentItem.url == webView.url seems to be the proper way to determine whether the webView has updated or not.
        if currentItem.url == webView.url {
            debugPrint("WebView is updated")
            debugPrint("WebViewURL = \(String(describing: webView.url))")
            
            let currentIndex = backCount
            let list = webView.backForwardList.backList + [currentItem] + webView.backForwardList.forwardList
            
            if list.count < internalList.count {
                //Branched for sure.
                debugPrint("Branch | list < internal")
                let number_to_remove = (internalList.count - 1) - currentIndex + 1
                if  number_to_remove >= 0 && number_to_remove <= internalList.count {
                    internalList.removeLast(number_to_remove)
                }
                else {
                    debugPrint("number_to_remove is wrong. Check, maybe you are missing a case.")
                }
                modifyHistory(action: .Add, item: currentItem, currentIndex: currentIndex)
            }
            else if list.count == internalList.count {
                //here are 2 possibilities. Either a replace or a branch.
                //this check is necessary to elimintate entries from pressing back and forward, for the Branch case. And to make sure we don't replace unncecessarily, for the Replace case.
                if internalList.isIndexValid(index: currentIndex), webView.url != internalList[currentIndex].url {
                    if _last_forward_count > 0 { //this is true of back and forward
                        debugPrint("Branch | _last_current = \(_last_forward_count) | currentIndex = \(currentIndex)")
                        internalList.removeLast()
                        modifyHistory(action: .Add, item: currentItem, currentIndex: currentIndex)
                    }
                    else {
                        debugPrint("Replace")
                        modifyHistory(action: .Replace, item: currentItem, currentIndex: currentIndex)
                    }
                }
            }
            else if list.count > internalList.count {
                //for sure an add.
                debugPrint("Add")
                for i in internalList.count..<list.count {
                    let item = list[i]
                    modifyHistory(action: .Add, item: item, currentIndex: currentIndex)
                }
            }
            
            _last_forward_count = forwardCount
            
            //make sure I have updated the internal list properly
            #if DEBUG
            assert(internalList.count == list.count)
            #endif
            //Update happened. No need to wait anymore.
            updateQueue.cancelAllOperations()
            
            //KEEP RETURN HERE!
            return
        }
        
        //Use queue to wait for the internal webview history to update
        updateQueue.addOperation {
            self.update()
        }
    
    }
    
    fileprivate func modifyHistory(action: WebViewHistoryAction, item: WKBackForwardListItem, currentIndex: Int) {
        
        if action == .Add {
            let entry = internalList.appendItem(item: item)
            //send Add notification
            NotificationCenter.default.post(name: HistoryAddNotification, object: nil, userInfo: ["url": entry.url, "title": entry.title, "timestamp": entry.timestamp])
        }
        else if action == .Replace {
            let currentUrl = internalList[currentIndex].url
            let entry = internalList.modifyItem(index: currentIndex, with: item)
            //send Replace notification
            if let entry = entry {
                NotificationCenter.default.post(name: HistoryReplaceNotification, object: nil, userInfo: ["new_url": entry.url, "old_url": currentUrl, "title": entry.title, "timestamp": entry.timestamp])
            }
        }
    }
}


extension Array where Element == HistoryEntry {
    mutating func appendItem(item: WKBackForwardListItem) -> HistoryEntry {
        let internalItem = HistoryEntry(url: item.url, title: item.title ?? "", timestamp: Date())
        self.append(internalItem)
        return internalItem
    }
    
    mutating func modifyItem(index: Int, with item: WKBackForwardListItem) -> HistoryEntry? {
        guard index >= 0 && index <= self.count else { return nil }
        var internalItem = self[index]
        internalItem.url = item.url
        internalItem.title = item.title ?? ""
        self[index] = internalItem
        return internalItem
    }
}
