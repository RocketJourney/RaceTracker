//
//  Preferences.swift
//  RaceTracker
//
//  Created by Ernesto Cambuston on 10/4/15.
//  Copyright © 2015 CocoaPods. All rights reserved.
//

import Foundation

class Preferences {
  class var instance: Preferences {
    struct Static {
      static let instance: Preferences = Preferences()
    }
    return Static.instance
  }
  private let kLastRunType = "kLastRunType"
  var lastRunType:Int {
    get {
      return NSUserDefaults.standardUserDefaults().integerForKey(kLastRunType)
    }
    set(value) {
      NSUserDefaults.standardUserDefaults().setInteger(value, forKey: kLastRunType)
    }
  }
  private let kUnitSystem = "kUnitSystem"
  var unitSystem:Bool {
    get {
      return NSUserDefaults.standardUserDefaults().boolForKey(kUnitSystem)
    }
    set(value) {
      NSUserDefaults.standardUserDefaults().setBool(value, forKey: kUnitSystem)
    }
  }
  private let lastDistance = "kLastDistance"
  var lastDistanceSelected:Int {
    get {
      return NSUserDefaults.standardUserDefaults().integerForKey(lastDistance)
    }
    set(value) {
      NSUserDefaults.standardUserDefaults().setInteger(value, forKey: lastDistance)
    }
  }
  private let lastTime = "kLastTime"
  var lastTimeSelected:Int {
    get {
      return NSUserDefaults.standardUserDefaults().integerForKey(lastTime)
    }
    set(value) {
      NSUserDefaults.standardUserDefaults().setInteger(value, forKey: lastTime)
    }
  }
  private let voiceFeedback = "kVoiceFeedback"
  var voiceFeedbackEnabled:Int {
    get {
      return NSUserDefaults.standardUserDefaults().integerForKey(voiceFeedback)
    }
    set(value) {
      NSUserDefaults.standardUserDefaults().setInteger(value, forKey: voiceFeedback)
    }
  }
  private let kVoiceFeedbackValue = "kvoiceFeedbackValue"
  var voiceFeedbackDistance:Int {
    get {
      return NSUserDefaults.standardUserDefaults().integerForKey(kVoiceFeedbackValue)
    }
    set(value) {
      NSUserDefaults.standardUserDefaults().setInteger(value, forKey: kVoiceFeedbackValue)
    }
  }
  private let kVoiceFeedbackTime = "kvoiceFeedbackTime"
  var voiceFeedbackTime:Int {
    get {
      return NSUserDefaults.standardUserDefaults().integerForKey(kVoiceFeedbackTime)
    }
    set(value) {
      NSUserDefaults.standardUserDefaults().setInteger(value, forKey: kVoiceFeedbackTime)
    }
  }
  private let kAutopauseEnabled = "kAutopauseEnabled"
  var autopause:Bool {
    get {
      return NSUserDefaults.standardUserDefaults().boolForKey(kAutopauseEnabled)
    }
    set(value) {
      NSUserDefaults.standardUserDefaults().setBool(value, forKey: kAutopauseEnabled)
    }
  }
}