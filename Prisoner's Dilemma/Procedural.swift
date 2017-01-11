//
//  Procedural.swift
//  act-r
//
//  Created by Niels Taatgen on 3/29/15.
//  Copyright (c) 2015 Niels Taatgen. All rights reserved.
//

import Foundation

class Procedural {
    var utilityNoise = 0.2
    var defaultU = 10.0
    var productions: [String:Production] = [:]
    
    func addProduction(production p: Production) {
        productions[p.name] = p
    }
}
