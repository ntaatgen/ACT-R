//
//  Vision.swift
//  Prisoner's Dilemma
//
//  Created by Niels Taatgen on 5/3/18.
//  Copyright © 2018 Niels Taatgen. All rights reserved.
//

import Foundation

class VisualObject {
    var name: String
    var visualType: String
    var attributes: [String:String] = [:]
    var color: String = "black"
    var x, y, w, h, d : Double
    var attended = false
    var attendedTime = 0.0
    var creationTime = 0.0
    var visloc: Chunk? = nil
    var visual: Chunk? = nil
    init(name: String, visualType: String, x: Double, y: Double, w: Double, h: Double, d: Double) {
        self.name = name
        self.visualType = visualType
        self.x = x + w/2
        self.y = y + h/2
        self.w = w
        self.h = h
        self.d = d
    }
    
    static func == (left: VisualObject, right: VisualObject) -> Bool {
        return left.visualType == right.visualType && left.x == right.x && left.y == right.y && left.attributes == right.attributes && left.color == right.color
    }
    func getVisualLocation(model: Model) -> Chunk {
        
        if visloc != nil {
            return visloc!
        } else {
            let vislocChunk = model.generateNewChunk(string: "visloc")
            vislocChunk.setSlot(slot: "isa", value: "visual-location")
            vislocChunk.setSlot(slot: "kind", value: visualType)
            vislocChunk.setSlot(slot: "screen-x", value: x)
            vislocChunk.setSlot(slot: "screen-y", value: y)
            vislocChunk.setSlot(slot: "width", value: w)
            vislocChunk.setSlot(slot: "height", value: h)
            vislocChunk.setSlot(slot: "distance", value: d)
            vislocChunk.setSlot(slot: "color", value: color)
            visloc = vislocChunk
            return vislocChunk
        }
    }
    
    func getVisual(model: Model) -> Chunk {
        if visual == nil {
            let visChunk = model.generateNewChunk(string: "visual")
            visChunk.setSlot(slot: "isa", value: visualType)
            visChunk.setSlot(slot: "screen-pos", value: visloc!)
            visChunk.setSlot(slot: "color", value: color)
            visChunk.setSlot(slot: "width", value: w)
            visChunk.setSlot(slot: "height", value: h)
            for (att,val) in attributes {
                visChunk.setSlot(slot: att, value: val)
            }
            visual = visChunk
        }
        return visual!
    }
}


class Vision {
    let model: Model
    var visualAttentionLatency = 0.085
    var visualNumFinsts = 10
    var visualOnsetSpan = 0.5
    var bufferStuffing = true
    var visualFinstSpan = 20.0
    var visualMovementTolerance = 3.0
    var visicon: [VisualObject] = []
    var finsts: [VisualObject] = []
    var currentlyAttended: VisualObject? = nil
    var visualError = false
    var visualLocationError = false
    
    init(model: Model) {
        self.model = model
    }
    
    func reset() {
        visicon = []
        finsts = []
        visualError = false
        visualLocationError = false
        currentlyAttended = nil
    }
    
    
    
    
    func clearVisual() {
        visicon = []
        currentlyAttended = nil
    }
    
    // We need functions that:
    // - Handle a visual-location request
    // - Build/update the visicon
    // - Handle a visual request
    // - Handle status checks
    // - A function that resets all attended flags
    // - A function that carries out matching (in particular specials like :attended)
    
    /**
     Update the vision with the object currently in the View.
     If the object is already in the current visicon, keep it,
     if it is new, add it. Remove the rest
     - Parameter items: should be set to the result of the items produced by ACTRWindowView
     */
    func updateVisicon(items: [VisualObject]) {
        var newVisicon : [VisualObject] = []
        for item in items {
            let findObject = visicon.filter({$0 == item})
            if findObject.isEmpty {
                item.name = model.generateName(string: "visobj")
                item.creationTime = model.time
                newVisicon.append(item)
            } else {
                newVisicon += findObject
                print("Adding object \(findObject) to visicon.")
            }
        }
        visicon = newVisicon
    }
    
