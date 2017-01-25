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
    
    fileprivate var canvas: Canvas!
    fileprivate var toolbar: DrawingToolbar!
    fileprivate var palette: ColorPalette!
    fileprivate var brushControl: BrushControl!

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
        
        brushControl.isHidden = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        updateToolbar()
    }
    
    override var prefersStatusBarHidden : Bool {
        return true
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    fileprivate func updateToolbar() {
        toolbar.brushButton.backgroundColor = canvas.brush.color
        brushControl.brushWidth = canvas.brush.width
        brushControl.brushColor = canvas.brush.color
    }
}

// MARK: - Canvas Delegate
extension DrawingViewController: CanvasDelegate {
    func canvas(_ canvas: Canvas, willStartDrawing drawing: Drawing) {
        UIView.animate(withDuration: 0.2, animations: {
            self.toolbar.alpha = 0.0
            self.palette.alpha = 0.0
            self.brushControl.alpha = 0
        }) 
    }
    
    func canvas(_ canvas: Canvas, didUpdateDrawing drawing: Drawing, mergedImage image: UIImage?) {
       
        updateToolbar()
        
        UIView.animate(withDuration: 0.2, animations: {
            self.toolbar.alpha = 1.0
            self.palette.alpha = 1.0
            self.brushControl.alpha = 1.0
        }) 
    }
    
    func canvas(_ canvas: Canvas, didSaveDrawing drawing: Drawing, mergedImage image: UIImage?) {
        if let validImage = image {
            if let imagePreviewVC = self.presentingViewController as? ImagePreviewViewController {
                imagePreviewVC.imageToPreview = validImage
                self.dismiss(animated: false, completion: nil)
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
        brushControl.isHidden = !brushControl.isHidden
    }
    
    func eraserTapped() {
        canvas.brush.color = UIColor.clear
        brushControl.isHidden = true
    }
    
    func toolbar(_ toolbar: DrawingToolbar, didChangedBrushWidth width: CGFloat) {
        canvas.brush.width = width
    }
}

// MARK: - Color Palette Delegate
extension DrawingViewController: ColorPaletteDelegate {
    func colorPalette(_ colorPalette: ColorPalette, didChooseColor color: UIColor) {
        canvas.brush.color = color
        toolbar.brushButton.backgroundColor = color
        brushControl.brushColor = color
    }
}

// MARK: - Brush Size Control Delegate
extension DrawingViewController: BrushControlDelegate {
    func brushControl(_ brushControl: BrushControl, didChangeBrushWidth width: CGFloat) {
        canvas.brush.width = width
    }
}


