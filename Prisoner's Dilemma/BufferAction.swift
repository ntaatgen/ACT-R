//
//  BufferAction.swift
//  act-r
//
//  Created by Niels Taatgen on 3/25/15.
//  Copyright (c) 2015 Niels Taatgen. All rights reserved.
//

import Foundation

class BufferAction: CustomStringConvertible {
    let model: Model
    let prefix: String
    let buffer: String
    var slotActions: [SlotAction] = []
    var description: String {
        get {
            var s = "  \(prefix+buffer)"
            s += ">\n"
            for sc in slotActions {
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
    
    func addAction(slotAction sa: SlotAction) { slotActions.append(sa) }
    
    func storeAndClear (_ inst: Instantiation) {
        let bufferChunk = model.buffers[buffer]
        if bufferChunk != nil && !(!model.dm.retrievaltoDM && (buffer == "retrieval" || buffer == "partial")) {
            let newChunk = model.dm.addToDMOrStrengthen(chunk: bufferChunk!)
            if newChunk !== bufferChunk! {
                inst.replace(s1: bufferChunk!.name, s2: newChunk)
            }
            model.buffers[buffer] = nil  // clear the buffer
        }
    }
    
    func fire(_ inst: Instantiation) {
        // directAction possibility
        switch prefix {
            case "+":
                storeAndClear(inst)
                let newChunk = model.generateNewChunk(string: buffer)
                newChunk.isRequest = true
                model.buffers[buffer] = newChunk
                fallthrough
            case "=":   // ordinary buffer contents change without action
                let bufferChunk = model.buffers[buffer]
                if bufferChunk != nil {
                    for slot in slotActions {
                        slot.fire(instantiation: inst, bufferChunk: bufferChunk!)
                    }
                } else { print("Buffer \(buffer) is empty") }
            case "-":
                storeAndClear(inst)
            default: break
        }
    }
    
}
