//
//  SingleStockViewController.swift
//  P07-Quote
//
//  Created by William Edward Gillespie on 12/11/15.
//  Copyright © 2015 William Edward Gillespie. All rights reserved.
//  
//  This class represents a single stock to view.  The stock info
//  can be updated, autoupdated, and the auto updating can be paused.
//  This view can be unwound to the StockListViewController

import UIKit

class SingleStockViewController: UIViewController {
    //upper level stock data labels
    @IBOutlet weak var stockNameLabel: UILabel!
    @IBOutlet weak var companyNameLabel: UILabel!
    @IBOutlet weak var stockPriceLabel: UILabel!
    @IBOutlet weak var timeSinceLastUpdateLabel: UILabel!
    @IBOutlet weak var pointsChangedLabel: UILabel!
    @IBOutlet weak var percentChangedLabel: UILabel!
    @IBOutlet weak var askLabel: UILabel!
    @IBOutlet weak var bidLabel: UILabel!
    @IBOutlet weak var containerView: UIView!
    
    //lower level stock data labels
    @IBOutlet weak var openPriceLabel: UILabel!
    @IBOutlet weak var highPriceLabel: UILabel!
    @IBOutlet weak var _52wHighLabel: UILabel!
    @IBOutlet weak var preClosePriceLabel: UILabel!
    @IBOutlet weak var lowPriceLabel: UILabel!
    @IBOutlet weak var _52wLowLabel: UILabel!
    
    //bottom toolbar buttons
    @IBOutlet weak var updateButton: UIBarButtonItem!
    @IBOutlet weak var autoUpdateButton: UIBarButtonItem!
    @IBOutlet weak var pauseButton: UIBarButtonItem!
    
    
    var tickerName:String = ""
    let startOfUrl:String = "http://download.finance.yahoo.com/d/quotes.csv?s="
    let endOfUrl:String = "&f=snbapohgkjl1t1c1p2a5b6&e=.csv"
    
    var timer:NSTimer? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.title = tickerName
        pauseButton.enabled = false
        
