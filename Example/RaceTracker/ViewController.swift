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
  private var unitSystem:Bool
  private var unitString:String
  override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
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
  
  private func updatedDistance(distance:Int) {
    Preferences.instance.lastDistanceSelected = distance
  }
  
  private func updateTime(timePosition:Int) {
    Preferences.instance.lastTimeSelected = timePosition
  }
  
  private let distanceProvider:RunDistancePickerProvider
  private let timeProvider:RunTimePickerProvider
  
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
    NSNotificationCenter.defaultCenter().addObserver(self, selector: "setupGps", name: UIApplicationDidBecomeActiveNotification, object: nil)
  }
  
  override func viewDidDisappear(animated: Bool) {
    super.viewDidDisappear(animated)
    NSNotificationCenter.defaultCenter().removeObserver(self)
  }
  
  private func setupPickerViews() {
    distancePickerView.delegate = distanceProvider
    distancePickerView.dataSource = distanceProvider
    timePickerView.delegate = timeProvider
    timePickerView.dataSource = timeProvider
    distancePickerView.selectRow(Preferences.instance.lastDistanceSelected, inComponent: 0, animated: false)
    timePickerView.selectRow(Preferences.instance.lastTimeSelected, inComponent: 0, animated: false)
  }
  
  private func setupLastSelected() {
    let lastSelected = Preferences.instance.lastRunType
    segmentControl.selectedSegmentIndex = lastSelected
    changeTo(lastSelected)
    setupFeedbackBtn()
  }
  private func setupFeedbackBtn() {
    let prefs = Preferences.instance
    let feedbackType = prefs.voiceFeedbackEnabled
    let feedbackValue = prefs.voiceFeedbackValue
    updateFeedbackLabel(feedbackType, value: feedbackValue)
  }
  
  private func setFeedbackTitle(string:String) {
    feedbackBtn.setTitle(string, forState: .Normal)
  }
  
  private func setupStyle() {
    goBtn.layer.cornerRadius = goBtn.frame.size.height / 2
    goBtn.layer.masksToBounds = true
  }
  
  @IBAction func goSettings(sender: AnyObject) {
    UIApplication.sharedApplication().openURL(NSURL(string: UIApplicationOpenSettingsURLString)!)

  }
  
  func setupGps() {
    let status = CLLocationManager.authorizationStatus()
    switch status {
    case .AuthorizedWhenInUse, .AuthorizedAlways: showViewIfAvailable()
    case .Denied, .Restricted: _goToSettings()
    case .NotDetermined: locationManager.requestWhenInUseAuthorization()
    }
  }

  @IBAction func goRunning(sender: AnyObject) {
    performSegueWithIdentifier("kGoRunningSegue", sender: nil)
  }
  
  @IBAction func feedbackAction(sender: AnyObject) {
    performSegueWithIdentifier("kGoRunSettings", sender: nil)
  }
  
  @IBAction func changedTab(sender: UISegmentedControl) {
    let number = sender.selectedSegmentIndex
    Preferences.instance.lastRunType = number
    changeTo(number)
  }
  private func changeTo(num:Int) {
    switch num {
    case 1: pickDistance()
    case 2: pickTime()
    default: pickFree()
    }
  }
  @IBOutlet weak var goToSettingsView: UIView!
  
  private func pickDistance() {
    distanceRunView.hidden = false
    timeRunView.hidden = true
  }
  
  private func pickTime() {
    distanceRunView.hidden = true
    timeRunView.hidden = false
  }
  
  private func pickFree() {
    distanceRunView.hidden = true
    timeRunView.hidden = true
  }
  @IBOutlet weak var unitLabel: UILabel!
}

extension ViewController:RunSettingsDelegate {
  func updateUnitSystem(unitSystem:Bool) {
    unitString = unitSystem ? "km" : "mi"
    unitLabel.text = unitString
    self.unitSystem = unitSystem
    setupFeedbackBtn()
  }
  func updateFeedbackLabel(type:Int, value:Int) {
    switch type {
    case 0: setFeedbackTitle("No Music")
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
  private func showViewIfAvailable() {
    goToSettingsView.hidden = true
    goBtn.hidden = false
    segmentControl.hidden = false
    feedbackBtn.hidden = false
    changeTo(segmentControl.selectedSegmentIndex)
  }
  private func askForGpsPermissions() {
    goToSettingsView.hidden = true
    goBtn.hidden = true
    segmentControl.hidden = true
    feedbackBtn.hidden = true
    timeRunView.hidden = true
    distanceRunView.hidden = true
  }
  private func _goToSettings() {
    goToSettingsView.hidden = false
    goBtn.hidden = true
    segmentControl.hidden = true
    feedbackBtn.hidden = true
    timeRunView.hidden = true
    distanceRunView.hidden = true
  }
  func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
    switch status {
    case .AuthorizedWhenInUse: showViewIfAvailable()
    case .NotDetermined: askForGpsPermissions()
    case .Restricted, .Denied: _goToSettings()
    default: break
    }
  }
}