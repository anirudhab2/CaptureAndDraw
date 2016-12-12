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
    optional func canvas(canvas: Canvas, didUpdateDrawing drawing: Drawing, mergedImage image: UIImage?)
    optional func canvas(canvas: Canvas, didSaveDrawing drawing: Drawing, mergedImage image: UIImage?)
    optional func canvas(canvas: Canvas, willStartDrawing drawing: Drawing)
    
    //    func brush() -> Brush?
}

// MARK: - Main Class
class Canvas: UIView {

    weak var delegate: CanvasDelegate?
    
    // Subviews
    private var backgroundImageView = UIImageView()
    private var mainDrawingImageView = UIImageView()
    private var tempDrawingImageView = UIImageView()
    
    // Tools
    var brush = Brush()
    private var drawing = Drawing()
    private let drawingSession = DrawingSession()
    private let path = UIBezierPath()
    
    // Variables
    private var touchPointMoved = false
    private var touchPointIndex = -1
    private var touchpoints = [CGPoint](count: 5, repeatedValue: CGPointZero)
    
    private var saved = false
    private let scale = UIScreen.mainScreen().scale
    
    
    // MARK: Initialization
    init(backgroundImage image: UIImage? = nil) {
        super.init(frame: CGRectZero)
        
        path.lineCapStyle = .Round
        
        backgroundImageView.image = image
        
        if (image != nil) {
            drawingSession.appendBackground(Drawing(stroke: nil, background: image))
        }
        
        addSubviews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    private func addSubviews() {
        backgroundColor = UIColor.whiteColor()
        
        self.addSubview(backgroundImageView)
        backgroundImageView.contentMode = .ScaleAspectFit
        backgroundImageView.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
        
        self.addSubview(mainDrawingImageView)
        mainDrawingImageView.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
        
        self.addSubview(tempDrawingImageView)
        tempDrawingImageView.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
    }
}

// MARK: - Touch Controls
extension Canvas {
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        saved = false
        touchPointMoved = false
        touchPointIndex = 0
        
        //        brush = (delegate?.brush())!
        
        
        let touch: UITouch = touches.first!
        touchpoints[0] = touch.locationInView(self)
        
        willStartDrawing()
    }
    
    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
        
        touchPointMoved = true
        
        let touch = touches.first!
        let touchPoint = touch.locationInView(self)
        
        touchPointIndex += 1
        touchpoints[touchPointIndex] = touchPoint
        
        if (touchPointIndex == 4) {
            
            touchpoints[3] = CGPoint(x: (touchpoints[2].x + touchpoints[4].x)/2, y: (touchpoints[2].y + touchpoints[4].y)/2)
            
            path.moveToPoint(touchpoints[0])
            path.addCurveToPoint(touchpoints[3], controlPoint1: touchpoints[1], controlPoint2: touchpoints[2])
            
            touchpoints[0] = touchpoints[3]
            touchpoints[1] = touchpoints[4]
            touchPointIndex = 1
        }
        
        drawStroke()
    }
    
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        
        if (touchPointMoved == false) {
            path.moveToPoint(touchpoints[0])
            path.addLineToPoint(touchpoints[0])
            drawStroke()
        }
        
        mergeStrokes()
        didUpdateCanvas()
        
        path.removeAllPoints()
        touchPointIndex = 0
    }
    
    override func touchesCancelled(touches: Set<UITouch>?, withEvent event: UIEvent?) {
        self.touchesEnded(touches!, withEvent: event)
    }
}

// MARK: - Drawing
extension Canvas {
    private func drawStroke() {
        // Renders the drawn stroke to tempDrawingImageView temporarily
        
        UIGraphicsBeginImageContextWithOptions(self.frame.size, false, 0.0)
        
        path.lineWidth = (brush.width/scale)
        
        brush.color.setStroke()
        
        if (brush.isEraser) {
            mainDrawingImageView.image?.drawInRect(self.bounds)
        }
        
        
        path.strokeWithBlendMode(brush.blendMode, alpha: 1)
        
        let targetImageView = brush.isEraser ? mainDrawingImageView : tempDrawingImageView
        targetImageView.image = UIGraphicsGetImageFromCurrentImageContext()
        
        UIGraphicsEndImageContext()
    }
    
    private func mergeStrokes() {
        // Add the temporary stroke to main Drawing
        
        UIGraphicsBeginImageContextWithOptions(self.frame.size, false, 0.0)
        
        mainDrawingImageView.image?.drawInRect(self.bounds)
        tempDrawingImageView.image?.drawInRect(self.bounds)
        
        mainDrawingImageView.image = UIGraphicsGetImageFromCurrentImageContext()
        drawingSession.append(currentDrawing())
        tempDrawingImageView.image = nil
        
        UIGraphicsEndImageContext()
    }
    
    private func mergeStrokesAndImages() -> UIImage {
        // Merge strokes, existing and background images
        
        UIGraphicsBeginImageContextWithOptions(self.frame.size, false, 0.0)
        
        if (backgroundImageView.image != nil) {
            let rect = centeredRectForImage(backgroundImageView.image!)
            backgroundImageView.image?.drawInRect(rect)
        }
        
        mainDrawingImageView.image?.drawInRect(self.bounds)
        
        let mergedImage = UIGraphicsGetImageFromCurrentImageContext()
        
        UIGraphicsEndImageContext()
        
        return mergedImage
    }
}

// MARK: - Drawing Session Management
extension Canvas {
    private func currentDrawing() -> Drawing {
        return Drawing(stroke: mainDrawingImageView.image, background: backgroundImageView.image)
    }
    
    private func updateByLastSession() {
        let lastSession = drawingSession.lastSession()
        mainDrawingImageView.image = lastSession?.stroke
        backgroundImageView.image = lastSession?.background
    }
    
    private func willStartDrawing() {
        delegate?.canvas?(self, willStartDrawing: currentDrawing())
    }
    
    private func didUpdateCanvas() {
        delegate?.canvas?(self, didUpdateDrawing: currentDrawing(), mergedImage: mergeStrokesAndImages())
    }
    
    private func didSaveCanvas() {
        delegate?.canvas?(self, didSaveDrawing: drawing, mergedImage: mergeStrokesAndImages())
    }
    
    private func isStrokeEqual() -> Bool {
        return compare(drawing.stroke, isEqualTo: mainDrawingImageView.image)
    }
    
    private func isBackgroundEqual() -> Bool {
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
    
    
    func update(backgroundImage: UIImage?) {
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
    private func centeredRectForImage(image: UIImage) -> CGRect {
        
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
    
    private func compare(image1: UIImage?, isEqualTo image2: UIImage?) -> Bool {
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

