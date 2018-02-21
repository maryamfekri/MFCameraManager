//
//  UIDeviceOrientationExtension.swift
//  
//
//  Created by Mohammad Ali Jafarian on 21/2/18.
//

import UIKit
import AVFoundation

extension UIDeviceOrientation {
    var avCaptureVideoOrientation: AVCaptureVideoOrientation {
        switch self {
        case .portrait:
            return AVCaptureVideoOrientation.portrait
        case .landscapeRight:
            return AVCaptureVideoOrientation.landscapeLeft
        case .landscapeLeft:
            return AVCaptureVideoOrientation.landscapeRight
        case .portraitUpsideDown:
            return AVCaptureVideoOrientation.portraitUpsideDown
        default:
            return AVCaptureVideoOrientation.portrait
        }
    }
}
