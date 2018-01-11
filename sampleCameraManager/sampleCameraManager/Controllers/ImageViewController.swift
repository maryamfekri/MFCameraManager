//
//  ReadabilityViewController.swift
//  CaptureCard
//
//  Created by Fekri on 12/11/16.
//  Copyright © 2016 MF. All rights reserved.
//

import UIKit

class ImageViewController: UIViewController {

    @IBOutlet weak var caprturesImageView: UIImageView!
    var image: UIImage?

    override func viewDidLoad() {
        super.viewDidLoad()

        initView()
    }
}

// MARK: - InitView
extension ImageViewController {
    func initView() {

        if self.image != nil {
            self.caprturesImageView.image = self.image
        }
    }
}
