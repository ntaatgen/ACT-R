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
    lazy var temporal = Temporal(model: self)
    lazy var visual = Vision(model: self)
    var buffers: [String:Chunk] = [:]
    var chunkIdCounter = 0
    var running = false
    var isValid = false
    var imaginalActionTime = 0.2
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
    func lastAction(slot: String) -> String? {
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
    func modifyLastAction(slot:String, value:String) {
        if let action = buffers["action"] {
            action.setSlot(slot: slot, value: value)
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
    
    func addToTrace(string s: String) {
        let timeString = String(format:"%.2f", time)
        trace += "\(timeString)  " + s + "\n"
    }
    
    func clearTrace() {
        trace = ""
    }
    
    func loadModel(fileName fname: String) {
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
    func mismatchFunction(x: Value, y: Value) -> Double? {
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
    func run(maxTime: Double, step: Bool = false) {
        let startTime = time
        running = true
        waitingForAction = false
        if let action = buffers["action"] {
            action.isRequest = false
        }
        while (true) {

            temporal.updateTimer()
            var inst: Instantiation?
            for (_,p) in procedural.productions {
                if let result = p.instantiate() {
//                    print("Matching \(result.p.name) with utility \(result.u)")
                    if inst == nil {
                        inst = result
                    } else if result.u > inst!.u {
                        inst = result
                    }
                }
            }
            if inst == nil && buffers["temporal"] == nil { return } // no matching productions and no running clock
            time += 0.05
            if time > startTime + maxTime { return }
            if inst == nil {
                print("waiting for temporal to do something")
                continue }
            addToTrace(string: "production \(inst!.p.name) fires")
            print("production \(inst!.p.name) fires")
            inst!.p.fire(instantiation: inst!)
            //model.addToTrace("Goal after production\n\(goalchunk)")
            
            //        for (buffer,chunk) in buffers {
            //            println("Buffer \(buffer) has chunk\n\(chunk)")
            //        }
            var moduleLatency = 0.0
            if let retrievalQuery = buffers["retrieval"] {
                if retrievalQuery.isRequest {
                    retrievalQuery.isRequest = false
                    let (latency, retrieveResult) = dm.retrieve(chunk: retrievalQuery)
                    moduleLatency = max(moduleLatency, latency)
//                    time += latency
                    if retrieveResult != nil {
                        addToTrace(string: "Retrieving \(retrieveResult!.name)")
                        buffers["retrieval"] = retrieveResult!
                        print("Retrieving \(retrieveResult!.name)")
                    } else {
                        addToTrace(string: "Retrieval failure")
                        print("Retrieval failure")
                        buffers["retrieval"] = nil
                    }
                }
            } else if let retrievalQuery = buffers["partial"] {
                if retrievalQuery.isRequest {
                    retrievalQuery.isRequest = false
                    let (latency, retrieveResult) = dm.partialRetrieve(chunk: retrievalQuery, mismatchFunction: mismatchFunction)
                    moduleLatency = max(moduleLatency, latency)
                    //                    time += latency
                    if retrieveResult != nil {
                        addToTrace(string: "Partial retrieving \(retrieveResult!.name)")
                        buffers["partial"] = retrieveResult!
                    } else {
                        addToTrace(string: "Partial retrieval failure")
                        buffers["partial"] = nil
                    }
                }
            }
            moduleLatency = max(moduleLatency, visual.update())
            if let imaginalQuery = buffers["imaginal"] {
                if imaginalQuery.isRequest {
                    moduleLatency = max(moduleLatency, imaginalActionTime)
                }
            }
            if let actionQuery = buffers["action"] {
                if actionQuery.isRequest {
                    waitingForAction = true
                    return
                }
            }
            if let temporalQuery = buffers["temporal"] {
                if temporalQuery.isRequest {
                    temporal.action()
                    temporalQuery.isRequest = false
                }
            }
            time += moduleLatency
            if step { return }
        }
        
    }
    
    func run(step: Bool = false) {
        if isValid {
            run(maxTime: 10000, step: step)
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
        visual.reset()
        let parser = Parser(model: self, text: modelText)
        do {
            try parser.parseModel()
        } catch Parser.ParserError.expected(what: let expected) {
            print("\nExpected \(expected)")
        } catch Parser.ParserError.unexpectedEOF {
            print("\nUnexpected end-of-file")
        } catch Parser.ParserError.notAChunk(name: let s) {
            print("\n\(s) is not a chunk (yet).")
        } catch Parser.ParserError.notANumber(s: let s) {
            print("\n\(s) is not a number.")
        } catch Parser.ParserError.productionDoesNotExist(production: let s) {
            print("\n\(s) is not a production.")
        } catch Parser.ParserError.unExpected(what: let w, but: let s) {
            print("\nFound \(w) while expecting \(s)")
        } catch Parser.ParserError.unknownActionBufferPrefix(character: let s) {
            print("\n\(s) is not a known possible prefix for a buffer action (has to be +, = or -)")
        } catch Parser.ParserError.unknownBufferName(name: let s) {
            print("\n\(s) is not a valid buffer name")
        } catch Parser.ParserError.unknownConditionBufferPrefix(character: let s) {
            print("\n\(s) is not a known possible prefix for a buffer condition (has to be = or ?)")
        } catch {
            print("\nUnknown error")
        }
        clearTrace()
        running = false
        waitingForAction = false
    }
    
    
    /**
    Generate a chunk with a unique ID starting with the given string
    - parameter s1: The base name of the chunk
    - returns: the new chunk
    */
    func generateNewChunk(string s1: String = "chunk") -> Chunk {
        let name = generateName(string: s1)
        let chunk = Chunk(s: name, m: self)
        return chunk
    }
    
    func generateName(string s1: String = "name") -> String {
        let name = s1 + "\(chunkIdCounter)"
        chunkIdCounter += 1
        return name
    }
    
    func stringToValue(_ s: String) -> Value {
        let possibleNumVal = Double(s) //NumberFormatter().number(from: s)?.doubleValue
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
