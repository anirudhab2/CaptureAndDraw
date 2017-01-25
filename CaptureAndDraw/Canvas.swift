//
//  Canvas.swift
//  CaptureAndDraw
//
//  Created by Anirudha Tolambia on 11/12/16.
//  Copyright © 2016 Anirudha Tolambia. All rights reserved.
//

import UIKit

// MARK: - Canvas Delegate
@objc
protocol CanvasDelegate {
    @objc optional func canvas(_ canvas: Canvas, didUpdateDrawing drawing: Drawing, mergedImage image: UIImage?)
    @objc optional func canvas(_ canvas: Canvas, didSaveDrawing drawing: Drawing, mergedImage image: UIImage?)
    @objc optional func canvas(_ canvas: Canvas, willStartDrawing drawing: Drawing)
    
    //    func brush() -> Brush?
}

// MARK: - Main Class
class Canvas: UIView {

    weak var delegate: CanvasDelegate?
    
    // Subviews
    fileprivate var backgroundImageView = UIImageView()
    fileprivate var mainDrawingImageView = UIImageView()
    fileprivate var tempDrawingImageView = UIImageView()
    
    // Tools
    var brush = Brush()
    fileprivate var drawing = Drawing()
    fileprivate let drawingSession = DrawingSession()
    fileprivate let path = UIBezierPath()
    
    // Variables
    fileprivate var touchPointMoved = false
    fileprivate var touchPointIndex = -1
    fileprivate var touchpoints = [CGPoint](repeating: CGPoint.zero, count: 5)
    
    fileprivate var saved = false
    fileprivate let scale = UIScreen.main.scale
    
    
    // MARK: Initialization
    init(backgroundImage image: UIImage? = nil) {
        super.init(frame: CGRect.zero)
        
        path.lineCapStyle = .round
        
        backgroundImageView.image = image
        
        if (image != nil) {
            drawingSession.appendBackground(Drawing(stroke: nil, background: image))
        }
        
        addSubviews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    fileprivate func addSubviews() {
        backgroundColor = UIColor.white
        
        self.addSubview(backgroundImageView)
        backgroundImageView.contentMode = .scaleAspectFit
        backgroundImageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        self.addSubview(mainDrawingImageView)
        mainDrawingImageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        self.addSubview(tempDrawingImageView)
        tempDrawingImageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    }
}

// MARK: - Touch Controls
extension Canvas {
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        saved = false
        touchPointMoved = false
        touchPointIndex = 0
        
        //        brush = (delegate?.brush())!
        
        
        let touch: UITouch = touches.first!
        touchpoints[0] = touch.location(in: self)
        
        willStartDrawing()
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        touchPointMoved = true
        
        let touch = touches.first!
        let touchPoint = touch.location(in: self)
        
        touchPointIndex += 1
        touchpoints[touchPointIndex] = touchPoint
        
        if (touchPointIndex == 4) {
            
            touchpoints[3] = CGPoint(x: (touchpoints[2].x + touchpoints[4].x)/2, y: (touchpoints[2].y + touchpoints[4].y)/2)
            
            path.move(to: touchpoints[0])
            path.addCurve(to: touchpoints[3], controlPoint1: touchpoints[1], controlPoint2: touchpoints[2])
            
            touchpoints[0] = touchpoints[3]
            touchpoints[1] = touchpoints[4]
            touchPointIndex = 1
        }
        
        drawStroke()
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        if (touchPointMoved == false) {
            path.move(to: touchpoints[0])
            path.addLine(to: touchpoints[0])
            drawStroke()
        }
        
        mergeStrokes()
        didUpdateCanvas()
        
        path.removeAllPoints()
        touchPointIndex = 0
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.touchesEnded(touches, with: event)
    }
}

// MARK: - Drawing
extension Canvas {
    fileprivate func drawStroke() {
        // Renders the drawn stroke to tempDrawingImageView temporarily
        
        UIGraphicsBeginImageContextWithOptions(self.frame.size, false, 0.0)
        
        path.lineWidth = (brush.width/scale)
        
        brush.color.setStroke()
        
        if (brush.isEraser) {
            mainDrawingImageView.image?.draw(in: self.bounds)
        }
        
        
        path.stroke(with: brush.blendMode, alpha: 1)
        
        let targetImageView = brush.isEraser ? mainDrawingImageView : tempDrawingImageView
        targetImageView.image = UIGraphicsGetImageFromCurrentImageContext()
        
        UIGraphicsEndImageContext()
    }
    
