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
  fileprivate let kLastRunType = "kLastRunType"
  var lastRunType:Int {
    get {
      return UserDefaults.standard.integer(forKey: kLastRunType)
    }
    set(value) {
      UserDefaults.standard.set(value, forKey: kLastRunType)
    }
  }
  fileprivate let kUnitSystem = "kUnitSystem"
  var unitSystem:Bool {
    get {
      return UserDefaults.standard.bool(forKey: kUnitSystem)
    }
    set(value) {
      UserDefaults.standard.set(value, forKey: kUnitSystem)
    }
  }
  fileprivate let lastDistance = "kLastDistance"
  var lastDistanceSelected:Int {
    get {
      return UserDefaults.standard.integer(forKey: lastDistance)
    }
    set(value) {
      UserDefaults.standard.set(value, forKey: lastDistance)
    }
  }
  fileprivate let lastTime = "kLastTime"
  var lastTimeSelected:Int {
    get {
      return UserDefaults.standard.integer(forKey: lastTime)
    }
    set(value) {
      UserDefaults.standard.set(value, forKey: lastTime)
    }
  }
  fileprivate let voiceFeedback = "kVoiceFeedback"
  var voiceFeedbackEnabled:Int {
    get {
      return UserDefaults.standard.integer(forKey: voiceFeedback)
    }
    set(value) {
      UserDefaults.standard.set(value, forKey: voiceFeedback)
    }
  }
  fileprivate let kVoiceFeedbackValue = "kvoiceFeedbackValue"
  var voiceFeedbackDistance:Int {
    get {
      return UserDefaults.standard.integer(forKey: kVoiceFeedbackValue)
    }
    set(value) {
      UserDefaults.standard.set(value, forKey: kVoiceFeedbackValue)
    }
  }
  fileprivate let kVoiceFeedbackTime = "kvoiceFeedbackTime"
  var voiceFeedbackTime:Int {
    get {
      return UserDefaults.standard.integer(forKey: kVoiceFeedbackTime)
    }
    set(value) {
      UserDefaults.standard.set(value, forKey: kVoiceFeedbackTime)
    }
  }
  fileprivate let kAutopauseEnabled = "kAutopauseEnabled"
  var autopause:Bool {
    get {
      return UserDefaults.standard.bool(forKey: kAutopauseEnabled)
    }
    set(value) {
      UserDefaults.standard.set(value, forKey: kAutopauseEnabled)
    }
  }
}
