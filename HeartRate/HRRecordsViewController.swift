//
//  HRRecordsViewController.swift
//  HeartRate
//
//  Created by Kirill G on 8/31/18.
//  Copyright © 2018 ns-ios. All rights reserved.
//

import UIKit
import HealthKit
import SCLAlertView

class HRRecordsViewController: UIViewController
{
    
    var tempHeartBPM = [String]()
    
    let healthkitStore = HKHealthStore()
    let heartRateUnit:HKUnit = HKUnit(from: "count/min")
    let heartRateType:HKQuantityType   = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRate)!
    
    @IBOutlet weak var tableView: UITableView!
    
    @IBAction func readRecords(_ sender: Any) {
        self.readHeartRate()
    }
    
    @IBAction func addHeartRecod(_ sender: UIBarButtonItem) {
        
        let alertView = SCLAlertView()
        let alertViewIcon = UIImage(named: "icons8-heart-with-pulse-48")
        let txt = alertView.addTextField("Enter HR")
        
        alertView.addButton("Add record") {
            let newRate = (txt.text as! NSString).doubleValue
            self.saveHeartRate(newRate)
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
        alertView.showInfo("New Heart Rate record", subTitle: "Please enter new record below", circleIconImage: alertViewIcon)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.getHealthKitPermission()
    }
    
    // MARK: HealthKit methods
    func getHealthKitPermission() {
        let healthkitTypesToRead = NSSet(array: [
            HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRate) ?? ""
            ])
        
        let healthkitTypesToWrite = NSSet(array: [
            HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRate) ?? ""
            ])
        
        healthkitStore.requestAuthorization(toShare: healthkitTypesToWrite as? Set, read: healthkitTypesToRead as? Set) { (success, error) in
            if success {
                print("Permission accepted.")
                self.readHeartRate()
            } else {
                if error != nil {
                    print(error ?? "")
                }
                print("Permission denied.")
            }
        }
    }
    
    func saveHeartRate(_ rate:Double)
    {
        if let type = HKSampleType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRate) {
            let beatsPerMinuteQuantity = HKQuantity(unit: HKUnit.count().unitDivided(by: HKUnit.minute()), doubleValue: rate)
            let heartRateSampleData = HKQuantitySample(type: type, quantity: beatsPerMinuteQuantity, start: Date(), end: Date())
            self.healthkitStore.save(heartRateSampleData, withCompletion: { (success, error) in
                self.readHeartRate()
                print("Saved \(success), error \(String(describing: error))")
            })
        }
    }
    
    func removeHeartRate(at:Int)
    {
        if let type = HKSampleType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRate) {
            let beatsPerMinuteQuantity = HKQuantity(unit: HKUnit.count().unitDivided(by: HKUnit.minute()), doubleValue: 100)
            let heartRateSampleData = HKQuantitySample(type: type, quantity: beatsPerMinuteQuantity, start: Date(), end: Date())
            self.healthkitStore.delete(heartRateSampleData, withCompletion: { (success, error) in
                print("Saved \(success), error \(String(describing: error))")
            })
        }
        
    }
    
    func readHeartRate()
    {
        self.tempHeartBPM.removeAll() // Jsut to clear out temp bpm array
        
        let heartRateType = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRate)!
        let sortDesc = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        let query = HKSampleQuery(sampleType: heartRateType, predicate: nil, limit: HKObjectQueryNoLimit, sortDescriptors: [sortDesc])
        {
            (query, samplesOrNil, error) in
            if let samples = samplesOrNil {
                for i in stride(from: 0, to: samples.count, by: 1)
                {
                    guard let currData:HKQuantitySample = samples[i] as? HKQuantitySample else { return }
                    
                    let hearhRate: Double = (currData.quantity.doubleValue(for: self.heartRateUnit))
                    let tempStringForHR:String = String(format:"%.1f", hearhRate)
                    
                    self.tempHeartBPM.append(tempStringForHR)
                }
                DispatchQueue.main.async{
                    self.tableView.reloadData()
                }
                
            } else {
                print("No heart rate samples available.")
            }
        }
        self.healthkitStore.execute(query)
    }
}

// MARK: TableView methods
extension HRRecordsViewController: UITableViewDelegate, UITableViewDataSource
{
    
     func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tempHeartBPM.count;
    }
    
     func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "hrCell", for: indexPath)
        
        cell.textLabel?.text = "❤️ \(tempHeartBPM[indexPath.row])"
        cell.detailTextLabel?.text = "BPM"
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            tempHeartBPM.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
            self.removeHeartRate(at: indexPath.row)
        }
    }
    
}
