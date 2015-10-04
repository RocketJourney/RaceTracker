//
//  RunEnglishSpeaker.swift
//  RJv1
//
//  Created by Ernesto Cambuston on 5/2/15.
//  Copyright (c) 2015 Ernesto Cambuston. All rights reserved.
//

import Foundation

class RunEnglishSpeaker : RunTrackerSpeechLanguageProvider {
  var unitSystem:Bool {
    set(value) {
      if value {
        units = "kilometers"
      } else {
        units = "miles"
      }
    }
    get {
      return units == "miles" ? false : true
    }
  }
  private var units = ""
  func sayFeedback(time:TimeStructure, distance:DistanceStructure, pace:PaceStructure)->String {
    var string = "distance, \(distance.firstUnit), point \(distance.secondUnit) \(units) completed,  time.. "
    if time.hours != 0 {
      string += "\(time.hours) hour, "
    }
    string += "\(time.minutes) minutes, \(time.seconds) seconds,..   average pace, \(pace.firstUnit) minutes, \(pace.secondUnit) seconds per \(units)"
    return string
  }
  func sayFeedbackDecremental(time:TimeStructure, distance:DistanceStructure, pace:PaceStructure)->String {
    return " \(distance.firstUnit) point \(distance.secondUnit) \(units) to go. average pace, \(pace.firstUnit) minutes, \(pace.secondUnit) seconds per \(units)"
  }
  func sayMidpoint(time:TimeStructure, distance:DistanceStructure, pace:PaceStructure)->String {
    return " mid point. " + sayFeedbackDecremental(time, distance: distance, pace: pace)
  }
  func sayGoalAchieved(time:TimeStructure, distance:DistanceStructure, pace:PaceStructure)->String {
    return " goal achieved!. " + sayFeedback(time, distance: distance, pace: pace)
  }
  func sayLastSprint(time:TimeStructure, distance:DistanceStructure, pace:PaceStructure)->String {
    return " last sprint. "
  }
}