    /**
    Check whether there are finsts to be removed
    */
    func updateFinsts() {
        for i in stride(from: finsts.count - 1, to: 0, by: -1) {
            let finst = finsts[i]
            if finst.attendedTime < model.time - visualFinstSpan {
                finst.attended = false
                finst.attendedTime = 0
                finsts.remove(at: i)
            }
        }
    }
    
    /**
     Check whether a given visual object matches the request
     - Parameter request: The visual-location request
     - Parameter visualObject: The visual object
     - returns: Whether there is a match
     */
    func matchesVisualObject(request: Chunk, visualObject vo: VisualObject) -> Bool {
        for (slot,value) in request.slotvals {
            switch (slot, value.description) {
            case ("kind", _): if vo.visualType != value.description { return false }
            case ("isa", _), (":nearest", _): break
            case (":attended", "nil"): if vo.attended { return false }
            case (":attended", "t"): if !vo.attended { return false }
            case (":attended", "new"): if vo.creationTime < model.time - visualOnsetSpan { return false }
            case ("color", _): if value.description != vo.color { return false }
            case (_, "lowest"), (_, "highest"): break
            default:
                if let numValue = value.number() {
                    switch slot {
                    case "screen-x": if abs(vo.x - numValue) > visualMovementTolerance { return false }
                    case "screen-y": if abs(vo.y - numValue) > visualMovementTolerance { return false }
                    case "-screen-x": if vo.x == numValue { return false }
                    case "-screen-y": if vo.y == numValue { return false }
                    case "<screen-x": if vo.x >= numValue { return false }
                    case ">screen-x": if vo.x <= numValue { return false }
                    case "<=screen-x": if vo.x > numValue { return false }
                    case ">=screen-x": if vo.x < numValue { return false }
                    case "<screen-y": if vo.y >= numValue { return false }
                    case ">screen-y": if vo.y <= numValue { return false }
                    case "<=screen-y": if vo.y > numValue { return false }
                    case ">=screen-y": if vo.y < numValue { return false }
                    default: print("Error: unknown slot \(slot) in visual location request \(request)")
                        return false
                    }
                } else {
                    print("Error: trying to match a non-number in visual-location request \(request)")
                    return false
                }
            }
            
        }
        return true
    }
    
