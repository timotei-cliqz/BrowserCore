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
    
    enum VicinityStatus {
        case Changed
        case NotChanged
        case Undefined
    }
    
    fileprivate unowned var webView: WKWebView
    
    fileprivate var _last_currentIndex = -1 //careful if you want this to access array elements. Always check
    
    fileprivate var timer: Timer? = nil
    
    fileprivate var _last_forward_count = 0
    
    fileprivate var internalList: [HistoryEntry] = []
    
    fileprivate var backCount: Int {
        return self.webView.backForwardList.backList.count
    }
    
    fileprivate var forwardCount: Int {
        return self.webView.backForwardList.forwardList.count
    }
    
    init(webView: WKWebView) {
        self.webView = webView
        super.init()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        timer?.invalidate()
        timer = nil
    }
    
    func titleUpdated(new_title: String) {
        guard let currentItem = webView.backForwardList.currentItem, currentItem.title == new_title else { return }
        let currentIndex = backCount
        guard internalList.isIndexValid(index: currentIndex) else { return }
        modifyHistory(action: .Replace, item: currentItem, currentIndex: currentIndex)
    }

    func update() {
        assert(Thread.isMainThread)
        
        //I waiting for the internal webview history to update
        //I stop it when it something is modified.
        self.startTimer()

        guard let currentItem = webView.backForwardList.currentItem else { return }
        
        let currentIndex = backCount
    
        let list = webView.backForwardList.backList + [currentItem] + webView.backForwardList.forwardList
        
        //debugPrint("currentIndex = \(currentIndex) | forwardCount = \(forwardCount)")
        
        //Branching
        let isCurrentIndexValid = currentIndex >= 0 && currentIndex < internalList.count
        let urlIsDifferent = isCurrentIndexValid == false ? false : currentItem.url != internalList[currentIndex].url
        
        var vicinity: VicinityStatus {
            if internalList.isIndexValid(index: currentIndex + 1) && list.isIndexValid(index: currentIndex + 1) {
                if internalList[currentIndex + 1].url == list[currentIndex + 1].url {
                    return .NotChanged
                }
                else {
                    return .Changed
                }
            }
            
            return .Undefined
        }
        
        if _last_forward_count > 0 && urlIsDifferent && vicinity != .NotChanged {
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
        
        //this makes sure the timer does not run indefinitely.
        //Why does this work?
        //The point of the update is to bring the internalList in sync with the webView history.
        //That means bringing the internalList[currentIndex] to match with the current item in the webview history.
        //One way to check if that has happened is to check the internalList[currentIndex].url agains the webview's url, since the webview's url is the same as the url of the current item in the webview history.
        if internalList.isIndexValid(index: currentIndex) {
            if internalList[currentIndex].url == webView.url {
                stopTimer()
            }
        }
        
    }
    
    fileprivate func modifyHistory(action: WebViewHistoryAction, item: WKBackForwardListItem, currentIndex: Int) {
        
        //Stop the timer
        stopTimer()
        
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
        
//        debugPrint(internalList.map({ (item) -> URL in
//            return item.url
//        }))
    }
}

//Timer
extension WebViewHistory {
    fileprivate func startTimer() {
        guard timer == nil else { return }
        
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true, block: { (timer) in
            self.update()
        })
        timer?.fire()
        //debugPrint("Start Timer")
    }
    
    fileprivate func stopTimer() {
        timer?.invalidate()
        timer = nil
        //debugPrint("Stop Timer")
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
