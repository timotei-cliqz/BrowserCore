//
//  TabOverview.swift
//  BrowserCore
//
//  Created by Tim Palade on 1/24/18.
//  Copyright © 2018 Tim Palade. All rights reserved.
//

import UIKit

import UIKit
import RealmSwift

class TabOverview: UIViewController {
    
    let tableView = UITableView()
    let toolBar = UIToolbar()
    
    var tabs: [CustomWKWebView] {
        return TabManager.shared.tabs
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        tableView.dataSource = self
        tableView.delegate = self
        
        let done = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(donePressed))
        let addPrivateTab = UIBarButtonItem(title: "Add Private Tab", style: .plain, target: self, action: #selector(addPrivateTabPressed))
        toolBar.setItems([done, addPrivateTab], animated: false)
        
        view.addSubview(tableView)
        view.addSubview(toolBar)
        
        toolBar.snp.makeConstraints { (make) in
            make.bottom.left.right.equalToSuperview()
        }
        
        tableView.snp.makeConstraints { (make) in
            make.top.left.right.equalToSuperview()
            make.bottom.equalTo(self.toolBar.snp.top)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false
        
        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
        
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "HistoryCell")
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @objc func donePressed(_ button: UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @objc func addPrivateTabPressed(_ button: UIBarButtonItem) {
        let tab = TabManager.shared.addTab(privateTab: true)
        TabManager.shared.selectTab(tab: tab)
        self.dismiss(animated: true, completion: nil)
    }
    
}

extension TabOverview: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return tabs.count
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "HistoryCell", for: indexPath)
        
        // Configure the cell...
        //(tabs[indexPath.row].title != nil ? tabs[indexPath.row].title : tabs[indexPath.row].url?.absoluteString)
        
        let tab = tabs[indexPath.row]
        let prefix = tab.isPrivate ? "[Forget Tab]: " : "" 
        let label = prefix + (tab.title ?? "") + " - " + (tab.url?.host ?? "")
        let emptyLabel = prefix + "Empty Tab"
        
        cell.textLabel?.text = tab.url != nil ? label : emptyLabel
        cell.textLabel?.numberOfLines = 0
        
        
        if tab == TabManager.shared.selectedTab {
            cell.backgroundColor = UIColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1.0)
        }
        else {
            cell.backgroundColor = UIColor.white
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let tab = tabs[indexPath.row]
        TabManager.shared.selectTab(tab: tab)
        self.dismiss(animated: true, completion: nil)
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let tab = tabs[indexPath.row]
            TabManager.shared.removeTab(tab: tab)
            self.tableView.reloadData()
            if tabs.count == 0 {
                self.dismiss(animated: true, completion: nil)
            }
        }
    }
}
