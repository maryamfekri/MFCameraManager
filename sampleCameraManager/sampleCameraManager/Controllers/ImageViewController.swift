//
//  ReadabilityViewController.swift
//  CaptureCard
//
//  Created by Fekri on 12/11/16.
//  Copyright © 2016 MF. All rights reserved.
//

import UIKit

class ImageViewController: UIViewController {

    //=================
    // MARK: - Variables
    //=================
    var image: UIImage?

    //===============
    // MARK: Outlets
    //===============
    @IBOutlet weak var caprturesImageView: UIImageView!

}

extension ImageViewController {

    //=================
    // MARK: - Overrides
    //=================
    override func viewDidLoad() {
        super.viewDidLoad()
        initView()
    }

}

extension ImageViewController {

    //================
    // MARK: - Methods
    //================
    func initView() {
        caprturesImageView.image = image
    }
}