    fileprivate func mergeStrokes() {
        // Add the temporary stroke to main Drawing
        
        UIGraphicsBeginImageContextWithOptions(self.frame.size, false, 0.0)
        
        mainDrawingImageView.image?.draw(in: self.bounds)
        tempDrawingImageView.image?.draw(in: self.bounds)
        
        mainDrawingImageView.image = UIGraphicsGetImageFromCurrentImageContext()
        drawingSession.append(currentDrawing())
        tempDrawingImageView.image = nil
        
        UIGraphicsEndImageContext()
    }
    
    fileprivate func mergeStrokesAndImages() -> UIImage {
        // Merge strokes, existing and background images
        
        UIGraphicsBeginImageContextWithOptions(self.frame.size, false, 0.0)
        
        if (backgroundImageView.image != nil) {
            let rect = centeredRectForImage(backgroundImageView.image!)
            backgroundImageView.image?.draw(in: rect)
        }
        
        mainDrawingImageView.image?.draw(in: self.bounds)
        
        let mergedImage = UIGraphicsGetImageFromCurrentImageContext()
        
        UIGraphicsEndImageContext()
        
        return mergedImage!
    }
}

// MARK: - Drawing Session Management
extension Canvas {
    fileprivate func currentDrawing() -> Drawing {
        return Drawing(stroke: mainDrawingImageView.image, background: backgroundImageView.image)
    }
    
    fileprivate func updateByLastSession() {
        let lastSession = drawingSession.lastSession()
        mainDrawingImageView.image = lastSession?.stroke
        backgroundImageView.image = lastSession?.background
    }
    
    fileprivate func willStartDrawing() {
        delegate?.canvas?(self, willStartDrawing: currentDrawing())
    }
    
    fileprivate func didUpdateCanvas() {
        delegate?.canvas?(self, didUpdateDrawing: currentDrawing(), mergedImage: mergeStrokesAndImages())
    }
    
    fileprivate func didSaveCanvas() {
        delegate?.canvas?(self, didSaveDrawing: drawing, mergedImage: mergeStrokesAndImages())
    }
    
    fileprivate func isStrokeEqual() -> Bool {
        return compare(drawing.stroke, isEqualTo: mainDrawingImageView.image)
    }
    
    fileprivate func isBackgroundEqual() -> Bool {
        return compare(drawing.background, isEqualTo: backgroundImageView.image)
    }
    
    // MARK: Public Methods
    
    func canUndo() -> Bool {
        return drawingSession.canUndo()
    }
    
    func canRedo() -> Bool {
        return drawingSession.canRedo()
    }
    
    func canClear() -> Bool {
        return drawingSession.canReset()
    }
    
    func canSave() -> Bool {
        return !(isStrokeEqual() && isBackgroundEqual())
    }
    
    
    func update(_ backgroundImage: UIImage?) {
        backgroundImageView.image = backgroundImage
        drawingSession.append(currentDrawing())
        saved = canSave()
        didUpdateCanvas()
    }
    
    func undo() {
        drawingSession.undo()
        updateByLastSession()
        saved = canSave()
        didUpdateCanvas()
    }
    
    func redo() {
        drawingSession.redo()
        updateByLastSession()
        saved = canSave()
        didUpdateCanvas()
    }
    
    func clear() {
        drawingSession.reset()
        updateByLastSession()
        saved = true
        didUpdateCanvas()
    }
    
    func save() {
        drawing.stroke = mainDrawingImageView.image?.copy() as? UIImage
        drawing.background = backgroundImageView.image
        saved = true
        didSaveCanvas()
    }
}

// MARK: - Utilities
extension Canvas {
    fileprivate func centeredRectForImage(_ image: UIImage) -> CGRect {
        
        if (self.frame.size == image.size) {
            return self.frame
        }
        
        let selfWidth = self.frame.width
        let selfHeight = self.frame.height
        
        let widthRatio = selfWidth/image.size.width
        let heightRatio = selfHeight/image.size.height
        
        let imageScale = min(widthRatio, heightRatio)
        
        let scaledWidth = imageScale*image.size.width
        let scaledHeight = imageScale*image.size.height
        
        var rect = CGRect(x: 0, y: 0, width: scaledWidth, height: scaledHeight)
        
        if (selfWidth > scaledWidth) {
            rect.origin.x = (selfWidth - scaledWidth)/2
        }
        
        if (selfHeight > scaledHeight) {
            rect.origin.y = (selfHeight - scaledHeight)/2
        }
        
        return rect
    }
    
    fileprivate func compare(_ image1: UIImage?, isEqualTo image2: UIImage?) -> Bool {
        if (image1 == nil && image2 == nil) {
            return true
        } else if (image1 == nil || image2 == nil) {
            return false
        }
        
        let data1 = UIImagePNGRepresentation(image1!)
        let data2 = UIImagePNGRepresentation(image2!)
        
        if (data1 == nil || data2 == nil) {
            return false
        }
        
        return (data1 == data2)
    }
}

