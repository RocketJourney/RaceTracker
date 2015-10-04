//
//  RaceTracker.swift
//  RaceTracker
//
//  Created by Ernesto Cambuston on 10/3/15.
//  Copyright © 2015 CocoaPods. All rights reserved.
//
//   This class implements a finite state machine that tracks user running events.
// It also provides an interface you can use to update ui, log or synthesize strings,
// update a progress bar, or cache progress. You can configure distance or time goals,
// if you want to listen relevant feedback.
//
//   Language for log and feedback strings is configured through setLanguage in case you
// want to use an alternative voice.
//
//   To start using just initialize this class with a RunSetup struct, and call startTracking()
// to fire the tracking timer.

import Foundation
import CoreLocation
import AVFoundation

typealias TimeStructure = (hours:Int, minutes:Int, seconds:Int)
typealias DistanceStructure = (firstUnit:Int, secondUnit:Int)
typealias PaceStructure = (firstUnit:Int, secondUnit:Int)

protocol RunTrackerSpeechLanguageProvider {
  func sayFeedback(time:TimeStructure, distance:DistanceStructure, pace:PaceStructure)->String
  func sayFeedbackDecremental(time:TimeStructure, distance:DistanceStructure, pace:PaceStructure)->String
  func sayMidpoint(time:TimeStructure, distance:DistanceStructure, pace:PaceStructure)->String
  func sayGoalAchieved(time:TimeStructure, distance:DistanceStructure, pace:PaceStructure)->String
  func sayLastSprint(time:TimeStructure, distance:DistanceStructure, pace:PaceStructure)->String
}

protocol RaceTrackerDelegate {
  func updateViews(time: TimeStructure, distance: DistanceStructure, pace: PaceStructure, percent:Float)
  func logDescriptionString(string:String)
  func goalCompletion(percent:Double)
  func cacheRun(distance:Double,
    time:Int,
    calories:Int,
    elevation:Double,
    coordinates:[RaceCoordinate],
    metricMilestones:[Int]?,
    royalMilestones:[Int]?)
  func setIdle(isIdle:Bool)
}

enum RunType:Int {
  case None=0
  case Distance=1
  case Time=2
}

struct RunSetup {
  var unitSystem:Bool
  var voiceFeedback:RunType
  var goalType:RunType
  var goalValue:Bool
}

class RaceTracker: NSObject {
  typealias RunMetaData = (pace:Double, segment:Int, time:Int)
  //--------------------------------------------------
  // MARK: - Constants , var definitions, and config.
  //--------------------------------------------------
  //cached to position is used to send only missing run position to the delegate.
  private let oneSecond = 1.0 // once running, this is the time in between tick() calls,
  private var time = 0 //  each second tick gets called, it calculates new metrics, and adds one second to time..
  private let kCalcPeriod = 3 // seconds used to decide how long to wait before calculating metrics.
  private let kLogRequiredAccuracy = 42.0
  private var metric : Bool
  private var conversion : Double
  private var voiceTime = 0
  private var nextVoiceTime = 0
  private var hasGoal : Bool
  private var goalValue : Int
  private var distance : Double = 0.0
  private let updateInterval:Int16 = 3
  private let locationManager = CLLocationManager()
  private var paused = false
  private var pausedForAuto = false
  private var calories = 0
  private var elevation = 0.0
  private var cachedToPosition = 0 //position we cached to, last time we called delegate?.cacheRun(:)
  private var voiceFeedback : RunType
  private var feedbackDistance : Double
  private let date = NSDate()
  private var segment = 1
  // Milestones are references to each mile or kilometer completed.
  private var metricMilestone = Array<Int>()
  private var royalMilestone = Array<Int>()
  private var locationQueue = Array<CLLocation>()
  private var currentRun = Array<CLLocation>()
  private var currentRunMetadata = Array<RunMetaData>()
  
  private var timer : NSTimer?
  private var timeSinceUnpause = NSDate.timeIntervalSinceReferenceDate()
  private var needsResumePosition = false
  private var pace = 0.0
  
