//
//  BufferCondition.swift
//  act-r
//
//  Created by Niels Taatgen on 3/24/15.
//  Copyright (c) 2015 Niels Taatgen. All rights reserved.
//

import Foundation

class BufferCondition: CustomStringConvertible, Codable {
    var model: Model?
    let prefix: String
    let buffer: String
    var slotConditions: [SlotCondition] = []
    // specials?
    
    var description: String {
        get {
            var s = "  \(prefix+buffer)"
            s += ">\n"
            for sc in slotConditions {
                s += sc.description + "\n"
            }
            return s
        }
    }
    
    enum CodingKeys: String, CodingKey {
         case prefix, buffer, slotConditions
    }
    
    init(prefix: String, buffer: String, model: Model) {
        self.prefix = prefix
        self.buffer = buffer
        self.model = model
    }
    
    func addCondition(_ sc: SlotCondition) { slotConditions.append(sc) }
    
    func test(instantiation inst: Instantiation) -> Bool {
        // It may be necessary to put something in here for specials
        if (prefix == "=") {
            let bufferChunk = model!.buffers[buffer]
       //     println("Testing condition \(self) on buffer \(bufferChunk)")
            if bufferChunk == nil { return false }
            for condition in slotConditions {
                if !condition.test(bufferChunk: bufferChunk!, inst: inst) {  return false }
                if prefix == "=" {
                    inst.mapping["=" + buffer] = .Text(bufferChunk!.name)
                }
            }
       //     println("   Production \(inst.p.name) matches this bufferchunk")
            return true
        } else if (prefix == "?") {
            switch buffer {
            case "?retrieval":
                //                print("Testing \(self)")
                for condition in slotConditions {
                    if !model!.dm.retrievalState(slot: condition.slot, value: condition.value.description) { return false }
                }
                return true
            case "?visual-location":
                for condition in slotConditions {
                    if !model!.visual.visualLocationQuery(slot: condition.slot, value: condition.value.description) { return false }
                }
                return true
            case "?visual":
                for condition in slotConditions {
                    if !model!.visual.visualQuery(slot: condition.slot, value: condition.value.description) { return false }
                }
                return true
            case "?imaginal":
                for condition in slotConditions {
                    switch (condition.slot, condition.value.text()!) {
                    case ("state", "free"):  break
                    case ("state", "busy"):  return false
                    case ("buffer", "empty"): if model!.buffers["imaginal"] != nil { return false }
                    case ("buffer", "full"): if model!.buffers["imaginal"] == nil { return false }
                    default: return false
                    }
                }
                return true
            default: return false
            }
        }
        return false
    }
    
    
}