        if let comps:[String] = fetchStockData(tickerName) {
            updateLabels(components: comps)
        }

    }
    /*
        Fetches the stock data from yahoo
        @param:String ticker name for stock info to retrieve
        @return:[String] if the data could be retrieved, nil if there was a network error.
    */
    func fetchStockData(tickerName: String) -> [String]? {
        let concatenatedUrl:String = startOfUrl + tickerName + endOfUrl
        let url:NSURL = NSURL(string: concatenatedUrl)!
        if let data:String = try? String(contentsOfURL: url, encoding: NSUTF8StringEncoding){
            var modifiedStringOfData = data.stringByTrimmingCharactersInSet(NSCharacterSet.newlineCharacterSet())
            modifiedStringOfData = modifiedStringOfData.stringByReplacingOccurrencesOfString("\"", withString: "")
            modifiedStringOfData = modifiedStringOfData.stringByReplacingOccurrencesOfString(", ", withString: "<<")
            var comps:[String] = modifiedStringOfData.componentsSeparatedByString(",")
            comps[1] = comps[1].stringByReplacingOccurrencesOfString("<<", withString: ", ")
            return comps
        }else {
            return nil;
        }
    }
    
    
    /**
     * updates the displays with the contents of components.
     * Example of components:
     * "AAPL","Apple Inc.",114.75,114.77,115.00,116.36,116.69,114.02,134.54,92.00,114.71,"4:00pm",-0.29,"-0.25%"
     Index : contents
     0 : stockName
     1 : companyName
     2 : BidPrice - could be "N/A"
     3 : askingPrice - could be "N/A"
     4 : previousClose
     5 : openingPrice
     6 : dayHigh
     7 : dayLow
     8 : 52weekHigh
     9 : 52weekLow
     10: lastTradedPrice
     11: lastTimeTraded
     12: stockPointsChange
     13: stockPercentChange
     14: askSize - could be "N/A"
     15: bidSize - could be "N/A"
     * @param components : data from stocks
     */
    func updateLabels(components comps: [String]){
        //upper portion of labels
        stockNameLabel.text = comps[0]
        
        //logic for wrapping the company name so that the text doesn't collide with another view
        if comps[1].characters.count > 20 {
            var companyName:[String] = comps[1].componentsSeparatedByString(" ")
            var firstPart:String = companyName[companyName.startIndex]
            for index in 1 ..< companyName.count - 1 {
                firstPart = firstPart.stringByAppendingString(" \(companyName[index])")
            }
            firstPart = firstPart.stringByAppendingString("\n\(companyName[companyName.endIndex.predecessor()])")
            companyNameLabel.text = firstPart
        }else {
            companyNameLabel.text = comps[1]
        }
        stockPriceLabel.text = comps[10]
        timeSinceLastUpdateLabel.text = comps[11]
        
        //formatting for the points changed and percent changed.  It also sets the color for the background view.
        if let pointsChanged:Float = Float(comps[12]) {
            if pointsChanged > 0.0{// set background to #5B9F34 (green)
                pointsChangedLabel.text = String(format:"+%.2f", pointsChanged)
                let red:Double = 91.0
                let green:Double = 153.0
                let blue:Double = 3.0
                containerView.backgroundColor = UIColor(red: CGFloat(red/255.0), green: CGFloat(green/255.0), blue: CGFloat(blue/255.0), alpha: 1)//green
            }else{//set background to #AE2923 (red)
                pointsChangedLabel.text = String(format:"%.2f", pointsChanged)
                let red:Double = 174.0
                let green:Double = 41.0
                let blue:Double = 35.0
                containerView.backgroundColor = UIColor(red: CGFloat(red/255.0), green: CGFloat(green/255.0), blue: CGFloat(blue/255.0), alpha: 1)//red
            }
        }
        
        //string processing for the "-" and the "%"
        var percentChanged = comps[13].stringByReplacingOccurrencesOfString("%", withString: "")
        if percentChanged[percentChanged.startIndex] == "-" {
            percentChanged = percentChanged.stringByReplacingOccurrencesOfString("-", withString: "")
            if let thePercent:Float = Float(percentChanged) {
                percentChangedLabel.text = "\(String(format:"-%.2f", thePercent))%"
            }
        }else {
            percentChanged = percentChanged.stringByReplacingOccurrencesOfString("+", withString: "")
            if let thePercent:Float = Float(percentChanged) {
                percentChangedLabel.text = "\(String(format: "+%.2f%", thePercent))%"
            }
        }
        
        if let askPrice = Float(comps[3]) {
            askLabel.text = String(format: "Ask:\t %.2f x \(comps[14])", askPrice)
        }else {
            askLabel.text = "Ask:\t \(comps[3]) x \(comps[14])"
        }
        
        let bidSizeStr = comps[15].stringByTrimmingCharactersInSet(NSCharacterSet.newlineCharacterSet())
        if let bidPrice = Float(comps[2]) {
            bidLabel.text = String(format: "Bid:\t %.2f x \(bidSizeStr)", bidPrice)
        }else {
            bidLabel.text = "Bid:\t \(comps[2]) x \(bidSizeStr)"
        }
        
        //lower portion of labels
        
        if let openPrice = Float(comps[5]) {
            openPriceLabel.text = String(format: "Open:\t %.2f", openPrice)
        }else {
            openPriceLabel.text = "Open:\t \(comps[5])"
        }
        
        if let highPrice = Float(comps[6]) {
            highPriceLabel.text = String(format: "High:\t %.2f", highPrice)
        }else {
            highPriceLabel.text = "High:\t \(comps[6])"
        }
        
        if let _52wHighPrice = Float(comps[8]) {
            _52wHighLabel.text = String(format: "52w high:\t %.2f", _52wHighPrice)
        }else {
            _52wHighLabel.text = "52w high:\t \(comps[8])"
        }
        if let preClosePrice = Float(comps[4]) {
            preClosePriceLabel.text = String(format: "Pre-Close:\t %.2f", preClosePrice)
        }else {
            preClosePriceLabel.text = "Pre-Close:\t \(comps[4])"
        }
        if let lowPrice = Float(comps[7]) {
            lowPriceLabel.text = String(format: "Low:\t %.2f", lowPrice)
        }else {
            lowPriceLabel.text = "Low:\t \(comps[7])"
        }
        if let _52wLowPrice = Float(comps[9]){
            _52wLowLabel.text = String(format: "52w low:\t %.2f", _52wLowPrice)
        }else {
            _52wLowLabel.text = "52w low:\t \(comps[9])"
        }
        
        //_52wHighLabel.text = String(format: "52w high:\t %.2f", Float(comps[8])!)
        //preClosePriceLabel.text = String(format: "Pre-Close:\t %.2f", Float(comps[4])!)
        //lowPriceLabel.text = String(format: "Low:\t %.2f", Float(comps[7])!)
        //_52wLowLabel.text = String(format: "52w low:\t %.2f", Float(comps[9])!)
    }
    /*
        Fetches the data from the url on another thread, then updates the labels
    on the main thread.
    */
    func fetchDataAndUpdateLabels() {
        let qos:Int = Int(QOS_CLASS_USER_INTERACTIVE.rawValue)
        dispatch_async(dispatch_get_global_queue(qos, 0)) { () -> Void in
            if let comps:[String] = self.fetchStockData(self.tickerName) { //fetches on another thread
                dispatch_async(dispatch_get_main_queue()) { //updates labels on main thread
                    self.updateLabels(components: comps)
                }
            }
        }
    }
    /*
        Tests whether the UI updates correctly when the stock market is closed.
    */
    func updateWithRandomData() {
        let qos:Int = Int(QOS_CLASS_USER_INTERACTIVE.rawValue)
        dispatch_async(dispatch_get_global_queue(qos, 0)) { () -> Void in
            var comps:[String] = []
            for _ in 0...15 {
                comps.append(String(Float(arc4random()) / Float(UINT32_MAX)*Float(5.0)))
            }
            dispatch_async(dispatch_get_main_queue()) {
                self.updateLabels(components: comps)
                if self.updateButton.enabled == false {
                    self.updateButton.enabled = true
                }
            }
        }
    }
    
    @IBAction func updateStockData(sender: UIBarButtonItem) {
        fetchDataAndUpdateLabels()
        updateButton.enabled = true
    }
    
    @IBAction func autoUpdateStockData(sender: UIBarButtonItem) {
        autoUpdateButton.enabled = false
        updateButton.enabled = false
        pauseButton.enabled = true
        if timer == nil {
            timer = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: #selector(SingleStockViewController.fetchDataAndUpdateLabels), userInfo: nil, repeats: true)
        }
    }
    
    @IBAction func pauseAutoUpdate(sender: UIBarButtonItem) {
        autoUpdateButton.enabled = true
        updateButton.enabled = true
        pauseButton.enabled = false
        timer?.invalidate()
        timer = nil
    }
}
