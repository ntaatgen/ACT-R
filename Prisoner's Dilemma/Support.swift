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


// Chunk values can be a symbol, a number or nil

enum Value: CustomStringConvertible {
    case symbol(Chunk)
    case Number(Double)
    case Text(String)
    case Empty
    
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
