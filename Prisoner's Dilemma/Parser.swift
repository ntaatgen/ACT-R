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
    
    enum ParserError: Error {
        case expected(what: String)
        case unExpected(what: String, but: String)
        case notANumber(s: String)
        case productionDoesNotExist(production: String)
        case unknownBufferName(name: String)
        case unknownActionBufferPrefix(character: String)
        case unknownConditionBufferPrefix(character: String)
        case notAChunk(name: String)
        case unknownParameter(s: String)
        case unexpectedEOF
    }
    
    static let bufferNames = ["goal","imaginal","retrieval","action","temporal","partial","visual-location","visual"]
    static let numericParameters = [":ga",":rt",":ans",":lf",":mp",":mas",":egs, :bll"]
    static let boolParameters = [":ol"]
    
    func readToken(token: String) throws {
        guard t.token != nil else { throw ParserError.unexpectedEOF }
        guard t.token! == token else { throw ParserError.expected(what: token)}
        t.nextToken()
    }
    
    func nextTokenCheckEOF() throws {
        t.nextToken()
        if t.token == nil { throw ParserError.unexpectedEOF }
    }
    
    func checkEOF() throws {
            if t.token == nil { throw ParserError.unexpectedEOF }
    }

    func parseModel() throws {
        while (t.token != nil) {
            try readToken(token: "(")
            try checkEOF()
            switch t.token! {
            case "add-dm":
//                    print("Add-dm")
                    try nextTokenCheckEOF()
                    var chunk: Chunk?
                    repeat {
                        chunk = try parseChunk(dm: m.dm)
//                            print("Parsed \(chunk!)")
                            m.dm.addToDM(chunk!)
                    } while (t.token! != ")")
                t.nextToken()
            case "spp":
                    try nextTokenCheckEOF()
                    if let prod = m.procedural.productions[t.token!] {
                        try nextTokenCheckEOF()
                        try readToken(token: ":u")
                        try checkEOF()
                        if let value = Double(t.token!) { // NumberFormatter().number(from: t.token!)?.doubleValue {
                            prod.u = value
                        } else {
                            throw ParserError.notANumber(s: t.token!)
                        }
                    } else {
                        throw ParserError.productionDoesNotExist(production: t.token!)
                    }
                        try nextTokenCheckEOF()
                        try readToken(token: ")")
            case "sgp":
                try nextTokenCheckEOF()
                try parseSGP()
                try readToken(token: ")")
            case "p":
                    try nextTokenCheckEOF()
                    let prod = try parseProduction()
                    m.procedural.addProduction(production: prod)
//                    print("Parsed \(prod.name)")
            case "goal-focus":
                try nextTokenCheckEOF()
                if let chunk = m.dm.chunks[t.token!] {
                    let goalChunk = chunk.copy()
                    m.buffers["goal"] = goalChunk
                } else { throw ParserError.notAChunk(name: t.token!)}
                try nextTokenCheckEOF()
                try readToken(token: ")")
            case "set-all-baselevels":
                try nextTokenCheckEOF()
                if let timeDiff = Double(t.token!) { // NumberFormatter().number(from: t.token!)?.doubleValue {
                    try nextTokenCheckEOF()
                    if let number = Int(t.token!) { // NumberFormatter().number(from: t.token!)?.int32Value {
                        for (_,chunk) in m.dm.chunks {
                            chunk.setBaseLevel(timeDiff: timeDiff, references: Int(number))
                        }
                    } else { throw ParserError.notANumber(s: t.token!)}
                } else { throw ParserError.notANumber(s: t.token!)}
                try nextTokenCheckEOF()
                try readToken(token: ")")
            case "set-fixed-baselevels":
                try nextTokenCheckEOF()
                if let activation = Double(t.token!) { // NumberFormatter().number(from: t.token!)?.doubleValue {
                    for (_, chunk) in m.dm.chunks {
                        if chunk.fixedActivation == nil {
                            chunk.fixedActivation = activation
                        }
                    }
                } else { throw ParserError.notANumber(s: t.token!)}
                try nextTokenCheckEOF()
                try readToken(token: ")")
            default: throw ParserError.unExpected(what: t.token!, but: "a valid ACT-R command")
            }
        }
        m.isValid = true
    }
    
    fileprivate func parseChunk(dm: Declarative) throws -> Chunk {
        try readToken(token: "(")
        try checkEOF()
        let chunkName = t.token!
        try nextTokenCheckEOF()
        let chunk = Chunk(s: chunkName, m: m)
        while (t.token! != ")") {
            let slot = t.token!
            try nextTokenCheckEOF()
            let valuestring = t.token!
            if valuestring == ")" { throw ParserError.unExpected(what: ")", but: "Symbol or Value")}
            try nextTokenCheckEOF()
            if let number = Double(valuestring) { // NumberFormatter().number(from: valuestring)?.doubleValue   {
                    if slot != ":activation" {
                        chunk.setSlot(slot: slot, value: number)
                    } else {
                        chunk.fixedActivation = number
                    }
                } else {
                    chunk.setSlot(slot: slot,value: valuestring)
                }
        }
        try nextTokenCheckEOF()
        return chunk
    }
    
    fileprivate func parseSGP() throws {
        while t.token! != ")" {
            let parameterName = t.token!
            try nextTokenCheckEOF()
            let value = t.token!
            let numValue = Double(value) // NumberFormatter().number(from: value)?.doubleValue
            try nextTokenCheckEOF()
            if Parser.numericParameters.contains(parameterName) && numValue == nil { throw ParserError.notANumber(s: value)}
            if Parser.boolParameters.contains(parameterName) && value != "nil" && value != "t" { throw ParserError.unExpected(what: value, but: "t or nil")}
            switch parameterName {
            case ":ga":
                m.dm.goalActivation = numValue!
            case ":rt":
                m.dm.retrievalThreshold = numValue!
            case ":ans":
                m.dm.activationNoise = numValue!
            case ":lf":
                m.dm.latencyFactor = numValue!
            case ":mp":
                m.dm.misMatchPenalty = numValue!
            case ":mas":
                m.dm.maximumAssociativeStrength = numValue!
            case ":egs":
                m.procedural.utilityNoise = numValue!
            case ":ol":
                m.dm.optimizedLearning = value == "t"
            case ":bll":
                if numValue == nil && value != "nil" {
                    throw ParserError.expected(what: "number or nil")
                }
                m.dm.baseLevelDecay = value == "nil" ? nil : numValue!
            default: throw ParserError.unknownParameter(s: parameterName)
            }
        }
    }
    
    fileprivate func parseProduction() throws -> Production {
        let name = t.token!
        try nextTokenCheckEOF()
        let p = Production(name: name, model: m)
        while (t.token! != "==>") {
            let bc = try parseBufferCondition()
            p.addCondition(bc)
        }
        try nextTokenCheckEOF()
        while (t.token! != ")") {
            let ac = try parseBufferAction()
            p.addAction(ac)
        }
        t.nextToken()
        return p
    }
    
    fileprivate func parseBufferCondition() throws -> BufferCondition {
        let prefix = String(t.token![t.token!.startIndex])
        guard ["?","="].contains(prefix) else { throw ParserError.unknownConditionBufferPrefix(character: prefix)}
        let token = t.token!
        let bufferName =  token.substring(from: 1, to: token.count - 1) //  token[(start ..< end)]
        if !Parser.bufferNames.contains(bufferName) {
            throw ParserError.unknownBufferName(name: bufferName)
        }
        let buffer = (prefix == "?" ? "?" : "") + bufferName
        try nextTokenCheckEOF()
        let bc = BufferCondition(prefix: prefix, buffer: buffer, model: m)
        while (!t.token!.hasPrefix("?") && !(t.token!.hasPrefix("=") && t.token!.hasSuffix(">"))) {
            let sc = try parseSlotCondition()
            bc.addCondition(sc)
        }
        return bc
    }


    fileprivate func parseSlotCondition() throws -> SlotCondition {
        var op: String? = nil
        if (t.token == "-" || t.token == "<" || t.token == ">" || t.token == "<=" || t.token == ">=") {
            op = t.token
            try nextTokenCheckEOF()
        }
        let slot = t.token!
        try nextTokenCheckEOF()
        let value = t.token!
        try nextTokenCheckEOF()
        return SlotCondition(op: op, slot: slot, value: m.stringToValue(value))
    }
    
    
    fileprivate func parseBufferAction() throws -> BufferAction {
        let prefix = String(t.token![t.token!.startIndex])
        guard ["+","=","-"].contains(prefix) else { throw ParserError.unknownActionBufferPrefix(character: prefix)}
        let token = t.token!
        let buffer =  token.substring(from: 1, to: token.count - 1) //  token[(start ..< end)]
        if !Parser.bufferNames.contains(buffer) {
            throw ParserError.unknownBufferName(name: buffer)
        }
        try nextTokenCheckEOF()
        let ba = BufferAction(prefix: prefix, buffer: buffer, model: m)
        if prefix == "-" { return ba }
        /// Possible direct action
        while (!t.token!.hasPrefix("+") && t.token! != ")" && !(t.token!.hasPrefix("-") && t.token!.hasSuffix(">")) && !(t.token!.hasPrefix("=") && t.token!.hasSuffix(">"))) {
            let ac = try parseSlotAction()
            ba.addAction(slotAction: ac)
        }
        return ba
    }
    

    
    fileprivate func parseSlotAction() throws -> SlotAction {
        var slot = t.token!
        if slot == "-" || slot == ">" || slot == "<" || slot == ">=" || slot == "<=" {
            try nextTokenCheckEOF()
            slot += t.token!
        }
        try nextTokenCheckEOF()
        let value = t.token!
        try nextTokenCheckEOF()
        return SlotAction(slot: slot, value: m.stringToValue(value))

        
    }

}
