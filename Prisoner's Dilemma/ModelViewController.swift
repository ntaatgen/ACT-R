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
    var model: Prisoner!
    @IBOutlet weak var modelText: UITextView!
    @IBOutlet weak var traceText: UITextView!

    
    @IBAction func run() {
        if !model!.running {
        model.clearTrace()
        model.run()
        }
    }
    
    
    @IBAction func reset() {
        model.modelText = self.modelText.text
      model.reset()
    }
    
    
    @IBAction func loadSimple() {

        model.loadModel(fileName: "prisoner")
        self.modelText.text = model.modelText
        model.loadedModel = "prisoner"
        
    }
    
    @IBAction func loadComplex() {

        model.loadModel(fileName: "prisoner2")
        self.modelText.text = model.modelText
        model.loadedModel = "prisoner"
        model.reset()
    }
    
    @IBAction func loadSubitize(_ sender: UIButton) {
        model.loadModel(fileName: "subitize")
        self.modelText.text = model.modelText
        model.loadedModel = "subitize"
        model.reset()
    }
    
    @IBAction func loadCount() {
        model.loadModel(fileName: "count")
        self.modelText.text = model.modelText
        model.loadedModel = "count"
        model.reset()
    }
    
    @IBAction func loadTime(_ sender: UIButton) {
        model.loadModel(fileName: "time")
        self.modelText.text = model.modelText
        model.loadedModel = "time"
        model.reset()
    }
    
    @objc func updateTrace() {
        traceText.text! = model.trace
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(ModelViewController.updateTrace), name: NSNotification.Name(rawValue: "TraceChanged"), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(ModelViewController.keyboardShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(ModelViewController.keyboardHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        updateTrace()
        modelText.text = model.modelText
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override var shouldAutorotate : Bool {
        return !self.keyboardShowing
    }
    
    @objc func keyboardShow(_ n:Notification) {
        self.keyboardShowing = true
        
        let d = n.userInfo!
        var r = (d[UIResponder.keyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        r = self.modelText.convert(r, from:nil)
        self.modelText.contentInset.bottom = r.size.height
        self.modelText.scrollIndicatorInsets.bottom = r.size.height
    }
    
    @objc func keyboardHide(_ n:Notification) {
        self.keyboardShowing = false
        self.modelText.contentInset = UIEdgeInsets.zero
        self.modelText.scrollIndicatorInsets = UIEdgeInsets.zero
    }
    
    func doDone(_ sender:AnyObject) {
        self.view.endEditing(false)
    }


}


