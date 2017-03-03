//
//  ScanBarcodeViewController.swift
//  sampleCameraManager
//
//  Created by Maryam on 3/3/17.
//  Copyright © 2017 Maryam. All rights reserved.
//

import UIKit
import AVFoundation

class ScanBarcodeViewController: UIViewController {

    @IBOutlet weak var cameraView: UIView!
    
    var scanBarcodeCameraManager = ScanBarcodeCameraManager()
    
    let maskLayer = CALayer()
    let rectLayer = CAShapeLayer()
    var rectPath = UIBezierPath()
    let useFrontTextLayer = CATextLayer()
    let tapHereToCaptureTextLayer = CATextLayer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        scanBarcodeCameraManager.startRunning()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        scanBarcodeCameraManager.stopRunning()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        navigationController?.interactivePopGestureRecognizer?.isEnabled = true
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        scanBarcodeCameraManager.transitionCamera()
    }
    
    override func viewDidLayoutSubviews() {
        self.scanBarcodeCameraManager.updatePreviewFrame()
        drawOverRectView()
    }
    
    /**
     this func will draw a rect mask over the camera view
     */
    func drawOverRectView() {
        
        cameraView.layer.mask = nil
        
        let cameraSize = self.cameraView!.frame.size
        
        /// to calculate the height of frame based on screen size
        var frameHeight: CGFloat = 0.0
        /// to calculate the width of frame based on screen size
        var frameWidth: CGFloat =  0.0
        /// to calculate position Y of recFrame to be in center of cameraView
        var originY: CGFloat = 0.0
        /// to calculate position X of recFrame to be in center of cameraView
        var originX: CGFloat = 0.0
        
        let currentDevice: UIDevice = UIDevice.current
        let orientation: UIDeviceOrientation = currentDevice.orientation
        
        // calculatin position and frame of rectFrame based on screen size
        switch (orientation) {
        case .landscapeRight, .landscapeLeft:
            frameHeight = (cameraSize.height)/1.4
            frameWidth = cameraSize.width/1.5
            originY = ((cameraSize.height - frameHeight)/2)
            originX = (cameraSize.width - frameWidth)/2
            break
        default:
            //if it is faceUp or portrait or any other orientation
            frameHeight = (cameraSize.height)/1.5
            frameWidth = cameraSize.width/1.15
            originY = ((cameraSize.height - frameHeight)/2)
            originX = (cameraSize.width - frameWidth)/2
            break
        }
        
        //create a rect shape layer
        rectLayer.frame = CGRect(x: originX, y: originY, width: frameWidth, height: frameHeight)
        
        //create a beizier path for a rounded rectangle
        rectPath = UIBezierPath(roundedRect: CGRect(x: 0, y: 0, width: frameWidth, height: frameHeight), cornerRadius: 10)
        
        //add beizier to rect shapelayer
        rectLayer.path = rectPath.cgPath
        rectLayer.fillColor = UIColor.black.cgColor
        rectLayer.strokeColor = UIColor.white.cgColor
        
        //add shapelayer to layer
        maskLayer.frame = cameraView.bounds
        maskLayer.backgroundColor = UIColor(red: 0/255, green: 0/255, blue: 0/255, alpha: 0.5).cgColor
        maskLayer.addSublayer(rectLayer)
        
        //add layer mask to camera view
        cameraView.layer.mask = maskLayer
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let identifier = segue.identifier, identifier == "CameraView2ImageView" {
            (segue.destination as? ImageViewController)?.image = sender as? UIImage
        }
    }
    

    
}

// MARK: - InitView
extension ScanBarcodeViewController: ScanBarcodeCameraManagerDelegate {
    func initView() {
        
        self.scanBarcodeCameraManager.delegate = self
        scanBarcodeCameraManager.captureSetup(in: self.cameraView, with: .back)
        
    }
    
    func scanBarcodeCameraManagerDidRecognizeBarcode(barcode: Array<AVMetadataMachineReadableCodeObject>, image: UIImage?) {
        self.scanBarcodeCameraManager.stopRunning()
        print(barcode)
//        self.performSegue(withIdentifier: "CameraView2ImageView", sender: image)
        scanBarcodeCameraManager.startRunning()

    }
}


