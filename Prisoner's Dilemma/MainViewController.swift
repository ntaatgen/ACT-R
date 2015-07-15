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

    override func viewDidLoad() {
        super.viewDidLoad()
        let bundle = NSBundle.mainBundle()
        let path = bundle.pathForResource("prisoner2", ofType: "actr")!
        
        let modelText = String(contentsOfFile: path, encoding: NSUTF8StringEncoding, error: nil)!
        println("Got model text")
        //        println("\(modelText)")
        let parser = Parser(model: model, text: modelText)
        parser.parseModel()
        
        for (_,chunk) in model.dm.chunks {
            println("\(chunk)")
        }
        println()
        for (_,prod) in model.procedural.productions {
            println("\(prod)")
        }

        // Do any additional setup after loading the view.
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        println("PrepareForSegue called")
        if let identifier = segue.identifier {
            switch identifier {
            case "viewModel":
                println("Doing the segue")
                if let vm = segue.destinationViewController as? ModelViewController {
                    vm.model = self.model
                }
            case "viewPD":
                if let vm = segue.destinationViewController as? PDViewController {
                    vm.model = self.model
                }
            case "viewDM":
                if let vm = segue.destinationViewController as? DMViewController {
                    vm.model = self.model
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
