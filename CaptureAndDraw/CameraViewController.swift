//
//  CameraViewController.swift
//  CaptureAndDraw
//
//  Created by Anirudha Tolambia on 10/12/16.
//  Copyright © 2016 Anirudha Tolambia. All rights reserved.
//

import UIKit
import AVFoundation

// Session context for KVO
//private let CapturingStillImageContext = UnsafeMutableRawPointer.allocate(capacity: 1)
//private let SessionRunningContext = UnsafeMutableRawPointer.allocate(capacity: 1)




private enum CameraSetupResult: Int {
    case success, unauthorized, configurationFailed
}

// MARK: - Main Class
class CameraViewController: UIViewController {
    
    // MARK: Subviews
    fileprivate var previewView: CameraPreviewView!
    fileprivate var captureButton: UIButton!
    fileprivate var toggleCameraButton: UIButton!
    fileprivate var toggleFlashButton: UIButton!
    fileprivate var fileButton: UIButton!
    
    // MARK: Variables
    fileprivate var sessionQueue: DispatchQueue!
    fileprivate var captureSession: AVCaptureSession!
    fileprivate var captureDeviceInput: AVCaptureDeviceInput!
    fileprivate var stillImageOutput: AVCaptureStillImageOutput!
    
    
    fileprivate var cameraSetupResult: CameraSetupResult = .success
    fileprivate var isSessionRunning: Bool = false
    
    // MARK: Pointers
    fileprivate var sessionRunningContext = "SessionRunningContext"
    fileprivate var capturingStillImageContext = "CapturingStillImageContext"
    
    
    // MARK: View Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.black
        
        previewView = CameraPreviewView(frame: view.bounds)
        view.addSubview(previewView)
        
