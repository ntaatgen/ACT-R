//
//  SlotAction.swift
//  act-r
//
//  Created by Niels Taatgen on 3/25/15.
//  Copyright (c) 2015 Niels Taatgen. All rights reserved.
//

import Foundation

struct SlotAction: CustomStringConvertible {
    let slot: String
    let value: Value
    var description: String {
        get {
            return "      \(slot) \(value)"
        }
    }
    init(slot: String, value: Value) {
        self.slot = slot
        self.value = value
    }
    
    func fire(instantiation inst: Instantiation, bufferChunk: Chunk) {
        if isVariable(value: value) {
            bufferChunk.setSlot(slot: slot, value: inst.mapping[value.text()!]!) // assumption: no syntax errors in production
        } else {
            bufferChunk.setSlot(slot: slot, value: value)
        }
    }
}
