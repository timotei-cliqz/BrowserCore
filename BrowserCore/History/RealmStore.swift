//
//  RealmStore.swift
//  BrowserCore
//
//  Created by Tim Palade on 1/15/18.
//  Copyright © 2018 Tim Palade. All rights reserved.
//


import RealmSwift

class Entry: Object {
    @objc dynamic var timestamp = Date()
    @objc dynamic var url = ""
    @objc dynamic var title = ""
    
    override class func indexedProperties() -> [String] {
        return ["timestamp"]
    }
}

final class RealmStore: NSObject {
    
    class func getVisits() -> Results<Entry> {
        let realm = try! Realm()
        return realm.objects(Entry.self)
    }
    
    class func addVisitSync(url: String, title: String, date: Date) {
        let realm = try! Realm()
        _ = self.addVisit(realm: realm, url: url, title: title, date: date)
    }
    
    class func modifyVisit(new_url: String, new_title: String, timeStamp: Date) {
        let realm = try! Realm()
        let entry = realm.objects(Entry.self).first { (entry) -> Bool in
            return entry.timestamp == timeStamp
        }
        try! realm.write {
            entry?.url = new_url
            entry?.title = new_title
        }
    }
    
    private class func addVisit(realm: Realm, url: String, title: String, date: Date = Date()) -> Entry? {
        
        let visit = createVisit(url: url, title: title, date: date)
        
        executeWrite(realm: realm, objects: [visit])
        
        return visit
    }
    
    private class func createVisit(url: String, title: String, date: Date) -> Entry {
        let visit = Entry()
        visit.url = url
        visit.title = title
        visit.timestamp = date
        return visit
    }
    
    private class func executeWrite(realm: Realm, objects: [Object]) {
        do {
            try realm.write {
                realm.add(objects)
            }
        }
        catch {
            debugPrint("objects add failed -- \(objects)")
        }
    }
    
    private class func executeDelete(realm: Realm, objects: [Object]) {
        do {
            try realm.write {
                realm.delete(objects)
            }
        }
        catch {
            debugPrint("objects add failed -- \(objects)")
        }
    }
    
}
