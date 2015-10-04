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
    let viewController = sourceViewController as! ViewController
    let settingsController = destinationViewController as! RunSettingsController
    
    let navController = UINavigationController(rootViewController: settingsController)
    viewController.presentViewController(navController, animated: true, completion: nil)
  }
}