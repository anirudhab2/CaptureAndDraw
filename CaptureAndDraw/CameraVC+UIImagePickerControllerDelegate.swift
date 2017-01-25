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
        DispatchQueue.main.async {
            let picker = UIImagePickerController()
            picker.sourceType = .photoLibrary
            picker.allowsEditing = false
            picker.delegate = self
            self.present(picker, animated: true, completion: nil)
        }
    }
    
    func showOpenedImageFromPicker(_ image: UIImage) {
        self.goToPreviewImage(image)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        DispatchQueue.main.async {
            picker.dismiss(animated: true, completion: nil)
        }
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        if let originalImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
            picker.dismiss(animated: false, completion: { 
                self.showOpenedImageFromPicker(originalImage)
            })
        }
    }
}