        captureButton = UIButton(frame: CGRect(x: 0, y: 0, width: 60, height: 60))
        captureButton.center = CGPoint(x: view.center.x, y: view.bounds.height - 100)
        captureButton.backgroundColor = UIColor.clear
        captureButton.layer.cornerRadius = captureButton.bounds.width/2
        captureButton.layer.borderWidth = 5.0
        captureButton.layer.borderColor = UIColor.white.cgColor
        captureButton.addTarget(self, action: #selector(self.snapPhoto), for: .touchUpInside)
        view.addSubview(captureButton)
        
        
        toggleFlashButton = UIButton(frame: CGRect(x: 10, y: 0, width: 50, height: 40))
        toggleFlashButton.setTitle("Auto", for: UIControlState())
        toggleFlashButton.setTitleColor(UIColor.white, for: UIControlState())
        toggleFlashButton.setTitleColor(UIColor.white.withAlphaComponent(0.5), for: .highlighted)
        toggleFlashButton.addTarget(self, action: #selector(self.toggleFlash), for: .touchUpInside)
        view.addSubview(toggleFlashButton)
        
        
        toggleCameraButton = UIButton(frame: CGRect(x: view.bounds.width/2-25, y: 0, width: 40, height: 40))
        toggleCameraButton.imageEdgeInsets = UIEdgeInsetsMake(10, 10, 10, 10)
        toggleCameraButton.setImage(UIImage(assetIdentifier: .Toggle), for: UIControlState())
        toggleCameraButton.addTarget(self, action: #selector(self.toggleCamera), for: .touchUpInside)
        view.addSubview(toggleCameraButton)
        
        
        fileButton = UIButton(frame: CGRect(x: view.bounds.width-50, y: 0, width: 40, height: 40))
        fileButton.imageEdgeInsets = UIEdgeInsetsMake(7.5, 7.5, 7.5, 7.5)
        fileButton.setImage(UIImage(assetIdentifier: .Gallery), for: UIControlState())
        fileButton.addTarget(self, action: #selector(self.openFromGallery), for: .touchUpInside)
        view.addSubview(fileButton)
        
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.focusAndExposureTap(_:)))
        view.addGestureRecognizer(tap)
        

        setupCameraSessions()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        sessionQueue.async {
            
            switch self.cameraSetupResult {
            case .success:
                self.addObservers()
                self.captureSession.startRunning()
                self.isSessionRunning = self.captureSession.isRunning
                
            case .unauthorized:
                DispatchQueue.main.async(execute: { 
                    let message = "Please allow"
                    let alertController = UIAlertController(title: "Alert", message: message, preferredStyle: .alert)
                    
                    let settingsAction = UIAlertAction(title: "Settings", style: .default, handler: { (action) in
                        UIApplication.shared.openURL(URL(string: UIApplicationOpenSettingsURLString)!)
                    })
                    
                    let cancelAction = UIAlertAction(title: "Cancel", style: .default, handler: nil)
                    
                    alertController.addAction(settingsAction)
                    alertController.addAction(cancelAction)
                    
                    self.present(alertController, animated: true, completion: nil)
                })
                
            case .configurationFailed:
                DispatchQueue.main.async(execute: {
                    let message = "Configuration Failed"
                    let alertController = UIAlertController(title: "Alert", message: message, preferredStyle: .alert)
                    
                    let cancelAction = UIAlertAction(title: "Cancel", style: .default, handler: nil)
                    alertController.addAction(cancelAction)
                    
                    self.present(alertController, animated: true, completion: nil)
                })
            }
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        
        sessionQueue.async { 
            if (self.cameraSetupResult == .success) {
                self.captureSession.stopRunning()
                self.removeObservers()
            }
        }
        super.viewDidDisappear(animated)
    }
    
    override var prefersStatusBarHidden : Bool {
        return true
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    // MARK: Initial Camera Setup
    fileprivate func setupCameraSessions() {
        
        captureSession = AVCaptureSession()
        previewView.session = captureSession
        
        sessionQueue = DispatchQueue(label: "SessionQueue", attributes: [])
        
        checkCameraAuthorizationStatus()
        
        sessionQueue.async {
            
            guard (self.cameraSetupResult == .success) else {
                return
            }
            
            self.captureSession.beginConfiguration()
            
            self.addCaptureDeviceInput()
            self.addStillImageOutput()
            if let captureInput = self.captureDeviceInput {
                self.setFlashMode(.auto, forDevice: captureInput.device)
            }
            
            
            self.captureSession.commitConfiguration()
        }
        
        
    }
    
    fileprivate func checkCameraAuthorizationStatus() {
        cameraSetupResult = .success
        
        switch AVCaptureDevice.authorizationStatus(forMediaType: AVMediaTypeVideo) {
        case .authorized:
            break
        case .notDetermined:
            sessionQueue.suspend()
            
            AVCaptureDevice.requestAccess(forMediaType: AVMediaTypeVideo, completionHandler: { (granted) in
                if (granted == false) {
                    self.cameraSetupResult = .unauthorized
                }
                self.sessionQueue.resume()
            })
            
        default:
            cameraSetupResult = .unauthorized
        }
    }
    
    fileprivate func addCaptureDeviceInput() {
        let videoDevice = captureDeviceAtPosition(.back)
        var videoDeviceInput: AVCaptureDeviceInput!
        
        var error: NSError!
        
        do {
            videoDeviceInput = try AVCaptureDeviceInput(device: videoDevice)
        } catch let err as NSError {
            error  = err
            videoDeviceInput = nil
        }
        
        if (error == nil && captureSession.canAddInput(videoDeviceInput)) {
            captureDeviceInput = videoDeviceInput
            captureSession.addInput(videoDeviceInput)
            
            DispatchQueue.main.async(execute: { 
                let orientation = AVCaptureVideoOrientation.portrait
                let previewLayer = self.previewView.layer as! AVCaptureVideoPreviewLayer
                previewLayer.connection.videoOrientation = orientation
            })
            
        } else {
            cameraSetupResult = .configurationFailed
        }
    }
    
    fileprivate func addStillImageOutput() {
        let imageOutput = AVCaptureStillImageOutput()
        
        if (captureSession.canAddOutput(imageOutput)) {
            imageOutput.outputSettings = [AVVideoCodecKey: AVVideoCodecJPEG]
            captureSession.addOutput(imageOutput)
            stillImageOutput = imageOutput
        } else {
            cameraSetupResult = .configurationFailed
        }
    }
    
    
    // MARK: Camera Utilities
    fileprivate func captureDeviceAtPosition(_ position: AVCaptureDevicePosition) -> AVCaptureDevice? {
        let devices = AVCaptureDevice.devices(withMediaType: AVMediaTypeVideo) as! [AVCaptureDevice]
        
        if (devices.isEmpty) {
            print("The device doesn't have any capture device, may it is simulator")
            return nil
        }
        
        var captureDevice = devices.first
        
        for device in devices {
            if (device.position == position) {
                captureDevice = device
                break
            }
        }
        
        return captureDevice
    }
    
    fileprivate func setFlashMode(_ flashMode: AVCaptureFlashMode, forDevice device: AVCaptureDevice) {
        if (device.hasFlash && device.isFlashModeSupported(flashMode)) {
            do {
                try device.lockForConfiguration()
                device.flashMode = flashMode
                device.unlockForConfiguration()
                
                var flashTitle = ""
                if (flashMode == .auto) {
                    flashTitle = "Auto"
                } else if (flashMode == .on) {
                    flashTitle = "On"
                } else {
                    flashTitle = "Off"
                }
                
                DispatchQueue.main.async(execute: {
                    self.toggleFlashButton.setTitle(flashTitle, for: UIControlState())
                })
                
            } catch let error as NSError {
                print("flash configuration failed: \(error.localizedDescription)")
            }
        } else {
            DispatchQueue.main.async(execute: {
                self.toggleFlashButton.setTitle("Off", for: UIControlState())
            })
        }
    }
    
    fileprivate func focusWithMode(_ focusMode: AVCaptureFocusMode, exposureWithMode exposureMode: AVCaptureExposureMode, atDevicePoint point: CGPoint, monitorSubjectAreaChange: Bool) {
        
        sessionQueue.async {
            if let device = self.captureDeviceInput.device {
                do {
                    try device.lockForConfiguration()
                    
                    if (device.isFocusPointOfInterestSupported && device.isFocusModeSupported(focusMode)) {
                        device.focusPointOfInterest = point
                        device.focusMode = focusMode
                    }
                    if (device.isExposurePointOfInterestSupported && device.isExposureModeSupported(exposureMode)) {
                        device.exposurePointOfInterest = point
                        device.exposureMode = exposureMode
                    }
                    
                    if (device.isWhiteBalanceModeSupported(.continuousAutoWhiteBalance)) {
                        device.whiteBalanceMode = .continuousAutoWhiteBalance
                    }
                    
                    device.isSubjectAreaChangeMonitoringEnabled = monitorSubjectAreaChange
                    
                } catch let error as NSError {
                    print("focus and exposure setup failed: \(error.localizedDescription)")
                }
            }
        }
    }
    
    
    // MARK: Actions
    func toggleFlash() {
        // For Back: Auto -> On -> Off, For Front, only Off
        sessionQueue.async {
            
            guard (self.captureDeviceInput != nil),
                let currentCaptureDevice = self.captureDeviceInput.device else {
                return
            }
            
//            let currentCaptureDevice = self.captureDeviceInput.device
            let currentPosition = currentCaptureDevice.position
            
            var preferredFlashMode = AVCaptureFlashMode.off
            
            if (currentPosition == .back) {
                let currentFlashMode = currentCaptureDevice.flashMode
                
                switch currentFlashMode {
                case .auto:
                    preferredFlashMode = .on
                case .on:
                    preferredFlashMode = .off
                case .off:
                    preferredFlashMode = .auto
                }
            }
            
            self.setFlashMode(preferredFlashMode, forDevice: currentCaptureDevice)
        }
    }
    
    
    
    func toggleCamera() {
        sessionQueue.async { 
            
            guard (self.captureDeviceInput != nil),
            let currentCaptureDevice = self.captureDeviceInput.device else {
                return
            }
            
//            let currentCaptureDevice = self.captureDeviceInput.device
            let currentPosition = currentCaptureDevice.position
            
            var preferredPosition = AVCaptureDevicePosition.unspecified
            
            switch currentPosition {
            case .back:
                preferredPosition = .front
            case .unspecified, .front:
                preferredPosition = .back
            }
            
            if let videoDevice = self.captureDeviceAtPosition(preferredPosition) {
                var videoDeviceInput: AVCaptureDeviceInput!
                var error: NSError!
                
                do {
                    videoDeviceInput = try AVCaptureDeviceInput(device: videoDevice)
                } catch let err as NSError {
                    error = err
                    print("Error while adding video device input: \(error)")
                    videoDeviceInput = nil
                }
                
                self.captureSession.beginConfiguration()
                
                self.captureSession.removeInput(self.captureDeviceInput)
                
                if (error == nil && self.captureSession.canAddInput(videoDeviceInput)) {
                    
                    NotificationCenter.default.removeObserver(self, name: NSNotification.Name.AVCaptureDeviceSubjectAreaDidChange, object: currentCaptureDevice)
                    
                    if (preferredPosition == .front) {
                        self.setFlashMode(.off, forDevice: videoDevice)
                    } else {
                        self.setFlashMode(.auto, forDevice: videoDevice)
                    }
                    
                    NotificationCenter.default.addObserver(self, selector: #selector(self.deviceSubjectAreaDidChange(_:)), name: NSNotification.Name.AVCaptureDeviceSubjectAreaDidChange, object: videoDevice)
                    
                    self.captureSession.addInput(videoDeviceInput)
                    self.captureDeviceInput = videoDeviceInput
                } else {
                    self.captureSession.addInput(self.captureDeviceInput)
                }
                
                self.captureSession.commitConfiguration()
            }
        }
    }
    
    func focusAndExposureTap(_ gesture: UITapGestureRecognizer) {
        let previewLayer = previewView.layer as! AVCaptureVideoPreviewLayer
        let devicePoint = previewLayer.captureDevicePointOfInterest(for: gesture.location(in: gesture.view))
        focusWithMode(.autoFocus, exposureWithMode: .autoExpose, atDevicePoint: devicePoint, monitorSubjectAreaChange: true)
    }
    
    
    
    
    // MARK: Image Capture
    func snapPhoto() {
        sessionQueue.async { 
            guard let videoConnection = self.stillImageOutput.connection(withMediaType: AVMediaTypeVideo) else {
                return
            }
            
            let previewLayer = self.previewView.layer as! AVCaptureVideoPreviewLayer
            videoConnection.videoOrientation = previewLayer.connection.videoOrientation
            
            self.stillImageOutput.captureStillImageAsynchronously(from: videoConnection, completionHandler: { (sampleBuffer, error) in
                if (sampleBuffer != nil) {
                    let imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(sampleBuffer)
                    
                    let capturedImage = UIImage(data: imageData!)
                    self.goToPreviewImage(capturedImage!)
                }
            })
        }
    }
    
    func goToPreviewImage(_ image: UIImage) {
        DispatchQueue.main.async { 
            let vc = self.storyboard?.instantiateViewController(withIdentifier: "ImagePreviewViewController") as! ImagePreviewViewController
            vc.imageToPreview = image
            self.present(vc, animated: true, completion: nil)
        }
    }
    
    
    // MARK: KVO and Notifications
    fileprivate func addObservers() {
        
//        captureSession.addObserver(self, forKeyPath: "running", options: NSKeyValueObservingOptions.new, context: SessionRunningContext)
//        stillImageOutput.addObserver(self, forKeyPath: "capturingStillImage", options: NSKeyValueObservingOptions.new, context: CapturingStillImageContext)
        
        captureSession.addObserver(self, forKeyPath: "running", options: NSKeyValueObservingOptions.new, context: &sessionRunningContext)
        stillImageOutput.addObserver(self, forKeyPath: "capturingStillImage", options: NSKeyValueObservingOptions.new, context: &capturingStillImageContext)
        
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.deviceSubjectAreaDidChange(_:)), name: NSNotification.Name.AVCaptureDeviceSubjectAreaDidChange, object: captureDeviceInput.device)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.sessionRuntimeError(_:)), name: NSNotification.Name.AVCaptureSessionRuntimeError, object: captureSession)
        NotificationCenter.default.addObserver(self, selector: #selector(self.sessionWasInterrupted(_:)), name: NSNotification.Name.AVCaptureSessionWasInterrupted, object: captureSession)
        NotificationCenter.default.addObserver(self, selector: #selector(self.sessionInteruptionEnded(_:)), name: NSNotification.Name.AVCaptureSessionInterruptionEnded, object: captureSession)
    }
    
    fileprivate func removeObservers() {
        NotificationCenter.default.removeObserver(self)
        
        captureSession.removeObserver(self, forKeyPath: "running", context: &sessionRunningContext)
        stillImageOutput.removeObserver(self, forKeyPath: "capturingStillImage", context: &capturingStillImageContext)
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        
        if (context == &sessionRunningContext) {
            let isSessionRunning = change![NSKeyValueChangeKey.newKey] as! Bool
            print("Is Session Running: \(isSessionRunning)")
        } else if (context == &capturingStillImageContext) {
            let isCapturingStillImage = change![NSKeyValueChangeKey.newKey] as! Bool
            
            if isCapturingStillImage {
                DispatchQueue.main.async {
                    self.previewView.layer.opacity = 0.0
                    UIView.animate(withDuration: 0.25, animations: {
                        self.previewView.layer.opacity = 1.0
                    })
                }
            }
        } else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
    
    // Notifications
    
    func deviceSubjectAreaDidChange(_ notification: Notification) {
        let devicePoint = CGPoint(x: 0.5, y: 0.5)
        focusWithMode(.continuousAutoFocus, exposureWithMode: .continuousAutoExposure, atDevicePoint: devicePoint, monitorSubjectAreaChange: false)
    }
    
    func sessionRuntimeError(_ notification: Notification) {
        let error = notification.userInfo![AVCaptureSessionErrorKey] as! NSError
        print("Capture Session Runtime Error: \(error)")
        
        if (error.code == AVError.Code.mediaServicesWereReset.rawValue) {
            sessionQueue.async(execute: {
                if (self.isSessionRunning) {
                    self.captureSession.startRunning()
                    self.isSessionRunning = self.captureSession.isRunning
                } else {
                    // show alert
                }
            })
        } else {
            // show alert
        }
    }
    
    func sessionWasInterrupted(_ notification: Notification) {
        print("Session was interrupted")
    }
    
    func sessionInteruptionEnded(_ notification: Notification) {
        print("Session Interruption Ended")
    }
    
    func resumeInterruptedSession() {
        sessionQueue.async {
            
            self.captureSession.startRunning()
            self.isSessionRunning = self.captureSession.isRunning
            
            if (self.captureSession.isRunning == false) {
                // showAlert
            }
            
        }
    }
    
    
}
