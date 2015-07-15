//
//  PDViewController.swift
//  act-r
//
//  Created by Niels Taatgen on 4/2/15.
//  Copyright (c) 2015 Niels Taatgen. All rights reserved.
//

import UIKit

class PDViewController: UIViewController {
    var model: Model?
    var timer: NSTimer? = nil
    
    @IBOutlet weak var dialog: UILabel!
    
    @IBOutlet weak var modelImage: UIImageView!
    
    @IBAction func decide(sender: UIButton) {
        if timer != nil {
            timer!.invalidate()
            timer = nil
        }
        var playercoop: Bool = false
        var modelreward: Double
        var playerreward: Double
        if (model != nil && model!.waitingForAction) && model!.buffers["action"] != nil {
            let actionChunk = model!.buffers["action"]!
            actionChunk.isRequest = false
            switch sender.currentTitle! {
                case "Cooperate":
                    println("Player did coop")
                actionChunk.setSlot("player", value: "coop")
                playercoop = true
                case "Defect":
                    println("Player did defect")
                actionChunk.setSlot("player", value: "defect")
                playercoop = false
            default: break
            }
            var newImage: UIImage = UIImage(named: "Decision.jpg")!
            switch (playercoop, actionChunk.slotValue("model")!) {
            case (true,.Text("coop")):
                 modelreward = 1.0
                 playerreward = 1.0
                newImage = UIImage(named: "Cooperate.jpg")!
            case (true,.Text("defect")):
                 modelreward = 10.0
                 playerreward = -10.0
                 newImage = UIImage(named: "Defect.jpg")!
            case (false,.Text("coop")):
                 modelreward = -10.0
                 playerreward = 10.0
                 newImage = UIImage(named: "Cooperate.jpg")!
            case (false,.Text("defect")):
                 modelreward = -1.0
                 playerreward = -1.0
                 newImage = UIImage(named: "Defect.jpg")!
            default:  modelreward = 0.0
             playerreward = 0.0
            }
            UIView.transitionWithView(modelImage, duration: 0.75, options: UIViewAnimationOptions.TransitionFlipFromLeft, animations: { self.modelImage.image = newImage }, completion: nil)
            //modelImage.image
            timer = NSTimer.scheduledTimerWithTimeInterval(2.0, target: self, selector: "flipCardBack:", userInfo: nil, repeats: false)
            model!.playerScore += playerreward
            model!.modelScore += modelreward
            dialog.text = "You get \(playerreward) and I get \(modelreward)\n"
            dialog.text = dialog.text! + "Your score is \(model!.playerScore) and mine is \(model!.modelScore)\n"
            
            actionChunk.setSlot("payoffA", value: modelreward)
            actionChunk.setSlot("payoffB", value: playerreward)
            model!.waitingForAction = false

            model?.time += 2.0
            // model!.dm.addToDM(actionChunk)
            model?.run()
        }
    }
    
    func flipCardBack(x: NSTimer) {
        UIView.transitionWithView(modelImage, duration: 0.75, options: UIViewAnimationOptions.TransitionFlipFromRight, animations: { self.modelImage.image = UIImage(named: "Decision.jpg")! }, completion: nil)
        timer = nil
    }
    
    @IBAction func run() {
        if model != nil && !model!.running {
            model?.clearTrace()
            model?.run()
        }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        println("Setting listener for Action")
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "recieveAction", name: "Action", object: nil)
        if model != nil {
            if model!.waitingForAction { recieveAction() }
        }
    }

    func recieveAction() {
        println("added line")
        dialog.text = dialog.text! + "Please indicate your decision\n"

    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
