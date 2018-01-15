//
//  GeneralHistoryModule.swift
//  BrowserCore
//
//  Created by Tim Palade on 1/15/18.
//  Copyright © 2018 Tim Palade. All rights reserved.
//

import UIKit
import RealmSwift

class GeneralHistoryModule: NSObject {
    
    static let shared = GeneralHistoryModule()
    
    override init() {
        super.init()
        NotificationCenter.default.addObserver(self, selector: #selector(historyAdded), name: HistoryAddNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(historyModified), name: HistoryReplaceNotification, object: nil)
    }
    
    func getVisits() -> Results<Entry> {
        return RealmStore.getVisits()
    }
}

extension GeneralHistoryModule {
    @objc func historyAdded(_ notification: Notification) {
        guard let dict = notification.userInfo, let url = dict["url"] as? URL, let title = dict["title"] as? String, let timestamp = dict["timestamp"] as? Date else { return }
        RealmStore.addVisitSync(url: url.absoluteString, title: title, date: timestamp)
    }
    
    @objc func historyModified(_ notification: Notification) {
        guard let dict = notification.userInfo, let new_url = dict["new_url"] as? URL, let title = dict["title"] as? String, let timestamp = dict["timestamp"] as? Date else { return }
        RealmStore.modifyVisit(new_url: new_url.absoluteString, new_title: title, timeStamp: timestamp)
    }
}
