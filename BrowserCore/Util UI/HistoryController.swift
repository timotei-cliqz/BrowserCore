//
//  HistoryController.swift
//  BrowserCore
//
//  Created by Tim Palade on 1/15/18.
//  Copyright © 2018 Tim Palade. All rights reserved.
//

import UIKit
import RealmSwift

protocol HistoryControllerDelegate: class { 
    func didPressUrl(url: URL)
}

class HistoryController: UIViewController {
    
    var tableView: BubbleTableView? = nil
    let toolBar = UIToolbar()
    
    weak var delegate: HistoryControllerDelegate? = nil
    
    var details = RealmStore.getVisits().sorted(byKeyPath: "timestamp", ascending: false)
    
    //timestamp, number of timestamps, sum of previous number of timestamps
    //example [(date0, 1, 0), (date1, 3, 1), (date2, 2, 4), ... ]
    //I use the sum to easily map section and row to the index of the entry in details.
    var dateBuckets: [(Date, Int, Int)] = []
    
    private let standardDateFormat = "dd-MM-yyyy"
    private let standardTimeFormat = "HH:mm"
    
    private let standardDateFormatter = DateFormatter()
    private let standardTimeFormatter = DateFormatter()
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        tableView = BubbleTableView(customDataSource: self, customDelegate: self)
        
        self.dateBuckets = self.buildDateBuckets(details: self.details)
        standardDateFormatter.dateFormat = standardDateFormat
        standardTimeFormatter.dateFormat = standardTimeFormat
        
        let done = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(donePressed))
        toolBar.setItems([done], animated: false)
        
        view.addSubview(tableView!)
        view.addSubview(toolBar)
        
        toolBar.snp.makeConstraints { (make) in
            make.bottom.left.right.equalToSuperview()
        }
        
        tableView?.snp.makeConstraints { (make) in
            make.top.left.right.equalToSuperview()
            make.bottom.equalTo(self.toolBar.snp.top)
        }
        
        tableView?.backgroundColor = UIColor(red: 0.95, green: 0.95, blue: 0.95, alpha: 1.0)
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
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @objc func donePressed(_ button: UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil)
    }

}

extension HistoryController: BubbleTableViewDataSource, BubbleTableViewDelegate {
    
    func buildDateBuckets(details: Results<Entry>) -> [(Date, Int, Int)] {
        
        guard details.count > 0 else { return [] }
        
        var array: [(Date, Int, Int)] = [(details[0].timestamp, 1, 0)]
        
        var last: Date = details[0].timestamp
        var last_sum: Int = 0
        
        for i in 1..<details.count {
            let detail = details[i]
            let detail_comp = detail.timestamp.dayMonthYear()
            
            let last_comp = last.dayMonthYear()
            
            if detail_comp != last_comp {
                last_sum += array[array.count - 1].1
                array.append((detail.timestamp, 1, last_sum))
                last = detail.timestamp
            }
            else {
                let (d, c, s) = array[array.count - 1]
                array[array.count - 1] = (d, c + 1, s)
            }
        }
        
        return array
    }
    
    func logo(completionBlock: @escaping (_ image: UIImage?, _ customView: UIView?) -> Void) {
        completionBlock(nil, nil)
    }
    
    func url(indexPath: IndexPath) -> String {
        return detail(indexPath: indexPath)?.url ?? ""
    }
    
    func title(indexPath: IndexPath) -> String {
        guard let detail = detail(indexPath: indexPath) else { return "" }
        return detail.title != "" ? detail.title : "Title Missing"
    }
    
    func titleSectionHeader(section: Int) -> String {
        return standardDateFormatter.string(from: dateBuckets[section].0)
    }
    
    func time(indexPath: IndexPath) -> String {
        if let date = detail(indexPath: indexPath)?.timestamp {
            return standardTimeFormatter.string(from: date)
        }
        return ""
    }
    
    func numberOfSections() -> Int {
        return dateBuckets.count//sortedDetails.count
    }
    
    func numberOfRows(section: Int) -> Int {
        return dateBuckets[section].1
    }
    
    func baseUrl() -> String {
        return ""
    }
    
    func isNews() -> Bool {
        return false
    }
    
    func useRightCell(indexPath: IndexPath) -> Bool {
        return false
    }
    
    func detail(indexPath: IndexPath) -> Entry? {
        let section = indexPath.section
        let row = indexPath.row
        //transform from section and row to list index
        let list_index = dateBuckets[section].2 + row
        return details[list_index]
    }
    
    func cellPressed(indexPath: IndexPath, rightCell: Bool) {
        if let url_str = detail(indexPath: indexPath)?.url, let url = URL(string: url_str) {
            delegate?.didPressUrl(url: url)
        }
        dismiss(animated: true, completion: nil)
    }
}

extension Date {
    
    public struct DayMonthYear: Equatable {
        let day: Int
        let month: Int
        let year: Int
        
        static public func ==(lhs: DayMonthYear, rhs: DayMonthYear) -> Bool {
            return lhs.day == rhs.day && lhs.month == rhs.month && lhs.year == rhs.year
        }
    }
    
    static public func ==(lhs: Date, rhs: Date) -> Bool {
        return lhs.compare(rhs) == .orderedSame
    }
    
    static public func <(lhs: Date, rhs: Date) -> Bool {
        return lhs.compare(rhs) == .orderedAscending
    }
    
    static public func >(lhs: Date, rhs: Date) -> Bool {
        return lhs.compare(rhs) == .orderedDescending
    }
    
    public func isYoungerThanOneDay() -> Bool {
        let currentDate = NSDate(timeIntervalSinceNow: 0)
        let difference_seconds = currentDate.timeIntervalSince(self)
        let oneDay_seconds     = Double(24 * 360)
        if difference_seconds > 0 && difference_seconds < oneDay_seconds {
            return true
        }
        return false
    }
    
    public func dayMonthYear() -> DayMonthYear {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd-MM-yyyy"
        
        let components = dateFormatter.string(from: self).components(separatedBy: "-")
        
        if components.count != 3 {
            //something went terribly wrong
            NSException.init(name: NSExceptionName(rawValue: "ERROR: Date might be corrupted"), reason: "There should be exactly 3 components.", userInfo: nil).raise()
        }
        
        //this conversion should never fail
        let day = Int(components[0])
        let month = Int(components[1])
        let year = Int(components[2])
        
        return DayMonthYear(day: day!, month: month!, year: year!)
    }
}

private struct Color {
    var red: CGFloat
    var green: CGFloat
    var blue: CGFloat
};

extension UIColor {
    /**
     * Initializes and returns a color object for the given RGB hex integer.
     */
    public convenience init(rgb: Int) {
        self.init(
            red:   CGFloat((rgb & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgb & 0x00FF00) >> 8)  / 255.0,
            blue:  CGFloat((rgb & 0x0000FF) >> 0)  / 255.0,
            alpha: 1)
    }
    
    public convenience init(colorString: String) {
        var colorInt: UInt32 = 0
        Scanner(string: colorString).scanHexInt32(&colorInt)
        self.init(rgb: (Int) (colorInt))
    }
}
