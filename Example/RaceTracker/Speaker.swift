//
//  Speakable.swift
//  RocketJourney
//
//  Created by Ernesto Cambuston on 7/16/15.
//  Copyright (c) 2015 RocketJourney. All rights reserved.
//

import Foundation
import AVFoundation

class Speaker:NSObject, AVSpeechSynthesizerDelegate {
  
  private var speechSynthesizer = AVSpeechSynthesizer()
  var audioSession = AVAudioSession.sharedInstance()
  
  private var utteranceRate = AVSpeechUtteranceDefaultSpeechRate * 0.83
  private var queue = [String]()
  
  var language:String
  override init() {
    self.language = AVSpeechSynthesisVoice.currentLanguageCode()
    super.init()
    speechSynthesizer.delegate = self
  }
  
  deinit {
    NSNotificationCenter.defaultCenter().removeObserver(self)
  }
  func shut() {
    speechSynthesizer.stopSpeakingAtBoundary(.Immediate)
    queue.removeAll(keepCapacity: true)
  }
  func speak(string:String) {
    queue.append(string)
    if !speechSynthesizer.speaking {
      sayNext()
    }
  }
  
  private func sayNext() {
    if !queue.isEmpty {
      aboutToSpeak()
      if let stringToSpeak = queue[0] as String? {
        speakString(stringToSpeak, language: language)
        queue.removeAtIndex(0)
        sayNext()
      }
    }
  }
  private func delay(delay:Double, closure:()->()) {
    dispatch_after(
      dispatch_time(
        DISPATCH_TIME_NOW,
        Int64(delay * Double(NSEC_PER_SEC))
      ),
      dispatch_get_main_queue(), closure)
  }
  func speechSynthesizer(synthesizer: AVSpeechSynthesizer, didFinishSpeechUtterance utterance: AVSpeechUtterance) {
    didEndSpeaking()
  }
  
  private func aboutToSpeak() {
    let errorPointer = NSErrorPointer()
    do {
      try audioSession.setCategory(AVAudioSessionCategoryPlayback, withOptions: .DuckOthers)
    } catch let error as NSError {
      errorPointer.memory = error
    }
    do {
      try audioSession.setActive(true)
    } catch _ {
    }
  }

  private func speakString(string:String, language:String) {
    let utterance = AVSpeechUtterance(string: string)
    utterance.voice = AVSpeechSynthesisVoice(language: language)
    utterance.rate = utteranceRate
    utterance.preUtteranceDelay = 0.4
    utterance.postUtteranceDelay = 0.4
    speechSynthesizer.speakUtterance(utterance)
  }
  
  private func didEndSpeaking() {
    let errorPointer = NSErrorPointer()
    do {
      try audioSession.setCategory(AVAudioSessionCategoryPlayback, withOptions: .MixWithOthers)
      try audioSession.setActive(false, withOptions: .NotifyOthersOnDeactivation)
    } catch let error as NSError {
      errorPointer.memory = error
    }
  }
}