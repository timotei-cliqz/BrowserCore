//
//  TrackerList.swift
//  GhosteryBrowser
//
//  Created by Joe Swindler on 2/10/16.
//  Copyright © 2016 Ghostery. All rights reserved.
//

import Foundation
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}

let trackersLoadedNotification = Notification.Name(rawValue:"TrackersLoadedNotification")

@objc class TrackerList : NSObject {
    static let instance = TrackerList()
    
    static let BugEntityName = "Bug"
    static let BlockAttributeName = "block"
    static let AppIdAttributeName = "aid"
    static let BlockedTrackerListChangedNotification = "BlockedTrackerListChangedNotification"
    
    var apps = [Int: TrackerListApp]()   // App ID is the key
    var bugs = [Int: Int]()              // Bug ID is the key, AppId is the value
    var app2bug = [Int: [Int]]()           // App ID is the key, Bug ID array is the value
    var hosts = TrackerListHosts()
    var hostPaths = TrackerListHostPaths()
    var regexes = [TrackerListRegex]()
    var paths = [TrackerListPath]()
    var discoveredBugs = [String: PageTrackersFound]() // Page URL is the key

    // MARK: - Tracker List Initialization
    
    func loadTrackerList() {
        // Check version of tracker list.
        if let url = URL(string: "https://cdn.ghostery.com/update/version") {
            let task = URLSession.shared.dataTask(with: url, completionHandler: { (data, response, error) in
                if error == nil && data != nil {
                    do {
                        if let json = try JSONSerialization.jsonObject(with: data!, options: []) as? [String: AnyObject] {
                            if let publishedVersion = json["bugsVersion"] as? NSNumber {
                                let localVersion = UserPreferences.instance.trackerListVersion()
                                //let localVersion = UserDefaults.standard.integer(forKey: "TrackerListVersion")
                                if publishedVersion.intValue > localVersion {
                                    // List is out of date. Update it.
                                    self.downloadTrackerList()
                                }
                                else {
                                    // load local copy
                                    self.loadLocalTrackerList()
                                }
                            }
                        }
                    }
                    catch {
                        NSLog("Couldn't download tracker list version number.")
                        // load local copy
                        self.loadLocalTrackerList()
                    }
                }
                else {
                    // load local copy
                    self.loadLocalTrackerList()
                }
            })
            task.resume()
        }
    }
    
    func localTrackerFileURL() -> URL? {
        let documentsURLs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return documentsURLs.first?.appendingPathComponent("bugs.json")
    }

    func downloadTrackerList() {
        // Download tracker list from server.
        if let url = URL(string: "https://cdn.ghostery.com/update/v3/bugs") {
            let task = URLSession.shared.dataTask(with: url, completionHandler: { (data, response, error) in
                if error == nil && data != nil {
                    // save json file to documents directory
                    if let filePath = self.localTrackerFileURL()?.path {
                        FileManager.default.createFile(atPath: filePath, contents: data, attributes: nil)
                    }
                    
                    self.loadTrackerList(data!)
                }
                else {
                    NSLog("Tracker list download failed.")
                }
            })
            task.resume()
        }
    }

    func loadLocalTrackerList() {
        if let filePath = self.localTrackerFileURL()?.path {
            if FileManager.default.fileExists(atPath: filePath) {
                if let data = try? Data.init(contentsOf: URL(fileURLWithPath: filePath)) {
                    loadTrackerList(data)
                }
            }
            else {
                print("File does not exist.")
            }
        }
    }
    
