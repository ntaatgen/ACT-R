//
//  Parser.swift
//  actr
//
//  Created by Niels Taatgen on 3/4/15.
//  Copyright (c) 2015 Niels Taatgen. All rights reserved.
//

import Foundation

class Parser  {
    fileprivate let t: Tokenizer
    fileprivate let m: Model


init(model: Model, text: String) {
    m = model
    t = Tokenizer(s: text)
    model.modelText = text
}

    func parseModel() {
        while (t.token != nil) {
            if t.token! != "(" {
                print("( expected")
                return
            }
            t.nextToken()
            switch t.token! {
            case "add-dm":
                    print("Add-dm")
                    t.nextToken()
                    var chunk: Chunk?
                    repeat {
                        chunk = parseChunk(dm: m.dm)
                        print("Parsed \(chunk)")
                        if chunk != nil {  m.dm.addToDM(chunk!)
                                }
                    } while (chunk != nil && t.token != ")")
                    if t.token != ")" {
                        print(") expected")
                        return
                    }
                t.nextToken()
            case "p":
                    t.nextToken()
                    let prod = parseProduction()
                    if prod != nil { m.procedural.addProduction(production: prod!) }
            case "goal-focus":
                t.nextToken()
                if let chunk = m.dm.chunks[t.token!] {
                    let goalChunk = chunk.copy()
                    m.buffers["goal"] = goalChunk
                }
                t.nextToken()
                t.nextToken()
            case "set-all-baselevels":
                t.nextToken()
                if let timeDiff = NumberFormatter().number(from: t.token!)?.doubleValue {
                    t.nextToken()
                    if let number = NumberFormatter().number(from: t.token!)?.int32Value {
                        for (_,chunk) in m.dm.chunks {
                            chunk.setBaseLevel(timeDiff: timeDiff, references: Int(number))
                    }
                    }
                }
                t.nextToken()
                if t.token != ")" {
                    print(") expected")
                    return
                }
                t.nextToken()
            default: print("Cannot yet handle \(t.token!)")
                return
            }
        }
    }
    
    fileprivate func parseChunk(dm: Declarative) -> Chunk? {
        if t.token != "(" {
            print("( expected")
            return nil
        }
        t.nextToken()
        let chunkName = t.token!
        t.nextToken()
        let chunk = Chunk(s: chunkName, m: m)
        while (t.token != nil && t.token! != ")") {
            let slot = t.token
            t.nextToken()
            let valuestring = t.token
            t.nextToken()
            if (slot != nil && valuestring != nil) {
                if let number = NumberFormatter().number(from: valuestring!)?.doubleValue   {
                    if slot != ":activation" {
                        chunk.setSlot(slot: slot!, value: number)
                    } else {
                        chunk.fixedActivation = number
                    }
                } else {
                    chunk.setSlot(slot: slot!,value: valuestring!)
                } }
            else {
                print("Wrong chunk syntax")
                return nil
            }
        }
        if (t.token == nil || t.token! != ")") {
            return nil }
        t.nextToken()
        return chunk
    }
    
    fileprivate func parseProduction() -> Production? {
        let name = t.token!
        t.nextToken()
        let p = Production(name: name, model: m)
        while (t.token != nil && t.token! != "==>") {
            let bc = parseBufferCondition()
            if bc != nil { p.addCondition(bc!) }
        }
        if t.token != "==>" { print("Parsing error in \(name)") }
        t.nextToken()
        while (t.token != nil && t.token != ")") {
            let ac = parseBufferAction()
            if ac !=  nil { p.addAction(ac!) }
        }
        t.nextToken()
        return p
    }
    
    fileprivate func parseBufferCondition() -> BufferCondition? {
        let prefix = String(t.token![t.token!.startIndex])
        let token = t.token!
        let start = token.characters.index(token.startIndex, offsetBy: 1)
        let end = token.characters.index(token.endIndex, offsetBy: -1)
        let bufferName = token[(start ..< end)]
        let buffer = (prefix == "?" ? "?" : "") + bufferName
        t.nextToken()
        let bc = BufferCondition(prefix: prefix, buffer: buffer, model: m)
        while (t.token != nil  && !t.token!.hasPrefix("?") && !(t.token!.hasPrefix("=") && t.token!.hasSuffix(">"))) {
            let sc = parseSlotCondition()
            if sc != nil { bc.addCondition(sc!) }
        }
        return bc
    }


    fileprivate func parseSlotCondition() -> SlotCondition? {
        var op: String? = nil
        if (t.token == "-" || t.token == "<" || t.token == ">" || t.token == "<=" || t.token == ">=") {
            op = t.token
            t.nextToken()
        }
        let slot = t.token
        t.nextToken()
        let value = t.token
        t.nextToken()
        if slot != nil && value != nil {
            return SlotCondition(op: op, slot: slot!, value: m.stringToValue(value!), model: m)
        }
        else { return nil }
    }
    
    
    fileprivate func parseBufferAction() -> BufferAction? {
        let prefix = String(t.token![t.token!.startIndex])
        let token = t.token!
        let start = token.characters.index(token.startIndex, offsetBy: 1)
        let end = token.characters.index(token.endIndex, offsetBy: -1)
        let buffer = token[(start ..< end)]
        t.nextToken()
        let ba = BufferAction(prefix: prefix, buffer: buffer, model: m)
        if prefix == "-" { return ba }
        /// Possible direct action
        while (t.token != nil && !t.token!.hasPrefix("+") && t.token! != ")" && !(t.token!.hasPrefix("-") && t.token!.hasSuffix(">")) && !(t.token!.hasPrefix("=") && t.token!.hasSuffix(">"))) {
            let ac = parseSlotAction()
            if ac != nil { ba.addAction(slotAction: ac!) }
        }
        return ba
    }
    

    
    fileprivate func parseSlotAction() -> SlotAction? {
        if (t.token == "-" || t.token == "<" || t.token == ">" || t.token == "<=" || t.token == ">=") {
            t.nextToken()
        }
        let slot = t.token
        t.nextToken()
        let value = t.token
        t.nextToken()
        if slot != nil && value != nil {
            return SlotAction(slot: slot!, value: m.stringToValue(value!))
        }
        else { return nil }
        
    }

}
