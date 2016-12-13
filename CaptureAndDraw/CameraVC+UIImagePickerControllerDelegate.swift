//
//  CameraVC+UIImagePickerControllerDelegate.swift
//  CaptureAndDraw
//
//  Created by Anirudha Tolambia on 13/12/16.
//  Copyright © 2016 Anirudha Tolambia. All rights reserved.
//

import UIKit

extension CameraViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func openFromGallery() {
        dispatch_async(dispatch_get_main_queue()) {
            let picker = UIImagePickerController()
            picker.sourceType = .PhotoLibrary
            picker.allowsEditing = false
            picker.delegate = self
            self.presentViewController(picker, animated: true, completion: nil)
        }
    }
    
    func showOpenedImageFromPicker(image: UIImage) {
        self.goToPreviewImage(image)
    }
    
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        dispatch_async(dispatch_get_main_queue()) {
            picker.dismissViewControllerAnimated(true, completion: nil)
        }
    }
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        
        if let originalImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
            picker.dismissViewControllerAnimated(false, completion: { 
                self.showOpenedImageFromPicker(originalImage)
            })
        }
    }
}
