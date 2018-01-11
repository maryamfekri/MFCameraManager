//
//  CameraManager.swift
//  Maryam Fekri
//
//  Created by Fekri on 12/28/16.
//  Copyright © 2016 Maryam Fekri. All rights reserved.
//

import Foundation
import AVFoundation
import UIKit

public typealias MFCameraMangerCompletion = (UIImage?, Error?) -> Void

/// manage camera session
open class CameraManager: NSObject {

    // MARK: - Private Variables
    /// cameera device position
    private var cameraPosition: CameraDevice?
    /// camera UIView
    private var cameraView: UIView?
    /// preview layer for camera
    weak private var previewLayer: AVCaptureVideoPreviewLayer?

    //Private variables that cannot be accessed by other classes in any way.
    /// view data output
    fileprivate var stillImageOutput: AVCaptureStillImageOutput?
    /// camera session
    fileprivate var captureSession: AVCaptureSession!

    // MARK: - Actions

    /**
     Setup the camera preview.
     - Parameter in:   UIView which camera preview will show on that.Actions
     - Parameter withPosition: a AVCaptureDevicePosition which is camera device position which default is back
     
     */
    open func captureSetup(in cameraView: UIView, withPosition cameraPosition: AVCaptureDevice.Position? = .back) {
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
    }

    /**
     Start Running the camera session.
     */
    open func startRunning() {
        if captureSession?.isRunning != true {
            captureSession.startRunning()
        }
    }

    /**
     Stop the camera session.
     */
    open func stopRunning() {
        if captureSession?.isRunning == true {
            captureSession.stopRunning()
        }
    }

    /**
     Update frame of camera preview
     */
    open func updatePreviewFrame() {
        if cameraView != nil {
            self.previewLayer?.frame = cameraView!.bounds
        }
    }

    /**
     change orientation of the camera when view is transitioning
     */
    open func transitionCamera() {
        if let connection =  self.previewLayer?.connection {
            let currentDevice: UIDevice = UIDevice.current
            let orientation: UIDeviceOrientation = currentDevice.orientation

            let previewLayerConnection: AVCaptureConnection = connection

            if previewLayerConnection.isVideoOrientationSupported {
                switch orientation {
                case .portrait:
                    previewLayerConnection.videoOrientation = AVCaptureVideoOrientation.portrait
                case .landscapeRight:
                    previewLayerConnection.videoOrientation = AVCaptureVideoOrientation.landscapeLeft
                case .landscapeLeft:
                    previewLayerConnection.videoOrientation = AVCaptureVideoOrientation.landscapeRight
                case .portraitUpsideDown:
                    previewLayerConnection.videoOrientation = AVCaptureVideoOrientation.portraitUpsideDown
                default:
                    previewLayerConnection.videoOrientation = AVCaptureVideoOrientation.portrait
                }
            }
        }

    }

    /**
     Switch on torch mode for camera if its using the back camera
     - Parameter level:   level for torch
     
     */
    open func enableTorchMode(level: Float? = 1) {
        for testedDevice in AVCaptureDevice.devices(for: AVMediaType.video) {
            if (testedDevice as AnyObject).position == AVCaptureDevice.Position.back
                && self.cameraPosition == .back {
                let currentDevice = testedDevice
                if currentDevice.isTorchAvailable &&
                    currentDevice.isTorchModeSupported(AVCaptureDevice.TorchMode.auto) {
                    do {
                        try currentDevice.lockForConfiguration()
                        if currentDevice.isTorchActive {
                            currentDevice.torchMode = AVCaptureDevice.TorchMode.off
                        } else {
                            try currentDevice.setTorchModeOn(level: level!)
                        }
                        currentDevice.unlockForConfiguration()
                    } catch {
                        print("torch can not be enable")
                    }
                }
            }
        }
    }

