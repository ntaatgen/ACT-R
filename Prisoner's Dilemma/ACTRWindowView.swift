//
//  ACTRWindowView.swift
//  Prisoner's Dilemma
//
//  Created by Niels Taatgen on 13/3/18.
//  Copyright © 2018 Niels Taatgen. All rights reserved.
//

import UIKit


class ACTRWindowView: UIView {
    
    var vr: FocusRing? = nil
    
    func getVisicon() -> [VisualObject] {
        return getVisiconR(view: self)
    }
    
    func createVisualObject(view: UIView, s: [String:String]) -> VisualObject {
        let obj = VisualObject(name: "", visualType: s["type"]!, x: 0, y: 0, w: Double(view.frame.width), h: Double(view.frame.height), d: 0)
        for (att, val) in s {
            switch att {
            case "type": break
            case "color": obj.color = val
            default: obj.attributes[att] = val
            }
        }
        return obj
    }
    
    func getVisiconR(view: UIView) -> [VisualObject] {
        var result: [VisualObject] = []
        for subView in view.subviews {
            let objs = getVisiconR(view: subView)
            for obj in objs {
                obj.x += Double(subView.frame.origin.x)
                obj.y += Double(subView.frame.origin.y)
            }
            result += objs
        }
        let ownObject = view.visiconValue()
        if ownObject != [:] {
            result.append(createVisualObject(view: view, s: ownObject))
        }
        return result
    }
    
    func displayFocusRing(vo: VisualObject) {
        if vr == nil {
            vr = FocusRing(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
            vr?.isOpaque = false
            self.addSubview(vr!)
        }
        if !self.subviews.contains(vr!) {
            self.addSubview(vr!)
        }
        vr!.frame = CGRect(x: CGFloat(vo.x) - 15, y: CGFloat(vo.y) - 15, width: 30, height: 30)
        self.setNeedsLayout()
    }
    
}

extension UIView {
    @objc func visiconValue() -> [String:String] {
        return [:]
    }
}

extension UILabel {
    override func visiconValue() -> [String:String] {
        if self.text != nil && self.text != "" {
            return ["type" : "text", "text" : self.text!]
        } else { return [:] }
    }
}

extension UIButton {
    override func visiconValue() -> [String:String] {
        if self.currentTitle != nil {
            return ["type" : "button", "text" : self.currentTitle!]
        } else {
            return ["type" : "button", "text" : "notitle"]
        }
    }
}
