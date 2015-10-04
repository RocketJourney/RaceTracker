//
//  RunSetingsController.swift
//  RaceTracker
//
//  Created by Ernesto Cambuston on 10/4/15.
//  Copyright © 2015 CocoaPods. All rights reserved.
//

import UIKit

protocol RunSettingsDelegate {
  func updateUnitSystem(unitSystem:Bool)
  func updateFeedbackSettings()
}

class RunSettingsController : UITableViewController {
  var delegate:RunSettingsDelegate?
  var unitSystem = false
  private var unitString = "km"
  
  override func viewDidLoad() {
    super.viewDidLoad()
    unitString = unitSystem ? "km" : "mi"
  }
  
  override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
    return 4
  }
  
  override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    switch section {
    case 0, 1: return 3
    default: return 1
    }
  }
  
  override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
    return 60.0
  }
  
  override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    let cell = UITableViewCell()
    switch indexPath.section {
    case 0:
      switch indexPath.row {
      case 0:
        cell.textLabel?.text = "1.0 \(unitString)"
      case 1:
        cell.textLabel?.text = "1.5 \(unitString)"
      case 2:
        cell.textLabel?.text = "2.0 \(unitString)"
      default: break
      }
    case 1:
      switch indexPath.row {
      case 0:
        cell.textLabel?.text = "5:00 min"
      case 1:
        cell.textLabel?.text = "10:00 min"
      case 2:
        cell.textLabel?.text = "15:00 min"
      default: break
      }
    case 2:
      cell.textLabel?.text = unitSystem ? "Metric" : "Imperial"
    case 3:
      cell.textLabel?.text = "Pace tracking"
    default: break
    }
    return cell
  }
  override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
    switch indexPath.section {
    case 0: setDistance(indexPath.row)
    case 1: setTime(indexPath.row)
    case 2: toggleMetric()
    case 3: paceSelect()
    default: break
    }
  }
  private func setDistance(value:Int) {
    
  }
  private func setTime(value:Int) {
    
  }
  private func toggleMetric() {
    
  }
  private func paceSelect() {
    
  }
}