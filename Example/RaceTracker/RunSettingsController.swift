//
//  RunSetingsController.swift
//  RaceTracker
//
//  Created by Ernesto Cambuston on 10/4/15.
//  Copyright © 2015 CocoaPods. All rights reserved.
//

import UIKit

protocol RunSettingsDelegate {
  func updateUnitSystem(_ unitSystem:Bool)
  func updateFeedbackLabel(_ type:Int, value:Int)
}

class RunSettingsController : UITableViewController {
  var delegate:RunSettingsDelegate?
  var unitSystem = Preferences.instance.unitSystem
  var autopause = Preferences.instance.autopause
  fileprivate var unitString = "km"
  
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Settings"
    setupNavbar()
    updateUnitString()
  }
  fileprivate func updateUnitString() {
    unitString = unitSystem ? "km" : "mi"
  }
  
  fileprivate func setupNavbar() {
    let navBar = navigationController!.navigationBar
    navBar.barTintColor = UIColor.black
    navBar.tintColor = UIColor.white
    navBar.isTranslucent = false
    
    let nav = UIBarButtonItem(title: "Done", style: .done, target: self, action: "dismiss")
    navigationItem.rightBarButtonItem = nav
  }
  func dismiss() {
    self.dismiss(animated: true, completion: nil)
  }
  
  override func numberOfSections(in tableView: UITableView) -> Int {
    return 6
  }
  
  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    switch section {
    case 1, 2: return 3
    default: return 1
    }
  }
  
  override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
    return 60.0
  }
  
  override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
    let xview = UIView()
    xview.backgroundColor = UIColor.lightGray
    return xview
  }
  weak var uiswitch:UISwitch?
  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = UITableViewCell()
    cell.backgroundColor = UIColor.black
    cell.textLabel?.textColor = UIColor.white
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
      cell.selectionStyle = .none
      uiswitch!.center = CGPoint(x: view.frame.size.width * 0.9, y: 20)
      uiswitch!.isOn = autopause
      uiswitch!.addTarget(self, action: "toggleAutopause:", for: .valueChanged)
      cell.textLabel?.text = "Autopause"
    default: break
    }
    return cell
  }
  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    switch indexPath.section {
    case 0: setNoSound()
    case 1: setDistance(indexPath.row)
    case 2: setTime(indexPath.row)
    case 3: toggleMetric()
    case 4: paceSelect()
    default: break
    }
  }
  func toggleAutopause(_ uiswitch:UISwitch) {
    autopause = !autopause
    Preferences.instance.autopause = autopause
    uiswitch.setOn(autopause, animated: true)
  }
  fileprivate func setNoSound() {
    Preferences.instance.voiceFeedbackEnabled = 0
    delegate!.updateFeedbackLabel(0, value: 0)
    dismiss()
  }
  fileprivate func setDistance(_ value:Int) {
    Preferences.instance.voiceFeedbackEnabled = 1
    Preferences.instance.voiceFeedbackDistance = value
    delegate!.updateFeedbackLabel(1, value: value)
    dismiss()
  }
  fileprivate func setTime(_ value:Int) {
    Preferences.instance.voiceFeedbackEnabled = 2
    delegate!.updateFeedbackLabel(2, value: value)
    Preferences.instance.voiceFeedbackTime = value
    dismiss()
  }
  fileprivate func toggleMetric() {
    let prefs = Preferences.instance
    unitSystem = !prefs.unitSystem
    prefs.unitSystem = unitSystem
    updateUnitString()
    delegate!.updateUnitSystem(unitSystem)
    tableView.reloadData()
  }
  fileprivate func paceSelect() {
    
  }
}
