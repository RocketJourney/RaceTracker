//
//  RunSpanishSpeaker.swift
//  RJv1
//
//  Created by Ernesto Cambuston on 5/2/15.
//  Copyright (c) 2015 Ernesto Cambuston. All rights reserved.
//

import Foundation

class RunSpanishSpeaker : RunTrackerSpeechLanguageProvider {
  private var _unitSystem = false
  var unitSystem:Bool {
    set(value) {
      _unitSystem = value
      if value {
        units = "kilómetros"
        unit = "kilómetro"
      } else {
        units = "millas"
        unit = "milla"
      }
    }
    get {
      return _unitSystem
    }
  }
  private var unit = ""
  private var units = ""
  private func distanceString(distance:DistanceStructure)->String {
    var string = "distancia,.. \(distance.firstUnit) "
    if distance.secondUnit < 10 {
      if distance.firstUnit == 1 {
        string += unit
      } else {
        string += units
      }
    } else {
      string += "punto \(printFirst(distance.secondUnit)) \(units),"
    }
    string += ",...  "
    return string
  }
  private func printFirst(number:Int)->String {
    let string = Array(arrayLiteral: "\(number)".characters)[0]
    return String(string.first!)
  }
  private func timeString(time:TimeStructure)->String {
    var string = " tiempo,.. "
    if time.hours != 0 {
      if time.hours == 1 {
       string += "una hora, "
      } else {
      string += "\(time.hours) horas, "
      }
    }
    if time.minutes == 1 {
      string += " \(time.minutes) minuto"
    } else {
      string += " \(time.minutes) minutos"
    }
    string += ", con \(time.seconds) segundos,...  "
    return string
  }
  private func paceString(pace:PaceStructure)->String{
    return " ritmo promedio: \(pace.firstUnit) minutos, \(pace.secondUnit) segundos por \(unit)"
  }
  
  func sayFeedback(time:TimeStructure, distance:DistanceStructure, pace:PaceStructure)->String {
    var string = distanceString(distance)
    string += timeString(time)
    string += paceString(pace)
    return string
  }
  func sayFeedbackDecremental(time:TimeStructure, distance:DistanceStructure, pace:PaceStructure)->String {
    var string = " restan solo \(distance.firstUnit) punto \(distance.secondUnit) \(units),...  "
    string += timeString(time)
    string += paceString(pace)
    return string
  }
  func sayMidpoint(time:TimeStructure, distance:DistanceStructure, pace:PaceStructure)->String {
    return " mitad del camino,... " + sayFeedbackDecremental(time, distance: distance, pace: pace)
  }
  func sayGoalAchieved(time:TimeStructure, distance:DistanceStructure, pace:PaceStructure)->String {
    return " meta alcanzada,... " + sayFeedback(time, distance: distance, pace: pace)
  }
  func sayLastSprint(time:TimeStructure, distance:DistanceStructure, pace:PaceStructure)->String {
    return " ultimo estiron,... adelante,... "
  }
}