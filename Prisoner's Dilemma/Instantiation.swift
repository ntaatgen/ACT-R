//
//  Instantiation.swift
//  actr
//
//  Created by Niels Taatgen on 3/21/15.
//  Copyright (c) 2015 Niels Taatgen. All rights reserved.
//

import Foundation

class Instantiation {
    let p: Production
    var mapping: [String:Value] = [:]
    var u: Double
    var time: Double
    
    init(prod: Production, time: Double, u: Double) {
        self.p = prod
        self.u = u
        self.time = time
    }
    
    func replace(s1: String, s2: Chunk) {
        for (s,v) in mapping {
            switch v {
            case .Text(let str): if str == s1 { mapping[s] = .symbol(s2) }
            case .symbol(let chunk): if chunk.name == s1 { mapping[s] = .symbol(s2) }
            default: break
            }
        }
    }
    
}
