//
//  BufferCondition.swift
//  act-r
//
//  Created by Niels Taatgen on 3/24/15.
//  Copyright (c) 2015 Niels Taatgen. All rights reserved.
//

import Foundation

class BufferCondition: CustomStringConvertible {
    let model: Model
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
    
    init(prefix: String, buffer: String, model: Model) {
        self.prefix = prefix
        self.buffer = buffer
        self.model = model
    }
    
    func addCondition(_ sc: SlotCondition) { slotConditions.append(sc) }
    
    func test(instantiation inst: Instantiation) -> Bool {
        // It may be necessary to put something in here for specials
        if (prefix == "=") {
            let bufferChunk = model.buffers[buffer]
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
                print("Testing \(self)")
            for condition in slotConditions {
                if !model.dm.retrievalState(slot: condition.slot, value: condition.value.text()!) { return false }
                }
                return true
            default: return false
            }
        }
        return false
    }
    
    
}
