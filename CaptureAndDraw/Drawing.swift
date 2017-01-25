//
//  Drawing.swift
//  CaptureAndDraw
//
//  Created by Anirudha Tolambia on 11/12/16.
//  Copyright © 2016 Anirudha Tolambia. All rights reserved.
//

import UIKit

// A Drawing consists of two images, stroke and background
// They will be merged to generate a final image
class Drawing: NSObject {
    
    var stroke: UIImage?
    var background: UIImage?
    
    init(stroke: UIImage? = nil, background: UIImage? = nil) {
        self.stroke = stroke
        self.background = background
    }
}
