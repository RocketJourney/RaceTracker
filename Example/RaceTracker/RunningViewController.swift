//
//  RunningViewController.swift
//  RaceTracker
//
//  Created by Ernesto Cambuston on 10/4/15.
//  Copyright © 2015 CocoaPods. All rights reserved.
//

import UIKit

class RunningViewController:UIViewController {
  @IBOutlet weak var distanceLabel: UILabel!
  @IBOutlet weak var paceLabel: UILabel!
  @IBOutlet weak var timeLabel: UILabel!
  @IBOutlet weak var pauseButton: UIButton!
  private var tracker:RaceTracker
  @IBOutlet weak var slider: UISlider!
  override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
    let preferences = Preferences.instance
    let runType = RunType(rawValue: preferences.lastRunType)!
    var value:Int
    switch runType {
    case .None:
      value = 0
    case .Distance:
      value = preferences.lastDistanceSelected
    case .Time:
      value = preferences.lastTimeSelected
    }
    let setup = RunSetup(unitSystem:preferences.unitSystem,voiceFeedback:RunType(rawValue: preferences.voiceFeedbackEnabled)!,goalType:runType, goalValue: value)
    tracker = RaceTracker(setup: setup)
    super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
  }

  required init?(coder aDecoder: NSCoder) {
    let preferences = Preferences.instance
    let runType = RunType(rawValue: preferences.lastRunType)!
    var value:Int
    switch runType {
    case .None:
      value = 0
    case .Distance:
      value = preferences.lastDistanceSelected
    case .Time:
      value = preferences.lastTimeSelected
    }
    let setup = RunSetup(unitSystem:preferences.unitSystem,voiceFeedback:RunType(rawValue: preferences.voiceFeedbackEnabled)!,goalType:runType, goalValue: value)
    tracker = RaceTracker(setup: setup)
    super.init(coder: aDecoder)
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    tracker.delegate = self
    tracker.startTracking()
  }
  var lastColor:UIColor?
  @IBAction func togglePause(sender: UIButton) {
    if sender.tag == 0 {
      lastColor = pauseButton.borderColor
      pauseButton.borderColor = UIColor.redColor()
      pauseButton.titleLabel?.text = "Pause"
      sender.tag = 1
      tracker.resumeRun()
    } else if sender.tag == 1 {
      pauseButton.titleLabel?.text = "Resume"
      pauseButton.borderColor = lastColor
      sender.tag = 0
      tracker.pauseRun()
    }
  }
}

extension RunningViewController:RaceTrackerDelegate {
  private func timeText(hours:Int, minutes:Int, seconds:Int)->String {
    var hoursString = hours == 0 ? "" : "\(hours):"
    if minutes < 10 {
      hoursString.appendContentsOf("0\(minutes):")
    } else {
      hoursString.appendContentsOf("\(minutes):")
    }
    if seconds < 10 {
      hoursString.appendContentsOf("0\(seconds)")
    } else {
      hoursString.appendContentsOf("\(seconds)")
    }
    return hoursString
  }
  private func paceText(firstUnit:Int, secondUnit:Int)->String {
    var firstUnit = "\(firstUnit)'"
    if secondUnit < 10 {
      firstUnit.appendContentsOf("0\(secondUnit)''")
    } else {
      firstUnit.appendContentsOf("\(secondUnit)''")
    }
    return firstUnit
  }
  private func distanceText(firstUnit:Int, secondUnit:Int)->String {
    var firstUnit = "\(firstUnit)."
    if secondUnit < 10 {
      firstUnit.appendContentsOf("0\(secondUnit)")
    } else {
      firstUnit.appendContentsOf("\(secondUnit)")
    }
    return firstUnit
  }
  func updateViews(time: TimeStructure, distance: DistanceStructure, pace: PaceStructure, percent:Float) {
    timeLabel.text = timeText(time.hours, minutes: time.minutes, seconds: time.seconds)
    distanceLabel.text = distanceText(distance.firstUnit, secondUnit: distance.secondUnit)
    paceLabel.text = paceText(pace.firstUnit, secondUnit: pace.secondUnit)
  }
  func logDescriptionString(string:String) {
    print(string)
  }
  func goalCompletion(percent:Double) {
    slider.value = Float(percent)
  }
  func cacheRun(distance:Double,
    time:Int,
    calories:Int,
    elevation:Double,
    coordinates:[RaceCoordinate],
    metricMilestones:[Int]?,
    royalMilestones:[Int]?) {
      
  }
  func setIdle(isIdle:Bool) {
    
  }
}