//
//  RunningViewController.swift
//  RaceTracker
//
//  Created by Ernesto Cambuston on 10/4/15.
//  Copyright © 2015 CocoaPods. All rights reserved.
//

import UIKit
import RaceTracker

class RunningViewController:UIViewController {
  @IBOutlet weak var distanceLabel: UILabel!
  @IBOutlet weak var paceLabel: UILabel!
  @IBOutlet weak var timeLabel: UILabel!
  @IBOutlet weak var pauseButton: UIButton!
  private var tracker = RaceTracker(setup: RunSetup.getSetup)
  @IBOutlet weak var slider: UISlider!

  private let speaker = Speaker()
  
  override func viewDidLoad() {
    super.viewDidLoad()
    tracker.delegate = self
    tracker.startTracking()
    speaker.speak("Beginning workout")
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
    speaker.speak(string)
  }
  func cacheRun(distance:Double,
    time:Int,
    calories:Int,
    elevation:Double,
    metricMilestones:Array<Int>,
    royalMilestones:Array<Int>,
    coordinates:Array<Coordinate>) -> () {
      
  }
  func goalCompletion(percent:Double) {
    slider.value = Float(percent)
  }
  
  func setIdle(isIdle:Bool) {
    
  }
}


extension RunSetup {
  static var getSetup:RunSetup {
    get {
      let preferences = Preferences.instance
      let unitSystem = preferences.unitSystem
      let runType = RunType(rawValue: preferences.lastRunType)!
      let goalDistance = (1.5 + (Double(preferences.lastDistanceSelected) * 0.5)) * (unitSystem ? 1000.0 : 1609.0)
      let goalTime = (preferences.lastTimeSelected + 1) * 5 * 60
      let voiceFeedbackType = RunType(rawValue: preferences.voiceFeedbackEnabled)!
      let _voiceDistance = preferences.voiceFeedbackDistance + 1
      var voiceDistance:Double
      let conversion =  unitSystem ? 1.0 : 1.609
      switch _voiceDistance {
      case 1: voiceDistance =  1000.0 * conversion
      case 2: voiceDistance =  1500.0 * conversion
      case 3: voiceDistance =  2000.0 * conversion
      default: voiceDistance = 0.0
      }
      let _voiceTime = preferences.voiceFeedbackTime + 1
      let voiceTime =  _voiceTime * 3000
      let setup = RunSetup(unitSystem:unitSystem,voiceFeedback:voiceFeedbackType,voiceDistance: voiceDistance, voiceTime: voiceTime, goalType:runType, goalDistance: Double(goalDistance), goalTime: goalTime)
      return setup
    }
  }
}