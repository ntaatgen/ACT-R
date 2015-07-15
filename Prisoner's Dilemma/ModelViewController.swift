//
//  ViewController.swift
//  act-r
//
//  Created by Niels Taatgen on 3/24/15.
//  Copyright (c) 2015 Niels Taatgen. All rights reserved.
//

import UIKit

class ModelViewController: UIViewController {

    var keyboardShowing = false
    var model: Model!
    @IBOutlet weak var modelText: UITextView!
    @IBOutlet weak var traceText: UITextView!
    
    
    @IBAction func run() {
        if !model!.running {
        model.clearTrace()
        model.run()
        }
    }
    
    
    @IBAction func reset() {
        model.time = 0
        model.dm.chunks = [:]
        model.procedural.productions = [:]
        model.buffers = [:]
        let parser = Parser(model: model, text: modelText.text!)
        parser.parseModel()
        model.modelScore = 0
        model.playerScore = 0
        model.clearTrace()
        model.running = false
        model.waitingForAction = false
    }
    
    
    @IBAction func loadSimple() {
        let bundle = NSBundle.mainBundle()
        let path = bundle.pathForResource("prisoner", ofType: "actr")!
        
        let modelText = String(contentsOfFile: path, encoding: NSUTF8StringEncoding, error: nil)!
        self.modelText.text = modelText
        reset()
        
    }
    
    @IBAction func loadComplex() {

        let bundle = NSBundle.mainBundle()
        let path = bundle.pathForResource("prisoner2", ofType: "actr")!
        
        let modelText = String(contentsOfFile: path, encoding: NSUTF8StringEncoding, error: nil)!
        self.modelText.text = modelText
        reset()

    }
    
    
    @IBAction func loadCount() {
        let bundle = NSBundle.mainBundle()
        let path = bundle.pathForResource("count", ofType: "actr")!
        
        let modelText = String(contentsOfFile: path, encoding: NSUTF8StringEncoding, error: nil)!
        self.modelText.text = modelText
        reset()
    }
    
    
    func updateTrace() {
        traceText.text! = model.trace
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "updateTrace", name: "TraceChanged", object: nil)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardShow:", name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardHide:", name: UIKeyboardWillHideNotification, object: nil)
        updateTrace()
        modelText.text = model.modelText
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func shouldAutorotate() -> Bool {
        return !self.keyboardShowing
    }
    
    func keyboardShow(n:NSNotification) {
        self.keyboardShowing = true
        
        let d = n.userInfo!
        var r = (d[UIKeyboardFrameEndUserInfoKey] as! NSValue).CGRectValue()
        r = self.modelText.convertRect(r, fromView:nil)
        self.modelText.contentInset.bottom = r.size.height
        self.modelText.scrollIndicatorInsets.bottom = r.size.height
    }
    
    func keyboardHide(n:NSNotification) {
        self.keyboardShowing = false
        self.modelText.contentInset = UIEdgeInsetsZero
        self.modelText.scrollIndicatorInsets = UIEdgeInsetsZero
    }
    
    func doDone(sender:AnyObject) {
        self.view.endEditing(false)
    }


}


