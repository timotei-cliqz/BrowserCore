//
//  GhosteryBlockListHelper.swift
//  BrowserCore
//
//  Created by Tim Palade on 3/19/18.
//  Copyright © 2018 Tim Palade. All rights reserved.
//

import WebKit

fileprivate let ghosteryBlockListSplit = "ghostery_content_blocker_split"
fileprivate let ghosteryBlockListNotSplit = "ghostery_content_blocker"

final class BlockListManager {

    //appIds need to be first translated to bugIds and then loaded.
    class func getBlockLists(appIds: [Int], callback: @escaping ([WKContentRuleList]) -> Void) {
        func getBugIds(appIds: [Int]) -> [Int] {
            return appIds.flatMap { (appId) -> [Int] in
                return TrackerList.instance.app2bug[appId] ?? []
            }
        }
        
        let bugIds = getBugIds(appIds: appIds).map { i in String(i) }
        
        self.getBlockLists(forIdentifiers: bugIds) { (lists) in
            callback(lists)
        }
    }
    
    class func getBlockLists(forIdentifiers: [String], callback: @escaping ([WKContentRuleList]) -> Void) {
        
        var returnList = [WKContentRuleList]()
        let dispatchGroup = DispatchGroup()
        let listStore = WKContentRuleListStore.default()
        
        for id in forIdentifiers {
            dispatchGroup.enter()
            listStore?.lookUpContentRuleList(forIdentifier: id) { (ruleList, error) in
                if let ruleList = ruleList {
                    returnList.append(ruleList)
                }
                else {
                    debugPrint("did not find list for identifier = \(id)")
                }
                dispatchGroup.leave()
            }
        }
        
        dispatchGroup.notify(queue: .global()) {
            callback(returnList)
        }
    }
    
    
    class func load() {
        //check if anything need to be loaded
        let lists = BlockListIdentifiers.all()
        let listStore = WKContentRuleListStore.default()
        
        var needsToBeLoaded: [String] = []
        
        WKContentRuleListStore.default().getAvailableContentRuleListIdentifiers { (availableLists) in
            if let availableLists = availableLists {
                let availableSet = Set(availableLists)
                for identifier in lists {
                    if !availableSet.contains(identifier) {
                        needsToBeLoaded.append(identifier)
                    }
                }
            }
            else{
                needsToBeLoaded = lists
            }
            
            if needsToBeLoaded.count > 0 {
                let blockListFM = BlockListFileManager()
                for identifier in needsToBeLoaded {
                    let json = blockListFM.json(forIdentifier: identifier)
                    listStore?.compileContentRuleList(forIdentifier: identifier, encodedContentRuleList: json) { (ruleList, error) in
                        guard let _ = ruleList else { fatalError("problem compiling \(identifier)") }
                    }
                }
            }
        }
    }
}

final class BlockListIdentifiers {
    
    class func all() -> [String] {
        return allBugIds() + BlockListIdentifiers.antitrackingIdentifiers
    }
    
    static let antitrackingIdentifiers = ["ghostery_content_blocker"]
    
    //all bug ids in the ghostery file
    class private func allBugIds() -> [String] {
        let path = URL(fileURLWithPath: Bundle.main.path(forResource: ghosteryBlockListSplit, ofType: "json")!)
        guard let jsonFileContent = try? Data.init(contentsOf: path) else { fatalError("Rule list for \(ghosteryBlockListSplit) doesn't exist!") }
        
        let jsonObject = try? JSONSerialization.jsonObject(with: jsonFileContent, options: [])
        
        if let id_dict = jsonObject as? [String: Any] {
            return Array(id_dict.keys)
        }
        return []
    }
}

final class BlockListFileManager {
    
    typealias BugID = String
    typealias BugJson = String
    
    private let ghosteryBlockDict: [BugID:BugJson]
    
    init() {
        ghosteryBlockDict = BlockListFileManager.parseGhosteryBlockList()
    }
    
    func json(forIdentifier: String) -> String {
        
        if let json = ghosteryBlockDict[forIdentifier] {
            return json
        }
        //otherwise
        //search the bundle for a json and parse it.
        let path = Bundle.main.path(forResource: forIdentifier, ofType: "json")!
        guard let jsonFileContent = try? String(contentsOfFile: path, encoding: String.Encoding.utf8) else { fatalError("Rule list for \(forIdentifier) doesn't exist!") }
        return jsonFileContent
    }
    
    class private func parseGhosteryBlockList() -> [BugID:BugJson] {
        let path = URL(fileURLWithPath: Bundle.main.path(forResource: ghosteryBlockListSplit, ofType: "json")!)
        guard let jsonFileContent = try? Data.init(contentsOf: path) else { fatalError("Rule list for \(ghosteryBlockListSplit) doesn't exist!") }
        
        let jsonObject = try? JSONSerialization.jsonObject(with: jsonFileContent, options: [])
        
        var dict: [BugID:BugJson] = [:]
        
        if let id_dict = jsonObject as? [String: Any] {
            debugPrint("number of keys = \(id_dict.keys.count)")
            for key in id_dict.keys {
                if let value_dict = id_dict[key] as? [[String: Any]],
                    let json_data = try? JSONSerialization.data(withJSONObject: value_dict, options: []),
                    let json_string = String.init(data: json_data, encoding: String.Encoding.utf8)
                {
                    dict[key] = json_string
                }
            }
        }
        debugPrint("number of keys successfully parsed = \(dict.keys.count)")
        return dict
    }
}



