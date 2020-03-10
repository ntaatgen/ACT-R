//
//  Support.swift
//  act-r
//
//  Created by Niels Taatgen on 3/29/15.
//  Copyright (c) 2015 Niels Taatgen. All rights reserved.
//

import Foundation

// Global stuff

func actrNoise(noise: Double) -> Double {
    let rand = Double(Int(arc4random_uniform(100000-2)+1))/100000.0
    return noise * log((1 - rand) / rand )
}

func isVariable(string s: String) -> Bool {
    return s.hasPrefix("=")
}

func isVariable(value v: Value) -> Bool {
    if let s = v.text() {
        return s.hasPrefix("=") }
    else { return false }
}

// Loading and saving models

func writeModel(filename: String, model: Model) {
    do {
        let fileURL = try FileManager.default
            .url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            .appendingPathComponent(filename)

        try JSONEncoder().encode(model)
            .write(to: fileURL)
    } catch {
        print(error)
    }
}

func readModel(filename: String) -> Model? {
    do {
        let fileURL = try FileManager.default
            .url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            .appendingPathComponent(filename)

        let data = try Data(contentsOf: fileURL)
        let model = try JSONDecoder().decode(Model.self, from: data)
        for (_,chunk) in model.dm.chunks {
            chunk.model = model
        }
        for (_, proc) in model.procedural.productions {
            proc.model = model
            for cond in proc.conditions {
                cond.model = model
            }
            for act in proc.actions {
                act.model = model
            }
        }
        return model
    } catch {
        return nil
    }
}


// Chunk values can be a symbol, a number or nil

enum Value: CustomStringConvertible, Codable {
   case symbol(Chunk)
    case Number(Double)
    case Text(String)
    case Empty
    
    private enum CodingKeys: String, CodingKey {
        case symbol
        case Number
        case Text
        case Empty
    }
    
       init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        if let value = try? values.decode(Double.self, forKey: .Number) {
            self = .Number(value)
            return
        }
        if let value = try? values.decode(String.self, forKey: .Text) {
            self = .Text(value)
            return
        }
        if let value = try? values.decode(Chunk.self, forKey: .symbol) {
            self = .symbol(value)
            return
        }
        self = .Empty
       }
       
       func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .symbol(let chunk):
            try container.encode(chunk, forKey: .symbol)
        case .Number(let num):
            try container.encode(num, forKey: .Number)
        case .Text(let str):
            try container.encode(str, forKey: .Text)
        case .Empty:
            try container.encodeNil(forKey: .Empty)
        }
       }
       
    
    func number() -> Double? {
        switch self {
        case .Number(let value):
            return value
        default:
            return nil
        }
    }
    
    func text() -> String? {
        switch self {
        case .Text(let s):
            return s
        default: return nil
        }
    }
    
    func empty() -> Bool {
        switch self {
        case .Empty: return true
        default: return false
        }
    }
    
    
    func chunk() -> Chunk? {
        switch self {
        case .symbol(let chunk):
            return chunk
        default:
            return nil
        }
    }
    
    func isEqual(value v: Value) ->  Bool {
        return v.description == self.description
    }
    
    var description: String {
        get {
            switch self {
            case .symbol(let value):
                return "\(value.name)"
            case .Number(let value):
                return "\(value)"
            case .Text(let value):
                return "\(value)"
            case .Empty:
                return "nil"
            }
        }
    }
}

func == (left: Value, right: Value) -> Bool {
    return left.description == right.description
}


extension String {
    func substring(from: Int, to: Int) -> String {
        let start = index(startIndex, offsetBy: from)
        let end = index(start, offsetBy: to - from)
        return String(self[start ..< end])
    }
    
    func substring(from: Int) -> String {
        let start = index(startIndex, offsetBy: from)
        return String(self[start...])
    }
    
    func substring(to: Int) -> String {
        let end = index(startIndex, offsetBy: to)
        return String(self[ ..<end])
    }
    
}

extension Int {
    func randomNumber() -> Int {
        return Int(arc4random_uniform(UInt32(self)))
    }
}