  var delegate : RaceTrackerDelegate?
  //--------------------------------------------------
  // MARK: - Initializers
  //--------------------------------------------------
  required init(setup:RunSetup) {
    // Initial state
    metric = setup.unitSystem
    hasGoal = false
    voiceFeedback = setup.voiceFeedback
    goalValue = 1
    conversion = metric == true ? 1000.0 : 1609.0
    feedbackDistance = 1000.0
    super.init()
    locationQueue.reserveCapacity(15000)
    currentRun.reserveCapacity(15000)
    locationManager.delegate = self
    locationManager.distanceFilter = kCLDistanceFilterNone
    locationManager.desiredAccuracy = kCLLocationAccuracyBest
    locationManager.activityType = .Fitness
    
  }
  func setup(metric:Bool, distance:Double?, feedbackType:Int, feedbackValue:Int) {
    if distance != nil {
      hasGoal = true
      goalValue = Int(metric ? distance! : (distance! * 1.609))
      print("Distance goal set @ \(goalValue)")
    } else {
      goalValue = 0
      hasGoal = false
    }
    if feedbackType == 1 {
      voiceFeedback = .Distance
      var value:Double
      if feedbackValue == 0 {
        value = 500.0
      } else if feedbackValue == 1 {
        value = 1000.0
      } else {
        value = 2000.0
      }
      feedbackDistance = metric == true ? value : (value * 1.609)
      reachedNextVoice = feedbackDistance
      print("Voice feedback each \(feedbackDistance) \(metric)")
    } else if feedbackType == 2 {
      voiceFeedback = .Time
      var value:Int
      if feedbackValue == 0 {
        value = 120
      } else if feedbackValue == 1 {
        value = 300
      } else {
        value = 600
      }
      voiceTime = value
      nextVoiceTime = voiceTime
      print("Voice feedback each \(voiceTime) seconds")
    }
  }
  //--------------------------------------------------
  // MARK: - Setup
  //--------------------------------------------------
  func startTracking() {
    locationManager.startUpdatingLocation()
    locationQueue.removeAll(keepCapacity: true)
    currentRun.removeAll(keepCapacity: true)
    setupSpeaker()
    resumeRun()
  }
  func resumeRun() {
    idle(true)
    segment = segment + 1
    paused = false
    timer = NSTimer.scheduledTimerWithTimeInterval(oneSecond, target: self, selector: "tick", userInfo: nil, repeats: true)
    needsResumePosition = true
    
  }
  func pauseRun() {
    paused = true
    timer?.invalidate()
    timeSinceUnpause = NSDate.timeIntervalSinceReferenceDate()
    if pausedForAuto {
      locationManager.stopUpdatingLocation()
      idle(true)
    }
    
  }
  func idle(isIdle:Bool) {
    delegate?.setIdle(isIdle)
  }
  //--------------------------------------------------
  // MARK: - Tracker Runloop
  //--------------------------------------------------
  func tick() {
    if paused {
      self.timer?.invalidate()
      return
    }
    time += 1
    if needsResumePosition {
      needsResumePosition = false
      return
    } else if locationQueue.count > 0 && (time % kCalcPeriod) == 0 {
      calculateMetrics()
      locationQueue.removeAll(keepCapacity: true)
      evaluateAutopause(pace)
      if hasGoal && reachedMidlepoint() {
        checkgoalCompletion()
      } else if reachedNextFeedback() && midpoint == false {
        delegate?.logDescriptionString(sayFeedback())
      }
      assert(currentRun.count == currentRunMetadata.count, "Run must have metadata")
      if (time % 60) == 0 && distance >= 800.0 {
        if let runDiff = getRunDiff() {
          print("Caching run @ \(time) seconds distance \(distance)")
          delegate?.cacheRun(distance, time: time, calories: calories, elevation: elevation, coordinates: runDiff, metricMilestones:[0], royalMilestones:[0])
        }
      }
    } else {
      evaluateAutopause(-1.0)
    }
    delegate?.updateViews(getTime(), distance: getDistance(), pace: getPace(), percent:0.5)
  }
  
  private func reachedMidlepoint()->Bool {
    let goal = Double(goalValue)
    if distance >= goal {
      delegate?.goalCompletion(1.0)
    } else {
      delegate?.goalCompletion(distance / goal)
    }
    if !midpoint && distance > (goal / 2.0) {
      midpoint = true
      delegate?.logDescriptionString(midpointFeedback())
    } else if midpoint == true {
      return true
    }
    return false
  }
  
