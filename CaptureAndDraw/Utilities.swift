//
//  Utilities.swift
//  CaptureAndDraw
//
//  Created by Anirudha Tolambia on 11/12/16.
//  Copyright © 2016 Anirudha Tolambia. All rights reserved.
//

import UIKit

// Extension of UIImage so that asset names will be in form of enum, to avoid typos
extension UIImage {
    enum AssetIdentifier: String {
        case Brush, Cancel, Eraser, Pencil, Redo, Save, Share, Toggle, Undo
    }
    
    convenience init!(assetIdentifier: AssetIdentifier) {
        self.init(named: assetIdentifier.rawValue)
    }
}