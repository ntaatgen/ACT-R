//
//  PDViewController.swift
//  act-r
//
//  Created by Niels Taatgen on 4/2/15.
//  Copyright (c) 2015 Niels Taatgen. All rights reserved.
//

import UIKit

class PDViewController: UIViewController {
    var model: Prisoner?
    var timer: Timer? = nil
    
    @IBOutlet weak var dialog: UILabel!
    
    @IBOutlet weak var modelImage: UIImageView!
    
    @IBAction func decide(_ sender: UIButton) {
        if timer != nil {
            timer!.invalidate()
            timer = nil
        }
        var playercoop: Bool = false
        var modelreward: Double
        var playerreward: Double
        // Only do something if there is a model and that model is waiting for the player to take an action
        if (model != nil && model!.loadedModel == "prisoner" && model!.waitingForAction) && model!.actionChunk() {
            switch sender.currentTitle! {
                case "Cooperate":
                    print("Player did coop")
                model!.modifyLastAction(slot: "player", value: "coop")
                playercoop = true
                case "Defect":
                    print("Player did defect")
                model!.modifyLastAction(slot: "player", value: "defect")
                playercoop = false
            default: break
            }
            var newImage: UIImage = UIImage(named: "Decision.jpg")!
            switch (playercoop, model!.lastAction(slot: "model")!) {
            case (true,"coop"):
                 modelreward = 1.0
                 playerreward = 1.0
                newImage = UIImage(named: "Cooperate.jpg")!
            case (true,"defect"):
                 modelreward = 10.0
                 playerreward = -10.0
                 newImage = UIImage(named: "Defect.jpg")!
            case (false,"coop"):
                 modelreward = -10.0
                 playerreward = 10.0
                 newImage = UIImage(named: "Cooperate.jpg")!
            case (false,"defect"):
                 modelreward = -1.0
                 playerreward = -1.0
                 newImage = UIImage(named: "Defect.jpg")!
            default:  modelreward = 0.0
             playerreward = 0.0
            }
            UIView.transition(with: modelImage, duration: 0.75, options: UIView.AnimationOptions.transitionFlipFromLeft, animations: { self.modelImage.image = newImage }, completion: nil)
            //modelImage.image
            timer = Timer.scheduledTimer(timeInterval: 2.0, target: self, selector: #selector(PDViewController.flipCardBack(_:)), userInfo: nil, repeats: false)
            model!.playerScore += playerreward
            model!.modelScore += modelreward
            dialog.text = "You get \(playerreward) and I get \(modelreward)\n"
            dialog.text = dialog.text! + "Your score is \(model!.playerScore) and mine is \(model!.modelScore)\n"
            
            model!.modifyLastAction(slot: "payoffA", value: String(modelreward))
            model!.modifyLastAction(slot: "payoffB", value: String(playerreward))
//            model!.waitingForAction = false

            model?.time += 2.0
            model?.run()
        }
    }
    
    @objc func flipCardBack(_ x: Timer) {
        UIView.transition(with: modelImage, duration: 0.75, options: UIView.AnimationOptions.transitionFlipFromRight, animations: { self.modelImage.image = UIImage(named: "Decision.jpg")! }, completion: nil)
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
        if model!.loadedModel != "prisoner" {
            model!.loadedModel = "prisoner"
            model!.loadModel(fileName: "prisoner2")
            model!.reset()
        }
        print("Setting listener for Action")
        NotificationCenter.default.addObserver(self, selector: #selector(PDViewController.receiveAction), name: NSNotification.Name(rawValue: "Action"), object: nil)
        if model != nil {
            if model!.waitingForAction { receiveAction() }
        }
    }

    @objc func receiveAction() {
        print("added line")
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
