//
//  RunJapanneseSpeaker.swift
//  RJv1
//
//  Created by Ernesto Cambuston on 5/2/15.
//  Copyright (c) 2015 Ernesto Cambuston. All rights reserved.
//

import Foundation

class RunJapanneseSpeaker : RunTrackerSpeechLanguageProvider {
    func sayFeedback(time:TimeStructure, distance:DistanceStructure, pace:PaceStructure)->String {
        return " "
    }
    func sayFeedbackDecremental(time:TimeStructure, distance:DistanceStructure, pace:PaceStructure)->String {
        return " "
    }
    func sayMidpoint(time:TimeStructure, distance:DistanceStructure, pace:PaceStructure)->String {
        return " "
    }
    func sayGoalAchieved(time:TimeStructure, distance:DistanceStructure, pace:PaceStructure)->String {
        return " "
    }
    func sayLastSprint(time:TimeStructure, distance:DistanceStructure, pace:PaceStructure)->String {
        return " "
    }
}