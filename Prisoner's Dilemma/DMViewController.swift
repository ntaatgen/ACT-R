//
//  DMViewController.swift
//  act-r
//
//  Created by Niels Taatgen on 4/5/15.
//  Copyright (c) 2015 Niels Taatgen. All rights reserved.
//

import UIKit

class DMViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate   {

    var model: Prisoner?
    var chunkList: [(String,String,Double)] = []
    
    @IBOutlet weak var chunkTable: UITableView!

    @IBOutlet weak var text: UILabel!
    
    func compare (_ x: (String, String, Double), y: (String, String, Double)) -> Bool {
        let (_,s1,a1) = x
        let (_,s2,a2) = y
        if s2 != s1 { return s2 > s1 }
        else { return a1 > a2 }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.chunkTable.register(UITableViewCell.self, forCellReuseIdentifier: "groupcell")
        chunkTable.delegate = self
        chunkTable.dataSource = self
        if model != nil {
            for (_,chunk) in model!.dm.chunks {
                let chunkTp = chunk.slotvals["isa"]
                let chunkType = chunkTp == nil ? "No Type" : chunkTp!.description
                chunkList.append((chunk.name,chunkType,chunk.activation()))
            }
        }
        chunkList = chunkList.sorted(by: compare)
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Potentially incomplete method implementation.
        // Return the number of sections.
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete method implementation.
        // Return the number of rows in the section.
        return chunkList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell{
        let cell : UITableViewCell = tableView.dequeueReusableCell(withIdentifier: "chunk", for: indexPath) 
        let (label,type,act) = chunkList[indexPath.row]
        let activation = String(format:"%.2f", act)
        cell.textLabel?.text = label //  self.groupList[indexPath.row]
        cell.detailTextLabel?.text = "  isa " + type + "  A = " + activation
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let (chunkName,_,_) = chunkList[indexPath.row]
        let chunk = model!.dm.chunks[chunkName]
        if chunk != nil {
            text.text = chunk!.description
            if chunk!.creationTime != nil {
                let timeString = String(format:"%.3f", chunk!.creationTime!)
                text.text! += "Creation time = \(timeString)\n"
            if model!.dm.optimizedLearning {
                text.text! += "References = \(chunk!.references)\n"
            } else {
                text.text! += "References times: "
                for time in chunk!.referenceList {
                    let timeString = String(format:" %.3f", time)
                    text.text! += timeString
                }
                }
            }
        }
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