    /// Get Image of the preview camera
    ///
    /// - Parameters:
    ///   - rect: CGRect to cropp the image inside it.
    ///   - completionHandler: block code which has the UIImage
    ///     and any error of getting image out of data representation.
    open func getImage(croppWith rect: CGRect? = nil,
                       completion: @escaping MFCameraMangerCompletion) {

        var croppedImage: UIImage?
        if let videoConnection = stillImageOutput?.connection(with: AVMediaType.video) {
            stillImageOutput?
                .captureStillImageAsynchronously(from: videoConnection) { (imageDataSampleBuffer, error) -> Void in
                    if imageDataSampleBuffer != nil {
                        let imageData = AVCaptureStillImageOutput
                            .jpegStillImageNSDataRepresentation(imageDataSampleBuffer!)

                        // The image returned in initialImageData will be larger than what
                        //  is shown in the AVCaptureVideoPreviewLayer, so we need to crop it.
                        let capturedImage: UIImage = UIImage(data: imageData!)!

                        let originalSize: CGSize
                        // THE ACTUAL VISIBLE AREA IN THE LAYER FRAME
                        let visibleLayerFrame = rect ?? self.cameraView?.frame
                            ?? CGRect.zero

                        // Calculate the fractional size that is shown in the preview
                        if let metaRect = self.previewLayer?
                            .metadataOutputRectConverted(fromLayerRect: visibleLayerFrame) {
                            if capturedImage.imageOrientation == UIImageOrientation.left
                                || capturedImage.imageOrientation == UIImageOrientation.right {
                                // For these images (which are portrait), swap the size of the
                                // image, because here the output image is actually rotated
                                // relative to what you see on screen.
                                originalSize = CGSize(width: capturedImage.size.height,
                                                      height: capturedImage.size.width)
                            } else {
                                originalSize = capturedImage.size
                            }

                            let x = metaRect.origin.x * originalSize.width
                            let y = metaRect.origin.y * originalSize.height
                            // metaRect is fractional, that's why we multiply here.
                            let cropRect: CGRect = CGRect( x: x,
                                                           y: y,
                                                           width: metaRect.size.width * originalSize.width,
                                                           height: metaRect.size.height * originalSize.height).integral

                            //getting the device orientation to change the final image orientation
                            let imageOrientation: UIImageOrientation?
                            let currentDevice: UIDevice = UIDevice.current
                            let orientation: UIDeviceOrientation = currentDevice.orientation
                            if self.cameraPosition == .back {
                                switch orientation {
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
                                }
                            } else {
                                switch orientation {
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
                                }
                            }

                            croppedImage =
                                UIImage(cgImage: capturedImage.cgImage!.cropping(to: cropRect)!,
                                        scale: 1,
                                        orientation: imageOrientation! )

                            //save the original and cropped image in gallery
                            //                        UIImageWriteToSavedPhotosAlbum(capturedImage, nil, nil, nil)
                            //                        if croppedImage != nil {
                            //                            UIImageWriteToSavedPhotosAlbum(croppedImage!, nil, nil, nil)
                            //                        }
                        }
                    }
                    completion(croppedImage, error)
            }
        }

    }

    /**
     this func will setup the camera and capture session and add to cameraView
     - Parameter withDevicePosition:   AVCaptureDevicePosition which is the position of camera
     
     */
    fileprivate func captureSetup (withDevicePosition position: AVCaptureDevice.Position) {

        captureSession.stopRunning()
        captureSession = AVCaptureSession()
        previewLayer?.removeFromSuperlayer()

        var captureError: NSError?
        var captureDevice: AVCaptureDevice!

        //Device
        for testedDevice in AVCaptureDevice.devices(for: AVMediaType.video)
            where (testedDevice as AnyObject).position == position {
                captureDevice = testedDevice
        }
        if captureDevice == nil {
            captureDevice = AVCaptureDevice.default(for: AVMediaType.video)
        }

        //Input
        var deviceInput: AVCaptureDeviceInput?
        do {
            deviceInput = try AVCaptureDeviceInput(device: captureDevice)
        } catch let error as NSError {
            captureError = error
            deviceInput = nil
            print("you dont have camera")
            return
        }

        //Output
        self.stillImageOutput = AVCaptureStillImageOutput()
        self.stillImageOutput?.outputSettings = [AVVideoCodecKey: AVVideoCodecJPEG]

        if captureError == nil {
            if captureSession.canAddInput(deviceInput!) {
                captureSession.addInput(deviceInput!)
            }

            if captureSession.canAddOutput(self.stillImageOutput!) {
                captureSession.addOutput(self.stillImageOutput!)
            }
        }

        //To get the highest quality of bufferData add below code
        //        captureSession.sessionPreset = AVCaptureSessionPresetPhoto

        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        if cameraView != nil {
            previewLayer?.frame = cameraView!.bounds
        }

        previewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
        cameraView?.layer.addSublayer(previewLayer!)

        //to detect orientation of device and to show the AVCapture as the orientation is
        let currentDevice: UIDevice = UIDevice.current
        let orientation: UIDeviceOrientation = currentDevice.orientation
        let previewLayerConnection =  self.previewLayer?.connection
        switch orientation {
        case .portrait:
            previewLayerConnection?.videoOrientation = AVCaptureVideoOrientation.portrait
        case .landscapeRight:
            previewLayerConnection?.videoOrientation = AVCaptureVideoOrientation.landscapeLeft
        case .landscapeLeft:
            previewLayerConnection?.videoOrientation = AVCaptureVideoOrientation.landscapeRight
        case .portraitUpsideDown:
            previewLayerConnection?.videoOrientation = AVCaptureVideoOrientation.portraitUpsideDown
        default:
            previewLayerConnection?.videoOrientation = AVCaptureVideoOrientation.portrait
        }

        self.captureSession.startRunning()

    }

}
