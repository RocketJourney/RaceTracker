//
//  GoRunSettings.swift
//  RaceTracker
//
//  Created by Ernesto Cambuston on 10/4/15.
//  Copyright © 2015 CocoaPods. All rights reserved.
//

import UIKit

class GoRunSettings:UIStoryboardSegue {
  override func perform() {
    let viewController = source as! ViewController
    let settingsController = destination as! RunSettingsController
    settingsController.delegate = viewController
    let navController = UINavigationController(rootViewController: settingsController)
    viewController.present(navController, animated: true, completion: nil)
  }
}
