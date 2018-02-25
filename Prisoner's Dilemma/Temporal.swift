//
//  Temporal.swift
//  PRIMs
//
//  Created by Niels Taatgen on 5/27/17.
//  Copyright © 2017 Niels Taatgen. All rights reserved.
//

import Foundation

/// T0 is the duration of the start pulse
/// Tn+1 = aTn + noise(SD = b * a * Tn)
/// The temporal module has three parameters:
/// time-t0: the start time (default 0.011 or 0.1)
/// time-a: the a parameter (default 1.1 or 1.02)
/// time-b: the b parameter (default 0.015)
///
/// +temporal> isa time starts the clock
/// ticks slot has the number of pulses
/// +temporal> isa clear stops the timer

class Temporal {
    static let timeT0Default = 0.011
    static let timeADefault = 1.1
    static let timeBDefault = 0.015
    unowned let model: Model
    var timeT0 = timeT0Default
    var timeA = timeADefault
    var timeB = timeBDefault
    var currentPulse: Int? = nil
    var currentPulseLength: Double? = nil
    var startTime: Double? = nil
    var nextPulseTime: Double? = nil
    
    init(model: Model) {
        self.model = model
    }
    
    func setParametersToDefault() {
        timeT0 = Temporal.timeT0Default
        timeA = Temporal.timeADefault
        timeB = Temporal.timeBDefault
    }
    
    func startTimer() {
        currentPulse = 0
        startTime = model.time
        nextPulseTime = timeT0
        currentPulseLength = timeT0
//        let timeChunk = model.generateNewChunk(string: "time")
//        timeChunk.setSlot(slot: "isa", value: "time")
//        timeChunk.setSlot(slot: "ticks", value: 0)
//        model.buffers["temporal"] = timeChunk
    }
    
    func action() {
        guard let timeChunk = model.buffers["temporal"] else { return }
        if let command = timeChunk.slotValue(slot: "isa") {
            switch command.description {
            case "time":
                startTimer()
                return
            case "clear":
                stopTimer()
                return
            default:
                return
            }
        }
    }
    
    func updateTimer() {
       guard let timeChunk = model.buffers["temporal"] else { return }
       guard startTime != nil && nextPulseTime != nil else { return }
        if model.time > startTime! + nextPulseTime! {
            while model.time > startTime! + nextPulseTime! {
                currentPulse = currentPulse! + 1
                print("Incrementing pulse to \(currentPulse!) at time \(model.time - startTime!)")
                currentPulseLength = timeA * currentPulseLength! + actrNoise(noise: timeB * timeA * currentPulseLength!)
                nextPulseTime = nextPulseTime! + currentPulseLength!
            }
            timeChunk.setSlot(slot: "ticks", value: Double(currentPulse!))
        }
    }
    
    // Probably don't need the following function
    func compareTime(compareValue: Double?) -> Bool {
        guard let timeChunk = model.buffers["temporal"] else { return false }
        guard compareValue != nil else { return false }
        return (timeChunk.slotValue(slot: "ticks")?.number()!)! >= compareValue!
    }
    
    func stopTimer() {
        model.buffers["temporal"] = nil
        reset()
    }
    
    func reset() {
        currentPulse = nil
        currentPulseLength = nil
        startTime = nil
    }
    
}
