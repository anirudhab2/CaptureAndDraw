//
//  CameraPreviewView.swift
//  CaptureAndDraw
//
//  Created by Anirudha Tolambia on 10/12/16.
//  Copyright © 2016 Anirudha Tolambia. All rights reserved.
//

import UIKit
import AVFoundation

class CameraPreviewView: UIView {

    var session: AVCaptureSession {
        get {
            return (self.layer as! AVCaptureVideoPreviewLayer).session
        }
        set {
            (self.layer as! AVCaptureVideoPreviewLayer).session = newValue
        }
    }
    
    override class var layerClass : AnyClass {
        return AVCaptureVideoPreviewLayer.self
    }

}
