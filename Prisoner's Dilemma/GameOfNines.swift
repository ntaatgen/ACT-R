//
//  GameOfNines.swift
//  actr
//
//  Created by Niels Taatgen on 3/5/15.
//  Copyright (c) 2015 Niels Taatgen. All rights reserved.
//

//  let us rename slots, this is confusing. difference = agent1mns-bid-difference playermove = agent2move type = agent1action mymove = agent1move strategy = agent1strategy


import UIKit

class GameOfNines: Model {
    
    var modelBid: Int? = nil
    
    private var modelPreviousBid: Int? = nil
    
    var modelDidQuit = false
    
    var gameEnded = false
    
    var modelComment: String = ""
    
    var modelFinal = false
    
    var playerLastBid: Int? = nil
    
    var playerMNS: Int = 0
    
    var modelMNS = 0
    
    var modelStrategyCoop: Bool = true
    
    var score: Int = 0
    
    var modelScore: Int = 0
    
    var lastGameDone: Bool = false

    var lastConflictSet: [(Chunk,Double)] = []
    
    var currentFeedBackChunk: Chunk? = nil
    
    var playerStarts: Bool
    
    var trueMNSdiff: Int = 0
    
    var modelName: String? = nil
    
    var learningModel: Bool = false
    
    var actionClassification: String? = nil {
        didSet {
            if actionClassification != nil && currentFeedBackChunk != nil {
                currentFeedBackChunk!.setSlot("agent1strategy", value: actionClassification!)
                currentFeedBackChunk!.fixedActivation = 1.0
                if currentFeedBackChunk!.slotvals["agent1mns-bid-difference"] != nil {
                    currentFeedBackChunk!.setSlot("agent1mns-bid-difference", value: Double(trueMNSdiff))
                }
                if currentFeedBackChunk!.slotvals["agent1mns"] != nil {
                    currentFeedBackChunk!.setSlot("agent1mns", value: Double(playerMNS))
                }
                dm.addToDM(currentFeedBackChunk!)
            }
        }
    }

    let modelType: String
    
    class func allExperiments() -> [String:[(Int,Int)]] {
        return ["Kelley 1":[(1,1),(2,2),(3,3),(1,4),(4,1),(1,6),(6,1)],
            "Kelley 2":[(1,1),(2,2),(3,3),(4,4),(1,3),(3,1),(1,5),(5,1),(2,6),(6,2),(4,5),(5,4)],
            "Kelley 3":[(1,1),(2,2),(3,3),(4,4),(1,3),(3,1),(1,5),(5,1),(2,6),(6,2),(4,3),(3,4)],
            "Schoeninger": [(3,3),(4,4),(5,5),(6,1),(3,2),(6,4),(5,3),(5,1),(4,3),(1,6),(2,3),(4,6),(3,5),(1,5),(3,4)],
            "Daamen": [(1,1),(1,3),(3,1),(2,2),(3,3),(2,3),(3,2),(3,4),(4,3),(2,4),(4,2),(4,4)]]
    }
    
    
    class func experimentTitles() -> [String] {
        var result: [String] = []
        for (title,_) in allExperiments() {
            result.append(title)            
        }
        return result
    }
    
    //var allGames = [(1,1),(2,2),(3,3),(1,4),(4,1),(1,6),(6,1)] // Original Kelley experiment 1
    var allGames = [(1,1),(2,2),(3,3),(4,4),(1,3),(3,1),(1,5),(5,1),(2,6),(6,2),(4,5),(5,4)] // Original Kelley experiment 2
    
    var modelCoop: Bool {
        get {
            let aggrChunk = dm.chunks["aggressive"]!
            let coopChunk = dm.chunks["coop"]!
            let coopval = dm.chunks["aggressive"]!.activation() <= dm.chunks["coop"]!.activation()
            let mood = (coopval ? "Cooperative" : "Aggressive")
            println("I feel \(mood)")
            return coopval
        }
    }
    
    let averageMNS: Double
    
