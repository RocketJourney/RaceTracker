//
//  RaceTracker.swift
//  RaceTracker
//
//  Created by Ernesto Cambuston on 10/3/15.
//  Copyright © 2015 CocoaPods. All rights reserved.
//
//   This class implements a server that tracks user running events.
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


public typealias TimeStructure = (hours:Int, minutes:Int, seconds:Int)
public typealias DistanceStructure = (firstUnit:Int, secondUnit:Int)
public typealias PaceStructure = (firstUnit:Int, secondUnit:Int)

public typealias Coordinate = (longitude:Double, latitude:Double, altitude: Double, pace: Double, section:Int, position:Int, segment:Int)

public protocol RunTrackerSpeechLanguageProvider {
  var unitSystem:Bool {get set}
  func sayFeedback(time:TimeStructure, distance:DistanceStructure, pace:PaceStructure)->String
  func sayFeedbackDecremental(time:TimeStructure, distance:DistanceStructure, pace:PaceStructure)->String
  func sayMidpoint(time:TimeStructure, distance:DistanceStructure, pace:PaceStructure)->String
  func sayGoalAchieved(time:TimeStructure, distance:DistanceStructure, pace:PaceStructure)->String
  func sayLastSprint(time:TimeStructure, distance:DistanceStructure, pace:PaceStructure)->String
}

public protocol RaceTrackerDelegate {
  func updateViews(time: TimeStructure, distance: DistanceStructure, pace: PaceStructure, percent:Float)
  func logDescriptionString(string:String)
  func goalCompletion(percent:Double)
  func setIdle(isIdle:Bool)
  func gpsSignal(isWeak:Bool)
  func autopausedRace(paused:Bool)
  func cacheRun(distance:Double,
                    time:Int,
                calories:Int,
               elevation:Double,
                segments:Int,
        metricMilestones:Array<Int>,
         royalMilestones:Array<Int>,
             coordinates:Array<Coordinate>)
}

public enum RunType:Int {
  case None=0
  case Distance=1
  case Time=2
}

public struct RunSetup {
  public var unitSystem:Bool
  public var voiceFeedback:RunType
  public var voiceDistance:Double
  public var voiceTime:Int
  public var goalType:RunType
  public var goalDistance:Double
  public var goalTime:Int
  public var autopause:Bool
  public init (unitSystem:Bool,
            voiceFeedback:RunType,
            voiceDistance:Double,
                voiceTime:Int,
                 goalType:RunType,
             goalDistance:Double,
                 goalTime:Int,
                autopause:Bool) {
    self.unitSystem = unitSystem
    self.goalType = goalType
    self.voiceFeedback = voiceFeedback
    self.voiceDistance = voiceDistance
    self.voiceTime = voiceTime
    self.goalDistance = goalDistance
    self.goalTime = goalTime
    self.autopause = autopause
  }
}

public class RaceTracker: NSObject {
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
  private var nextVoiceTime:Int
  private var hasGoal : Bool
  private var goalDistance : Double
  private var voiceDistance:Double
  private var voiceTime:Int
  private var goalTime : Int
  private var distance : Double = 0.0
  private let updateInterval:Int16 = 3
  private var reachedNextVoice:Double
  private let locationManager = CLLocationManager()
  private var paused = false
  private var pausedForAutopause = false
  private var calories = 0
  private var elevation = 0.0
  private var cachedToPosition = 0 //position we cached to, last time we called delegate?.cacheRun(:)
  private var voiceFeedback : RunType
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
  private var noComparePoint = false
  private var pace = 0.0
  private var speed = 0.0
  private var goalType:RunType
  
