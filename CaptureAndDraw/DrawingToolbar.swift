//
//  DrawingToolbar.swift
//  CaptureAndDraw
//
//  Created by Anirudha Tolambia on 11/12/16.
//  Copyright © 2016 Anirudha Tolambia. All rights reserved.
//

import UIKit

@objc
protocol DrawingToolbarDelegate {
    func undoTapped()
    func redoTapped()
    func resetTapped()
    func saveTapped()
    func brushTapped()
    func eraserTapped()
}

class DrawingToolbar: UIView {
    
    weak var delegate: DrawingToolbarDelegate?

    var undoButton: UIButton!
    var redoButton: UIButton!
    var resetButton: UIButton!
    var saveButton: UIButton!
    var brushButton: UIButton!
    var eraserButton: UIButton!
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initialize()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initialize()
    }
    
    fileprivate func initialize() {
        let buttonWidth = self.bounds.height
        let padding = (6*buttonWidth < self.bounds.width) ? (self.bounds.width - 6*buttonWidth)/7 : 0
        
        undoButton = UIButton()
        undoButton.frame = CGRect(x: padding, y: 0, width: buttonWidth, height: buttonWidth)
        undoButton.imageEdgeInsets = UIEdgeInsetsMake(5, 5, 5, 5)
        undoButton.setImage(UIImage(assetIdentifier: .Undo), for: UIControlState())
        undoButton.addTarget(self, action: #selector(self.undoTapped), for: .touchUpInside)
        self.addSubview(undoButton)
        
        redoButton = UIButton()
        redoButton.frame = CGRect(x: 2*padding+buttonWidth, y: 0, width: buttonWidth, height: buttonWidth)
        redoButton.imageEdgeInsets = UIEdgeInsetsMake(5, 5, 5, 5)
        redoButton.setImage(UIImage(assetIdentifier: .Redo), for: UIControlState())
        redoButton.addTarget(self, action: #selector(self.redoTapped), for: .touchUpInside)
        self.addSubview(redoButton)
        
        resetButton = UIButton()
        resetButton.frame = CGRect(x: 3*padding+2*buttonWidth, y: 0, width: buttonWidth, height: buttonWidth)
        resetButton.imageEdgeInsets = UIEdgeInsetsMake(10, 10, 10, 10)
        resetButton.setImage(UIImage(assetIdentifier: .Toggle), for: UIControlState())
        resetButton.addTarget(self, action: #selector(self.resetTapped), for: .touchUpInside)
        self.addSubview(resetButton)
        
        saveButton = UIButton()
        saveButton.frame = CGRect(x: 4*padding+3*buttonWidth, y: 0, width: buttonWidth, height: buttonWidth)
        saveButton.imageEdgeInsets = UIEdgeInsetsMake(10, 10, 10, 10)
        saveButton.setImage(UIImage(assetIdentifier: .Save), for: UIControlState())
        saveButton.addTarget(self, action: #selector(self.saveTapped), for: .touchUpInside)
        self.addSubview(saveButton)
        
        brushButton = UIButton()
        brushButton.frame = CGRect(x: 5*padding+4*buttonWidth + 5, y: 5, width: buttonWidth-10, height: buttonWidth-10)
        brushButton.imageEdgeInsets = UIEdgeInsetsMake(5, 5, 5, 5)
        brushButton.layer.cornerRadius = brushButton.bounds.width/2
        brushButton.setImage(UIImage(assetIdentifier: .Brush), for: UIControlState())
        brushButton.addTarget(self, action: #selector(self.brushTapped), for: .touchUpInside)
        self.addSubview(brushButton)
        
        eraserButton = UIButton()
        eraserButton.frame = CGRect(x: 6*padding+5*buttonWidth, y: 0, width: buttonWidth, height: buttonWidth)
        eraserButton.imageEdgeInsets = UIEdgeInsetsMake(5, 5, 5, 5)
        eraserButton.setImage(UIImage(assetIdentifier: .Eraser), for: UIControlState())
        eraserButton.addTarget(self, action: #selector(self.eraserTapped), for: .touchUpInside)
        self.addSubview(eraserButton)
    }
    
    func undoTapped() {
        delegate?.undoTapped()
    }
    
    func redoTapped() {
        delegate?.redoTapped()
    }
    
    func resetTapped() {
        delegate?.resetTapped()
    }
    
    func saveTapped() {
        delegate?.saveTapped()
    }
    
    func brushTapped() {
        delegate?.brushTapped()
    }
    
    func eraserTapped() {
        delegate?.eraserTapped()
    }
}
