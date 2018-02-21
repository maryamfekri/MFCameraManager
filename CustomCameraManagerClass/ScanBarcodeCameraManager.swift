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

open class ScanBarcodeCameraManager: NSObject, AVCaptureMetadataOutputObjectsDelegate {

    private var cameraPosition: CameraDevice?
    private var cameraView: UIView?
    weak private var previewLayer: AVCaptureVideoPreviewLayer!

    //Private variables that cannot be accessed by other classes in any way.
    fileprivate var metaDataOutput: AVCaptureMetadataOutput?
    fileprivate var stillImageOutput: AVCaptureStillImageOutput?
    fileprivate var captureSession: AVCaptureSession!

    weak var delegate: ScanBarcodeCameraManagerDelegate?
    private var captureDevice: AVCaptureDevice!
    private var isFocusMode = false
    private var isAutoUpdateLensPosition = false
    private var lensPosition: Float = 0
    private var isBusy = false

    private var focusMarkLayer = FocusMarker()
    private var focusLine = FocusLine()

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

    open func startRunning() {
        if captureSession?.isRunning != true {
            captureSession.startRunning()
        }
    }

    open func stopRunning() {
        if captureSession?.isRunning == true {
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

    func autoUpdateLensPosition() {
        self.lensPosition += 0.01
        if self.lensPosition > 1 {
            self.lensPosition = 0
        }
        if let device = self.captureDevice {
            do {
                try device.lockForConfiguration()
                device.setFocusModeLocked(lensPosition: self.lensPosition, completionHandler: nil)
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

    @objc func onTap(_ gesture: UITapGestureRecognizer) {
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
        for testedDevice in AVCaptureDevice.devices(for: AVMediaType.video) {
            if (testedDevice as AnyObject).position == AVCaptureDevice.Position.back
                && self.cameraPosition == .back {
                let currentDevice = testedDevice
                if currentDevice.isTorchAvailable
                    && currentDevice.isTorchModeSupported(AVCaptureDevice.TorchMode.auto) {
                    do {
                        try currentDevice.lockForConfiguration()
                        if currentDevice.isTorchActive {
                            currentDevice.torchMode = AVCaptureDevice.TorchMode.off
                        } else {
                            try currentDevice.setTorchModeOn(level: level)
                        }
                        currentDevice.unlockForConfiguration()
                    } catch {
                        print("torch can not be enable")
                    }
                }
            }
        }
    }

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

    private func crop(image: UIImage, withRect rect: CGRect) throws -> UIImage {
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

    open func captureSetup(in cameraView: UIView, with cameraPosition: AVCaptureDevice.Position? = .back) throws {
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

        let tapGestureRecognizer = UITapGestureRecognizer(target: self,
                                                          action: #selector(ScanBarcodeCameraManager.onTap(_:)))
        self.cameraView?.addGestureRecognizer(tapGestureRecognizer)
    }

    private func getDevice(withPosition position: AVCaptureDevice.Position) throws -> AVCaptureDevice {
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

    /**
     this func will setup the camera and capture session and add to cameraView
     */
    fileprivate func captureSetup(withDevicePosition position: AVCaptureDevice.Position) throws {

        captureSession.stopRunning()
        captureSession = AVCaptureSession()
        previewLayer?.removeFromSuperlayer()

        // device
        let captureDevice: AVCaptureDevice = try getDevice(withPosition: position)
        //Input
        let deviceInput = try AVCaptureDeviceInput(device: captureDevice)

        //Output
        metaDataOutput = AVCaptureMetadataOutput()

        // Remove previous added inputs from session
        if self.metaDataOutput?.metadataObjectsDelegate == nil
            || self.metaDataOutput?.metadataObjectsCallbackQueue == nil {
            let queue = DispatchQueue(label: "com.pdq.rsbarcodes.metadata",
                                      attributes: .concurrent)
            self.metaDataOutput?.setMetadataObjectsDelegate(self, queue: queue)
        }

        // Remove previous added outputs from session
        var metadataObjectTypes: [AnyObject]?
        for output in self.captureSession.outputs {
            metadataObjectTypes = (output as AnyObject).metadataObjectTypes as [AnyObject]?
            self.captureSession.removeOutput(output )
        }

        //Output stillImage
        self.stillImageOutput = AVCaptureStillImageOutput()
        self.stillImageOutput?.outputSettings = [AVVideoCodecKey: AVVideoCodecJPEG]

            if captureSession.canAddInput(deviceInput) {
                captureSession.addInput(deviceInput)
            }

            if self.captureSession.canAddOutput(self.metaDataOutput!) {
                self.captureSession.addOutput(self.metaDataOutput!)
                if let metadataObjectTypes = metadataObjectTypes as? [AVMetadataObject.ObjectType] {
                    self.metaDataOutput?.metadataObjectTypes = metadataObjectTypes
                } else {
                    self.metaDataOutput?.metadataObjectTypes = self.metaDataOutput?.availableMetadataObjectTypes
                }
            }

            if captureSession.canAddOutput(self.stillImageOutput!) {
                captureSession.addOutput(self.stillImageOutput!)
            }

        //To get the highest quality of bufferData add below code
        //        captureSession.sessionPreset = AVCaptureSessionPresetPhoto

        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        if let cameraView = cameraView {
            previewLayer?.frame = cameraView.bounds
        }

        previewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
        cameraView?.layer.addSublayer(previewLayer)

        focusMarkLayer.frame = self.cameraView?.bounds ?? .zero
        cameraView?.layer.insertSublayer(self.focusMarkLayer, above: self.previewLayer)

        self.focusLine.frame = self.cameraView?.bounds ?? .zero
        self.cameraView?.layer.insertSublayer(self.focusLine, above: self.previewLayer)

        //to detect orientation of device and to show the AVCapture as the orientation is
        previewLayer.connection?.videoOrientation = UIDevice.current.orientation.avCaptureVideoOrientation
        self.captureSession.startRunning()

    }

    public func metadataOutput(_ captureOutput: AVCaptureMetadataOutput,
                               didOutput metadataObjects: [AVMetadataObject],
                               from connection: AVCaptureConnection) {

        if !isBusy {
            isBusy = true
            var barcodeObjects = [AVMetadataMachineReadableCodeObject]()
            var corners = [[Any]]()
            for metadataObject in metadataObjects {
                if let videoPreviewLayer = self.previewLayer {
                    if let transformedMetadataObject = videoPreviewLayer
                        .transformedMetadataObject(for: metadataObject ) {
                        if let barcodeObject = transformedMetadataObject as? AVMetadataMachineReadableCodeObject {
                            barcodeObjects.append(barcodeObject)
                            corners.append(barcodeObject.corners)
                        }
                    }
                }
            }
            self.focusLine.corners = corners

            if !barcodeObjects.isEmpty {
                self.getImage { (image, _) in
                    self.delegate?.scanBarcodeCameraManagerDidRecognizeBarcode(barcode: barcodeObjects, image: image)
                    self.isBusy = false
                    self.focusLine.corners = []
                }
            }
        }
    }
}