    func visualObjectDistance(_ obj1: VisualObject, _ obj2: VisualObject) -> Double {
        return pow(obj1.x - obj2.x,2) + pow(obj1.y - obj2.y,2)  /// Omit sqrt because we are not really interested in the actual distance
    }
    
    
    /**
     Find a visual location that matches the request
     - Parameter request: A chunk representing the request
     - returns: A matching visual location, or nil if no match could be found
     */
    func findVisualLocation(request: Chunk) -> Chunk? {
        request.isRequest = false
        visualLocationError = false
        var candidates: [VisualObject] = []
        for obj in visicon {
            if matchesVisualObject(request: request, visualObject: obj) {
                candidates.append(obj)
            }
        }
        if candidates.isEmpty {
            visualLocationError = true
            return nil
        }
        // If we are looking for nearest remove all candidates that are not nearest
        if request.slotvals[":nearest"] != nil && currentlyAttended != nil {
            var shortestDistance = visualObjectDistance(currentlyAttended!, candidates[0])
            for vl in candidates {
                shortestDistance = min(shortestDistance, visualObjectDistance(currentlyAttended!, vl))
            }
            candidates = candidates.filter({ visualObjectDistance(currentlyAttended!, $0) <= shortestDistance })
        }
        var slotWithHighestOrLowest: String? = nil
        var lowest = false
        for (slot, value) in request.slotvals {
            if value.description == "lowest" {
                slotWithHighestOrLowest = slot
                lowest = true
                break
            } else if value.description == "highest" {
                slotWithHighestOrLowest = slot
                break
            }
        }
        if slotWithHighestOrLowest == nil {
            slotWithHighestOrLowest = "screen-x"
            lowest = true
        }
        var lhVL: VisualObject = candidates[0]
        for vl in candidates {
            switch (slotWithHighestOrLowest!, lowest) {
            case ("screen-x", true): if vl.x < lhVL.x  || (vl.x == lhVL.x && vl.y < lhVL.y) { lhVL = vl }
            case ("screen-y", true): if vl.y < lhVL.y  || (vl.y == lhVL.y && vl.x < lhVL.x) { lhVL = vl }
            case ("screen-x", false): if vl.x > lhVL.x  || (vl.x == lhVL.x && vl.y > lhVL.y) { lhVL = vl }
            case ("screen-y", false): if vl.y > lhVL.y  || (vl.y == lhVL.y && vl.x > lhVL.x) { lhVL = vl }
            case ("width", true): if vl.w < lhVL.w || ( vl.w == lhVL.w && vl.h < lhVL.h) { lhVL = vl }
            case ("height", true): if vl.h < lhVL.h || ( vl.h == lhVL.h && vl.w < lhVL.w) { lhVL = vl }
            case ("width", false): if vl.w > lhVL.w || ( vl.w == lhVL.w && vl.h > lhVL.h) { lhVL = vl }
            case ("height", false): if vl.h > lhVL.h || ( vl.h == lhVL.h && vl.w > lhVL.w) { lhVL = vl }
            default: break
            }
        }
        return lhVL.getVisualLocation(model: model)
    }
    
    
    func visualLocationQuery(slot: String, value: String) -> Bool {
        switch (slot, value) {
        case ("state", "free"): return true
        case ("state", "error"): return visualLocationError
        case ("buffer", "empty"): return model.buffers["visual-location"] == nil
        default: return false
        }
    }
    
    func visualQuery(slot: String, value: String) -> Bool {
        switch (slot, value) {
        case ("state", "free"): return true
        case ("state", "error"): return visualError
        case ("buffer", "empty"): return model.buffers["visual"] == nil
        default: return false
        }
    }
    
    func update() -> Double {
        updateFinsts()
        if let request = model.buffers["visual-location"], request.isRequest {
            print("Handling visual-location request")
            if let result = findVisualLocation(request: request) {
                model.buffers["visual-location"] = result
                print("Using \(result) for visual-location")
                model.addToTrace(string: "Found visual-location \(result.name)")
            } else {
                model.buffers["visual-location"] = nil
                model.addToTrace(string: "No visual-location found")
            }
        }
        if let request = model.buffers["visual"], request.isRequest {
            print("handling visual request \(request)")
            model.buffers["visual"] = nil
            if let requestType = request.slotvals["isa"] {
                print("Request isa \(requestType.description)")
                switch requestType.description {
                case "move-attention":
                    if let vl = request.slotvals["screen-pos"]?.description {
                        let vo = visicon.filter({ $0.visloc != nil && $0.visloc!.name == vl } )
                        if vo.isEmpty {
                            visualError = true
                            currentlyAttended = nil
                            print("Couldn't find visual-location in visicon")
                            model.addToTrace(string: "Trying to attend to visual-location \(vl) but is it already empty.")
                        } else {
                            model.buffers["visual"] = vo[0].getVisual(model: model)
                            vo[0].attended = true
                            vo[0].attendedTime = model.time + visualAttentionLatency
                            currentlyAttended = vo[0]
                            print("Setting visual to \(vo[0].getVisual(model: model))")
                            model.addToTrace(string: "Attending visual \(vo[0].getVisual(model: model).name)")
                            return visualAttentionLatency
                        }
                        
                    } else {
                        model.addToTrace(string: "Move-attention visual request has no screen-pos slot.")
                    }
                case "clear": clearVisual()
                default: model.addToTrace(string: "Illegal visual action \(requestType.description)")
                }
            } else {
                model.addToTrace(string: "No type given for +visual>")
            }
        }
        return 0.0
    }
    
}
