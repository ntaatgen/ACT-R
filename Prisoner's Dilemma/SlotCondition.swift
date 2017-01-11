//
//  SlotCondition.swift
//  actr
//
//  Created by Niels Taatgen on 3/21/15.
//  Copyright (c) 2015 Niels Taatgen. All rights reserved.
//

import Foundation

struct SlotCondition: CustomStringConvertible {
    let model: Model
    let slot: String
    let value: Value
    let op: String?
    
    var description: String {
        get {
            let op2 = (op != nil ? op! : " ")
            return "    \(op2) \(slot) \(value)"
        }
    }
    
init(op: String?, slot: String, value: Value, model: Model) {
    self.model = model
    self.value = value
    self.slot = slot
    self.op = op
    }
    
    func opTest(op: String?, val1: Double, val2: Double) -> Bool {
        if op == nil {
            return val1 == val2
        }
        switch op! {
            case "-": return val1 != val2
            case ">": return val1 <= val2
            case "<": return val1 >= val2
            case ">=": return val1 < val2
            case "<=": return val1 > val2
        default: return false
        }
    }
    
    func opTest(op: String?, val1: String, val2: String) -> Bool {
      //  println("Testing \(op) on \(val1) and \(val2)")
        let numval1 = NumberFormatter().number(from: val1)?.doubleValue
        let numval2 = NumberFormatter().number(from: val2)?.doubleValue
        if numval1 != nil && numval2 != nil {
            return opTest(op: op, val1: numval1!, val2: numval2!)
        }
        if op == nil {
//            println("Result equality test between \(val1) and \(val2)")
            return val1 == val2
        } else {
            return val1 != val2
        }
    }
    
    func test(bufferChunk: Chunk, inst: Instantiation) -> Bool {
        var testValue = self.value
        var bufferSlotValue = bufferChunk.slotvals[slot]
//        println("The value in the buffer is \(bufferSlotValue)")
        if bufferSlotValue == nil {
            bufferSlotValue = .Empty
        }
        if let text = testValue.text() {
            if isVariable(string: text) {
                let instVal = inst.mapping[text]
                if op == nil && instVal == nil { // Variable has not been assigned yet, so assign it
                    if bufferSlotValue!.empty() {
                        return false // Variable cannot be instatiated with nil
                    } else {
//                        println("\(text) is a new variable with value \(bufferSlotValue!)")
                        inst.mapping[text] = bufferSlotValue!
                        return true
                    }
                }
                
                    testValue = instVal!
//                    println("\(text) is an existing variable with value \(instVal!)")
                
            }
        }
        switch testValue {
        case .Empty:
            if (op == nil) {
                return  bufferSlotValue!.empty()
            } else  if (op! == "-")
            {
                return !bufferSlotValue!.empty()
            }
            case .symbol(let chunk):

                switch bufferSlotValue! {
                case .Empty: return op != nil && op! == "-"
                case .symbol(let chunk2): return opTest(op: op, val1: chunk.name, val2: chunk2.name )
                case .Text(let testString): return opTest(op: op, val1: chunk.name, val2: testString)
                case .Number(_): return op != nil
                }
            case .Text(let testString):
                switch bufferSlotValue! {
                case .Empty: return op != nil && op! == "-"
                case .symbol(let chunk2): return opTest(op: op, val1: chunk2.name, val2: testString)
                case .Text(let testString2): // println("Comparing two texts with \(op), \(testString2) and \(testString)")
                    return opTest(op: op, val1: testString2, val2: testString)
                case .Number(let num2): return opTest(op: op, val1: "\(num2)", val2: testString)
                }
            case .Number(let numVal):
                switch bufferSlotValue! {
                case .Empty: return op != nil && op! == "-"
                case .symbol(let chunk2): return opTest(op: op, val1: chunk2.name, val2: "\(numVal)")
                case .Text(let testString2): return opTest(op: op, val1: testString2, val2: "\(numVal)")
                case .Number(let num2): return opTest(op: op, val1: num2, val2: numVal)
            }
        }
        return false
    }


    
}