  public var delegate : RaceTrackerDelegate?
  //--------------------------------------------------
  // MARK: - Initializers
  //--------------------------------------------------
  required public init(setup:RunSetup) {
    // Initial state
    metric = setup.unitSystem
    goalType = setup.goalType
    hasGoal = goalType != .None ? true : false
    voiceFeedback = setup.voiceFeedback
    voiceDistance = setup.voiceDistance
    voiceTime = setup.voiceTime
    nextVoiceTime = voiceTime
    goalDistance = setup.goalDistance
    reachedNextVoice = voiceDistance
    goalTime = setup.goalTime
    isAutopauseEnabled = setup.autopause
    conversion = metric == true ? 1000.0 : 1609.0
    super.init()
    if #available(iOS 9.0, *) {
      locationManager.allowsBackgroundLocationUpdates = true
    }
    locationQueue.reserveCapacity(15000)
    currentRun.reserveCapacity(15000)
    locationManager.delegate = self
    locationManager.distanceFilter = kCLDistanceFilterNone
    locationManager.desiredAccuracy = kCLLocationAccuracyBest
    locationManager.activityType = .Fitness
  }
  //--------------------------------------------------
  // MARK: - Setup
  //--------------------------------------------------
  public func startTracking() {
    idle(true)
    logSetup()
    locationManager.startUpdatingLocation()
    locationQueue.removeAll(keepCapacity: true)
    currentRun.removeAll(keepCapacity: true)
    setupSpeaker()
    resumeRun()
  }
  private func logSetup() {
    print("[RaceTracker] - Beggining run.")
    print("[RaceTracker] ... Setup: ")
    print("[RaceTracker] ......VoiceFeedback: \(voiceFeedback) ")
    switch voiceFeedback {
    case .Time:     print("[RaceTracker] ......FeedbackTime: \(voiceTime) ")
    case .Distance: print("[RaceTracker] ......FeedbackDistance: \(voiceDistance) ")
    case .None: break
    }
    print("[RaceTracker] ......VoiceGoal: \(goalType) ")
    switch goalType {
    case .Time:     print("[RaceTracker] ......GoalTime: \(goalTime) ")
    case .Distance: print("[RaceTracker] ......GoalDistance: \(goalDistance) ")
    case .None: break
    }
  }
  public func resumeRun() {
    idle(true)
    segment = segment + 1
    paused = false
    UIApplication.sharedApplication().beginBackgroundTaskWithExpirationHandler(nil)
    timer = NSTimer(timeInterval: oneSecond, target: self, selector: "tick", userInfo: nil, repeats: true)
    NSRunLoop.mainRunLoop().addTimer(timer!, forMode: NSRunLoopCommonModes)
    noComparePoint = true
    
  }
  public func pauseRun() {
    paused = true
    timer?.invalidate()
    timer = nil
    timeSinceUnpause = NSDate.timeIntervalSinceReferenceDate()
    if pausedForAutopause {
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
    if noComparePoint {
      return
    } else if delayedUpdate {
      updateMetrics()
    } else {
      evaluateAutopause(-1.0)
    }
    delegate?.updateViews(getTime(), distance: getDistance(), pace: getPace(), percent:0.5)
  }
  private var delayedCache:Bool {
    get {
      return (time % 60) == 0 && distance >= 800.0
    }
  }
  private var delayedUpdate:Bool {
    get {
      return locationQueue.count > 0 && (time % kCalcPeriod) == 0
    }
  }
  private func updateMetrics() {
    calculateMetrics()
    locationQueue.removeAll(keepCapacity: true)
    evaluateAutopause(speed)
    checkGoalAndFeedback()
    if delayedCache { cacheRun() }
  }
  private func cacheRun() {
    if let runDiff = getRunDiff() {
      print("[RaceTracker] - Sending run to cache @ \(time) seconds distance \(distance)")
      delegate?.cacheRun(distance, time: time,
                               calories: calories,
                              elevation: elevation,
                               segments: segment,
                       metricMilestones:[0],
                        royalMilestones:[0],
                            coordinates: runDiff)
    }
  }
  private func checkGoalAndFeedback() {
    switch goalType {
    case .None: checkFeedback()
    case .Distance: checkDistanceGoal()
    case .Time: checkTimeGoal()
    }
  }
  private func checkFeedback() {
    if reachedNextFeedback() {
      delegate?.logDescriptionString(sayFeedback())
    }
  }
  
  private func checkDistanceGoal() {
    if distanceReachedMidlepoint() {
      checkgoalDistanceCompletion()
    } else if reachedNextFeedback() && midpoint == false {
      delegate?.logDescriptionString(sayFeedback())
    }
  }
  private func checkTimeGoal() {
    
  }
  
  private func distanceReachedMidlepoint()->Bool {
    let goal = goalDistance
    if distance >= goal {
      delegate?.goalCompletion(1.0)
    } else {
      delegate?.goalCompletion(distance / goal)
    }
    if !midpoint && distance > (goal / 2.0) {
      midpoint = true
      delegate?.logDescriptionString(midpointFeedback())
    } else {
      return midpoint
    }
    return false
  }
  
  
  private func reachedNextFeedback()->Bool {
    switch voiceFeedback {
    case .Distance:
      if distance >= reachedNextVoice {
        reachedNextVoice += voiceDistance
        return true
      }
    case .Time:
      if time >=  nextVoiceTime {
        nextVoiceTime += voiceTime
        return true
      }
    case .None: break
    }
    return false
  }
  private let weight = 67.0
  private func calculateMetrics() {
    if let sampleLocation = locationQueue.last {
      if sampleLocation.horizontalAccuracy <= kLogRequiredAccuracy && currentRun.count > 0 {
        let priorLocation = currentRun.last!
        let paceTimeInterval = sampleLocation.timestamp.timeIntervalSinceReferenceDate - priorLocation.timestamp.timeIntervalSinceReferenceDate
        let distanceToAdd = calculateDistanceFrom(priorLocation, newLocation: sampleLocation)
        distance = distance + distanceToAdd
        
        speed = distanceToAdd / paceTimeInterval
        pace = Double(time) / distance
        let speedMin = 60 * pace
        let climbed = sampleLocation.altitude - priorLocation.altitude
        elevation += climbed
        var grade = 0.0
        if distanceToAdd > 1 {
          grade = climbed / distanceToAdd
        }
        let caloriesToAdd = (paceTimeInterval * weight * (3.5 + (0.2 * speedMin) + (0.9 * speedMin * grade))) / 12600
        calories += Int(caloriesToAdd)
        currentRun.append(sampleLocation)
        currentRunMetadata.append(RunMetaData(pace: speed, segment: segment, time: time))
      }
      evaluateAccuracy((sampleLocation.horizontalAccuracy + sampleLocation.verticalAccuracy) / 2)
    }
  }
  var consecutiveHeadingCount = 0
  private func calculateDistanceFrom(priorLocation: CLLocation, newLocation: CLLocation)->Double {
    //let locationCount = currentRun.count
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
  private var isAutopauseEnabled = false
  private let kAutopauseDelay = 10.0
  private let kAutopauseSpeed = 0.25
  private func evaluateAutopause(speed:Double) {
    if speed < 0 {
      if let last = currentRun.last {
        if isAutopauseEnabled
             && ensureItHasntRecentlyAutopaused()
             && ((last.timestamp.timeIntervalSinceReferenceDate + kAutopauseDelay) < NSDate.timeIntervalSinceReferenceDate()) {

        }
      }
    } else {
      if isAutopauseEnabled
             && (speed < kAutopauseSpeed)
             && ensureItHasntRecentlyAutopaused() {
          
      }
    }
  }
  private var averageAccuracy = 0.0
  private let kEvaluateAccuracyPeriod = 12
  private let kMaxPermittedAccuracy = 30.0
  private var signalWeak = false
  private func evaluateAccuracy(accuracy:Double) {
    averageAccuracy += accuracy
    if (time % kEvaluateAccuracyPeriod) == 0 {
      if averageAccuracy > (Double(kEvaluateAccuracyPeriod) * kMaxPermittedAccuracy) {
        if !signalWeak {
          signalWeak = true
          delegate?.gpsSignal(true)
        }
      } else {
        if signalWeak {
          signalWeak = false
          delegate?.gpsSignal(false)
        }
      }
      averageAccuracy = 0.0
    }
    
  }
  private func ensureItHasntRecentlyAutopaused()->Bool {
    let timeSinceReference = NSDate.timeIntervalSinceReferenceDate()
    return ((timeSinceUnpause + kAutopauseDelay) < timeSinceReference)
      && (date.timeIntervalSinceReferenceDate + (kAutopauseDelay * 2) < timeSinceReference)
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
  private func checkgoalDistanceCompletion() {
    let reachedNext = reachedNextFeedback()
    let goal = goalDistance
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
    return speaker!.sayFeedbackDecremental(convertTimeToTimeStructure(time), distance:convertDistanceToDistanceStructure(goalDistance - distance, conversion: conversion), pace:convertTimeAndDistanceToPaceStructure(time, distance: distance, conversion: conversion))
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
    
    func round2(number: Double, nearest: Double) -> Double {
        return round(number / nearest) * nearest
    }


  
  func getRunDiff()->Array<Coordinate>? {
    var locArr = [Coordinate]()
    for i in cachedToPosition..<currentRun.count {
      let currCoord = currentRun[i]
      let currCoordMeta = currentRunMetadata[i]
      let storedLocation = Coordinate(longitude: Double(currCoord.coordinate.longitude), latitude: Double(currCoord.coordinate.latitude),
        altitude: Double(currCoord.altitude), pace: pace, section: currCoordMeta.segment, position: cachedToPosition + i, segment: currCoordMeta.segment)
      locArr.append(storedLocation)
    }
    cachedToPosition = currentRun.count
    return locArr
  }
  
  public func finishRun() {
    if let runDiff = getRunDiff() {
      delegate?.cacheRun(distance, time: time, calories: calories, elevation: elevation, segments: segment, metricMilestones:[0], royalMilestones:[0], coordinates: runDiff)
    }
    locationManager.stopUpdatingLocation()
    locationManager.delegate = nil
    timer?.invalidate()
  }
  private var speaker:RunTrackerSpeechLanguageProvider?
  private func setupSpeaker() {
    let code = AVSpeechSynthesisVoice.currentLanguageCode()
    print("[RaceTracker] - Language code \(code)")
    switch code {
    case "es-ES", "es-MX":
      print("[RaceTracker] - Setup spanish speaker")
      setLanguage(RunSpanishSpeaker())
    case "it-IT":
      print("[RaceTracker] - Setup italian speaker")
      setLanguage(RunItalianSpeaker())
    case "ja-JP":
      print("[RaceTracker] - Setup japannese speaker")
      setLanguage(RunJapanneseSpeaker())
    case "fr-CA", "fr-FR":
      print("[RaceTracker] - Setup french speaker")
      setLanguage(RunFrenchSpeaker())
    case "de-DE":
      print("[RaceTracker] - Setup german speaker")
      setLanguage(RunGermanSpeaker())
    case "nl-BE", "nl-NL":
      print("[RaceTracker] - Setup dutch speaker")
      setLanguage(RunDutchSpeaker())
    case "el-GR":
      print("[RaceTracker] - Setup greek speaker")
      setLanguage(RunGreekSpeaker())
    case "zh-CN":
      print("[RaceTracker] - Setup mandarin speaker")
      setLanguage(RunMandarinSpeaker())
    case "zh-HK":
      print("[RaceTracker] - Setup cantonese speaker")
      setLanguage(RunCantoneseSpeaker())
    default:
      print("[RaceTracker] - Setup english speaker")
      setLanguage(RunEnglishSpeaker())
    }
  }
  func setLanguage(speakerLanguage:RunTrackerSpeechLanguageProvider) {
    speaker = speakerLanguage
    speaker!.unitSystem = metric
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
        let x = Int(distance / (conversion / 100))
        return DistanceStructure(firstUnit:0, secondUnit: Int(round2(Double(x), nearest: 10.0)))
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
  private func appendBlindLocation(location:CLLocation) {
    noComparePoint = false
    currentRunMetadata.append(RunMetaData(pace: 0.0, segment: segment, time: time))
    currentRun.append(location)
  }
  private func verifyLocationHistory() {
    let locationCount = locationQueue.count
    if pausedForAutopause && locationCount > 2 {
      let _ = locationQueue.last
      let _ = locationQueue[locationCount - 2]
      let _ = locationQueue[locationCount - 3]
      locationQueue.removeAll(keepCapacity: true)
    }
  }
  //--------------------------------------------------
  // MARK: - CLLocationManagerDelegate
  //--------------------------------------------------
  public func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    if let location = locations.last  {
      if noComparePoint {
        appendBlindLocation(location)
      } else {
        locationQueue.append(location)
        verifyLocationHistory()
      }
    }
  }
    
    
    
}