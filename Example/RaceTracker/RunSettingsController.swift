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
  override func viewDidLoad() {
    super.viewDidLoad()
    
  }
}