    func loadTrackerList(_ data: Data) {
        do {
            if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: AnyObject] {
                if let versionNum = json["version"] as? NSNumber {
                    // save version to preferences
                    UserDefaults.standard.set(versionNum.intValue, forKey: "TrackerListVersion")
                    UserDefaults.standard.synchronize()
                    UserPreferences.instance.setTrackerListVersion(versionNum)
                    UserPreferences.instance.writeToDisk()
                }
                
                if let appData = json["apps"] as? [String: AnyObject] {
                    loadApps(appData)
                }
                
                if let bugData = json["bugs"] as? [String: AnyObject] {
                    loadBugs(bugData)
                }
                
                if let patternData = json["patterns"] as? [String: AnyObject] {
                    if let hostData = patternData["host"] as? [String: AnyObject] {
                        hosts.populate(hostData)
                    }
                    
                    if let hostPathData = patternData["host_path"] as? [String: AnyObject] {
                        hostPaths.populate(hostPathData)
                    }
                    
                    if let pathData = patternData["path"] as? [String: NSNumber] {
                        loadPaths(pathData)
                    }
                    
                    if let regexData = patternData["regex"] as? [String: String] {
                        loadRegexes(regexData)
                    }
                }
                
                debugPrint("Tracker data loaded.")
                NotificationCenter.default.post(name: trackersLoadedNotification, object: nil)
            }
        }
        catch {
            NSLog("Unable to process tracker list.")
        }
    }

    func loadApps(_ data: [String: AnyObject]) {
        for (key, valueObject) in data {
            if let appId = Int(key) {
                if let value = valueObject as? [String: AnyObject] {
                    self.apps[appId] = TrackerListApp(id: appId, jsonData: value)
                }
            }
        }
    }

    func loadBugs(_ data: [String: AnyObject]) {
        for (key, valueObject) in data {
            if let bugId = Int(key) {
                if let value = valueObject as? [String: NSNumber] {
                    if let appId = value["aid"] {
                        bugs[bugId] = appId.intValue
                        if let _ = app2bug[appId.intValue] {
                            app2bug[appId.intValue]?.append(bugId)
                        }
                        else {
                            app2bug[appId.intValue] = [bugId]
                        }
                    }
                }
            }
        }
    }

    func loadPaths(_ data: [String: NSNumber]) {
        for (key, value) in data {
            paths.append(TrackerListPath(path: key, bugId: value.intValue))
        }
    }

    func loadRegexes(_ data: [String: String]) {
        for (key, value) in data {
            if let bugId = Int(key) {
                regexes.append(TrackerListRegex(bugId: bugId, regex: value))
            }
        }
    }
    
    // MARK: - Debugging

    func printContents() -> String {
        var output = "\n------------APPS------------\n"
        for (_, value) in apps {
            output += value.printContents()
        }

        output += "\n------------BUGS------------\n"
        for (key, value) in bugs {
            output += "\(key): \(value)\n"
        }

        output += "\n------------HOST------------\n"
        output += hosts.printContents()

        output += "\n------------HOST PATH------------\n"
        output += hostPaths.printContents()

        output += "\n------------REGEX------------\n"
        for item in regexes {
            output += item.printContents()
        }

        output += "\n------------PATH------------\n"
        for item in paths {
            output += item.printContents()
        }

        return output
    }
    
    func printPageTrackerList() -> String {
        var output = "\n----------TRACKERS FOUND----------\n"
        for (pageUrl, trackerList) in discoveredBugs {
            output += "\n----------PAGE " + pageUrl + "----------\n"
            output += trackerList.printContents()
        }

        return output
    }
    
    // MARK: - Tracker Matching
    
    func isTracker(_ checkUrl: URL, pageUrl: URL, timestamp: Double) -> TrackerListBug? {
        let bugId = isTracker(checkUrl, pageUrl: pageUrl)
        if bugId >= 0 {
            if let trackerBug = addDiscoveredTracker(bugId, bugUrl: checkUrl, pageUrl: pageUrl, timestamp: timestamp) {
                // Fire notification that the tracker list changed and subscribe to it in BugListViewController.
                let trackerApp = trackerAppFromBug(trackerBug)
                NotificationCenter.default.post(name: Notification.Name(rawValue: TrackerList.BlockedTrackerListChangedNotification),
                                                                          object: trackerApp)

                return trackerBug
            }
        }
        
        // not a tracker
        return nil
    }

    func addDiscoveredTracker(_ bugId: Int, bugUrl: URL, pageUrl: URL, timestamp: Double) -> TrackerListBug? {
        let appId = appIdFromBugId(bugId)
        if (appId >= 0) {
            let pageUrlString = pageUrl.absoluteString
            var pageTrackers = discoveredBugs[pageUrlString]
            if pageTrackers == nil {
                // add a tracker list for this page
                pageTrackers = PageTrackersFound()
            }
            
            // add the tracker to the list for the page
            let trackerBug = TrackerListBug(bugId: bugId, appId: appId, url: bugUrl.absoluteString)
            trackerBug.timestamp = timestamp
            
            // see if this one should be blocked
            if shouldBlockTracker(appId) {
                trackerBug.isBlocked = true
            }

            pageTrackers?.addTracker(trackerBug)
            
            // update the list
            discoveredBugs[pageUrlString] = pageTrackers

            return trackerBug
        }
        
        //print("Total trackers: \(pageTrackers.count)")
        return nil
    }
    
    fileprivate func isTracker(_ checkUrl: URL, pageUrl: URL) -> Int {
        //print("Checking \(checkUrl)")
        guard let urlHost = checkUrl.host else {
            // no host
            return -1
        }

        let urlPath = checkUrl.path
        var reverseHost = urlHost.components(separatedBy: ".")
        reverseHost = reverseHost.reversed()

        
        // Skip host matching to prevent blocking the initial page request.
        // Doing this should also cover first party exceptions.
        if urlHost == pageUrl.host {
            //print("Ignoring because host matches")
            return -1
        }
        
        if urlHost.hasSuffix("ghostery.com") {
            // let Ghostery endpoint calls through
            return -1
        }
        
        // Match host and path
        var bugId = hostPaths.isMatch(reverseHost, path: urlPath)
        if bugId >= 0  {
            //print("HOST PATH TRACKER FOUND")
            return bugId
        }
        
        // Match host
        bugId = hosts.isMatch(reverseHost)
        if bugId >= 0 {
            //print("HOST TRACKER FOUND")
            return bugId
        }

        // Match path
        bugId = isPathMatch(urlPath)
        if bugId >= 0 {
            //print("PATH TRACKER FOUND")
            return bugId
        }
        
        // Match regex
        bugId = isRegexMatch(urlHost + urlPath)

        return bugId
    }

    func isPathMatch(_ path: String) -> Int {
        if path.characters.count < 2 {
            // empty or '/'
            return -1
        }
        
        for pathItem in paths {
            if path.contains(pathItem.path) {
                return pathItem.bugId
            }
        }
        
        // not found
        return -1
    }
    
    func isRegexMatch(_ hostAndPath: String) -> Int {
        for regexItem in regexes {
            do {
                let regex = try NSRegularExpression(pattern: regexItem.regex, options: .caseInsensitive)
                let range = NSMakeRange(0, hostAndPath.characters.count)
                let matches = regex.firstMatch(in: hostAndPath, options: [], range: range)
                if matches != nil && matches?.numberOfRanges > 0 {
                    // match found
                    return regexItem.bugId
                }
            }
            catch {
                print("Regex item exception")
            }
        }
        
        // not found
        return -1
    }
    
    func appIdFromBugId(_ bugId: Int) -> Int {
        if let appId = bugs[bugId] {
            return appId
        }

        // Not found--should only happen if the bug list is not loaded for some reason.
        return -1
    }
    
    func clearTrackersForPage(_ pageUrl: String) {
        discoveredBugs.removeValue(forKey: pageUrl)
    }
    
    func globalTrackerList() -> [TrackerListApp] {
        // return the list of all trackers
        var appList = [TrackerListApp]()
        for (_, trackerApp) in apps {
            trackerApp.isBlocked = self.shouldBlockTracker(trackerApp.appId)
            appList.append(trackerApp)
        }
        
        // Sort list
        appList.sort { (trackerApp1, trackerApp2) -> Bool in
            return trackerApp1.name.localizedCaseInsensitiveCompare(trackerApp2.name) == ComparisonResult.orderedAscending
        }
        
        return appList
    }
    
    func trackerAppFromBug(_ trackerBug: TrackerListBug) -> TrackerListApp? {
        if let app = apps[trackerBug.appId] {
            return app
        }
        
        return nil
    }
    
    func detectedTrackersForPage(_ pageUrl: String) -> [TrackerListApp] {
        // convert the list of detected bugs into an array of tracker apps/vendors
        var appList = [TrackerListApp]()
        if let pageBugs = discoveredBugs[pageUrl] {
            let appIdList = pageBugs.appIdList()
            for appId in appIdList {
                if let trackerApp = apps[appId] {
                    trackerApp.isBlocked = self.shouldBlockTracker(appId)
                    appList.append(trackerApp)
                }
            }
        }

        // Sort list
        appList.sort { (trackerApp1, trackerApp2) -> Bool in
            return trackerApp1.name.localizedCaseInsensitiveCompare(trackerApp2.name) == ComparisonResult.orderedAscending
        }
        
        return appList
    }
    
    func detectedTrackerCountForPage(_ pageUrl: String) -> Int {
        if let pageBugs = discoveredBugs[pageUrl] {
            return pageBugs.appIdList().count
        }

        return 0
    }
    
    // MARK: - Database Access

    func shouldBlockTracker(_ appId: Int) -> Bool {
        if UserPreferences.instance.blockingMode == .all {
            return true
        }

        return TrackerStore.shared.contains(member: appId)
    }

    func blockAllTrackers() {
        // get the list of tracker apps to block
        var appList = [TrackerListApp]()
        for (_, trackerApp) in apps {
            trackerApp.isBlocked = true
            appList.append(trackerApp)
        }

        blockSpecificTrackers(appList)

        UserPreferences.instance.blockingMode = .all
        UserPreferences.instance.writeToDisk()
    }

    func unblockAllTrackers() {
        TrackerStore.shared.removeAll()

        UserPreferences.instance.blockingMode = .none
        UserPreferences.instance.writeToDisk()
    }

    func blockSpecificTrackers(_ trackers: [TrackerListApp]) {
        // run this on a background thread and context
        
        for tracker in trackers {
            TrackerStore.shared.add(member: tracker.appId)
        }

        UserPreferences.instance.blockingMode = .selected
        UserPreferences.instance.writeToDisk()
    }
    
    // MARK: - Helper Methods
    
    func logTrackerPanelData(_ bugId: Int, pageUrlString: String, endTime: Double) {
        if let pageTrackers = discoveredBugs[pageUrlString] {
            if let trackerBug = pageTrackers.getTracker(bugId) {
                trackerBug.endTimestamp = endTime
                
                // send the tracker panel data out the door
                //GhostrankUtils.logTrackerPanelData(trackerBug, pageUrlString: pageUrlString)
            }
        }
    }
    
    func getTrackerBug(_ bugUrl: String, pageUrl: String) -> TrackerListBug? {
        if let pageTrackers = discoveredBugs[pageUrl] {
            if let trackerBug = pageTrackers.getTracker(bugUrl) {
                return trackerBug
            }
        }
        
        return nil
    }
}
