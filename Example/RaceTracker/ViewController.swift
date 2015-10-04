//
//  ViewController.swift
//  RaceTracker
//
//  Created by Ernesto Cambuston on 10/03/2015.
//  Copyright (c) 2015 Ernesto Cambuston. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
  private var unitSystem:Bool
  override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
    unitSystem = Preferences.instance.unitSystem
    distanceProvider = RunDistancePickerProvider(units: unitSystem)
    timeProvider = RunTimePickerProvider()
    super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
  }

  required init?(coder aDecoder: NSCoder) {
    unitSystem = Preferences.instance.unitSystem
    distanceProvider = RunDistancePickerProvider(units: unitSystem)
    timeProvider = RunTimePickerProvider()
    super.init(coder: aDecoder)
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

  @IBAction func goRunning(sender: AnyObject) {
    performSegueWithIdentifier("", sender: nil)
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
