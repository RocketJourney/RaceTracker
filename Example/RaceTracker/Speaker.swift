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
  weak var audioSession = AVAudioSession.sharedInstance()
  
  private var utteranceRate = AVSpeechUtteranceDefaultSpeechRate * 0.83
  private var queue = [String]()
  
  var language:String
  override init() {
    self.language = AVSpeechSynthesisVoice.currentLanguageCode()
    super.init()
    speechSynthesizer.delegate = self
    queue.append(" ")
    sayNext()
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
    aboutToSpeak()
    if !queue.isEmpty {
      if let stringToSpeak = queue[0] as String? {
        speakString(stringToSpeak, language: language)
        queue.removeAtIndex(0)
        let dispatchTime: dispatch_time_t = dispatch_time(DISPATCH_TIME_NOW, Int64(0.3 * Double(NSEC_PER_SEC)))
        dispatch_after(dispatchTime, dispatch_get_main_queue(), { [weak self] in
          self?.sayNext()
          })
        
      }
    }
  }
  
  private func aboutToSpeak() {
    let errorPointer = NSErrorPointer()
    do {
      try audioSession?.setCategory(AVAudioSessionCategoryPlayback)
    } catch let error as NSError {
      errorPointer.memory = error
    }
    do {
      try audioSession?.setActive(true)
    } catch _ {
    }
  }
  private func speakString(string:String, language:String) {
    let utterance = AVSpeechUtterance(string: string)
    utterance.voice = AVSpeechSynthesisVoice(language: language)
    utterance.rate = utteranceRate
    speechSynthesizer.speakUtterance(utterance)
  }
  
  private func didEndSpeaking() {
    let errorPointer = NSErrorPointer()
    do {
      try audioSession?.setActive(false, withOptions: .NotifyOthersOnDeactivation)
    } catch let error as NSError {
      errorPointer.memory = error
    }
  }
}