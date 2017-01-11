//
//  Chunk.swift
//  actr
//
//  Created by Niels Taatgen on 3/1/15.
//  Copyright (c) 2015 Niels Taatgen. All rights reserved.
//

import Foundation

class Chunk: CustomStringConvertible {
    /// Name of the chunk
    let name: String
    /// The model that the chunk is part of
    let model: Model
    /// When was the chunk added to DM? If nil it means the chunk is not part of DM (yet)
    var creationTime: Double? = nil
    /// Number of references. Assume a single reference on creation
    var references: Int = 1
    /// Dictionary with slot value pairs
    var slotvals = [String:Value]()
    /// List of timestamps when the chunk was referenced. Only used when optimized learning is off
    var referenceList = [Double]()
    /// Current fan of the chunk: in how many other chunks does this chunk appear?
    var fan: Int = 0
    /// We only calculate noise once for a certain moment in time, so we need to remember it
    /// The last noise value
    var noiseValue: Double = 0
    /// At what time was the last noise value calculated?
    var noiseTime: Double = -1
    /// When non-nil, use this value as activation instead of calculating it
    var fixedActivation: Double? = nil
    /// Used for buffer chunks: is this a request (+buffer>)?
    var isRequest: Bool = false
    /// The order in which the slots have been declarared, necessary for proper printing
    var printOrder: [String] = [] // Order in which slots have to be printed
    init (s: String, m: Model) {
        name = s
        model = m
    }
    
    /**
      Printable version of the chunk
    */
    var description: String {
        get {
            var s = "\(name)\n"
            for slot in printOrder {
                if let val = slotvals[slot] {
                    s += "  \(slot)  \(val)\n"
                }
            }

            return s
        }
    }
    
    /**
     Make a copy of the chunk
      - returns: a copy of the chunk
    */
    func copy() -> Chunk {
        let newChunk = model.generateNewChunk(string: self.name)
        newChunk.slotvals = self.slotvals
        newChunk.printOrder = self.printOrder
        return newChunk
    }
    
    /**
     Set the creation time of the chunk to the current model time. Typically called when the chunk is added to dm.
    */
    func startTime() {
        creationTime = model.time
        if !model.dm.optimizedLearning {
            referenceList.append(model.time)
        }
    }
    
/**
Set the baselevel of a chunk 
 
 - Parameter timeDiff: How long ago was the chunk created
 - Parameter references: How many references in the time period
 */
    func setBaseLevel(timeDiff: Double, references: Int) {
        creationTime = model.time + timeDiff
        if model.dm.optimizedLearning {
            self.references = references
        } else {
            let increment = -timeDiff / Double(references)
            for i in 0..<references {
                let referenceTime = creationTime! + Double(i) * increment
              referenceList.append(referenceTime)
            }
        }
    }
//    
//    baseLevel = Math.log(useCount/(1-model.declarative.baseLevelDecayRate))
//    - model.declarative.baseLevelDecayRate*Math.log(time-creationTime);

    /**
    Calculate the base level activation of a chunk
    - returns: The activation
    */
    func baseLevelActivation () -> Double {
        if creationTime == nil { return 0 }
        if fixedActivation != nil {
            return fixedActivation!
        } else if model.dm.optimizedLearning {
            let x: Double = log((Double(references)/(1 - model.dm.baseLevelDecay)))
            let y = model.dm.baseLevelDecay + log(model.time - creationTime!)
            return x - y
        } else {
            return log(self.referenceList.map{ pow((self.model.time - $0),(-self.model.dm.baseLevelDecay))}.reduce(0.0, + )) // Wew! almost lisp! This is the standard baselevel equation
        }
    }
    
    /**
    Add a reference to the chunk, increasing its activation
    */
    func addReference() {
        if creationTime == nil { return }
        if model.dm.optimizedLearning {
            references += 1
            print("Added reference to \(self) references = \(references)")
        }
        else {
            referenceList.append(model.time)
        }
    }
    
