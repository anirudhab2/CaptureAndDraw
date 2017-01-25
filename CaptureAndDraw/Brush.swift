//
//  Brush.swift
//  CaptureAndDraw
//
//  Created by Anirudha Tolambia on 11/12/16.
//  Copyright © 2016 Anirudha Tolambia. All rights reserved.
//

import UIKit

// Our Main Drawing Tool
class Brush: NSObject {
    
    var color: UIColor = UIColor.black {
        willSet(newValue) {
            isEraser = (newValue == UIColor.clear)
            blendMode = isEraser ? CGBlendMode.clear : CGBlendMode.normal
        }
    }
    
    var width: CGFloat = 20.0
    var isEraser: Bool = false
    var blendMode: CGBlendMode = CGBlendMode.normal
}
