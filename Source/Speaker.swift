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
  
  private var utteranceRate = AVSpeechUtteranceDefaultSpeechRate
  private var queue = [String]()
  
  var language:String
  public override init() {
    self.language = AVSpeechSynthesisVoice.currentLanguageCode()
    super.init()
    speechSynthesizer.delegate = self
    throttle = Throttle(timeout: 0.8, callback: {
        self.didEndSpeaking()
    })
  }
    private var throttle:Throttle?
  deinit {
    NSNotificationCenter.defaultCenter().removeObserver(self)
  }
    
    public func next(string:String) {
        print("stop")
    speechSynthesizer.stopSpeakingAtBoundary(.Immediate)
    speechSynthesizer.speakUtterance(AVSpeechUtterance(string: ""))
    speechSynthesizer.stopSpeakingAtBoundary(.Immediate)
    speechSynthesizer = AVSpeechSynthesizer()
    speechSynthesizer.delegate = self
    queue.removeAll()
    throttle!.cancel()
    speak(string)
  }
  public func speak(string:String) {
    queue.append(string)
    sayNext()
  }
  
    private func sayNext() {
    if !queue.isEmpty && !speechSynthesizer.speaking {
      aboutToSpeak()
      if let stringToSpeak = queue[0] as String? {
        speakString(stringToSpeak, language: language)  
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
    private var different = false
  public func speechSynthesizer(synthesizer: AVSpeechSynthesizer, didFinishSpeechUtterance utterance: AVSpeechUtterance) {
    if !queue.isEmpty { queue.removeAtIndex(0) }
    if queue.isEmpty {
        different = !different
        throttle!.input()
    } else {
        sayNext()
    }
    
  }
  
  private func aboutToSpeak() {
    let errorPointer = NSErrorPointer()
    audioSession = AVAudioSession.sharedInstance()
    do {
        try audioSession.setActive(true)
      try audioSession.setCategory(AVAudioSessionCategoryPlayback, withOptions: .DuckOthers)
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
    print("Speaking - \(string)")
  }
  
  private func didEndSpeaking() {
    if !speechSynthesizer.speaking && queue.isEmpty {
        let errorPointer = NSErrorPointer()
        do {
            try audioSession.setActive(false)
        } catch let error as NSError {
            errorPointer.memory = error
        }
    }
  }
}





class Throttle: NSObject {
    let timeout: Double
    let callback: Void -> Void
    
    var timer: NSTimer? = nil
    
    init(timeout: Double, callback: Void -> Void) {
        self.timeout = timeout
        self.callback = callback
    }
    
    deinit {
        timer?.invalidate()
    }
    
    func input() {
        cancel()
        resetTimer()
    }
    
    func cancel() {
        if let timer = self.timer where timer.valid {
            timer.invalidate()
        }
        timer = nil
    }
    
    private func resetTimer() {
        timer = NSTimer.scheduledTimerWithTimeInterval(timeout, target: self, selector: #selector(fetchTimerDidFire(_:)), userInfo: nil, repeats: false)
    }
    
    func fetchTimerDidFire(sender: AnyObject) {
        callback()
    }
}