  private var reachedNextVoice = 0.0
  private func reachedNextFeedback()->Bool {
    if voiceFeedback == .Distance && distance >= reachedNextVoice {
      reachedNextVoice += feedbackDistance
      return true
    } else if voiceFeedback == .Time && time >= nextVoiceTime {
      nextVoiceTime += voiceTime
      return true
    }
    return false
  }
  private func calculateMetrics() {
    if let sampleLocation = locationQueue.last {
      if sampleLocation.horizontalAccuracy <= kLogRequiredAccuracy && currentRun.count > 0 {
        let priorLocation = currentRun.last!
        
        let paceTimeInterval = sampleLocation.timestamp.timeIntervalSinceReferenceDate - priorLocation.timestamp.timeIntervalSinceReferenceDate
        let distanceToAdd = calculateDistanceFrom(priorLocation, newLocation: sampleLocation)
        distance = distance + distanceToAdd
        
        let currentPace = distanceToAdd / paceTimeInterval
        
        //let speedMin = 60 * pace
        
        let climbed = sampleLocation.altitude - priorLocation.altitude
        var grade = 0.0
        if distanceToAdd > 1 {
          grade = climbed / distanceToAdd
        }
        pace = Double(time) / distance
        currentRun.append(sampleLocation)
        currentRunMetadata.append(RunMetaData(pace: currentPace, segment: segment, time: time))
      }
    }
  }
  var consecutiveHeadingCount = 0
  private func calculateDistanceFrom(priorLocation: CLLocation, newLocation: CLLocation)->Double {
    let locationCount = currentRun.count
    var distanceToAdd = 0.0
    if consecutiveHeadingCount > 0 {
      var cumulativeCourseDifferential = 0.0
      for (_, location) in currentRun.enumerate() {
        let diff = fabs(location.course - newLocation.course)
        if NSLocationInRange(Int(diff), NSMakeRange(-20, 40)) {
          self.consecutiveHeadingCount = 0
          break
        }
        cumulativeCourseDifferential += diff
        if cumulativeCourseDifferential > 50.0 {
          self.consecutiveHeadingCount = 0
          break
        }
      }
      //let location = currentRun[locationCount - consecutiveHeadingCount - 1]
      distanceToAdd = newLocation.distanceFromLocation(priorLocation)
    } else {
      let rangeAbs = fabs(priorLocation.course - newLocation.course)
      if NSLocationInRange(Int(rangeAbs), NSMakeRange(-20, 40)) {
        consecutiveHeadingCount += 1
      }
      distanceToAdd = newLocation.distanceFromLocation(priorLocation)
    }
    return distanceToAdd
  }
  private func evaluateAutopause(pace:Double) {
    
  }
  private func getTime()->TimeStructure {
    return convertTimeToTimeStructure(time)
  }
  private func getDistance()->DistanceStructure {
    return convertDistanceToDistanceStructure(distance, conversion: conversion)
  }
  private func getPace()->PaceStructure {
    return convertTimeAndDistanceToPaceStructure(time, distance: distance, conversion: conversion)
  }
  //--------------------------------------------------
  // MARK: - Feedback methods
  //--------------------------------------------------
  private var midpoint = false
  private var completed = false
  private var almostThere = false
  private func checkgoalCompletion() {
    let reachedNext = reachedNextFeedback()
    let goal = Double(goalValue)
    if !completed && midpoint && !almostThere && (goal - distance) < 120 {
      almostThere = true
      delegate?.logDescriptionString(almostThereFeedback())
    } else if almostThere && !completed && distance > goal {
      completed = true
      delegate?.logDescriptionString(goalAchievedFeedback())
    } else if midpoint && !completed && reachedNext {
      delegate?.logDescriptionString(decrementalFeedback())
    } else if reachedNext {
      delegate?.logDescriptionString(sayFeedback())
    }
  }
  
  // MARK - Speaker convenience methods
  private func sayFeedback()->String {
    return speaker!.sayFeedback(convertTimeToTimeStructure(time), distance:convertDistanceToDistanceStructure(distance, conversion: conversion), pace:convertTimeAndDistanceToPaceStructure(time, distance: distance, conversion: conversion))
  }
  private func decrementalFeedback()->String{
    return speaker!.sayFeedbackDecremental(convertTimeToTimeStructure(time), distance:convertDistanceToDistanceStructure(distance, conversion: conversion), pace:convertTimeAndDistanceToPaceStructure(time, distance: distance, conversion: conversion))
  }
  private func midpointFeedback()->String {
    
    return speaker!.sayMidpoint(convertTimeToTimeStructure(time), distance:convertDistanceToDistanceStructure(distance, conversion: conversion), pace:convertTimeAndDistanceToPaceStructure(time, distance: distance, conversion: conversion))
  }
  private func almostThereFeedback()->String {
    return speaker!.sayLastSprint(convertTimeToTimeStructure(time), distance:convertDistanceToDistanceStructure(distance, conversion: conversion), pace:convertTimeAndDistanceToPaceStructure(time, distance: distance, conversion: conversion))
  }
  private func goalAchievedFeedback()->String {
    
    return speaker!.sayGoalAchieved(convertTimeToTimeStructure(time), distance:convertDistanceToDistanceStructure(distance, conversion: conversion), pace:convertTimeAndDistanceToPaceStructure(time, distance: distance, conversion: conversion))
  }
  
  //MARK: - Helpers
  
