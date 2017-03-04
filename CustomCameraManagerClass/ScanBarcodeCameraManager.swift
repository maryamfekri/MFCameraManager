//
//  ScanBarcodeCameraManager.swift
//  sampleCameraManager
//
//  Created by Maryam on 3/3/17.
//  Copyright © 2017 Maryam. All rights reserved.
//

import Foundation
import AVFoundation
import UIKit

public protocol ScanBarcodeCameraManagerDelegate {
    func scanBarcodeCameraManagerDidRecognizeBarcode(barcode: Array<AVMetadataMachineReadableCodeObject>, image: UIImage?)
}

open class ScanBarcodeCameraManager: NSObject, AVCaptureMetadataOutputObjectsDelegate {
    
    //MARK: - Private Enum
    /**
     CameraDevice position.
     
     - back: back camera.
     - front: front camera.
     
     */
    private enum CameraDevice {
        case back
        case front
    }
    
    private var cameraPosition : CameraDevice?
    private var cameraView : UIView?
    weak private var previewLayer : AVCaptureVideoPreviewLayer?
    
    //Private variables that cannot be accessed by other classes in any way.
    fileprivate var metaDataOutput : AVCaptureMetadataOutput?
    fileprivate var stillImageOutput : AVCaptureStillImageOutput?
    fileprivate var captureSession: AVCaptureSession!
    
    var delegate: ScanBarcodeCameraManagerDelegate?
    private var captureDevice : AVCaptureDevice!
    private var isFocusMode = false
    private var isAutoUpdateLensPosition = false
    private var lensPosition: Float = 0
    private var isBusy = false
    
