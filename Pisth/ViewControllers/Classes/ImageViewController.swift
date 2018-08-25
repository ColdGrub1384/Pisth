// This source file is part of the https://github.com/ColdGrub1384/Pisth open source project
//
// Copyright (c) 2017 - 2018 Adrian Labbé
// Licensed under Apache License v2.0
//
// See https://raw.githubusercontent.com/ColdGrub1384/Pisth/master/LICENSE for license information

import UIKit

/// View controller used to view an image.
class ImageViewController: UIViewController, UIScrollViewDelegate {
    
    /// Dismiss this View controller.
    ///
    /// - Parameters:
    ///     - sender: Sender object.
    @IBAction func close(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    /// Scroll view used to zoom image.
    @IBOutlet weak var scrollView: UIScrollView!
    
    /// Image view displaying opened image.
    @IBOutlet weak var imageView: UIImageView!
    
    /// Image to display.
    var image: UIImage?
    
    // MARK: View Controller
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let image = image {
            imageView.image = image
        }
        
        // Enable image zooming
        scrollView.delegate = self
        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = 10.0
        scrollView.zoomScale = 1.0
    }
    
    // MARK: Scroll view delegate

    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
}
