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
private let CapturingStillImageContext = UnsafeMutablePointer<Void>.alloc(1)
private let SessionRunningContext = UnsafeMutablePointer<Void>.alloc(1)

private enum CameraSetupResult: Int {
    case Success, Unauthorized, ConfigurationFailed
}

// MARK: - Main Class
class CameraViewController: UIViewController {
    
    // MARK: Subviews
    private var previewView: CameraPreviewView!
    private var captureButton: UIButton!
    private var toggleCameraButton: UIButton!
    private var toggleFlashButton: UIButton!
    
    // MARK: Variables
    private var sessionQueue: dispatch_queue_t!
    private var captureSession: AVCaptureSession!
    private var captureDeviceInput: AVCaptureDeviceInput!
    private var stillImageOutput: AVCaptureStillImageOutput!
    
    
    private var cameraSetupResult: CameraSetupResult = .Success
    private var isSessionRunning: Bool = false
    
    
    // MARK: View Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.blackColor()
        
        previewView = CameraPreviewView(frame: view.bounds)
        view.addSubview(previewView)
        
        captureButton = UIButton(frame: CGRect(x: 0, y: 0, width: 60, height: 60))
        captureButton.center = CGPoint(x: view.center.x, y: view.bounds.height - 100)
        captureButton.backgroundColor = UIColor.clearColor()
        captureButton.layer.cornerRadius = captureButton.bounds.width/2
        captureButton.layer.borderWidth = 5.0
        captureButton.layer.borderColor = UIColor.whiteColor().CGColor
        captureButton.addTarget(self, action: #selector(self.snapPhoto), forControlEvents: .TouchUpInside)
        view.addSubview(captureButton)
        
        
        toggleFlashButton = UIButton(frame: CGRect(x: 10, y: 0, width: 50, height: 40))
        toggleFlashButton.setTitle("Auto", forState: .Normal)
        toggleFlashButton.setTitleColor(UIColor.whiteColor(), forState: .Normal)
        toggleFlashButton.setTitleColor(UIColor.whiteColor().colorWithAlphaComponent(0.5), forState: .Highlighted)
        toggleFlashButton.addTarget(self, action: #selector(self.toggleFlash), forControlEvents: .TouchUpInside)
        view.addSubview(toggleFlashButton)
        
        
        toggleCameraButton = UIButton(frame: CGRect(x: view.bounds.width/2-25, y: 0, width: 40, height: 40))
        toggleCameraButton.imageEdgeInsets = UIEdgeInsetsMake(10, 10, 10, 10)
        toggleCameraButton.setImage(UIImage(assetIdentifier: .Toggle), forState: .Normal)
        
        toggleCameraButton.setTitleColor(UIColor.whiteColor(), forState: .Normal)
        toggleCameraButton.setTitleColor(UIColor.whiteColor().colorWithAlphaComponent(0.5), forState: .Highlighted)
        toggleCameraButton.addTarget(self, action: #selector(self.toggleCamera), forControlEvents: .TouchUpInside)
        view.addSubview(toggleCameraButton)
        
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.focusAndExposureTap(_:)))
        view.addGestureRecognizer(tap)
        

        setupCameraSessions()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        dispatch_async(sessionQueue) {
            
            switch self.cameraSetupResult {
            case .Success:
                self.addObservers()
                self.captureSession.startRunning()
                self.isSessionRunning = self.captureSession.running
                
            case .Unauthorized:
                dispatch_async(dispatch_get_main_queue(), { 
                    let message = "Please allow"
                    let alertController = UIAlertController(title: "Alert", message: message, preferredStyle: .Alert)
                    
                    let settingsAction = UIAlertAction(title: "Settings", style: .Default, handler: { (action) in
                        UIApplication.sharedApplication().openURL(NSURL(string: UIApplicationOpenSettingsURLString)!)
                    })
                    
                    let cancelAction = UIAlertAction(title: "Cancel", style: .Default, handler: nil)
                    
                    alertController.addAction(settingsAction)
                    alertController.addAction(cancelAction)
                    
                    self.presentViewController(alertController, animated: true, completion: nil)
                })
                
            case .ConfigurationFailed:
                dispatch_async(dispatch_get_main_queue(), {
                    let message = "Configuration Failed"
                    let alertController = UIAlertController(title: "Alert", message: message, preferredStyle: .Alert)
                    
                    let cancelAction = UIAlertAction(title: "Cancel", style: .Default, handler: nil)
                    alertController.addAction(cancelAction)
                    
                    self.presentViewController(alertController, animated: true, completion: nil)
                })
            }
        }
    }
    
