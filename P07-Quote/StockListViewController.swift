//
//  StockListViewController.swift
//  P07-Quote
//
//  Created by William Edward Gillespie on 12/8/15.
//  Copyright © 2015 William Edward Gillespie. All rights reserved.
//

import UIKit

class StockListViewController: UITableViewController {
    
    let startOfUrl:String = "http://download.finance.yahoo.com/d/quotes.csv?s="
    let endOfUrl:String = "&f=snl1c1p2aba5b6&e=.csv"
    
    var tickerNamesList:[String] = ["AAPL", "AMZN", "FB", "GOOG", "MSFT", "INTC", "AMD", "QCOM"]
    var tickerInfoDict:[String:[String]?] = [String:[String]?]()
    
    @IBOutlet var stockTableView: UITableView!
    
    @IBOutlet weak var myRefreshControl: UIRefreshControl!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        for tickerName in tickerNamesList {
            tickerInfoDict[tickerName] = fetchStockData(tickerName)
        }
        self.myRefreshControl?.addTarget(self, action: "refreshStockData:", forControlEvents: UIControlEvents.ValueChanged)
    }
    /*
        Refreshes the info in the listview.  The stock data is fetched on a different thread.  The main thread is acquired
    and the tickerInfoDict is set to the new dictionary of data created in the other thread.  The data for the list is then reloaded.
    For the process of the fetching, user interaction for the tableview is disabled.  I did this to eliminate any possible concurrent
    modification of the original list by the table view and the asynchrounous thread.
    */
    func refreshStockData(refreshControl: UIRefreshControl) {
        stockTableView.userInteractionEnabled = false
        var newStockData:[String:[String]?] = [String:[String]?]()
        let qos:Int = Int(QOS_CLASS_USER_INTERACTIVE.rawValue)
        dispatch_async(dispatch_get_global_queue(qos, 0)) { () -> Void in
            for tickerName in self.tickerNamesList {
                newStockData[tickerName] = self.fetchStockData(tickerName)
            }
            dispatch_async(dispatch_get_main_queue()) { //updates labels on main thread
                self.tickerInfoDict = newStockData
                self.myRefreshControl.endRefreshing()
                self.stockTableView.reloadData()
                self.stockTableView.userInteractionEnabled = true
            }
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
    /*
        Adds a stock to the list of stocks (not permanent)
    */
    @IBAction func addStock(sender: UIBarButtonItem) {
        let alert = UIAlertController(title: "Stock Ticker Manager", message: "Add a Stock Ticker Symbol",preferredStyle: .Alert)
        
        let addAction = UIAlertAction(title: "Add",
            style: .Default,
            handler: { (action:UIAlertAction) -> Void in
                if let text = alert.textFields?.first?.text {
                    let upperCaseText = text.uppercaseString
                    if self.tickerNamesList.contains(upperCaseText) == false {//only add if it does not exist (i.e. no duplicates)
                        if let comps:[String] = self.fetchStockData(upperCaseText) {//attempt to fetch data.
                            if comps[1].containsString("N/A") == false {//if the price is "N/A", it is not a valid ticker symbol
                                self.tickerNamesList.append(upperCaseText)
                                self.tickerInfoDict[upperCaseText] = comps
                                self.tableView.reloadData()
                            }
                        }
                    }
                    
                }
        })
        
        let cancelAction = UIAlertAction(title: "Cancel",
            style: .Default) { (action: UIAlertAction) -> Void in
        }
        
        alert.addTextFieldWithConfigurationHandler {
            (textField: UITextField) -> Void in
        }
        
        alert.addAction(addAction)
        alert.addAction(cancelAction)
        
        presentViewController(alert,
            animated: true,
            completion: nil)
        
    }//end of addStock()
    
    /*
        Allows user to delete a stock from the list
    */
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == UITableViewCellEditingStyle.Delete {
            let removedTickerName:String = tickerNamesList.removeAtIndex(indexPath.row)
            tickerInfoDict.removeValueForKey(removedTickerName)
            stockTableView.reloadData()
        }
    }
    
    /*
        moves stocks
    */
    @IBAction func startEditing(sender: UIBarButtonItem) {
        self.editing = !self.editing
    }
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {
        let temp = tickerNamesList[fromIndexPath.row]
        tickerNamesList[fromIndexPath.row] = tickerNamesList[toIndexPath.row]
        tickerNamesList[toIndexPath.row] = temp
        stockTableView.reloadData()
    }
    
    /*
        Prepares for segue
    */
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if (segue.identifier == "forwardSegue") {
            if let destination = segue.destinationViewController as? SingleStockViewController {
                if let indexPath = stockTableView.indexPathForSelectedRow {
                    destination.tickerName = tickerNamesList[indexPath.row]
                }
            }
        }
    }
    /*
        This method allows for the SingleStockView to unwind to this ViewController, which makes the transition fast.
    */
    @IBAction func unwindToVC(segue: UIStoryboardSegue) {
    }
    
    override func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        /*
            makes the cell pretty and rounded
        */
        if let customCell:StockViewCell = cell as? StockViewCell{
            customCell.pointsAndPercentChangedLabel.layer.shadowColor = UIColor.darkGrayColor().CGColor
            customCell.pointsAndPercentChangedLabel.layer.shadowOffset = CGSize(width: 2.0, height: 2.0)
            customCell.pointsAndPercentChangedLabel.layer.shadowOpacity = 1.0
            customCell.pointsAndPercentChangedLabel.layer.shadowRadius = 2
            customCell.pointsAndPercentChangedLabel.layer.masksToBounds = false
            customCell.pointsAndPercentChangedLabel.clipsToBounds = true
            customCell.pointsAndPercentChangedLabel.layer.cornerRadius = 10
        }
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int{
        return tickerNamesList.count
    }
    /*
    Indices of stock data info to be used to fill the custom table cell.
    Index : data type
    0 -> tickerName
    1 -> companyName
    2 -> price
    3 -> pointsChanged
    4 -> percentChanged
    5 -> ask
    6 -> bid
    7 -> askSize
    8 -> bidSize
    */
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell:StockViewCell = self.tableView.dequeueReusableCellWithIdentifier("StockCell")! as! StockViewCell
        let tickerName:String = tickerNamesList[indexPath.row]
        if let data:[String] = tickerInfoDict[tickerName]!{
            cell.tickerNameLabel.text = data[0]
            cell.companyNameLabel.text = data[1]
            
            /*
                Formats the decimal numbers to two decimal numbers so they are nice and pretty
            */
            if let price = Float(data[2]){
                cell.priceLabel.text = String(format: "%.2f", price)
            }
            if let pointsChanged = Float(data[3]){
                var formattedPointsChanged:String = String(format: "%.2f", pointsChanged)
                if let formattedPercentChanged:String = formatPercent(data[4]) {
                    formattedPointsChanged = pointsChanged > 0 ? "+\(formattedPointsChanged)" : formattedPointsChanged
                    cell.pointsAndPercentChangedLabel.text = "\(formattedPointsChanged)\n\(formattedPercentChanged)"
                    cell.pointsAndPercentChangedLabel.backgroundColor = colorForPointsChanged(pointsChanged)
                }
            }
            if let askPrice = Float(data[5]) {
                cell.askLabel.text = String(format: "Ask: %.2f x \(data[7])", askPrice)
            }
            if let bidPrice = Float(data[6]) {
                cell.bidLabel.text = String(format: "Bid: %.2f x \(data[8])", bidPrice)
            }
        }
        
        if indexPath.row % 2 == 1{
            cell.backgroundColor = UIColor.lightGrayColor()
        }else {
            cell.backgroundColor = UIColor.clearColor()
        }
        
        return cell
    }
    
    /*
        Returns a red or green color according the the points changed
    @param:Float a number that represents the points changed of a stock
    @return:UIColor red or green depending on positive or negative number
    */
    func colorForPointsChanged(pointsChanged: Float) -> UIColor {
        if pointsChanged > 0.0{// set background to #5B9F34 (green)
            let red:Double = 91.0
            let green:Double = 153.0
            let blue:Double = 3.0
            return UIColor(red: CGFloat(red/255.0), green: CGFloat(green/255.0), blue: CGFloat(blue/255.0), alpha: 1)//green
        }else{//set background to #AE2923 (red)
            let red:Double = 174.0
            let green:Double = 41.0
            let blue:Double = 35.0
            return UIColor(red: CGFloat(red/255.0), green: CGFloat(green/255.0), blue: CGFloat(blue/255.0), alpha: 1)//red
        }
    }
    /*
        Takes a string that is in percent format and returns that string formatted with two decimal places.
    @param:String string that represents a percent
    @return:String formatted string if the parameter is a true percent value and can be parsed
            or nil if it cannot be parsed
    */
    func formatPercent(var percent: String) -> String? {
        percent = percent.stringByReplacingOccurrencesOfString("%", withString: "")
        var isNegative:Bool = false
        if percent[percent.startIndex] == "-" {
            percent = percent.stringByReplacingOccurrencesOfString("-", withString: "")
            isNegative = true
        }
        
        if let numericPercent = Float(percent) {//if the number is parseable, format it pretty and return it
            let formattedPercent:String = "\(String(format: "%.2f", numericPercent))%"
            return isNegative ? "-\(formattedPercent)" : "+\(formattedPercent)"
        }else{// if the number is unparseable, return nil
            return nil
        }
    }
}