    /**
    Set a slot to a particular value
    - parameter slot: the name of the slot
    - parameter value: the value the goes into the slot
    */
    func setSlot(slot: String, value: Chunk) {
        if slotvals[slot] == nil { printOrder.append(slot) }
        slotvals[slot] = Value.symbol(value)
    }
    /**
     Set a slot to a particular value
     - parameter slot: the name of the slot
     - parameter value: the value the goes into the slot
     */
    func setSlot(slot: String, value: Double) {
        if slotvals[slot] == nil { printOrder.append(slot) }
        slotvals[slot] = Value.Number(value)
    }

    /**
     Set a slot to a particular value
     - parameter slot: the name of the slot
     - parameter value: the value the goes into the slot
     */
    func setSlot(slot: String, value: String) {
        if slotvals[slot] == nil { printOrder.append(slot) }
        let possibleNumVal = NumberFormatter().number(from: value)?.doubleValue
        if possibleNumVal != nil {
            slotvals[slot] = Value.Number(possibleNumVal!)
        }
        if let chunk = model.dm.chunks[value] {
            slotvals[slot] = Value.symbol(chunk)
        } else {
            slotvals[slot] = Value.Text(value)
        }
    }
    
    /**
     Set a slot to a particular value
     - parameter slot: the name of the slot
     - parameter value: the value the goes into the slot
     */
    func setSlot(slot: String, value: Value) {
        if slotvals[slot] == nil { printOrder.append(slot) }
           slotvals[slot] = value
    }
    
    /**
    What value is there in a slot
    - parameter slot: the slot
    - returns: the value in the slot, if any, otherwise nil
    */
    func slotValue(slot: String) -> Value? {
        return slotvals[slot]
    }
    

    /**
    Checks whether a certain chunk appears in one of the slots of the current chunk
    - parameter chunk: the chunk to be checked
    - returns: whether the chunk has been found in one of the slots
    */
    func appearsInSlotOf(chunk: Chunk) -> Bool {
        for (_,value) in chunk.slotvals {
            switch value {
            case .symbol(let valChunk):
                if valChunk.name==self.name { return true }
            default: break
            }
        }
        return false
    }

    /**
    Calculate the Sji from this chunk to the given chunk
    - parameter chunk: the chunk that receives the spread
    - returns: the Sji value
    */
    func sji(chunk: Chunk) -> Double {
        if self.appearsInSlotOf(chunk: chunk) {
            return model.dm.maximumAssociativeStrength - log(Double(self.fan))
        }
        return 0.0
    }
    
    /**
    Calculate the spreading activation the current chunk receives from chunks in the goal
    - returns: the amount of spreading activation
    */
    func spreadingActivation() -> Double {
        if creationTime == nil {return 0}
        if let goal=model.buffers["goal"] {
            var totalSlots: Int = 0
            var totalSji: Double = 0
            for (_,value) in goal.slotvals {
                switch value {
                case .symbol(let valchunk):
                    totalSji += valchunk.sji(chunk: self)
                    totalSlots += 1
                default: break
                }
                return (totalSlots==0 ? 0 : totalSji * (model.dm.goalActivation / Double(totalSlots)))
            }
        }
        return 0
    }
    
    /**
    Calculate the noise. Only draw a new value if time has progressed
    - returns: the noise value
    */
    func calculateNoise() -> Double {
        if model.time != noiseTime {
            noiseValue = (model.dm.activationNoise == nil ? 0.0 : actrNoise(noise: model.dm.activationNoise!))
            noiseTime = model.time
        }
            return noiseValue
    }
    
    /**
    Return the total activation of the chunk
    - returns: the activation value
    */
    func activation() -> Double {
        if creationTime == nil {return 0}
        return  self.baseLevelActivation()
            + self.spreadingActivation() + calculateNoise()
    }
    
}

func == (left: Chunk, right: Chunk) -> Bool {
    // Are two chunks equal? They are if they have the same slots and values
    if left.slotvals.count != right.slotvals.count { return false }
    for (slot1,value1) in left.slotvals {
        if let rightVal = right.slotvals[slot1] {
            switch (rightVal,value1) {
            case (.Number(let val1),.Number(let val2)): if val1 != val2 { return false }
            case (.Empty, .Empty): break
            case (.Text(let s1), .Text(let s2)): if s1 != s2 { return false }
            case (.symbol(let c1), .symbol(let c2)): if c1 !== c2 { return false }
            default: return false
            }
        } else { return false }
    }
    return true
}
