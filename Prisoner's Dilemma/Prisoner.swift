//
//  Prisoner.swift
//  Prisoner's Dilemma
//
//  Created by Niels Taatgen on 12/4/15.
//  Copyright © 2015 Niels Taatgen. All rights reserved.
//

import Foundation

class Prisoner: Model {
    var playerScore:Double = 0
    var modelScore:Double = 0
    var loadedModel: String? = nil
    /**
    Reset the prisoner's model: reset scores then do standard model init
    */
    override func reset() {
        self.playerScore = 0
        self.modelScore = 0
        super.reset()
    }
    
}
