//
//  DrawingViewController.swift
//  CaptureAndDraw
//
//  Created by Anirudha Tolambia on 11/12/16.
//  Copyright © 2016 Anirudha Tolambia. All rights reserved.
//

import UIKit

class DrawingViewController: UIViewController {
    
    var imageToEdit: UIImage?
    
    private var canvas: Canvas!
    private var toolbar: DrawingToolbar!
    private var palette: ColorPalette!
    private var brushControl: BrushControl!

    override func viewDidLoad() {
        super.viewDidLoad()

        canvas = Canvas(backgroundImage: imageToEdit)
        canvas.frame = view.bounds
        canvas.delegate = self
        view.addSubview(canvas)
        
        toolbar = DrawingToolbar(frame: CGRect(x: 0, y: 0, width: view.bounds.width, height: 40))
        toolbar.delegate = self
        view.addSubview(toolbar)
        
        palette = ColorPalette(frame: CGRect(x: 0, y: view.bounds.height-30, width: view.bounds.width, height: 30))
        palette.delegate = self
        view.addSubview(palette)
        
        brushControl = BrushControl(frame: CGRect(x: 0, y: 40, width: view.bounds.width, height: 30))
        brushControl.delegate = self
        view.addSubview(brushControl)
        
        brushControl.hidden = true
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        updateToolbar()
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    private func updateToolbar() {
        toolbar.brushButton.backgroundColor = canvas.brush.color
        brushControl.brushWidth = canvas.brush.width
        brushControl.brushColor = canvas.brush.color
    }
}

// MARK: - Canvas Delegate
extension DrawingViewController: CanvasDelegate {
    func canvas(canvas: Canvas, willStartDrawing drawing: Drawing) {
        UIView.animateWithDuration(0.2) {
            self.toolbar.alpha = 0.0
            self.palette.alpha = 0.0
            self.brushControl.alpha = 0
        }
    }
    
    func canvas(canvas: Canvas, didUpdateDrawing drawing: Drawing, mergedImage image: UIImage?) {
       
        updateToolbar()
        
        UIView.animateWithDuration(0.2) {
            self.toolbar.alpha = 1.0
            self.palette.alpha = 1.0
            self.brushControl.alpha = 1.0
        }
    }
    
    func canvas(canvas: Canvas, didSaveDrawing drawing: Drawing, mergedImage image: UIImage?) {
        if let validImage = image {
            if let imagePreviewVC = self.presentingViewController as? ImagePreviewViewController {
                imagePreviewVC.imageToPreview = validImage
                self.dismissViewControllerAnimated(false, completion: nil)
            }
        }
    }
}

// MARK: - Drawing Toolbar Delegate
extension DrawingViewController: DrawingToolbarDelegate {
    func undoTapped() {
        canvas.undo()
    }
    
    func redoTapped() {
        canvas.redo()
    }
    
    func resetTapped() {
        canvas.clear()
    }
    
    func saveTapped() {
        canvas.save()
    }
    
    func brushTapped() {
        canvas.brush.color = palette.selectedColor
        brushControl.hidden = !brushControl.hidden
    }
    
    func eraserTapped() {
        canvas.brush.color = UIColor.clearColor()
        brushControl.hidden = true
    }
    
    func toolbar(toolbar: DrawingToolbar, didChangedBrushWidth width: CGFloat) {
        canvas.brush.width = width
    }
}

// MARK: - Color Palette Delegate
extension DrawingViewController: ColorPaletteDelegate {
    func colorPalette(colorPalette: ColorPalette, didChooseColor color: UIColor) {
        canvas.brush.color = color
        toolbar.brushButton.backgroundColor = color
        brushControl.brushColor = color
    }
}

// MARK: - Brush Size Control Delegate
extension DrawingViewController: BrushControlDelegate {
    func brushControl(brushControl: BrushControl, didChangeBrushWidth width: CGFloat) {
        canvas.brush.width = width
    }
}