    override func viewDidDisappear(animated: Bool) {
        
        dispatch_async(sessionQueue) { 
            if (self.cameraSetupResult == .Success) {
                self.captureSession.stopRunning()
                self.removeObservers()
            }
        }
        super.viewDidDisappear(animated)
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    // MARK: Initial Camera Setup
    private func setupCameraSessions() {
        
        captureSession = AVCaptureSession()
        previewView.session = captureSession
        
        sessionQueue = dispatch_queue_create("SessionQueue", DISPATCH_QUEUE_SERIAL)
        
        checkCameraAuthorizationStatus()
        
        dispatch_async(sessionQueue) {
            
            guard (self.cameraSetupResult == .Success) else {
                return
            }
            
            self.captureSession.beginConfiguration()
            
            self.addCaptureDeviceInput()
            self.addStillImageOutput()
            if let captureInput = self.captureDeviceInput {
                self.setFlashMode(.Auto, forDevice: captureInput.device)
            }
            
            
            self.captureSession.commitConfiguration()
        }
        
        
    }
    
    private func checkCameraAuthorizationStatus() {
        cameraSetupResult = .Success
        
        switch AVCaptureDevice.authorizationStatusForMediaType(AVMediaTypeVideo) {
        case .Authorized:
            break
        case .NotDetermined:
            dispatch_suspend(sessionQueue)
            
            AVCaptureDevice.requestAccessForMediaType(AVMediaTypeVideo, completionHandler: { (granted) in
                if (granted == false) {
                    self.cameraSetupResult = .Unauthorized
                }
                dispatch_resume(self.sessionQueue)
            })
            
        default:
            cameraSetupResult = .Unauthorized
        }
    }
    
    private func addCaptureDeviceInput() {
        let videoDevice = captureDeviceAtPosition(.Back)
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
            
            dispatch_async(dispatch_get_main_queue(), { 
                let orientation = AVCaptureVideoOrientation.Portrait
                let previewLayer = self.previewView.layer as! AVCaptureVideoPreviewLayer
                previewLayer.connection.videoOrientation = orientation
            })
            
        } else {
            cameraSetupResult = .ConfigurationFailed
        }
    }
    
