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
  override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
    unitSystem = Preferences.instance.unitSystem
    distanceProvider = RunDistancePickerProvider(units: unitSystem)
    timeProvider = RunTimePickerProvider()
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
  }
  private func setupLastSelected() {
    let lastSelected = Preferences.instance.lastRunType
    segmentControl.selectedSegmentIndex = lastSelected
    changeTo(lastSelected)
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
}

extension ViewController:RunSettingsDelegate {
  func updateUnitSystem(unitSystem:Bool) {
    
  }
  func updateFeedbackSettings() {
    
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