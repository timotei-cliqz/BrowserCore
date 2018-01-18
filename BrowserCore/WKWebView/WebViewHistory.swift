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
    
    fileprivate var _last_currentIndex = 0
    
    fileprivate var _url_changed = false
    
    unowned var webView: WKWebView
    
    var _last_forward_count = 0
    
    var backCount: Int {
        return self.webView.backForwardList.backList.count
    }
    
    var forwardCount: Int {
        return self.webView.backForwardList.forwardList.count
    }
    
    init(webView: WKWebView) {
        self.webView = webView
        super.init()
    }
    
    fileprivate var internalList: [HistoryEntry] = []
    
    func urlChanged() {
        _url_changed = true
    }

    func update() {
        
        let currentIndex = backCount
        
        //any change (Add, Replace, Branch), has _url_changed == true as a prerequisite.
        guard _url_changed else { return }
        guard let currentItem = webView.backForwardList.currentItem else { return }
        
        let list = webView.backForwardList.backList + [currentItem] + webView.backForwardList.forwardList
        
        //debugPrint("currentIndex = \(currentIndex) | forwardCount = \(forwardCount)")
        
        //Branching
        let isCurrentIndexValid = currentIndex >= 0 && currentIndex < internalList.count
        let urlIsDifferent = isCurrentIndexValid == false ? false : currentItem.url != internalList[currentIndex].url
        
        if _last_forward_count > 0 && urlIsDifferent {
            //remove everything from currentIndex..<internalList.count
            let number_to_remove = (internalList.count - 1) - currentIndex + 1
            if  number_to_remove >= 0 && number_to_remove <= internalList.count {
                internalList.removeLast(number_to_remove)
            }
            else {
                debugPrint("number_to_remove is wrong. Check, maybe you are missing a case.")
            }
            modifyHistory(action: .Add, item: currentItem, currentIndex: currentIndex)
        }
        else {
            if list.count > internalList.count {
                for i in internalList.count..<list.count {
                    let item = list[i]
                    modifyHistory(action: .Add, item: item, currentIndex: currentIndex)
                }
            }
            else if list.count == internalList.count {
                if urlIsDifferent {
                    modifyHistory(action: .Replace, item: currentItem, currentIndex: currentIndex)
                }
            }
            else {
                //assumption: items are removed only in case of branching
                //so this should be handled above.
            }
        }
        
        _last_forward_count = forwardCount
        _last_currentIndex = currentIndex
        
    }
    
    fileprivate func modifyHistory(action: WebViewHistoryAction, item: WKBackForwardListItem, currentIndex: Int) {
        
        //reset the _url_changed flag
        _url_changed = false
        
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
        
        debugPrint(internalList.map({ (item) -> URL in
            return item.url
        }))
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