    private func addStillImageOutput() {
        let imageOutput = AVCaptureStillImageOutput()
        
        if (captureSession.canAddOutput(imageOutput)) {
            imageOutput.outputSettings = [AVVideoCodecKey: AVVideoCodecJPEG]
            captureSession.addOutput(imageOutput)
            stillImageOutput = imageOutput
        } else {
            cameraSetupResult = .ConfigurationFailed
        }
    }
    
    
    // MARK: Camera Utilities
    private func captureDeviceAtPosition(position: AVCaptureDevicePosition) -> AVCaptureDevice? {
        let devices = AVCaptureDevice.devicesWithMediaType(AVMediaTypeVideo) as! [AVCaptureDevice]
        
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
    
    private func setFlashMode(flashMode: AVCaptureFlashMode, forDevice device: AVCaptureDevice) {
        if (device.hasFlash && device.isFlashModeSupported(flashMode)) {
            do {
                try device.lockForConfiguration()
                device.flashMode = flashMode
                device.unlockForConfiguration()
                
                var flashTitle = ""
                if (flashMode == .Auto) {
                    flashTitle = "Auto"
                } else if (flashMode == .On) {
                    flashTitle = "On"
                } else {
                    flashTitle = "Off"
                }
                
                dispatch_async(dispatch_get_main_queue(), {
                    self.toggleFlashButton.setTitle(flashTitle, forState: .Normal)
                })
                
            } catch let error as NSError {
                print("flash configuration failed: \(error.localizedDescription)")
            }
        } else {
            dispatch_async(dispatch_get_main_queue(), {
                self.toggleFlashButton.setTitle("Off", forState: .Normal)
            })
        }
    }
    
    private func focusWithMode(focusMode: AVCaptureFocusMode, exposureWithMode exposureMode: AVCaptureExposureMode, atDevicePoint point: CGPoint, monitorSubjectAreaChange: Bool) {
        
        dispatch_async(sessionQueue) {
            if let device = self.captureDeviceInput.device {
                do {
                    try device.lockForConfiguration()
                    
                    if (device.focusPointOfInterestSupported && device.isFocusModeSupported(focusMode)) {
                        device.focusPointOfInterest = point
                        device.focusMode = focusMode
                    }
                    if (device.exposurePointOfInterestSupported && device.isExposureModeSupported(exposureMode)) {
                        device.exposurePointOfInterest = point
                        device.exposureMode = exposureMode
                    }
                    
                    if (device.isWhiteBalanceModeSupported(.ContinuousAutoWhiteBalance)) {
                        device.whiteBalanceMode = .ContinuousAutoWhiteBalance
                    }
                    
                    device.subjectAreaChangeMonitoringEnabled = monitorSubjectAreaChange
                    
                } catch let error as NSError {
                    print("focus and exposure setup failed: \(error.localizedDescription)")
                }
            }
        }
    }
    
    
    // MARK: Actions
    func toggleFlash() {
        // For Back: Auto -> On -> Off, For Front, only Off
        dispatch_async(sessionQueue) {
            
            guard (self.captureDeviceInput != nil) else {
                return
            }
            
            let currentCaptureDevice = self.captureDeviceInput.device
            let currentPosition = currentCaptureDevice.position
            
            var preferredFlashMode = AVCaptureFlashMode.Off
            
            if (currentPosition == .Back) {
                let currentFlashMode = currentCaptureDevice.flashMode
                
                switch currentFlashMode {
                case .Auto:
                    preferredFlashMode = .On
                case .On:
                    preferredFlashMode = .Off
                case .Off:
                    preferredFlashMode = .Auto
                }
                self.setFlashMode(preferredFlashMode, forDevice: currentCaptureDevice)
            }
        }
    }
    
    
    
    func toggleCamera() {
        dispatch_async(sessionQueue) { 
            
            guard (self.captureDeviceInput != nil) else {
                return
            }
            
            let currentCaptureDevice = self.captureDeviceInput.device
            let currentPosition = currentCaptureDevice.position
            
            var preferredPosition = AVCaptureDevicePosition.Unspecified
            
            switch currentPosition {
            case .Back:
                preferredPosition = .Front
            case .Unspecified, .Front:
                preferredPosition = .Back
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
                    
                    NSNotificationCenter.defaultCenter().removeObserver(self, name: AVCaptureDeviceSubjectAreaDidChangeNotification, object: currentCaptureDevice)
                    
                    if (preferredPosition == .Front) {
                        self.setFlashMode(.Off, forDevice: videoDevice)
                    } else {
                        self.setFlashMode(.Auto, forDevice: videoDevice)
                    }
                    
                    NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(self.deviceSubjectAreaDidChange(_:)), name: AVCaptureDeviceSubjectAreaDidChangeNotification, object: videoDevice)
                    
                    self.captureSession.addInput(videoDeviceInput)
                    self.captureDeviceInput = videoDeviceInput
                } else {
                    self.captureSession.addInput(self.captureDeviceInput)
                }
                
                self.captureSession.commitConfiguration()
            }
        }
    }
    
    func focusAndExposureTap(gesture: UITapGestureRecognizer) {
        let previewLayer = previewView.layer as! AVCaptureVideoPreviewLayer
        let devicePoint = previewLayer.captureDevicePointOfInterestForPoint(gesture.locationInView(gesture.view))
        focusWithMode(.AutoFocus, exposureWithMode: .AutoExpose, atDevicePoint: devicePoint, monitorSubjectAreaChange: true)
    }
    
    
    
    
    // MARK: Image Capture
    func snapPhoto() {
        dispatch_async(sessionQueue) { 
            guard let videoConnection = self.stillImageOutput.connectionWithMediaType(AVMediaTypeVideo) else {
                return
            }
            
            let previewLayer = self.previewView.layer as! AVCaptureVideoPreviewLayer
            videoConnection.videoOrientation = previewLayer.connection.videoOrientation
            
            self.stillImageOutput.captureStillImageAsynchronouslyFromConnection(videoConnection, completionHandler: { (sampleBuffer, error) in
                if (sampleBuffer != nil) {
                    let imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(sampleBuffer)
                    
                    let capturedImage = UIImage(data: imageData)
                    self.goToPreviewImage(capturedImage!)
                }
            })
        }
    }
    
    private func goToPreviewImage(image: UIImage) {
        dispatch_async(dispatch_get_main_queue()) { 
            let vc = self.storyboard?.instantiateViewControllerWithIdentifier("ImagePreviewViewController") as! ImagePreviewViewController
            vc.imageToPreview = image
            self.presentViewController(vc, animated: true, completion: nil)
        }
    }
    
    
    // MARK: KVO and Notifications
    private func addObservers() {
        
        captureSession.addObserver(self, forKeyPath: "running", options: NSKeyValueObservingOptions.New, context: SessionRunningContext)
        stillImageOutput.addObserver(self, forKeyPath: "capturingStillImage", options: NSKeyValueObservingOptions.New, context: CapturingStillImageContext)
        
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(self.deviceSubjectAreaDidChange(_:)), name: AVCaptureDeviceSubjectAreaDidChangeNotification, object: captureDeviceInput.device)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(self.sessionRuntimeError(_:)), name: AVCaptureSessionRuntimeErrorNotification, object: captureSession)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(self.sessionWasInterrupted(_:)), name: AVCaptureSessionWasInterruptedNotification, object: captureSession)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(self.sessionInteruptionEnded(_:)), name: AVCaptureSessionInterruptionEndedNotification, object: captureSession)
    }
    
    private func removeObservers() {
        NSNotificationCenter.defaultCenter().removeObserver(self)
        
        captureSession.removeObserver(self, forKeyPath: "running", context: SessionRunningContext)
        stillImageOutput.removeObserver(self, forKeyPath: "capturingStillImage", context: CapturingStillImageContext)
    }
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        
        switch context {
        case SessionRunningContext:
            
            let isSessionRunning = change![NSKeyValueChangeNewKey] as! Bool
            
            print("Is Session Running: \(isSessionRunning)")
            
        case CapturingStillImageContext:
            
            let isCapturingStillImage = change![NSKeyValueChangeNewKey] as! Bool
            if isCapturingStillImage {
                dispatch_async(dispatch_get_main_queue()) {
                    self.previewView.layer.opacity = 0.0
                    UIView.animateWithDuration(0.25) {
                        self.previewView.layer.opacity = 1.0
                    }
                }
            }
            
        default:
            super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
        }
    }
    
    // Notifications
    
    func deviceSubjectAreaDidChange(notification: NSNotification) {
        let devicePoint = CGPointMake(0.5, 0.5)
        focusWithMode(.ContinuousAutoFocus, exposureWithMode: .ContinuousAutoExposure, atDevicePoint: devicePoint, monitorSubjectAreaChange: false)
    }
    
    func sessionRuntimeError(notification: NSNotification) {
        let error = notification.userInfo![AVCaptureSessionErrorKey] as! NSError
        print("Capture Session Runtime Error: \(error)")
        
        if (error.code == AVError.MediaServicesWereReset.rawValue) {
            dispatch_async(sessionQueue, {
                if (self.isSessionRunning) {
                    self.captureSession.startRunning()
                    self.isSessionRunning = self.captureSession.running
                } else {
                    // show alert
                }
            })
        } else {
            // show alert
        }
    }
    
    func sessionWasInterrupted(notification: NSNotification) {
        print("Session was interrupted")
    }
    
    func sessionInteruptionEnded(notification: NSNotification) {
        print("Session Interruption Ended")
    }
    
    func resumeInterruptedSession() {
        dispatch_async(sessionQueue) {
            
            self.captureSession.startRunning()
            self.isSessionRunning = self.captureSession.running
            
            if (self.captureSession.running == false) {
                // showAlert
            }
            
        }
    }
    
    
}
