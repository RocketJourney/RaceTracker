//
//  ViewController.swift
//  RaceTracker
//
//  Created by Ernesto Cambuston on 10/03/2015.
//  Copyright (c) 2015 Ernesto Cambuston. All rights reserved.
//

import UIKit
import CoreLocation

class ViewController: UIViewController {
  var locationManager = CLLocationManager()
  fileprivate var unitSystem:Bool
  fileprivate var unitString:String
  override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
    unitSystem = Preferences.instance.unitSystem
    distanceProvider = RunDistancePickerProvider(units: unitSystem)
    timeProvider = RunTimePickerProvider()
    unitString = unitSystem ? "km" : "mi"
    super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    distanceProvider.updateValue = { value in
      self.updatedDistance(value)
    }
    timeProvider.updateValue = { value in
      self.updateTime(value)
    }
  }

  required init?(coder aDecoder: NSCoder) {
    unitSystem = Preferences.instance.unitSystem
    distanceProvider = RunDistancePickerProvider(units: unitSystem)
    timeProvider = RunTimePickerProvider()
    unitString = unitSystem ? "km" : "mi"
    super.init(coder: aDecoder)
    distanceProvider.updateValue = { value in
      self.updatedDistance(value)
    }
    timeProvider.updateValue = { value in
      self.updateTime(value)
    }
  }
  
  fileprivate func updatedDistance(_ distance:Int) {
    Preferences.instance.lastDistanceSelected = distance
  }
  
  fileprivate func updateTime(_ timePosition:Int) {
    Preferences.instance.lastTimeSelected = timePosition
  }
  
  fileprivate let distanceProvider:RunDistancePickerProvider
  fileprivate let timeProvider:RunTimePickerProvider
  
  @IBOutlet weak var distanceRunView: UIView!
  @IBOutlet weak var timeRunView: UIView!
  @IBOutlet weak var distancePickerView: UIPickerView!
  @IBOutlet weak var timePickerView: UIPickerView!
  @IBOutlet weak var goBtn: UIButton!
  @IBOutlet weak var segmentControl: UISegmentedControl!
  @IBOutlet weak var feedbackBtn: UIButton!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    setupPickerViews()
    setupLastSelected()
    setupStyle()
    setupGps()
    updateUnitSystem(unitSystem)
    NotificationCenter.default.addObserver(self, selector: "setupGps", name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
  }
  
  override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    NotificationCenter.default.removeObserver(self)
  }
  
  fileprivate func setupPickerViews() {
    distancePickerView.delegate = distanceProvider
    distancePickerView.dataSource = distanceProvider
    timePickerView.delegate = timeProvider
    timePickerView.dataSource = timeProvider
    distancePickerView.selectRow(Preferences.instance.lastDistanceSelected, inComponent: 0, animated: false)
    timePickerView.selectRow(Preferences.instance.lastTimeSelected, inComponent: 0, animated: false)
  }
  
  fileprivate func setupLastSelected() {
    let lastSelected = Preferences.instance.lastRunType
    segmentControl.selectedSegmentIndex = lastSelected
    changeTo(lastSelected)
    setupFeedbackBtn()
  }
  fileprivate func setupFeedbackBtn() {
    let prefs = Preferences.instance
    let feedbackType = prefs.voiceFeedbackEnabled
    var feedbackValue:Int
    if feedbackType == 1 {
      feedbackValue = prefs.voiceFeedbackDistance
    } else if feedbackType == 2 {
      feedbackValue = prefs.voiceFeedbackTime
    } else {
      feedbackValue = 0
    }
    updateFeedbackLabel(feedbackType, value: feedbackValue)
  }
  
  fileprivate func setFeedbackTitle(_ string:String) {
    feedbackBtn.setTitle(string, for: UIControlState())
  }
  
  fileprivate func setupStyle() {
    goBtn.layer.cornerRadius = goBtn.frame.size.height / 2
    goBtn.layer.masksToBounds = true
  }
  
  @IBAction func goSettings(_ sender: AnyObject) {
    UIApplication.shared.openURL(URL(string: UIApplicationOpenSettingsURLString)!)

  }
  
  func setupGps() {
    let status = CLLocationManager.authorizationStatus()
    switch status {
    case .authorizedWhenInUse, .authorizedAlways: showViewIfAvailable()
    case .denied, .restricted: _goToSettings()
    case .notDetermined: locationManager.requestWhenInUseAuthorization()
    }
  }

  @IBAction func goRunning(_ sender: AnyObject) {
    performSegue(withIdentifier: "kGoRunningSegue", sender: nil)
  }
  
  @IBAction func feedbackAction(_ sender: AnyObject) {
    performSegue(withIdentifier: "kGoRunSettings", sender: nil)
  }
  
  @IBAction func changedTab(_ sender: UISegmentedControl) {
    let number = sender.selectedSegmentIndex
    Preferences.instance.lastRunType = number
    changeTo(number)
  }
  fileprivate func changeTo(_ num:Int) {
    switch num {
    case 1: pickDistance()
    case 2: pickTime()
    default: pickFree()
    }
  }
  @IBOutlet weak var goToSettingsView: UIView!
  
  fileprivate func pickDistance() {
    distanceRunView.isHidden = false
    timeRunView.isHidden = true
  }
  
  fileprivate func pickTime() {
    distanceRunView.isHidden = true
    timeRunView.isHidden = false
  }
  
  fileprivate func pickFree() {
    distanceRunView.isHidden = true
    timeRunView.isHidden = true
  }
  @IBOutlet weak var unitLabel: UILabel!
}

extension ViewController:RunSettingsDelegate {
  func updateUnitSystem(_ unitSystem:Bool) {
    unitString = unitSystem ? "km" : "mi"
    unitLabel.text = unitString
    self.unitSystem = unitSystem
    setupFeedbackBtn()
  }
  func updateFeedbackLabel(_ type:Int, value:Int) {
    switch type {
    case 0: setFeedbackTitle("No Feedback")
    case 1:
      switch value {
      case 0: setFeedbackTitle("1.0 \(unitString)")
      case 1: setFeedbackTitle("1.5 \(unitString)")
      case 2: setFeedbackTitle("2.0 \(unitString)")
      default: break
      }
    case 2:
      switch value {
      case 0: setFeedbackTitle("5:00 min")
      case 1: setFeedbackTitle("10:00 min")
      case 2: setFeedbackTitle("15:00 min")
      default: break
      }
    default: break
    }
  }
}

extension ViewController:CLLocationManagerDelegate {
  fileprivate func showViewIfAvailable() {
    goToSettingsView.isHidden = true
    goBtn.isHidden = false
    segmentControl.isHidden = false
    feedbackBtn.isHidden = false
    changeTo(segmentControl.selectedSegmentIndex)
  }
  fileprivate func askForGpsPermissions() {
    goToSettingsView.isHidden = true
    goBtn.isHidden = true
    segmentControl.isHidden = true
    feedbackBtn.isHidden = true
    timeRunView.isHidden = true
    distanceRunView.isHidden = true
  }
  fileprivate func _goToSettings() {
    goToSettingsView.isHidden = false
    goBtn.isHidden = true
    segmentControl.isHidden = true
    feedbackBtn.isHidden = true
    timeRunView.isHidden = true
    distanceRunView.isHidden = true
  }
  func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
    switch status {
    case .authorizedWhenInUse: showViewIfAvailable()
    case .notDetermined: askForGpsPermissions()
    case .restricted, .denied: _goToSettings()
    default: break
    }
  }
}
