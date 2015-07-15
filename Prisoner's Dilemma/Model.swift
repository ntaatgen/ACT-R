//
//  Model.swift
//  actr
//
//  Created by Niels Taatgen on 3/1/15.
//  Copyright (c) 2015 Niels Taatgen. All rights reserved.
//

import Foundation

class Model {
    var time: Double = 0
    var dm = Declarative()
    var procedural = Procedural()
    var goal: Chunk? = nil
    var buffers: [String:Chunk] = [:]
    var chunkIdCounter = 0
    var playerScore:Double = 0
    var modelScore:Double = 0
    var running = false
    var trace: String {
        didSet {
            NSNotificationCenter.defaultCenter().postNotificationName("TraceChanged", object: nil)
        }
    }
    var waitingForAction: Bool = false {
        didSet {
            if waitingForAction == true {
            println("Posted Action notification")
            NSNotificationCenter.defaultCenter().postNotificationName("Action", object: nil)
            }
        }
    }
    var modelText: String = ""

    init() {
        trace = ""
    }
    
    func addToTrace(s: String) {
        let timeString = String(format:"%.2f", time)
        trace += "\(timeString)  " + s + "\n"
    }
    
    func clearTrace() {
        trace = ""
    }
    
    func run() {
        running = true
        while (true) {
        let goalchunk = buffers["goal"]!
     //   addToTrace("Goal before production\n\(goalchunk)")
        var inst: Instantiation?
        for (_,p) in procedural.productions {
            if let result = p.instantiate() {
                println("Matching \(result.p.name) with utility \(result.u)")
                if inst == nil {
                    inst = result
                } else if result.u > inst!.u {
                    inst = result
                }
            }
        }
        if inst == nil { return } // no matching productions
        time += 0.05
        addToTrace("production \(inst!.p.name) fires")
        inst!.p.fire(inst!)
        //model.addToTrace("Goal after production\n\(goalchunk)")
        
//        for (buffer,chunk) in buffers {
//            println("Buffer \(buffer) has chunk\n\(chunk)")
//        }
        if let retrievalQuery = buffers["retrieval"] {
            if retrievalQuery.isRequest {
                retrievalQuery.isRequest = false
                let (latency, retrieveResult) = dm.retrieve(retrievalQuery)
                time += latency
                if retrieveResult != nil {
                    addToTrace("Retrieving \(retrieveResult!.name)")
                    buffers["retrieval"] = retrieveResult!
                } else {
                    addToTrace("Retrieval failure")
                    buffers["retrieval"] = nil
                }
            }
        }
           if let actionQuery = buffers["action"] {
                if actionQuery.isRequest {
                    waitingForAction = true
                    return
                }
            }
            
        }

    }
    
    func generateNewChunk(s1: String = "chunk") -> Chunk {
        let name = s1 + "\(chunkIdCounter++)"
        let chunk = Chunk(s: name, m: self)
        return chunk
    }
    
    func stringToValue(s: String) -> Value {
        let possibleNumVal = NSNumberFormatter().numberFromString(s)?.doubleValue
        if possibleNumVal != nil {
            return Value.Number(possibleNumVal!)
        }
        if let chunk = self.dm.chunks[s] {
            return Value.Symbol(chunk)
        } else if s == "nil" {
            return Value.Empty
        } else {
            return Value.Text(s)
        }
    }
}