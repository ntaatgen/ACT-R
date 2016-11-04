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
    var buffers: [String:Chunk] = [:]
    var chunkIdCounter = 0
    var running = false
    var trace: String {
        didSet {
            NotificationCenter.default.post(name: Notification.Name(rawValue: "TraceChanged"), object: nil)
        }
    }
    var waitingForAction: Bool = false {
        didSet {
            if waitingForAction == true {
            print("Posted Action notification")
            NotificationCenter.default.post(name: Notification.Name(rawValue: "Action"), object: nil)
            }
        }
    }
    var modelText: String = ""

    /**
    Inspect a slot value of the last action
     - parameter slot: The name of the slot
     - returns: the value of the slot as String or nil if it doesn't exist
    */
    func lastAction(_ slot: String) -> String? {
        if let action = buffers["action"] {
            if let value = action.slotvals[slot] {
                return value.description
            }
        }
        return nil
    }
    
    
    /**
    Set a slot value of the chunk in the action buffer
    - parameter slot: the name of the slot
    - parameter value: the value to be put into the slot
    */
    func modifyLastAction(_ slot:String, value:String) {
        if let action = buffers["action"] {
            action.setSlot(slot, value: value)
        }
    }
    
    /**
    Is there a chunk in the action buffer?
    - returns: Whether there is one
    */
    func actionChunk() -> Bool {
        return buffers["action"] != nil
    }
    
    init() {
        trace = ""
    }
    
    func addToTrace(_ s: String) {
        let timeString = String(format:"%.2f", time)
        trace += "\(timeString)  " + s + "\n"
    }
    
    func clearTrace() {
        trace = ""
    }
    
    func loadModel(_ fname: String) {
        let bundle = Bundle.main
        let path = bundle.path(forResource: fname, ofType: "actr")!
        
        modelText = try! String(contentsOfFile: path, encoding: String.Encoding.utf8)
        print("Got model text")
        //        println("\(modelText)")
        self.reset()

        
        for (_,chunk) in dm.chunks {
            print("\(chunk)")
        }
        print("")
        for (_,prod) in procedural.productions {
            print("\(prod)")
        }
    }
    
    /**
    When you want to use partial matching, override this function when you subclass Model
    */
    func mismatchFunction(_ x: Value, y: Value) -> Double? {
        if x == y {
            return 0
        } else {
            return -1
        }
    }
    
    
   /**
    Run the model until a production has a +action> or no productions match. If the model stops because of an action, waitingForAction is made true, which in turn posts
     an "Action" notification
    */
    func run() {
        running = true
        waitingForAction = false
        if let action = buffers["action"] {
            action.isRequest = false
        }
        while (true) {
//        let goalchunk = buffers["goal"]!
     //   addToTrace("Goal before production\n\(goalchunk)")
        var inst: Instantiation?
        for (_,p) in procedural.productions {
            if let result = p.instantiate() {
                print("Matching \(result.p.name) with utility \(result.u)")
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
            } else if let retrievalQuery = buffers["partial"] {
                if retrievalQuery.isRequest {
                    retrievalQuery.isRequest = false
                    let (latency, retrieveResult) = dm.partialRetrieve(retrievalQuery, mismatchFunction: mismatchFunction)
                    time += latency
                    if retrieveResult != nil {
                        addToTrace("Partial retrieving \(retrieveResult!.name)")
                        buffers["partial"] = retrieveResult!
                    } else {
                        addToTrace("Partial retrieval failure")
                        buffers["partial"] = nil
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
    
    /**
    Reset the model to its initial state
    */
    func reset() {
        time = 0
        dm.chunks = [:]
        procedural.productions = [:]
        buffers = [:]
        let parser = Parser(model: self, text: modelText)
        parser.parseModel()
        clearTrace()
        running = false
        waitingForAction = false
    }
    
    
    /**
    Generate a chunk with a unique ID starting with the given string
    - parameter s1: The base name of the chunk
    - returns: the new chunk
    */
    func generateNewChunk(_ s1: String = "chunk") -> Chunk {
        let name = s1 + "\(chunkIdCounter)"
        chunkIdCounter += 1
        let chunk = Chunk(s: name, m: self)
        return chunk
    }
    
    func stringToValue(_ s: String) -> Value {
        let possibleNumVal = NumberFormatter().number(from: s)?.doubleValue
        if possibleNumVal != nil {
            return Value.Number(possibleNumVal!)
        }
        if let chunk = self.dm.chunks[s] {
            return Value.symbol(chunk)
        } else if s == "nil" {
            return Value.Empty
        } else {
            return Value.Text(s)
        }
    }
}
