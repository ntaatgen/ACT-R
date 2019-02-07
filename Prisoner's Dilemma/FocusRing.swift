//
//  FocusRing.swift
//  Prisoner's Dilemma
//
//  Created by Niels Taatgen on 15/3/18.
//  Copyright © 2018 Niels Taatgen. All rights reserved.
//

import UIKit

class FocusRing: UIView {

    
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        let ovalRect = CGRect(x: 3, y: 3, width: self.bounds.width - 6, height: self.bounds.height - 6)
        let curve = UIBezierPath(ovalIn: ovalRect)
        #colorLiteral(red: 0.7450980544, green: 0.1568627506, blue: 0.07450980693, alpha: 1).setStroke()
        backgroundColor = nil
     
        curve.lineWidth = 5
        curve.stroke()
        // Drawing code
    }
    

}
