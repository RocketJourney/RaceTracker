//
//  GoRunningSegue.swift
//  RaceTracker
//
//  Created by Ernesto Cambuston on 10/4/15.
//  Copyright © 2015 CocoaPods. All rights reserved.
//

import UIKit

class GoRunningSegue:UIStoryboardSegue {
  override func perform() {
    let mainController = sourceViewController as! ViewController
    let runningController = destinationViewController as! RunningViewController
    
    mainController.navigationController?.pushViewController(runningController, animated: true)
  }
}