    private var focusMarkLayer = FocusMarker()
    private var focusLine = FocusLine()

    
    open func captureSetup(in cameraView: UIView, with cameraPosition: AVCaptureDevicePosition? = .back) {
        self.cameraView = cameraView
        self.captureSession = AVCaptureSession()
        switch cameraPosition! {
        case .back:
            self.captureSetup(withDevicePosition: .back)
            self.cameraPosition = .back
        case .front:
            self.captureSetup(withDevicePosition: .front)
            self.cameraPosition = .front
        default:
            self.captureSetup(withDevicePosition: .back)
        }
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(ScanBarcodeCameraManager.onTap(_:)))
        self.cameraView?.addGestureRecognizer(tapGestureRecognizer)
    }
    
    open func startRunning() {
        if (captureSession?.isRunning != true) {
            captureSession.startRunning()
        }
    }
    
    open func stopRunning() {
        if (captureSession?.isRunning == true) {
            captureSession.stopRunning()
        }
    }
    
    open func updatePreviewFrame() {
        if cameraView != nil {
            self.previewLayer?.frame = cameraView!.bounds
            self.focusMarkLayer.frame = cameraView!.bounds
            self.focusLine.frame = cameraView!.bounds
        }
    }
    
    open func transitionCamera() {
        if let connection =  self.previewLayer?.connection  {
            let currentDevice: UIDevice = UIDevice.current
            let orientation: UIDeviceOrientation = currentDevice.orientation
            
            let previewLayerConnection : AVCaptureConnection = connection
            
            if (previewLayerConnection.isVideoOrientationSupported)
            {
                switch (orientation)
                {
                case .portrait:
                    previewLayerConnection.videoOrientation = AVCaptureVideoOrientation.portrait
                    break
                case .landscapeRight:
                    previewLayerConnection.videoOrientation = AVCaptureVideoOrientation.landscapeLeft
                    break
                case .landscapeLeft:
                    previewLayerConnection.videoOrientation = AVCaptureVideoOrientation.landscapeRight
                    break
                case .portraitUpsideDown:
                    previewLayerConnection.videoOrientation = AVCaptureVideoOrientation.portraitUpsideDown
                    break
                default:
                    previewLayerConnection.videoOrientation = AVCaptureVideoOrientation.portrait
                    break
                }
            }
        }
        
    }

    func autoUpdateLensPosition() {
        self.lensPosition += 0.01
        if self.lensPosition > 1 {
            self.lensPosition = 0
        }
        if let device = self.captureDevice {
            do {
                try device.lockForConfiguration()
                device.setFocusModeLockedWithLensPosition(self.lensPosition, completionHandler: nil)
                device.unlockForConfiguration()
            } catch _ {
            }
        }
        if captureSession.isRunning {
            let when = DispatchTime.now() + Double(Int64(10 * Double(USEC_PER_SEC))) / Double(NSEC_PER_SEC)
            DispatchQueue.main.asyncAfter(deadline: when, execute: {
                self.autoUpdateLensPosition()
            })
        }
    }
    
    func onTap(_ gesture: UITapGestureRecognizer) {
        let tapPoint = gesture.location(in: self.cameraView)
        let focusPoint = CGPoint(
            x: tapPoint.x / self.cameraView!.bounds.size.width,
            y: tapPoint.y / self.cameraView!.bounds.size.height)
        
        if let device = self.captureDevice {
            do {
                try device.lockForConfiguration()
                if device.isFocusPointOfInterestSupported {
                    device.focusPointOfInterest = focusPoint
                } else {
                    print("Focus point of interest not supported.")
                }
                if self.isFocusMode {
                    if device.isFocusModeSupported(.locked) {
                        device.focusMode = .locked
                    } else {
                        print("Locked focus not supported.")
                    }
                    if !self.isAutoUpdateLensPosition {
                        self.isAutoUpdateLensPosition = true
                        DispatchQueue.main.async(execute: { () -> Void in
                            self.autoUpdateLensPosition()
                        })
                    }
                } else {
                    if device.isFocusModeSupported(.continuousAutoFocus) {
                        device.focusMode = .continuousAutoFocus
                    } else if device.isFocusModeSupported(.autoFocus) {
                        device.focusMode = .autoFocus
                    } else {
                        print("Auto focus not supported.")
                    }
                }
                if device.isAutoFocusRangeRestrictionSupported {
                    device.autoFocusRangeRestriction = .none
                } else {
                    print("Auto focus range restriction not supported.")
                }
                device.unlockForConfiguration()
                self.focusMarkLayer.point = tapPoint
            } catch _ {
            }
        }
    }
    
    open func enableTorchMode(with level: Float) {
        for testedDevice in AVCaptureDevice.devices(withMediaType: AVMediaTypeVideo){
            if ((testedDevice as AnyObject).position == AVCaptureDevicePosition.back && self.cameraPosition == .back) {
                let currentDevice = testedDevice as! AVCaptureDevice
                if currentDevice.isTorchAvailable && currentDevice.isTorchModeSupported(AVCaptureTorchMode.auto) {
                    do {
                        try currentDevice.lockForConfiguration()
                        if currentDevice.isTorchActive {
                            currentDevice.torchMode = AVCaptureTorchMode.off
                        } else {
                            try currentDevice.setTorchModeOnWithLevel(level)
                        }
                        currentDevice.unlockForConfiguration()
                    } catch {
                        print("torch can not be enable")
                    }
                }
            }
        }
    }
    
    func getImage(croppedWith rect: CGRect? = nil, completionHandler: @escaping (UIImage?, Error?) -> Void){
        
        var image : UIImage?
        if let videoConnection = stillImageOutput?.connection(withMediaType: AVMediaTypeVideo) {
            stillImageOutput?.captureStillImageAsynchronously(from: videoConnection) {
                (imageDataSampleBuffer, error) -> Void in
                if imageDataSampleBuffer != nil {
                    let imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(imageDataSampleBuffer)
                    
                    // The image returned in initialImageData will be larger than what
                    //  is shown in the AVCaptureVideoPreviewLayer, so we need to crop it.
                    image = UIImage(data: imageData!)!
                    
                    let originalSize : CGSize
                    
                    if rect != nil {
                        // Calculate the fractional size that is shown in the preview
                        if let metaRect : CGRect = (self.previewLayer?.metadataOutputRectOfInterest(for: rect!)) {
                            if (image!.imageOrientation == UIImageOrientation.left || image!.imageOrientation == UIImageOrientation.right) {
                                // For these images (which are portrait), swap the size of the
                                // image, because here the output image is actually rotated
                                // relative to what you see on screen.
                                originalSize = CGSize(width: image!.size.height, height: image!.size.width)
                            }
                            else {
                                originalSize = image!.size
                            }
                            
                            let x = metaRect.origin.x * originalSize.width
                            let y = metaRect.origin.y * originalSize.height
                            // metaRect is fractional, that's why we multiply here.
                            let cropRect : CGRect = CGRect( x: x,
                                                            y: y,
                                                            width: metaRect.size.width * originalSize.width,
                                                            height: metaRect.size.height * originalSize.height).integral
                            
                            //getting the device orientation to change the final image orientation
                            let imageOrientation : UIImageOrientation?
                            let currentDevice: UIDevice = UIDevice.current
                            let orientation: UIDeviceOrientation = currentDevice.orientation
                            if self.cameraPosition == .back {
                                switch (orientation) {
                                case .portrait:
                                    imageOrientation = .right
                                case .portraitUpsideDown:
                                    imageOrientation = .left
                                case .landscapeRight:
                                    imageOrientation = .down
                                case .landscapeLeft:
                                    imageOrientation = .up
                                default:
                                    imageOrientation = .right
                                    break
                                }
                            } else {
                                switch (orientation) {
                                case .portrait:
                                    imageOrientation = .leftMirrored
                                case .portraitUpsideDown:
                                    imageOrientation = .rightMirrored
                                case .landscapeRight:
                                    imageOrientation = .upMirrored
                                case .landscapeLeft:
                                    imageOrientation = .downMirrored
                                default:
                                    imageOrientation = .leftMirrored
                                    break
                                }
                            }
                            
                            image =
                                UIImage(cgImage: image!.cgImage!.cropping(to: cropRect)!,
                                        scale:1,
                                        orientation: imageOrientation! )
                            
                        }
                        //save the original and cropped image in gallery
                        //                        UIImageWriteToSavedPhotosAlbum(capturedImage, nil, nil, nil)
                        //                        if croppedImage != nil {
                        //                            UIImageWriteToSavedPhotosAlbum(croppedImage!, nil, nil, nil)
                        //                        }
                    }

                }
                OperationQueue.main.addOperation {
                    completionHandler(image, error)
                }
            }
        }

        
    }
    
    /**
     this func will setup the camera and capture session and add to cameraView
     */
    fileprivate func captureSetup (withDevicePosition position : AVCaptureDevicePosition) {
        
        captureSession.stopRunning()
        captureSession = AVCaptureSession()
        previewLayer?.removeFromSuperlayer()
        
        var captureError : NSError?
        
        //Device
        for testedDevice in AVCaptureDevice.devices(withMediaType: AVMediaTypeVideo){
            if ((testedDevice as AnyObject).position == position) {
                captureDevice = testedDevice as! AVCaptureDevice
            }
        }
        if (captureDevice == nil) {
            captureDevice = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo)
        }
        
        //Input
        var deviceInput : AVCaptureDeviceInput?
        do {
            deviceInput = try AVCaptureDeviceInput(device: captureDevice)
        } catch let error as NSError {
            captureError = error
            deviceInput = nil
            print("you dont have camera")
            return
        }
        
        //Output
        metaDataOutput = AVCaptureMetadataOutput()
        
        // Remove previous added inputs from session

        if self.metaDataOutput?.metadataObjectsDelegate == nil
            || self.metaDataOutput?.metadataObjectsCallbackQueue == nil {
            let queue = DispatchQueue(label: "com.pdq.rsbarcodes.metadata", attributes: DispatchQueue.Attributes.concurrent)
            self.metaDataOutput?.setMetadataObjectsDelegate(self, queue: queue)
        }
        
        // Remove previous added outputs from session
        var metadataObjectTypes: [AnyObject]?
        for output in self.captureSession.outputs {
            metadataObjectTypes = (output as AnyObject).metadataObjectTypes as [AnyObject]?
            self.captureSession.removeOutput(output as! AVCaptureOutput)
        }

        
        //Output stillImage
        self.stillImageOutput = AVCaptureStillImageOutput()
        self.stillImageOutput?.outputSettings = [AVVideoCodecKey:AVVideoCodecJPEG]
        
        if (captureError == nil) {
            if (captureSession.canAddInput(deviceInput)) {
                captureSession.addInput(deviceInput)
            }
            
            if self.captureSession.canAddOutput(self.metaDataOutput) {
                self.captureSession.addOutput(self.metaDataOutput)
                if let metadataObjectTypes = metadataObjectTypes {
                    self.metaDataOutput?.metadataObjectTypes = metadataObjectTypes
                } else  {
                    self.metaDataOutput?.metadataObjectTypes = self.metaDataOutput?.availableMetadataObjectTypes
                }
            }
            
            if (captureSession.canAddOutput(self.stillImageOutput)) {
                captureSession.addOutput(self.stillImageOutput)
            }
        }
        
        //To get the highest quality of bufferData add below code
        //        captureSession.sessionPreset = AVCaptureSessionPresetPhoto
        
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        if cameraView != nil {
            previewLayer?.frame = cameraView!.bounds
        }
        
        previewLayer?.videoGravity = AVLayerVideoGravityResizeAspectFill
        cameraView?.layer.addSublayer(previewLayer!)
        
        self.focusMarkLayer.frame = self.cameraView!.bounds
        cameraView?.layer.insertSublayer(self.focusMarkLayer, above: self.previewLayer)
        
        self.focusLine.frame = self.cameraView!.bounds
        self.cameraView?.layer.insertSublayer(self.focusLine, above: self.previewLayer)
        
        //to detect orientation of device and to show the AVCapture as the orientation is
        let currentDevice: UIDevice = UIDevice.current
        let orientation: UIDeviceOrientation = currentDevice.orientation
        let previewLayerConnection =  self.previewLayer?.connection
        switch (orientation) {
        case .portrait:
            previewLayerConnection?.videoOrientation = AVCaptureVideoOrientation.portrait
            break
        case .landscapeRight:
            previewLayerConnection?.videoOrientation = AVCaptureVideoOrientation.landscapeLeft
            break
        case .landscapeLeft:
            previewLayerConnection?.videoOrientation = AVCaptureVideoOrientation.landscapeRight
            break
        case .portraitUpsideDown:
            previewLayerConnection?.videoOrientation = AVCaptureVideoOrientation.portraitUpsideDown
            break
        default:
            previewLayerConnection?.videoOrientation = AVCaptureVideoOrientation.portrait
            break
        }
        
        self.captureSession.startRunning()
        
    }
    
    
    
    public func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputMetadataObjects metadataObjects: [Any]!, from connection: AVCaptureConnection!) {
        
        if !isBusy {
            isBusy = true
            var barcodeObjects : Array<AVMetadataMachineReadableCodeObject> = []
            var corners = [[Any]]()
            for metadataObject in metadataObjects {
                if let videoPreviewLayer = self.previewLayer {
                    if let transformedMetadataObject = videoPreviewLayer.transformedMetadataObject(for: metadataObject as! AVMetadataObject) {
                        if transformedMetadataObject.isKind(of: AVMetadataMachineReadableCodeObject.self) {
                            let barcodeObject = transformedMetadataObject as! AVMetadataMachineReadableCodeObject
                            barcodeObjects.append(barcodeObject)
                            corners.append(barcodeObject.corners)
                        }
                    }
                }
            }
            self.focusLine.corners = corners
            
            if barcodeObjects.count > 0 {
                self.getImage(completionHandler: { (image, error) in
                    self.delegate?.scanBarcodeCameraManagerDidRecognizeBarcode(barcode: barcodeObjects, image: image)
                    self.isBusy = false
                    self.focusLine.corners = []
                })
            }
        }
    }
}
