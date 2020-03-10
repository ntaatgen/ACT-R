//
//  Declarative.swift
//  actr
//
//  Created by Niels Taatgen on 3/1/15.
//  Copyright (c) 2015 Niels Taatgen. All rights reserved.
//

import Foundation

class Declarative: Codable  {
    /// Baselevel decay parameter, d in the equations, or bll in ACT-R
    var baseLevelDecay: Double? = 0.5
    /// Is optimized learning on or off (ol in ACT-R)
    var optimizedLearning = false
    /// Maximum associate strength parameter (mas in ACT-R). If this parameter is too low you can get negative Sji's!
    var maximumAssociativeStrength: Double = 3
    /// Parameter that controls spreading activation from the goal (W in ACT-R)
    var goalActivation: Double = 1
    /// Retrieval threshold parameter (rt in ACT-R)
    var retrievalThreshold: Double = -2
    /// Activation noise parameter (ans in ACT-R). Can be nil to switch off noise.
    var activationNoise: Double? = 0.25
    /// A dictionary with all the chunks in DM, indexed by chunk name
    var chunks = [String:Chunk]()
    /// The mismatch penalty, to be used in partial matching (mp in ACT-R)
    var misMatchPenalty: Double = 5
    /// The latency factor parameter (lf in ACT-R)
    var latencyFactor = 0.2
    
    var retrieveBusy = false
    var retrieveError = false
    var retrievaltoDM = false
    
    enum CodingKeys: String, CodingKey {
        case chunks
        case baseLevelDecay
        case optimizedLearning
        case maximumAssociativeStrength
        case goalActivation
        case retrievalThreshold
        case activationNoise
        case misMatchPenalty
        case latencyFactor
    }
    
    required init(from decoder: Decoder) throws {
         let values = try decoder.container(keyedBy: CodingKeys.self)
        self.chunks = try values.decode([String:Chunk].self, forKey: .chunks)
        self.baseLevelDecay = try values.decodeIfPresent(Double.self, forKey: .baseLevelDecay)
        self.optimizedLearning = try values.decode(Bool.self, forKey: .optimizedLearning)
        self.maximumAssociativeStrength = try values.decode(Double.self, forKey: .maximumAssociativeStrength)
        self.goalActivation = try values.decode(Double.self, forKey: .goalActivation)
        self.retrievalThreshold = try values.decode(Double.self, forKey: .retrievalThreshold)
        self.activationNoise = try values.decodeIfPresent(Double.self, forKey: .activationNoise)
        self.misMatchPenalty = try values.decode(Double.self, forKey: .misMatchPenalty)
        self.latencyFactor = try values.decode(Double.self, forKey: .latencyFactor)
    }
    
    required init() {
        return
    }
    
    /**
        Is er there a duplicate of a chunk in dm?
        - parameter chunk: The chunk to be checked
        - returns: nil if there is no duplicate, or the duplicate chunk
    */
    func duplicate(chunk: Chunk) -> Chunk? {
        /* Return duplicate chunk if there is one, else nil */
        for (_,c1) in chunks {
            if c1 == chunk { return c1 }
        }
        return nil
    }
    
    /**
        What is the state of the declarative module?
        - parameter slot: the name of the state slot, currently only "state"
        - parameter value: the value of the slot to be checked, currently "busy" or "error"
        - returns: a boolean whether the test is true or false
    */
    func retrievalState(slot: String, value: String) -> Bool {
        switch (slot,value) {
        case ("state","busy"): return retrieveBusy
        case ("state","error"): return retrieveError
        default: return false
        }
    }
    
    /**
        Add a new chunk to DM, or strengthen it if is already there
        - parameter chunk: The chunk to be added
        - returns: Either the chunk itself, or the duplicate in DM if it exists.
    */
    func addToDMOrStrengthen(chunk: Chunk) -> Chunk {
        if let dupChunk = duplicate(chunk: chunk) {
            dupChunk.addReference()
                        return dupChunk
        } else {
            chunk.startTime()
            chunks[chunk.name] = chunk
            for (_,val) in chunk.slotvals {
                switch val {
                case .symbol(let refChunk):
                    refChunk.fan += 1
                default: break
                }
            }
        return chunk
        }
    }
    
    /**
     Add a new chunk to DM, or strengthen it if is already there
     - parameter chunk: The chunk to be added
     */
    func addToDM(_ chunk: Chunk) {
        if let dupChunk = duplicate(chunk: chunk) {
            dupChunk.addReference()
//            return dupChunk
        } else {
            chunk.startTime()
            chunks[chunk.name] = chunk
            for (_,val) in chunk.slotvals {
                switch val {
                case .symbol(let refChunk):
                    refChunk.fan += 1
                default: break
                }
            }
//            return chunk
        }
    }
    
    /**
        Given an activation, calculate the retrieval latency
        - parameter activation: The activation value
        - returns: the latency in seconds
    */
    func latency(activation: Double) -> Double {
        return latencyFactor * exp(-activation)
    }
    
