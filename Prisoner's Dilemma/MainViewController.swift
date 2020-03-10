//
//  MainViewController.swift
//  act-r
//
//  Created by Niels Taatgen on 4/2/15.
//  Copyright (c) 2015 Niels Taatgen. All rights reserved.
//

import UIKit

class MainViewController: UIViewController {
    var model = Model()
    var prisoner = Prisoner()
    override func viewDidLoad() {
        super.viewDidLoad()
        if let m = readModel(filename: "prisoner.json") {
            model = m
            let goal = Chunk(s: "goal", m: model)
            goal.setSlot(slot: "isa", value: "decision")
            goal.setSlot(slot: "state", value: "start")
            model.buffers["goal"] = goal
            for (_,chunk) in model.dm.chunks {
                print("\(chunk)")
            }
            print("")
            for (_,prod) in model.procedural.productions {
                print("\(prod)")
            }
            model.isValid = true
        } else {
            model.loadModel(fileName: "prisoner2")
        }
       prisoner.loadedModel = "prisoner"

        // Do any additional setup after loading the view.
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        print("PrepareForSegue called")
        if let identifier = segue.identifier {
            switch identifier {
            case "viewModel":
                print("Doing the segue")
                if let vm = segue.destination as? ModelViewController {
                    vm.model = self.model
                    vm.prisoner = self.prisoner
                }
            case "viewPD":
                if let vm = segue.destination as? PDViewController {
                    vm.model = self.model
                    vm.prisoner = self.prisoner
                }
            case "viewDM":
                if let vm = segue.destination as? DMViewController {
                    vm.model = self.model
                }
            case "subitize":
                if let vm = segue.destination as? SubitizeViewController {
                    vm.model = self.model
                    vm.prisoner = self.prisoner
                }
            default : break
            }
        }
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
