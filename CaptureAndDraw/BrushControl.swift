//
//  BrushControl.swift
//  CaptureAndDraw
//
//  Created by Anirudha Tolambia on 12/12/16.
//  Copyright © 2016 Anirudha Tolambia. All rights reserved.
//

import UIKit

@objc
protocol BrushControlDelegate {
    func brushControl(_ brushControl: BrushControl, didChangeBrushWidth width: CGFloat)
}

class BrushControl: UIView {

    weak var delegate: BrushControlDelegate?
    
    fileprivate let scale = UIScreen.main.scale
    
    fileprivate var brushSizeSlider: UISlider!
    fileprivate var brushSizeIndicator: UIView!
    
    var brushColor: UIColor? {
        get {
            return brushSizeIndicator.backgroundColor
        }
        set {
            brushSizeIndicator.backgroundColor = newValue
        }
    }
    
    var brushWidth: CGFloat {
        get {
            return CGFloat(brushSizeSlider.value)
        }
        set {
            brushSizeSlider.setValue(Float(newValue), animated: false)
            
            let newWidth = newValue/scale
            brushSizeIndicator.frame.size = CGSize(width: newWidth, height: newWidth)
            brushSizeIndicator.center.y = brushSizeSlider.frame.midY
            brushSizeIndicator.layer.cornerRadius = brushSizeIndicator.bounds.width/2
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initialize()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initialize()
    }
    
    fileprivate func initialize() {
        brushSizeSlider = UISlider(frame: CGRect(x: self.bounds.width/2-75, y: 0, width: 150, height: self.bounds.height))
        brushSizeSlider.minimumValue = 5.0
        brushSizeSlider.maximumValue = 50.0
        brushSizeSlider.addTarget(self, action: #selector(self.brushSizeSliderValueChanged(_:)), for: .valueChanged)
        self.addSubview(brushSizeSlider)
        
        
        brushSizeIndicator = UIView(frame: CGRect(x: brushSizeSlider.frame.maxX+20, y: brushSizeSlider.frame.midY, width: brushWidth, height: brushWidth))
        brushSizeIndicator.backgroundColor = UIColor.black
        brushSizeIndicator.layer.cornerRadius = brushSizeIndicator.bounds.width/2
        self.addSubview(brushSizeIndicator)
    }
    
    func brushSizeSliderValueChanged(_ slider: UISlider) {
        let width = CGFloat(slider.value)
        brushWidth = width
        delegate?.brushControl(self, didChangeBrushWidth: width)
    }

}
