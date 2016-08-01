//
//  Speakable.swift
//  RocketJourney
//
//  Created by Ernesto Cambuston on 7/16/15.
//  Copyright (c) 2015 RocketJourney. All rights reserved.
//

import Foundation
import AVFoundation

public class Speaker:NSObject, AVSpeechSynthesizerDelegate {
  
  public var speechSynthesizer = AVSpeechSynthesizer()
  var audioSession = AVAudioSession.sharedInstance()
  
  private var utteranceRate = AVSpeechUtteranceDefaultSpeechRate * 0.83
  private var queue = [String]()
  
  var language:String
  public override init() {
    self.language = AVSpeechSynthesisVoice.currentLanguageCode()
    super.init()
    speechSynthesizer.delegate = self
  }
  
  deinit {
    NSNotificationCenter.defaultCenter().removeObserver(self)
  }
  public func shut() {
    if speechSynthesizer.speaking {
        queue.removeAll(keepCapacity: true)
        speechSynthesizer.stopSpeakingAtBoundary(.Immediate)
        speechSynthesizer.speakUtterance(AVSpeechUtterance(string: ""))
        speechSynthesizer.stopSpeakingAtBoundary(.Immediate)
    }
  }
  public func speak(string:String) {
    queue.append(string)
    sayNext(false)
  }
  
    private func sayNext(isClosure:Bool) {
    if !queue.isEmpty {
      aboutToSpeak()
      if let stringToSpeak = queue[0] as String? {
        speakString(stringToSpeak, language: language)  
      } else if isClosure {
        self.didEndSpeaking()
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
  public func speechSynthesizer(synthesizer: AVSpeechSynthesizer, didFinishSpeechUtterance utterance: AVSpeechUtterance) {
    speechSynthesizer.delegate = self
    if !queue.isEmpty {
        queue.removeAtIndex(0)
    }
    
    delay(0.8, closure: {
        if self.queue.isEmpty && !synthesizer.speaking && utterance.speechString != "" {
            self.didEndSpeaking()
        } else {
            self.sayNext(true)
        }
    })
  }
  
  private func aboutToSpeak() {
    let errorPointer = NSErrorPointer()
    do {
      try audioSession.setCategory(AVAudioSessionCategoryPlayback, withOptions: .DuckOthers)
        try audioSession.setActive(true)
    } catch let error as NSError {
      errorPointer.memory = error
    }
  }

  private func speakString(string:String, language:String) {
    let utterance = AVSpeechUtterance(string: string)
    utterance.voice = AVSpeechSynthesisVoice(language: language)
    utterance.rate = utteranceRate
    utterance.preUtteranceDelay = 0.1
    utterance.postUtteranceDelay = 0.1
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