//
//  ScanBarcodeCameraManagerDelegate.swift
//  sampleCameraManager
//
//  Created by Mohammad Ali Jafarian on 1/11/18.
//  Copyright © 2018 Maryam. All rights reserved.
//

import UIKit
import AVFoundation

public protocol ScanBarcodeCameraManagerDelegate: class {

    /// barcode recognize delegate function
    ///
    /// - Parameters:
    ///   - barcode: barcode object
    ///   - image: image which barcode object is fetched from
    func scanBarcodeCameraManagerDidRecognizeBarcode(barcode: [AVMetadataMachineReadableCodeObject], image: UIImage?)
}
