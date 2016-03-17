//
//  Declarative.swift
//  actr
//
//  Created by Niels Taatgen on 3/1/15.
//  Copyright (c) 2015 Niels Taatgen. All rights reserved.
//

import Foundation

class Declarative  {

    var baseLevelDecay: Double = 0.5
    var optimizedLearning = false
    var maximumAssociativeStrength: Double = 3
    var goalActivation: Double = 1 // W parameter
    var retrievalThreshold: Double = -2
    var activationNoise: Double? = 0.25
    var chunks = [String:Chunk]()
    var misMatchPenalty: Double = 5
    var latencyFactor = 0.2
    
    var retrieveBusy = false
    var retrieveError = false
    var retrievaltoDM = false
    
    func duplicateChunk(chunk: Chunk) -> Chunk? {
        /* Return duplicate chunk if there is one, else nil */
        for (_,c1) in chunks {
            if c1 == chunk { return c1 }
        }
        return nil
    }
    
    func retrievalState(slot: String, value: String) -> Bool {
        switch (slot,value) {
        case ("state","busy"): return retrieveBusy
        case ("state","error"): return retrieveError
        default: return false
        }
    }
    
    func addToDMOrStrengthen(chunk: Chunk) -> Chunk {
        if let dupChunk = duplicateChunk(chunk) {
            dupChunk.addReference()
                        return dupChunk
        } else {
            chunk.startTime()
            chunks[chunk.name] = chunk
            for (_,val) in chunk.slotvals {
                switch val {
                case .Symbol(let refChunk):
                    refChunk.fan++
                default: break
                }
            }
        return chunk
        }
    }
    
    func addToDM(chunk: Chunk) {
        if let dupChunk = duplicateChunk(chunk) {
            dupChunk.addReference()
//            return dupChunk
        } else {
            chunk.startTime()
            chunks[chunk.name] = chunk
            for (_,val) in chunk.slotvals {
                switch val {
                case .Symbol(let refChunk):
                    refChunk.fan++
                default: break
                }
            }
//            return chunk
        }
    }
    
    func latency(activation: Double) -> Double {
        return latencyFactor * exp(-activation)
    }
    
    func retrieve(chunk: Chunk) -> (Double, Chunk?) {
        retrieveError = false
        var bestMatch: Chunk? = nil
        var bestActivation: Double = retrievalThreshold
        chunkloop: for (_,ch1) in chunks {
            for (slot,value) in chunk.slotvals {
                if let val1 = ch1.slotvals[slot] {
                    if !val1.isEqual(value) {
                        continue chunkloop }
                } else { continue chunkloop }
            }
            if ch1.activation() > bestActivation {
                bestActivation = ch1.activation()
                bestMatch = ch1
            }
        }
        if bestActivation > retrievalThreshold {
            return (latency(bestActivation) , bestMatch)
        } else {
            retrieveError = true
            return (latency(retrievalThreshold), nil)
        }
        
    }
    

    
    func partialRetrieve(chunk: Chunk, mismatchFunction: (x: Value, y: Value) -> Double? ) -> (Double, Chunk?) {
        var bestMatch: Chunk? = nil
        var bestActivation: Double = retrievalThreshold
        chunkloop: for (_,ch1) in chunks {
            var mismatch = 0.0
            for (slot,value) in chunk.slotvals {
                if let val1 = ch1.slotvals[slot] {
                    if !val1.isEqual(value) {
                        let slotmismatch = mismatchFunction(x: val1, y: value)
                        if slotmismatch != nil {
                            mismatch += slotmismatch! * misMatchPenalty
                        } else
                        {
                            continue chunkloop
                        }
                    }
                } else { continue chunkloop }
            }
//            println("Candidate: \(ch1) with activation \(ch1.activation() + mismatch)")
            if ch1.activation()  + mismatch > bestActivation {
                bestActivation = ch1.activation() + mismatch
                bestMatch = ch1
            }
        }
        if bestActivation > retrievalThreshold {
            return (latency(bestActivation) , bestMatch)
        } else {
            retrieveError = true
            return (latency(retrievalThreshold), nil)
        }
    }

    func blendedRetrieve(chunk: Chunk) -> (Double, Chunk?) {
        let bestMatch = chunk.copy()
        var currentReturn: [String:Double] = [:]
        var totalpChunk = 0.0
        chunkloop: for (_,ch1) in chunks {
//            var mismatch = 0.0
            for (slot,value) in chunk.slotvals {
                    if let val1 = ch1.slotvals[slot] {
                        if !val1.isEqual(value) {
                            continue chunkloop }
                    } else { continue chunkloop }
            }
            // The chunk does match. Now blend the remaining slots
            let activation = ch1.baseLevelActivation() + ch1.spreadingActivation()
            let pChunk = exp((-activation) / activationNoise!)
            totalpChunk += pChunk
            for (slot, value) in ch1.slotvals {
                switch value {
                case .Number(let num):
                    if let val1 = currentReturn[slot] {
                        currentReturn[slot] = val1 + num * pChunk
                    } else {
                        currentReturn[slot] = num * pChunk
                    }
                default: break
                }
            }
        }
        for (slot, value) in currentReturn {
            bestMatch.slotvals[slot] = .Number(value / totalpChunk)
        }
        if totalpChunk > 0.0 {
            return (latency(retrievalThreshold) , bestMatch)
        } else {
            retrieveError = true
            return (latency(retrievalThreshold), nil)
        }
    }
    
    
}