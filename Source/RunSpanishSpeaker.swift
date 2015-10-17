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
  func sayFeedback(time:TimeStructure, distance:DistanceStructure, pace:PaceStructure)->String {
    var string = " distancia: \(distance.firstUnit) punto \(distance.secondUnit) \(units) completado,.. tiempo: "
    if time.hours != 0 {
      string += "\(time.hours) horas, "
    }
    string += " \(time.minutes) minutos, con \(time.seconds) segundos,.. ritmo promedio: \(pace.firstUnit) minutos, \(pace.secondUnit) segundos por \(unit)"
    return string
  }
  func sayFeedbackDecremental(time:TimeStructure, distance:DistanceStructure, pace:PaceStructure)->String {
    var string = " restan solo \(distance.firstUnit) punto \(distance.secondUnit) \(units) más,..  tiempo: "
    if time.hours != 0 {
      string += "\(time.hours) horas, "
    }
    string += " \(time.minutes) minutos, \(time.seconds) segundos,... ritmo promedio: \(pace.firstUnit) minutos, \(pace.secondUnit) segundos por \(unit)"
    return string
  }
  func sayMidpoint(time:TimeStructure, distance:DistanceStructure, pace:PaceStructure)->String {
    return " mitad del camino. " + sayFeedbackDecremental(time, distance: distance, pace: pace)
  }
  func sayGoalAchieved(time:TimeStructure, distance:DistanceStructure, pace:PaceStructure)->String {
    return " meta alcanzada. " + sayFeedback(time, distance: distance, pace: pace)
  }
  func sayLastSprint(time:TimeStructure, distance:DistanceStructure, pace:PaceStructure)->String {
    return " ultimo estiron. adelante."
  }
}