//
//  RoundColorButton.swift
//  CaptureAndDraw
//
//  Created by Anirudha Tolambia on 11/12/16.
//  Copyright © 2016 Anirudha Tolambia. All rights reserved.
//

import UIKit

// Round color button to show in Color Palette
class RoundColorButton: UIButton {

    var diameter: CGFloat? {
        didSet {
            self.frame = CGRect(x: center.x-diameter!/2, y: center.y-diameter!/2, width: diameter!, height: diameter!)
            self.layer.cornerRadius = self.bounds.width/2
        }
    }
    
    var color: UIColor? {
        didSet {
            self.backgroundColor = color
        }
    }
    
    var borderColor: UIColor = UIColor.white {
        didSet {
            self.layer.borderColor = borderColor.cgColor
        }
    }
    
    var borderWidth: CGFloat = 3.0 {
        didSet {
            if (borderWidth > self.diameter!/2) {
                borderWidth = 3.0
            }
            self.layer.borderWidth = borderWidth
        }
    }
    
    init(center: CGPoint, diameter: CGFloat, color: UIColor) {
        super.init(frame: CGRect(x: center.x-diameter/2, y: center.y-diameter/2, width: diameter, height: diameter))
        
        self.diameter = diameter
        self.color = color
        self.backgroundColor = color
        
        self.layer.cornerRadius = self.bounds.width/2
        self.layer.borderColor = borderColor.cgColor
        self.layer.borderWidth = borderWidth
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

}
