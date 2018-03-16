//
//  SubitizeViewController.swift
//  Prisoner's Dilemma
//
//  Created by Niels Taatgen on 12/3/18.
//  Copyright © 2018 Niels Taatgen. All rights reserved.
//

import UIKit

class SubitizeViewController: UIViewController {

    
    @IBOutlet weak var modelFrame: ACTRWindowView!
    var model: Prisoner?

    @IBAction func run() {
        reset()
        let visualItems = modelFrame.getVisicon()
        model!.visual.updateVisicon(items: visualItems)
        let startTime = model!.time
        traceWindow.text = model!.trace
        model!.run(step: true)
        _ = Timer.scheduledTimer(timeInterval: model!.time - startTime, target: self, selector: #selector(step), userInfo: nil, repeats: false)
    }
    
    @objc func step () {
        traceWindow.text = model!.trace
        if let vo = model?.visual.currentlyAttended {
            modelFrame.displayFocusRing(vo: vo)
        }
        if model!.actionChunk() {
            let action = model!.lastAction(slot: "number") ?? "None"
            traceWindow.text = model!.trace + "\nAnswer: \(action)\n"
        } else {
            let startTime = model!.time
            model!.run(step: true)
            _ = Timer.scheduledTimer(timeInterval: model!.time - startTime, target: self, selector: #selector(step), userInfo: nil, repeats: false)
        }
    }
    
    
    func reset() {
        if model!.loadedModel! != "subitize" {
            model!.loadModel(fileName: "subitize")
            model!.loadedModel = "subitize"
        }
        model!.reset()
        populateFrame(n: 2 + 8.randomNumber())
    }
    
    @IBOutlet weak var traceWindow: UITextView!
    
    func populateFrame(n: Int) {
        for subview in modelFrame.subviews {
            subview.removeFromSuperview()
        }
        for _ in 1...n {
            let x = modelFrame.bounds.size.width * (0.2 + CGFloat(0.6).randomNumber())
            let y = modelFrame.bounds.size.height * (0.2 + CGFloat(0.6).randomNumber())
            let label = UILabel(frame: CGRect(x: x, y: y, width: 10, height: 10))
            label.text = "x"
            modelFrame.addSubview(label)
        }
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        populateFrame(n: 2 + 8.randomNumber())
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}

extension CGFloat {
    func randomNumber() -> CGFloat {
        return CGFloat(drand48()) * self
    }
}