    init(selectedGame: String, modelType: String, model: String) {
        let games = GameOfNines.allExperiments()
        allGames = games[selectedGame]!
        self.modelType = modelType
        var sum = 0
        for (mns1,mns2) in allGames { sum += mns1 }
        averageMNS = Double(sum) / Double(allGames.count)
        var permuted: [(Int,Int)] = []
        while !allGames.isEmpty {
            let position = Int(arc4random_uniform(UInt32(allGames.count)))
            permuted.append(allGames.removeAtIndex(position))
        }
        allGames = permuted
        self.playerStarts = false
        super.init()
        self.dm.optimizedLearning = true
        self.dm.activationNoise = 0.05
        let bundle = NSBundle.mainBundle()
        var path: String
//        println("\(model)")
        switch model {
            case "Empty model":
                path = bundle.pathForResource("GOFsimple", ofType: "actr")!
            learningModel = true
            case "Standard model": path = bundle.pathForResource("gameofnines", ofType: "actr")!
            learningModel = false
        case "Learned model":
            learningModel = true
            let dirs: [String]? = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.AllDomainsMask, true) as? [String]
        if (dirs != nil) {
            let directories:[String] = dirs!
            let dirs = directories[0]; //documents directory
             path = dirs.stringByAppendingPathComponent("learnedmodel.actr")
        } else {
              path = bundle.pathForResource("learnedmodel", ofType: "actr")!
        }
            
        default: return
        }
        modelName = model
        //let path = bundle.pathForResource("gameofnines", ofType: "actr")
        let modelText = String(contentsOfFile: path, encoding: NSUTF8StringEncoding, error: nil)!
        
        let parser = Parser(model: self, text: modelText)
        parser.parseModel()
        randomizeDM()
        switch modelType {
            case "Cooperative": dm.chunks["coop"]!.fixedActivation = 10.0
            case "Aggressive": dm.chunks["aggressive"]!.fixedActivation = 10.0
        default: break
        }
        
