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
  func updateFeedbackLabel(type:Int, value:Int)
}

class RunSettingsController : UITableViewController {
  var delegate:RunSettingsDelegate?
  var unitSystem = Preferences.instance.unitSystem
  var autopause = Preferences.instance.autopause
  private var unitString = "km"
  
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Settings"
    setupNavbar()
    updateUnitString()
  }
  private func updateUnitString() {
    unitString = unitSystem ? "km" : "mi"
  }
  
  private func setupNavbar() {
    let navBar = navigationController!.navigationBar
    navBar.barTintColor = UIColor.blackColor()
    navBar.tintColor = UIColor.whiteColor()
    navBar.translucent = false
    
    let nav = UIBarButtonItem(title: "Done", style: .Done, target: self, action: "dismiss")
    navigationItem.rightBarButtonItem = nav
  }
  func dismiss() {
    dismissViewControllerAnimated(true, completion: nil)
  }
  
  override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
    return 6
  }
  
  override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    switch section {
    case 1, 2: return 3
    default: return 1
    }
  }
  
  override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
    return 60.0
  }
  
  override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
    let xview = UIView()
    xview.backgroundColor = UIColor.lightGrayColor()
    return xview
  }
  weak var uiswitch:UISwitch?
  override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    let cell = UITableViewCell()
    cell.backgroundColor = UIColor.blackColor()
    cell.textLabel?.textColor = UIColor.whiteColor()
    switch indexPath.section {
    case 0:
      cell.textLabel?.text = "No Feedback"
    case 1:
      switch indexPath.row {
      case 0: cell.textLabel?.text = "1.0 \(unitString)"
      case 1: cell.textLabel?.text = "1.5 \(unitString)"
      case 2: cell.textLabel?.text = "2.0 \(unitString)"
      default: break
      }
    case 2:
      switch indexPath.row {
      case 0: cell.textLabel?.text = "5:00 min"
      case 1: cell.textLabel?.text = "10:00 min"
      case 2: cell.textLabel?.text = "15:00 min"
      default: break
      }
    case 3: cell.textLabel?.text = unitSystem ? "Metric" : "Imperial"
    case 4: cell.textLabel?.text = "Pace tracking"
    case 5:
      if let uiswitch = uiswitch {
        cell.addSubview(uiswitch)
      } else {
        let _uiswitch = UISwitch()
        cell.addSubview(_uiswitch)
        uiswitch = _uiswitch
      }
      cell.selectionStyle = .None
      uiswitch!.center = CGPointMake(view.frame.size.width * 0.9, 20)
      uiswitch!.on = autopause
      uiswitch!.addTarget(self, action: "toggleAutopause:", forControlEvents: .ValueChanged)
      cell.textLabel?.text = "Autopause"
    default: break
    }
    return cell
  }
  override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
    switch indexPath.section {
    case 0: setNoSound()
    case 1: setDistance(indexPath.row)
    case 2: setTime(indexPath.row)
    case 3: toggleMetric()
    case 4: paceSelect()
    default: break
    }
  }
  func toggleAutopause(uiswitch:UISwitch) {
    autopause = !autopause
    Preferences.instance.autopause = autopause
    uiswitch.setOn(autopause, animated: true)
  }
  private func setNoSound() {
    Preferences.instance.voiceFeedbackEnabled = 0
    delegate!.updateFeedbackLabel(0, value: 0)
    dismiss()
  }
  private func setDistance(value:Int) {
    Preferences.instance.voiceFeedbackEnabled = 1
    Preferences.instance.voiceFeedbackDistance = value
    delegate!.updateFeedbackLabel(1, value: value)
    dismiss()
  }
  private func setTime(value:Int) {
    Preferences.instance.voiceFeedbackEnabled = 2
    delegate!.updateFeedbackLabel(2, value: value)
    Preferences.instance.voiceFeedbackTime = value
    dismiss()
  }
  private func toggleMetric() {
    let prefs = Preferences.instance
    unitSystem = !prefs.unitSystem
    prefs.unitSystem = unitSystem
    updateUnitString()
    delegate!.updateUnitSystem(unitSystem)
    tableView.reloadData()
  }
  private func paceSelect() {
    
  }
}