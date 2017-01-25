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
    
    private var imageView: UIImageView!
    private var saveButton: UIButton!
    private var cancelButton: UIButton!
    private var drawButton: UIButton!
    private var shareButton: UIButton!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupSubviews()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        if let validImage = imageToPreview {
            imageView.image = validImage
        } else {
            saveButton.enabled = false
            shareButton.enabled = false
        }
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    private func setupSubviews() {
        
        imageView = UIImageView(frame: view.bounds)
        view.addSubview(imageView)
        
        
        saveButton = UIButton(frame: CGRect(x: 10, y: 0, width: 40, height: 40))
        saveButton.imageEdgeInsets = UIEdgeInsetsMake(10, 10, 10, 10)
        saveButton.setImage(UIImage(assetIdentifier: .Save), forState: .Normal)
        saveButton.addTarget(self, action: #selector(self.saveTapped), forControlEvents: .TouchUpInside)
        view.addSubview(saveButton)
        
        
        cancelButton = UIButton(frame: CGRect(x: 60, y: 0, width: 40, height: 40))
        cancelButton.imageEdgeInsets = UIEdgeInsetsMake(10, 10, 10, 10)
        cancelButton.setImage(UIImage(assetIdentifier: .Cancel), forState: .Normal)
        cancelButton.addTarget(self, action: #selector(self.cancelTapped), forControlEvents: .TouchUpInside)
        view.addSubview(cancelButton)
        
        
        drawButton = UIButton(frame: CGRect(x: view.bounds.width-100, y: 0, width: 40, height: 40))
        drawButton.imageEdgeInsets = UIEdgeInsetsMake(10, 10, 10, 10)
        drawButton.setImage(UIImage(assetIdentifier: .Pencil), forState: .Normal)
        drawButton.addTarget(self, action: #selector(self.drawTapped), forControlEvents: .TouchUpInside)
        view.addSubview(drawButton)
        
        
        shareButton = UIButton(frame: CGRect(x: view.bounds.width-50, y: 0, width: 40, height: 40))
        shareButton.imageEdgeInsets = UIEdgeInsetsMake(10, 10, 10, 10)
        shareButton.setImage(UIImage(assetIdentifier: .Share), forState: .Normal)
        shareButton.addTarget(self, action: #selector(self.shareTapped), forControlEvents: .TouchUpInside)
        view.addSubview(shareButton)
    }
    
    
    func saveTapped() {
        PHPhotoLibrary.requestAuthorization({(status: PHAuthorizationStatus) in
            if (status == PHAuthorizationStatus.Authorized) {
                self.saveImageToGallery(self.imageToPreview)
            } else {
                
                dispatch_async(dispatch_get_main_queue(), {
                    
                    let alertController = UIAlertController(title: "Alert", message: "Please allow", preferredStyle: .Alert)
                    
                    let settingsAction = UIAlertAction(title: "Settings", style: .Default, handler: { (action) in
                        UIApplication.sharedApplication().openURL(NSURL(string: UIApplicationOpenSettingsURLString)!)
                    })
                    let cancelAction = UIAlertAction(title: "Cancel", style: .Default, handler: nil)
                    alertController.addAction(settingsAction)
                    alertController.addAction(cancelAction)
                    self.presentViewController(alertController, animated: true, completion: nil)
                })
            }
        })
    }
    
    func cancelTapped() {
        dispatch_async(dispatch_get_main_queue(), {
            self.dismissViewControllerAnimated(true, completion: nil)
        })
    }
    
    func drawTapped() {
        dispatch_async(dispatch_get_main_queue(), {
            let vc = self.storyboard?.instantiateViewControllerWithIdentifier("DrawingViewController") as! DrawingViewController
            vc.imageToEdit = self.imageToPreview
            self.presentViewController(vc, animated: false, completion: nil)
        })
    }
    
    func shareTapped() {
        dispatch_async(dispatch_get_main_queue()) { 
            let imageItem = self.imageToPreview as AnyObject
            
            let activityVC = UIActivityViewController(activityItems: [imageItem], applicationActivities: nil)
            self.presentViewController(activityVC, animated: true, completion: nil)
        }
    }

    
    private func saveImageToGallery(image: UIImage) {
        
        guard let imageData = UIImageJPEGRepresentation(image, 1.0) else {
            print("Invalid image data, can't save")
            return
        }
        
        let tempFileName: NSString = "tempImage"
        let tempFilePath = (NSTemporaryDirectory() as NSString).stringByAppendingPathComponent(tempFileName.stringByAppendingPathExtension("jpg")!)
        let tempFileUrl = NSURL(fileURLWithPath: tempFilePath)
        
        var err: NSError?
        
        PHPhotoLibrary.sharedPhotoLibrary().performChanges({ 
            
            do {
                
                if NSFileManager.defaultManager().fileExistsAtPath(tempFilePath) {
                    try NSFileManager.defaultManager().removeItemAtPath(tempFilePath)
                    print("Removed existing file")
                }
                
                try imageData.writeToURL(tempFileUrl, options: .AtomicWrite)
                PHAssetChangeRequest.creationRequestForAssetFromImageAtFileURL(tempFileUrl)
                
            } catch let error as NSError {
                print("Error while saving image to gallery: \(err)")
                err = error
            }
            
            }) { (success, error) in
                
                if (err == nil && success == true) {
                    // Show success message
                    dispatch_async(dispatch_get_main_queue(), { 
                        self.dismissViewControllerAnimated(true, completion: nil)
                    })
                    
                } else {
                    // Show failed error message
                }
        }
    }
}