        time += 1

    }
    
    private func addAggressive() {
        dm.chunks["aggressive"]!.addReference()
    }
    
    private func addCoop() {
        dm.chunks["coop"]!.addReference()
    }
    
    func randomizeDM() {
        for (_,chunk) in dm.chunks {
            if chunk.fixedActivation != nil {
//                println("Chunk \(chunk) with fixed \(chunk.fixedActivation)")
            chunk.fixedActivation = 0.9 + Double(Int(arc4random_uniform(100))) / 500.0
            }
        }
    }

    func mismatchBids(x: Module.Value, y: Module.Value) -> Double? {
        switch x {
        case .Number(let num1):
            switch y {
            case .Number(let num2):
                let distance = (num1 - num2)*(num1 - num2)
                return 1.0 / (distance / 2.0 + 1.0) - 1.0
            default: return nil
            }
        case .Symbol(let chunk1):
            switch y {
            case .Symbol(let chunk2):
                switch (chunk1.symbol, chunk2.symbol) {
                case ("coop","neutral"): fallthrough
                case ("neutral","coop"): fallthrough
                case ("aggressive","neutral"): fallthrough
                case ("neutral","aggressive"):
                    return -0.1
                default: return nil
                }
            default: return nil
            }
        default: return nil
        }
    }

    // type can be: "bid" "final" "quit" "reject" "accept". Quit is only needed to update ToM, and to handle scoring
    
    func playerBid(var bid: Int, type: String) {
        var offer = 0
        modelComment = ""
        // we are going to build a dm request to interpret the opponent's move

        let tomRetrieve = Chunk(s: "learned\(chunkNameCounter++)", m:self)
        tomRetrieve.setSlot("isa", value: "move")
        // and one to retrieve our own action
        let retrieveAct = Chunk(s: "decide", m:self)
        time += 1.0
        if type == "quit"  {
            tomRetrieve.setSlot("agent1action", value: type)
            tomRetrieve.setSlot("agent1mns-bid-difference", value: Double(bid) - averageMNS)
            tomRetrieve.setSlot("agent2move", value: Double(modelPreviousBid == nil ? 1 : modelPreviousBid! - modelBid!))
            tomRetrieve.setSlot("agent2action", value: "bid")
           gameEnded = true
            modelComment += "No agreement.\n"
            modelDidQuit = true
        } else if type == "reject" {
            tomRetrieve.setSlot("agent1action", value: type)
            tomRetrieve.setSlot("agent1mns-bid-difference", value: Double(bid) - averageMNS)
            tomRetrieve.setSlot("agent2move", value: Double(modelPreviousBid == nil ? 1 : modelPreviousBid! - modelBid!))
            tomRetrieve.setSlot("agent2action", value: "final")
            gameEnded = true
            modelComment += "No agreement.\n"
            modelDidQuit = true
        } else if (type == "final" && playerLastBid == nil) {
            gameEnded = true
            modelComment += "I reject your offer.\n"
            modelDidQuit = true
        } else if (type == "accept") {
            tomRetrieve.setSlot("agent1action", value: type)
            tomRetrieve.setSlot("agent1mns-bid-difference", value: Double(bid) - averageMNS)
            tomRetrieve.setSlot("agent2move", value: Double(modelPreviousBid == nil ? 1 : modelPreviousBid! - modelBid!))
            tomRetrieve.setSlot("agent2action", value: "final")
            gameEnded = true
            modelComment += "I am glad we could come to an agreement.\n"
            bid = 9 - modelBid!
        } else if (type == "start") {
                retrieveAct.setSlot("agent1mns", value: Double(modelMNS))
            } else {
            if playerLastBid == nil { // Reaction to opening bid
                retrieveAct.setSlot("agent1mns", value: Double(modelMNS))
//                retrieveAct.setSlot("agent2action", value: "bid")
//                retrieveAct.setSlot("agent2value", value: Double(bid))
                tomRetrieve.setSlot("agent1action", value: "bid")
                tomRetrieve.setSlot("agent1move", value: Double(bid))
                tomRetrieve.setSlot("agent1mns", value: averageMNS)
            } else if type == "bid" {
                
                tomRetrieve.setSlot("agent1action",value: (bid == playerLastBid! ? "insist" : "concede"))
                tomRetrieve.setSlot("agent1move", value: Double(playerLastBid! - bid))
                tomRetrieve.setSlot("agent1mns-bid-difference", value: Double(bid) - averageMNS)
                tomRetrieve.setSlot("agent2action", value: "bid")
                tomRetrieve.setSlot("agent2move", value: Double(modelPreviousBid == nil ? 1 : modelPreviousBid! - modelBid! ))
                println("modelPreviousBid = \(modelPreviousBid), value = \(Double(modelPreviousBid == nil ? 1 : modelPreviousBid! - modelBid!))")
                retrieveAct.setSlot("agent2action", value: type)
                retrieveAct.setSlot("agent2move", value: Double(playerLastBid! - bid))
                retrieveAct.setSlot("agent1mns-bid-difference", value: Double(modelBid! - modelMNS))
            } else if type == "final" {
                tomRetrieve.setSlot("agent1action", value: type)
                tomRetrieve.setSlot("agent1move", value: Double(playerLastBid! - bid))
                tomRetrieve.setSlot("agent2action", value: "bid")
                tomRetrieve.setSlot("agent2move", value: Double(modelPreviousBid == nil ? 1 : modelPreviousBid! - modelBid! ))
                tomRetrieve.setSlot("agent1mns-bid-difference", value: Double(modelBid! - modelMNS))
                retrieveAct.setSlot("agent2action", value: type)
                retrieveAct.setSlot("agent2move", value: Double(playerLastBid! - bid))
                retrieveAct.setSlot("agent1mns-bid-difference", value: Double((9 - bid) - modelMNS))
            }
        }
        trueMNSdiff = bid - playerMNS  // This will be used for teaching the model
        if type != "start" {
            dm.retrievalThreshold = learningModel ? 0 : -20
        if modelType == "Metacognitive" && tomRetrieve.slotValue("agent1action") != nil {
            println("Tom request = \(tomRetrieve)")
            let tom = self.dm.partialRetrieve(tomRetrieve, mismatchFunction: mismatchBids)
            println("Retrieved TOM = \(tom)")
            if tom == nil {
                currentFeedBackChunk = tomRetrieve
                NSNotificationCenter.defaultCenter().postNotificationName("askClassification", object: nil)
            } else {
            switch tom!.slotValue("agent1strategy")! {
            case .Symbol(let chunk):
                switch chunk.symbol {
                case "coop": addCoop()
                    modelComment += "That is a cooperative bid.\n"
                case "aggressive": addAggressive()
                    modelComment += "That is an aggressive bid.\n"
                default: modelComment += "I think your bid is neutral.\n"
                }
            default: break
            }
            }
        }
        }
        lastConflictSet = dm.conflictSet
        time += 1
        dm.retrievalThreshold = learningModel ? -3.0 : -20
        modelStrategyCoop = modelCoop // remember  what the model strategy was during retrieval
        if !gameEnded {
            retrieveAct.setSlot("agent1strategy", value: (modelStrategyCoop ? "coop" : "aggressive"))
            println("Retrieve request = \(retrieveAct)")
            let action = self.dm.partialRetrieve(retrieveAct,mismatchFunction: mismatchBids)
            if action == nil {
                println("modelBid = \(modelBid)")
                if modelBid == nil {
                    offer = modelMNS + 3
                    modelComment += "My offer is \(offer).\n"
                } else {
                    switch type {
                    case "bid":
                        if (playerLastBid! - bid > 0) && modelBid! > modelMNS {
                        offer = modelBid! - 1
                            modelComment += "I will lower my bid to \(offer).\n" }
                        else {
                            offer = modelBid!
                            modelComment += "I will stick to \(offer).\n"
                        }
                    case "final":
                        gameEnded = true
                        if (9 - bid) > modelMNS {
                            offer = 9 - bid
                            modelComment += "I accept your offer\n"
                        } else {
                            offer = 9 - bid
                            modelComment += "I reject your offer\n"
                            modelDidQuit = true
                        }
                    default:
                        println("Didn't handle \(type)")
                        break
                }
                }
            } else {
            println("Retrieving \(action)")
            switch action!.slotValue("agent1action")! {
            case .Text("concede"):
                switch action!.slotValue("agent1move")! {
                case .Number(let move):
                    offer = modelBid! - Int(move)
                default:
                    offer = modelBid! - 1 // shouldn't happen
                }
                if (offer + bid < 9) { offer = 9 - bid }
                if (offer < modelMNS) { offer = modelMNS
                    modelComment += "My offer is \(offer).\n"
                } else {
                    modelComment += "I will lower my bid to \(offer).\n"
                }
            case .Text("bid"):
                switch action!.slotValue("agent1move")! {
                case .Number(let move):
                    offer = Int(move)
                default:
                    offer = 9 // shouldn't happen
                }
                modelComment += "My opening offer is \(offer).\n"
            case .Text("insist"):
                offer = modelBid!
                modelComment += "I will stick to \(offer).\n"
            case .Text("final"):
                switch action!.slotValue("agent1move")! {
                case .Number(let move):
                    offer = max(modelMNS, modelBid! - Int(move))
                default:
                    offer = modelBid! // shouldn't happen
                }
                modelFinal = true
                modelComment += "My final offer is \(offer).\n"
            case .Text("reject"):
                modelDidQuit = true
                gameEnded = true
                modelComment += "I reject your offer.\n"
            case .Text("accept"):
                offer = 9 - bid
                if offer < modelMNS {
                    modelComment += "I reject your offer.\n"
                    modelDidQuit = true
                } else {
                    modelComment += "I accept your offer.\n"
                }
                gameEnded = true

            case .Text("quit"):
                modelDidQuit = true
                gameEnded = true
                modelComment += "I quit.\n"
            default: break
            }
            }
            playerLastBid = bid
            time += 1.0
        }
        modelPreviousBid = modelBid
        if (offer + bid <= 9 && !modelDidQuit) {
            offer = 9 - bid /// don't give more than necessary
            modelComment += "We have an agreement: I take \(offer), and you get \(bid).\n"
            modelFinal = false
            gameEnded = true
        }
        modelBid = offer
        if gameEnded {
            let yield = modelDidQuit ? 0 : bid - playerMNS
            if !modelDidQuit {
                score += yield
                modelScore += (9 - bid) - modelMNS
            }
            let letter = (yield == 1 ? "" : "s")
            modelComment += "You score \(yield) point\(letter).\n"
            if allGames.isEmpty {
                lastGameDone = true
                // Now write model to a file, if necessary
                if (modelName != "Standard model") {
                    var modelOutput = "(add-dm\n"
                    for (_,chunk) in dm.chunks {
                        modelOutput += "(" + chunk.description
                        if chunk.slotvals["isa"]!.text()! == "move" {
                            modelOutput += "   :activation 1.0\n"
                        }
                        modelOutput += ")\n"
                        
                }
                    modelOutput += ")\n(set-env \(self.time) \(self.chunkNameCounter) )\n"
                    
                    println("\(modelOutput)")
                    let dirs: [String]? = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.AllDomainsMask, true) as? [String]
                    
                    if (dirs != nil) {
                        let directories:[String] = dirs!
                        let dirs = directories[0]; //documents directory
                        let path = dirs.stringByAppendingPathComponent("learnedmodel.actr")
                    modelOutput.writeToFile(path, atomically: true, encoding: NSUTF8StringEncoding, error: nil)
                    }
            }
            }
        }
    }


    
    func initGame() {
            (playerMNS, modelMNS) = allGames.removeAtIndex(0)
            playerLastBid = nil
            modelBid = nil
            modelPreviousBid = nil
            modelDidQuit = false
            gameEnded = false
            modelFinal = false
            playerStarts = !playerStarts

    }
}