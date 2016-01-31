//
//  RunEnglishSpeaker.swift
//  RJv1
//
//  Created by Ernesto Cambuston on 5/2/15.
//  Copyright (c) 2015 Ernesto Cambuston. All rights reserved.
//

import Foundation

class RunEnglishSpeaker : RunTrackerSpeechLanguageProvider {
  private var _unitSystem = false
  var unitSystem:Bool {
    set(value) {
      _unitSystem = value
      if value {
        units = "kilometers"
        unit = "kilometer"
      } else {
        units = "miles"
        unit = "mile"
      }
    }
    get {
      return _unitSystem
    }
  }
  private var unit = ""
  private var units = ""
  private func timeString(time:TimeStructure)->String {
    var string = "  time.. "
    if time.hours != 0 {
      if time.hours == 1 {
        string += "\(time.hours) hour, "
      } else {
        string += "\(time.hours) hours, "
      }
    }
    string += "\(time.minutes) "
    if time.minutes == 1 {
      string += "minute"
    } else {
      string += "minutes"
    }
    string += ", \(time.seconds) "
    if time.seconds == 1 {
      string += "second,.."
    } else {
      string += "seconds,.."
    }
    return string
  }
  func sayFeedback(time:TimeStructure, distance:DistanceStructure, pace:PaceStructure)->String {
    var string = "          distance,..  \(distance.firstUnit), "
    if distance.secondUnit > 9 {
      string += "point  "
      string += printFirst(distance.secondUnit)
    }
    if distance.firstUnit == 1 && distance.secondUnit <= 9 {
      string += " \(unit) completed,.. "
    } else {
      string += " \(units) completed,.. "
    }
    string += timeString(time)
    string += "   "
    string += paceString(pace) + "         "
    return string
  }
  private func printFirst(number:Int)->String {
    let string = Array(arrayLiteral: "\(number)".characters)[0]
    return String(string.first!)
  }
  private func paceString(pace:PaceStructure)->String{
    return " average pace,.. \(pace.firstUnit) minutes, \(pace.secondUnit) seconds per \(unit) "
  }
  func sayFeedbackDecremental(time:TimeStructure, distance:DistanceStructure, pace:PaceStructure)->String {
    return "          \(distance.firstUnit) point \(printFirst(distance.secondUnit)) \(units) to go... \(timeString(time)),.. Average pace.., \(pace.firstUnit) minutes, \(pace.secondUnit) seconds per \(unit)          "
  }
  func sayMidpoint(time:TimeStructure, distance:DistanceStructure, pace:PaceStructure)->String {
    return "          mid point,... " + sayFeedbackDecremental(time, distance: distance, pace: pace)
  }
  func sayGoalAchieved(time:TimeStructure, distance:DistanceStructure, pace:PaceStructure)->String {
    return "          goal achieved!,..    " + sayFeedback(time, distance: distance, pace: pace)
  }
  func sayLastSprint(time:TimeStructure, distance:DistanceStructure, pace:PaceStructure)->String {
    return "          last sprint.          "
  }
}