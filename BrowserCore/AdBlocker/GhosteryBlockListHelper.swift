//
//  GhosteryBlockListHelper.swift
//  BrowserCore
//
//  Created by Tim Palade on 3/19/18.
//  Copyright © 2018 Tim Palade. All rights reserved.
//

import WebKit

class GhosteryBlockListHelper {
    
    static let shared = GhosteryBlockListHelper()
    
    typealias TrackerID = String
    typealias TrackerJson = String
    
    let listName: String = "ghostery_content_blocker_split"
    
    init() {
        //make sure the list is compiled.
        //TODO: Make this more efficient. It works for now.
        //It could be more efficient by not having to parse the json every time.
        self.getBlockLists { (array) in }
    }
    
    func getBlockLists(appIds: [Int], callback: @escaping ([WKContentRuleList]) -> Void) {
        var returnList = [WKContentRuleList]()
        let dispatchGroup = DispatchGroup()
        let listStore = WKContentRuleListStore.default()
        
        for id in appIds {
            dispatchGroup.enter()
            listStore?.lookUpContentRuleList(forIdentifier: String(id)) { (ruleList, error) in
                if let ruleList = ruleList {
                    returnList.append(ruleList)
                }
                dispatchGroup.leave()
            }
        }
        
        dispatchGroup.notify(queue: .global()) {
            callback(returnList)
        }
    }
    
    func getBlockLists(callback: @escaping ([WKContentRuleList]) -> Void) {
        let lists = parseList()
        var returnList = [WKContentRuleList]()
        let dispatchGroup = DispatchGroup()
        let listStore = WKContentRuleListStore.default()
        
        for listTouple in lists {
            dispatchGroup.enter()
            let identifier = listTouple.0
            
            listStore?.lookUpContentRuleList(forIdentifier: identifier) { (ruleList, error) in
                if let ruleList = ruleList {
                    returnList.append(ruleList)
                    dispatchGroup.leave()
                } else {
                    listStore?.compileContentRuleList(forIdentifier: identifier, encodedContentRuleList: listTouple.1) { (ruleList, error) in
                        guard let ruleList = ruleList else { fatalError("problem compiling \(identifier)") }
                        returnList.append(ruleList)
                        dispatchGroup.leave()
                    }
                }
            }
        }
        
        dispatchGroup.notify(queue: .global()) {
            callback(returnList)
        }
    }
    
    private func parseList() -> [(TrackerID, TrackerJson)] {
        let path = URL(fileURLWithPath: Bundle.main.path(forResource: listName, ofType: "json")!)
        guard let jsonFileContent = try? Data.init(contentsOf: path) else { fatalError("Rule list for \(listName) doesn't exist!") }
        
        let jsonObject = try? JSONSerialization.jsonObject(with: jsonFileContent, options: [])
        
        var array: [(TrackerID, TrackerJson)] = []
        
        if let id_dict = jsonObject as? [String: Any] {
            debugPrint("number of keys = \(id_dict.keys.count)")
            for key in id_dict.keys {
                if let value_dict = id_dict[key] as? [[String: Any]],
                    let json_data = try? JSONSerialization.data(withJSONObject: value_dict, options: []),
                    let json_string = String.init(data: json_data, encoding: String.Encoding.utf8)
                {
                    let atom = (key, json_string)
                    array.append(atom)
                }
            }
        }
        debugPrint("number of keys successfully parsed = \(array.count)")
        return array
    }
}
