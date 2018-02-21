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
    /// getting the device orientation to change the final image orientation
    private var imageOrientation: UIImageOrientation {
        let currentDevice: UIDevice = UIDevice.current
        let orientation: UIDeviceOrientation = currentDevice.orientation
        if self.cameraPosition == .back {
            switch orientation {
            case .portrait:
                return .right
            case .portraitUpsideDown:
                return .left
            case .landscapeRight:
                return .down
            case .landscapeLeft:
                return .up
            default:
                return .right
            }
        } else {
            switch orientation {
            case .portrait:
                return .leftMirrored
            case .portraitUpsideDown:
                return .rightMirrored
            case .landscapeRight:
                return .upMirrored
            case .landscapeLeft:
                return .downMirrored
            default:
                return .leftMirrored
            }
        }
    }
    /// camera device position
    private var cameraPosition: CameraDevice = .back
    /// camera UIView
    private var cameraView: UIView?
    /// preview layer for camera
    weak private var previewLayer: AVCaptureVideoPreviewLayer!

    //Private variables that cannot be accessed by other classes in any way.
    /// view data output
    fileprivate var stillImageOutput: AVCaptureStillImageOutput!
    /// camera session
    fileprivate var captureSession: AVCaptureSession!

    // MARK: - Actions

    /**
     Setup the camera preview.
     - Parameter in:   UIView which camera preview will show on that.Actions
     - Parameter withPosition: a AVCaptureDevicePosition which is camera device position which default is back
     
     */
    open func captureSetup(in cameraView: UIView,
                           withPosition cameraPosition: AVCaptureDevice.Position? = .back) throws {
        self.cameraView = cameraView
        self.captureSession = AVCaptureSession()
        switch cameraPosition! {
        case .back:
            try captureSetup(withDevicePosition: .back)
            self.cameraPosition = .back
        case .front:
            try captureSetup(withDevicePosition: .front)
            self.cameraPosition = .front
        default:
            try captureSetup(withDevicePosition: .back)
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
        guard let videoConnection = stillImageOutput?.connection(with: .video) else {
            completion(nil, MFCameraError.noVideoConnection)
            return
        }

        stillImageOutput?
            .captureStillImageAsynchronously(from: videoConnection) { (imageDataSampleBuffer, error) -> Void in
                guard let imageDataSampleBuffer = imageDataSampleBuffer,
                    let imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(imageDataSampleBuffer),
                    let capturedImage: UIImage = UIImage(data: imageData) else {
                        completion(nil, MFCameraError.noImageCapture)
                        return
                }
                // The image returned in initialImageData will be larger than what
                //  is shown in the AVCaptureVideoPreviewLayer, so we need to crop it.
                do {
                    let croppedImage = try self.crop(image: capturedImage,
                                                     withRect: rect ?? self.cameraView?.frame ?? .zero)
                    completion(croppedImage, error)
                } catch {
                    completion(nil, error)
                }
        }
    }

    func crop(image: UIImage, withRect rect: CGRect) throws -> UIImage {
        let originalSize: CGSize
        // Calculate the fractional size that is shown in the preview
        guard let metaRect = previewLayer?.metadataOutputRectConverted(fromLayerRect: rect) else {
            throw MFCameraError.noMetaRect
        }
        if image.imageOrientation == UIImageOrientation.left
            || image.imageOrientation == UIImageOrientation.right {
            // For these images (which are portrait), swap the size of the
            // image, because here the output image is actually rotated
            // relative to what you see on screen.
            originalSize = CGSize(width: image.size.height,
                                  height: image.size.width)
        } else {
            originalSize = image.size
        }

        let x = metaRect.origin.x * originalSize.width
        let y = metaRect.origin.y * originalSize.height
        // metaRect is fractional, that's why we multiply here.
        let cropRect: CGRect = CGRect( x: x,
                                       y: y,
                                       width: metaRect.size.width * originalSize.width,
                                       height: metaRect.size.height * originalSize.height).integral
        guard let cropedCGImage = image.cgImage?.cropping(to: cropRect) else {
            throw MFCameraError.crop
        }

        return  UIImage(cgImage: cropedCGImage,
                        scale: 1,
                        orientation: imageOrientation)
    }

    /**
     this func will setup the camera and capture session and add to cameraView
     - Parameter withDevicePosition:   AVCaptureDevicePosition which is the position of camera
     
     */

    fileprivate func getDevice(withPosition position: AVCaptureDevice.Position) throws -> AVCaptureDevice {
        if #available(iOS 10.0, *) {
            guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position) else {
                throw MFCameraError.noDevice
            }
            return device
        } else {
            guard let device = AVCaptureDevice
                .devices(for: .video)
                .first(where: {device in
                    device.position == position
                }) else {
                    throw MFCameraError.noDevice
            }
            return device
        }
    }

    fileprivate func captureSetup (withDevicePosition position: AVCaptureDevice.Position) throws {

        captureSession.stopRunning()
        captureSession = AVCaptureSession()
        previewLayer?.removeFromSuperlayer()

        // device
        let captureDevice: AVCaptureDevice = try getDevice(withPosition: position)
        //Input
        let deviceInput = try AVCaptureDeviceInput(device: captureDevice)

        //Output
        stillImageOutput = AVCaptureStillImageOutput()
        stillImageOutput.outputSettings = [AVVideoCodecKey: AVVideoCodecJPEG]
        if captureSession.canAddInput(deviceInput) {
            captureSession.addInput(deviceInput)
        }

        if captureSession.canAddOutput(stillImageOutput) {
            captureSession.addOutput(stillImageOutput)
        }

        //To get the highest quality of bufferData add below code
        //        captureSession.sessionPreset = AVCaptureSessionPresetPhoto

        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        if let cameraView = cameraView {
            previewLayer?.frame = cameraView.bounds
        }

        previewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
        cameraView?.layer.addSublayer(previewLayer)

        //to detect orientation of device and to show the AVCapture as the orientation is
        previewLayer.connection?.videoOrientation = UIDevice.current.orientation.avCaptureVideoOrientation
        self.captureSession.startRunning()

    }

}