  func getRunDiff()->Array<RaceCoordinate>? {
    var locArr = [RaceCoordinate]()
    for i in cachedToPosition..<currentRun.count {
      let storedLocation = RaceCoordinate()
      let currCoord = currentRun[i]
      let currCoordMeta = currentRunMetadata[i]
      storedLocation.latitude = currCoord.coordinate.latitude
      storedLocation.longitude = currCoord.coordinate.longitude
      storedLocation.altitude = currCoord.altitude
      storedLocation.section = currCoordMeta.segment
      storedLocation.position = cachedToPosition + i
      locArr.append(storedLocation)
    }
    cachedToPosition = currentRun.count
    return locArr
  }
  
  func finishRun() {
    if let runDiff = getRunDiff() {
      delegate?.cacheRun(distance, time: time, calories: calories, elevation: elevation, coordinates: runDiff, metricMilestones:[0], royalMilestones:[0])
    }
    locationManager.stopUpdatingLocation()
    locationManager.delegate = nil
    timer?.invalidate()
  }
  private var speaker:RunTrackerSpeechLanguageProvider?
  private func setupSpeaker() {
    let code = AVSpeechSynthesisVoice.currentLanguageCode()
    print("Language code \(code)")
    switch code {
    case "es-ES", "es-MX":
      print("Setup spanish speaker")
      setLanguage(RunSpanishSpeaker())
    case "it-IT":
      setLanguage(RunItalianSpeaker())
    case "ja-JP":
      setLanguage(RunJapanneseSpeaker())
    case "fr-CA", "fr-FR":
      setLanguage(RunFrenchSpeaker())
    case "de-DE":
      setLanguage(RunGermanSpeaker())
    case "nl-BE", "nl-NL":
      setLanguage(RunDutchSpeaker())
    case "el-GR":
      setLanguage(RunGreekSpeaker())
    case "zh-CN":
      setLanguage(RunMandarinSpeaker())
    case "zh-HK":
      setLanguage(RunCantoneseSpeaker())
    default:
      print("Setup english speaker")
      setLanguage(RunEnglishSpeaker())
    }
  }
  func setLanguage(speakerLanguage:RunTrackerSpeechLanguageProvider) {
    speaker = speakerLanguage
  }
  
  func convertTimeToTimeStructure(time:Int)->TimeStructure {
    if time < 60 {
      return TimeStructure(hours:0, minutes: 0, seconds: time)
    } else {
      let seconds = time % 60
      let minutes = Int(Double(time) / 60.0)
      if time < 3600 {
        return TimeStructure(hours: 0, minutes: minutes, seconds: seconds)
      } else {
        
        let  _mins = minutes % 60
        return TimeStructure(hours: Int(minutes / 60), minutes: _mins, seconds: seconds)
      }
    }
  }
  func convertDistanceToDistanceStructure(distance:Double, conversion:Double)->DistanceStructure {
    if distance >= conversion {
      let _mainUnit = distance / conversion
      let mainUnit = Int(_mainUnit)
      let enMiles = distance % conversion
      let _secondaryUnit = Int(enMiles / (conversion / 100.0))
      return DistanceStructure(firstUnit:mainUnit, secondUnit: _secondaryUnit)
    } else {
      return DistanceStructure(firstUnit:0, secondUnit: Int(distance / (conversion / 100)))
    }
  }
  func convertTimeAndDistanceToPaceStructure(time:Int, distance:Double, conversion:Double)->PaceStructure {
    if distance < 30 || time < 10 {
      return PaceStructure(0,0)
    } else {
      //    sfloat = (time / (distance > 0.0 ? distance : 1.0)) * ((@isMetric ? 1000.0 : 1609.0) / 60.0)
      //    sf2 = ((sfloat % (sfloat.to_i > 0 ? sfloat.to_i : 1)) * 60.0).to_i
      let averagePaceFloat = (Double(time) / distance) * (conversion / 60.0)
      let firstUnit = Int(averagePaceFloat)
      let secondDigit = (averagePaceFloat % (Double(firstUnit) > 0.0 ? Double(firstUnit) : 1.0)) * 60.0
      return PaceStructure(firstUnit,Int(secondDigit))
    }
  }

}

extension RaceTracker: CLLocationManagerDelegate {
  //--------------------------------------------------
  // MARK: - CLLocationManagerDelegate
  //--------------------------------------------------
  func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    if let lastLocation = locations.last  {
      if needsResumePosition {
        needsResumePosition = false
        currentRunMetadata.append(RunMetaData(pace: 0.0, segment: segment, time: time))
        currentRun.append(lastLocation)
      } else {
        locationQueue.append(lastLocation)
        let locationCount = locationQueue.count
        if pausedForAuto && locationCount > 2 {
          let _ = locationQueue.last
          let _ = locationQueue[locationCount - 2]
          let _ = locationQueue[locationCount - 3]
          locationQueue.removeAll(keepCapacity: true)
        }
      }
    }
    
  }
}