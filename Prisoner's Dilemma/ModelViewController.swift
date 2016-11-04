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

        model.loadModel("prisoner")
        self.modelText.text = model.modelText
        
    }
    
    @IBAction func loadComplex() {

        model.loadModel("prisoner2")
        self.modelText.text = model.modelText

    }
    
    
    @IBAction func loadCount() {
        model.loadModel("count")
        self.modelText.text = model.modelText
    }
    
    
    func updateTrace() {
        traceText.text! = model.trace
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(ModelViewController.updateTrace), name: NSNotification.Name(rawValue: "TraceChanged"), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(ModelViewController.keyboardShow(_:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(ModelViewController.keyboardHide(_:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
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
    
    func keyboardShow(_ n:Notification) {
        self.keyboardShowing = true
        
        let d = n.userInfo!
        var r = (d[UIKeyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        r = self.modelText.convert(r, from:nil)
        self.modelText.contentInset.bottom = r.size.height
        self.modelText.scrollIndicatorInsets.bottom = r.size.height
    }
    
    func keyboardHide(_ n:Notification) {
        self.keyboardShowing = false
        self.modelText.contentInset = UIEdgeInsets.zero
        self.modelText.scrollIndicatorInsets = UIEdgeInsets.zero
    }
    
    func doDone(_ sender:AnyObject) {
        self.view.endEditing(false)
    }


}


