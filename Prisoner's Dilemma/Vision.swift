//
//  Vision.swift
//  Prisoner's Dilemma
//
//  Created by Niels Taatgen on 5/3/18.
//  Copyright © 2018 Niels Taatgen. All rights reserved.
//

import Foundation

class Vision {
    let model: Model
    
    class VisualObject {
        var name: String
        var visualType: String
        var value: String
        var x, y, w, h, d : Double
        var attended = false
        var attendedTime = 0.0
        var creationTime = 0.0
        var visloc: Chunk? = nil
        
        init(name: String, visualType: String, value: String, x: Double, y: Double, w: Double, h: Double, d: Double) {
            self.name = name
            self.visualType = visualType
            self.value = value
            self.x = x + w/2
            self.y = y + h/2
            self.w = w
            self.h = h
            self.d = d
        }
    }
    
    
    var visualAttentionLatency = 0.085
    var visualNumFirst = 4.0
    var bufferStuffing = true
    
    var visicon: [String:VisualObject] = [:]
    
    
    init(model: Model) {
        self.model = model
    }
    
    func getVisualLocation(name: String) -> Chunk? {
        if let vo = visicon[name] {
            if vo.visloc != nil {
                return vo.visloc!
            } else {
                let vislocChunk = model.generateNewChunk(string: name)
                vislocChunk.setSlot(slot: "isa", value: "visual-location")
                vislocChunk.setSlot(slot: "kind", value: vo.visualType)
                vislocChunk.setSlot(slot: "screenx", value: vo.x)
                vislocChunk.setSlot(slot: "screeny", value: vo.y)
                vislocChunk.setSlot(slot: "width", value: vo.w)
                vislocChunk.setSlot(slot: "height", value: vo.h)
                vislocChunk.setSlot(slot: "distance", value: vo.d)
                vo.visloc = vislocChunk
                return vislocChunk
            }
        } else {
            return nil
        }
    }
    
    func clearVisual() {
        visicon = [:]
    }
    
    
    
}