    /**
        Retrieve a chunk from DM
        - parameter chunk: A chunk containing the pattern to be matched by the retrieval
        - returns: A Tuple consisting of the retrieval time and the retrieved Chunk (or the maximum retrieval time and nil if the retrieval fails
     */
    func retrieve(chunk: Chunk) -> (Double, Chunk?) {
        retrieveError = false
        var bestMatch: Chunk? = nil
        var bestActivation: Double = retrievalThreshold
        chunkloop: for (_,ch1) in chunks {
            for (slot,value) in chunk.slotvals {
                if let val1 = ch1.slotvals[slot] {
                    if !val1.isEqual(value: value) {
                        continue chunkloop }
                } else { continue chunkloop }
            }
            if ch1.activation() > bestActivation {
                bestActivation = ch1.activation()
                bestMatch = ch1
            }
        }
        if bestActivation > retrievalThreshold {
            return (latency(activation: bestActivation) , bestMatch)
        } else {
            retrieveError = true
            return (latency(activation: retrievalThreshold), nil)
        }
        
    }
    

    /**
     Retrieve a chunk from DM using partial matching
     - parameter chunk: A chunk containing the pattern to be matched by the retrieval
     - mismatchFunction: A mismatch function that takes two Values, and returns a mismatch value (or nil if the two values cannot be properly compared). The function should return a value between -1 and 0 (or nil).
     - returns: A Tuple consisting of the retrieval time and the retrieved Chunk (or the maximum retrieval time and nil if the retrieval fails
     */
    func partialRetrieve(chunk: Chunk, mismatchFunction: (_ x: Value, _ y: Value) -> Double? ) -> (Double, Chunk?) {
        retrieveError = false
       var bestMatch: Chunk? = nil
        var bestActivation: Double = retrievalThreshold
        chunkloop: for (_,ch1) in chunks {
            var mismatch = 0.0
            for (slot,value) in chunk.slotvals {
                if let val1 = ch1.slotvals[slot] {
                    if !val1.isEqual(value: value) {
                        let slotmismatch = mismatchFunction(val1, value)
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
            return (latency(activation: bestActivation) , bestMatch)
        } else {
            retrieveError = true
            return (latency(activation: retrievalThreshold), nil)
        }
    }
    /**
     Retrieve a chunk from DM using blending
     - parameter chunk: A chunk containing the pattern to be matched by the retrieval
     - returns: A Tuple consisting of the retrieval time and the retrieved Chunk (or the maximum retrieval time and nil if the retrieval fails
     */
    func blendedRetrieve(chunk: Chunk) -> (Double, Chunk?) {
        retrieveError = false
       let bestMatch = chunk.copy()
        var currentReturn: [String:Double] = [:]
        var totalpChunk = 0.0
        chunkloop: for (_,ch1) in chunks {
            for (slot,value) in chunk.slotvals {
                    if let val1 = ch1.slotvals[slot] {
                        if !val1.isEqual(value: value) {
                            continue chunkloop }
                    } else { continue chunkloop }
            }
            // The chunk does match. Now blend the remaining slots
            let activation = ch1.baseLevelActivation() + ch1.spreadingActivation()
            let pChunk = exp(activation / activationNoise!)
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
            bestMatch.setSlot(slot: slot, value: value / totalpChunk)
        }
        if totalpChunk > 0.0 {
            return (latency(activation: retrievalThreshold) , bestMatch)
        } else {
            retrieveError = true
            return (latency(activation: retrievalThreshold), nil)
        }
    }
    
    func blendedPartialRetrieve(chunk: Chunk, mismatchFunction: (_ x: Value, _ y: Value) -> Double? ) -> (Double, Chunk?) {
        retrieveError = false
        let bestMatch = chunk.copy()
        var currentReturn: [String:Double] = [:]
        var totalpChunk = 0.0
        chunkloop: for (_,ch1) in chunks {
            var mismatch = 0.0
            for (slot,value) in chunk.slotvals {
                if let val1 = ch1.slotvals[slot] {
                    if !val1.isEqual(value: value) {
                        let slotmismatch = mismatchFunction(val1, value)
                        if slotmismatch != nil {
                            mismatch += slotmismatch! * misMatchPenalty
                        } else
                        {
                            continue chunkloop
                        }
                    }
                } else { continue chunkloop }
            }
            // The chunk does match. Now blend the remaining slots
            let activation = ch1.baseLevelActivation() + ch1.spreadingActivation() + mismatch
            let pChunk = exp(activation / activationNoise!)
            totalpChunk += pChunk
            for (slot, value) in ch1.slotvals {
                if chunk.slotvals[slot] == nil { // the slot is not in the request
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
        }
        for (slot, value) in currentReturn {
            bestMatch.setSlot(slot: slot, value: value / totalpChunk)
        }
        if totalpChunk > 0.0 {
            return (latency(activation: retrievalThreshold) , bestMatch)
        } else {
            retrieveError = true
            return (latency(activation: retrievalThreshold), nil)
        }
        
    }
    

    
}
