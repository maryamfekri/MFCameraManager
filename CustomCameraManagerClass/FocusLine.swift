//
//  FocusLine.swift
//  sampleCameraManager
//
//  Created by Maryam on 3/3/17.
//  Copyright © 2017 Maryam. All rights reserved.
//

import UIKit

class FocusLine: CALayer {

    open var strokeColor = UIColor.yellow.cgColor
    open var strokeWidth: CGFloat = 1
    open var drawingCornersArray = [[CGPoint]]()
    open var corners = [[Any]]() {
        willSet {
            DispatchQueue.main.async(execute: {
                self.setNeedsDisplay()
            })
        }
    }

    override open func draw(in ctx: CGContext) {
        objc_sync_enter(self)

        ctx.saveGState()

        ctx.setShouldAntialias(true)
        ctx.setAllowsAntialiasing(true)
        ctx.setFillColor(UIColor.clear.cgColor)
        ctx.setStrokeColor(self.strokeColor)
        ctx.setLineWidth(self.strokeWidth)

        for corners in self.corners {
            for i in 0...corners.count {
                var idx = i
                if i == corners.count {
                    idx = 0
                }

                if let dict = corners[idx] as? NSDictionary,
                    let rawXPosition = dict.object(forKey: "X") as? NSNumber,
                    let rawYPosition = dict.object(forKey: "Y") as? NSNumber {
                    let x = CGFloat(truncating: rawXPosition)
                    let y = CGFloat(truncating: rawYPosition)
                    if i == 0 {
                        ctx.move(to: CGPoint(x: x, y: y))
                    } else {
                        ctx.addLine(to: CGPoint(x: x, y: y))
                    }
                }
            }
        }

        ctx.drawPath(using: CGPathDrawingMode.fillStroke)

        ctx.restoreGState()

        objc_sync_exit(self)
    }
}
