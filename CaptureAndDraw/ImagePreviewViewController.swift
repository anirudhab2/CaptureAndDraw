//
//  ImagePreviewViewController.swift
//  CaptureAndDraw
//
//  Created by Anirudha Tolambia on 10/12/16.
//  Copyright © 2016 Anirudha Tolambia. All rights reserved.
//

import UIKit
import Photos

class ImagePreviewViewController: UIViewController {

    var imageToPreview: UIImage!
    
    fileprivate var imageView: UIImageView!
    fileprivate var saveButton: UIButton!
    fileprivate var cancelButton: UIButton!
    fileprivate var drawButton: UIButton!
    fileprivate var shareButton: UIButton!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupSubviews()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let validImage = imageToPreview {
            imageView.image = validImage
        } else {
            saveButton.isEnabled = false
            shareButton.isEnabled = false
        }
    }
    
    override var prefersStatusBarHidden : Bool {
        return true
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    fileprivate func setupSubviews() {
        
        imageView = UIImageView(frame: view.bounds)
        view.addSubview(imageView)
        
        
        saveButton = UIButton(frame: CGRect(x: 10, y: 0, width: 40, height: 40))
        saveButton.imageEdgeInsets = UIEdgeInsetsMake(10, 10, 10, 10)
        saveButton.setImage(UIImage(assetIdentifier: .Save), for: UIControlState())
        saveButton.addTarget(self, action: #selector(self.saveTapped), for: .touchUpInside)
        view.addSubview(saveButton)
        
        
        cancelButton = UIButton(frame: CGRect(x: 60, y: 0, width: 40, height: 40))
        cancelButton.imageEdgeInsets = UIEdgeInsetsMake(10, 10, 10, 10)
        cancelButton.setImage(UIImage(assetIdentifier: .Cancel), for: UIControlState())
        cancelButton.addTarget(self, action: #selector(self.cancelTapped), for: .touchUpInside)
        view.addSubview(cancelButton)
        
        
        drawButton = UIButton(frame: CGRect(x: view.bounds.width-100, y: 0, width: 40, height: 40))
        drawButton.imageEdgeInsets = UIEdgeInsetsMake(10, 10, 10, 10)
        drawButton.setImage(UIImage(assetIdentifier: .Pencil), for: UIControlState())
        drawButton.addTarget(self, action: #selector(self.drawTapped), for: .touchUpInside)
        view.addSubview(drawButton)
        
        
        shareButton = UIButton(frame: CGRect(x: view.bounds.width-50, y: 0, width: 40, height: 40))
        shareButton.imageEdgeInsets = UIEdgeInsetsMake(10, 10, 10, 10)
        shareButton.setImage(UIImage(assetIdentifier: .Share), for: UIControlState())
        shareButton.addTarget(self, action: #selector(self.shareTapped), for: .touchUpInside)
        view.addSubview(shareButton)
    }
    
    
    func saveTapped() {
        PHPhotoLibrary.requestAuthorization({(status: PHAuthorizationStatus) in
            if (status == PHAuthorizationStatus.authorized) {
                self.saveImageToGallery(self.imageToPreview)
            } else {
                
                DispatchQueue.main.async(execute: {
                    
                    let alertController = UIAlertController(title: "Alert", message: "Please allow", preferredStyle: .alert)
                    
                    let settingsAction = UIAlertAction(title: "Settings", style: .default, handler: { (action) in
                        UIApplication.shared.openURL(URL(string: UIApplicationOpenSettingsURLString)!)
                    })
                    let cancelAction = UIAlertAction(title: "Cancel", style: .default, handler: nil)
                    alertController.addAction(settingsAction)
                    alertController.addAction(cancelAction)
                    self.present(alertController, animated: true, completion: nil)
                })
            }
        })
    }
    
    func cancelTapped() {
        DispatchQueue.main.async(execute: {
            self.dismiss(animated: true, completion: nil)
        })
    }
    
    func drawTapped() {
        DispatchQueue.main.async(execute: {
            let vc = self.storyboard?.instantiateViewController(withIdentifier: "DrawingViewController") as! DrawingViewController
            vc.imageToEdit = self.imageToPreview
            self.present(vc, animated: false, completion: nil)
        })
    }
    
    func shareTapped() {
        DispatchQueue.main.async { 
            let imageItem = self.imageToPreview as AnyObject
            
            let activityVC = UIActivityViewController(activityItems: [imageItem], applicationActivities: nil)
            self.present(activityVC, animated: true, completion: nil)
        }
    }

    
    fileprivate func saveImageToGallery(_ image: UIImage) {
        
        guard let imageData = UIImageJPEGRepresentation(image, 1.0) else {
            print("Invalid image data, can't save")
            return
        }
        
        let tempFileName: NSString = "tempImage"
        let tempFilePath = (NSTemporaryDirectory() as NSString).appendingPathComponent(tempFileName.appendingPathExtension("jpg")!)
        let tempFileUrl = URL(fileURLWithPath: tempFilePath)
        
        var err: NSError?
        
        PHPhotoLibrary.shared().performChanges({ 
            
            do {
                
                if FileManager.default.fileExists(atPath: tempFilePath) {
                    try FileManager.default.removeItem(atPath: tempFilePath)
                    print("Removed existing file")
                }
                
                try imageData.write(to: tempFileUrl, options: .atomicWrite)
                PHAssetChangeRequest.creationRequestForAssetFromImage(atFileURL: tempFileUrl)
                
            } catch let error as NSError {
                print("Error while saving image to gallery: \(err)")
                err = error
            }
            
            }) { (success, error) in
                
                if (err == nil && success == true) {
                    // Show success message
                    DispatchQueue.main.async(execute: { 
                        self.dismiss(animated: true, completion: nil)
                    })
                    
                } else {
                    // Show failed error message
                }
        }
    }
}
