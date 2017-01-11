//
//  Production.swift
//  act-r
//
//  Created by Niels Taatgen on 3/29/15.
//  Copyright (c) 2015 Niels Taatgen. All rights reserved.
//

import Foundation

class Production: CustomStringConvertible {
    let name: String
    let model: Model
    var conditions: [BufferCondition] = []
    var actions: [BufferAction] = []
    var u: Double
    var reward: Double? = nil // if it has no value the production has no reward
    
    var description: String {
        get {
            var s = "(p \(name)\n"
            for cd in conditions {
                s += cd.description
            }
            s += "==>\n"
            for ac in actions {
                s += ac.description
            }
            return s + ")"
        }
    }
    
    
    init(name: String, model: Model) {
        self.name = name
        self.model = model
        self.u = model.procedural.defaultU
    }
    
    func addCondition(_ cd: BufferCondition) {
        conditions.append(cd)
    }
    
    func addAction(_ ac: BufferAction) {
        actions.append(ac)
    }
    
    /**
    - returns: If the production can be instantiated with the current buffers, otherwise nil
    */
    func instantiate() -> Instantiation? {
        let utility = u + actrNoise(noise: model.procedural.utilityNoise)
        let inst = Instantiation(prod: self, time: model.time, u: utility)
        for bc in conditions {
            if !bc.test(instantiation: inst) {
                return nil
            }
        }
        return inst
    }
    
    /**
    Function that executes all the production's actions
    - parameter inst: The instantiation of the production
    */
    func fire(instantiation inst: Instantiation) {
        for bc in conditions {
            if bc.prefix == "=" && bc.buffer != "goal" && bc.buffer != "imaginal" {
                var found = false
                for ac in actions {
                    if ac.buffer == bc.buffer {
                        found = true
                    }
                }
                if !found { model.buffers[bc.buffer] = nil }
            }
        }
        for ac in actions {
            ac.fire(inst)
        }
    }
    
}
