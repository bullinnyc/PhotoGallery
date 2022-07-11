//
//  ZoomViewController.swift
//  Gallery
//
//  Created by Dmitry Kononchuk on 24.06.2022.
//

import UIKit

protocol ZoomViewControllerDelegate: AnyObject {
    func zoomViewController(_ zoomViewController: ZoomViewController, scrollViewDidScroll scrollView: UIScrollView)
}

class ZoomViewController: UIViewController {
    // MARK: - IB Outlets
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var imageViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var imageViewLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var imageViewTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var imageViewTrailingConstraint: NSLayoutConstraint!
    
    // MARK: - Public Properties
    var image: UIImage!
    var index = 0
    
    weak var delegate: ZoomViewControllerDelegate!
    
    lazy var zoomingTapGesture: UITapGestureRecognizer = {
        let zoomingTap = UITapGestureRecognizer(
            target: self,
            action: #selector(didDoubleTapWith)
        )
        
        zoomingTap.numberOfTapsRequired = 2
        return zoomingTap
    }()
    
    // MARK: - Deinitializers
    deinit {
        print("**** DEINIT: \(self)")
    }
    
    // MARK: - Override Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
    }
    
    override func viewDidLayoutSubviews() {
        updateZoomScaleForSize(view.bounds.size)
    }
    
    // MARK: - Private Methods
    private func setupUI() {
        scrollView.delegate = self
        scrollView.contentInsetAdjustmentBehavior = .never
        
        imageView.image = image
        imageView.frame = CGRect(
            x: imageView.frame.origin.x,
            y: imageView.frame.origin.y,
            width: image.size.width,
            height: image.size.height
        )
        
        imageView.addGestureRecognizer(zoomingTapGesture)
        imageView.isUserInteractionEnabled = true
    }
    
    private func updateZoomScaleForSize(_ size: CGSize) {
        let currentZoomScale = scrollView.zoomScale
        let isZoomActive = currentZoomScale != scrollView.minimumZoomScale
        let widthScale = size.width / imageView.bounds.width
        let heightScale = size.height / imageView.bounds.height
        let minScale = min(widthScale, heightScale)
        let maxZooming: CGFloat = 4 // Set max zooming
        
        scrollView.minimumZoomScale = minScale
        scrollView.zoomScale = isZoomActive ? currentZoomScale : minScale
        
        if !isZoomActive {
            scrollView.maximumZoomScale = minScale * maxZooming
        }
    }
    
    private func updateConstraintsForSize(_ size: CGSize) {
        let yOffset = max(0, (size.height - imageView.frame.height) * 0.5)
        imageViewTopConstraint.constant = yOffset
        imageViewBottomConstraint.constant = yOffset

        let xOffset = max(0, (size.width - imageView.frame.width) * 0.5)
        imageViewLeadingConstraint.constant = xOffset
        imageViewTrailingConstraint.constant = xOffset

        let contentHeight = yOffset * 2 + imageView.frame.height
        view.layoutIfNeeded()
        scrollView.contentSize = CGSize(
            width: scrollView.contentSize.width,
            height: contentHeight
        )
    }
    
    @objc private func didDoubleTapWith(_ gestureRecognizer: UITapGestureRecognizer) {
        let pointInView = gestureRecognizer.location(in: imageView)
        var newZoomScale = scrollView.maximumZoomScale
        
        if scrollView.zoomScale >= newZoomScale || abs(scrollView.zoomScale - newZoomScale) <= 0.01 {
            newZoomScale = scrollView.minimumZoomScale
        }
        
        let width = scrollView.bounds.width / newZoomScale
        let height = scrollView.bounds.height / newZoomScale
        let originX = pointInView.x - width * 0.5
        let originY = pointInView.y - height * 0.5
        let rectToZoomTo = CGRect(x: originX, y: originY, width: width, height: height)
        
        scrollView.zoom(to: rectToZoomTo, animated: true)
    }
}

// MARK: - Ext. UIScrollViewDelegate
extension ZoomViewController: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        updateConstraintsForSize(view.bounds.size)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        delegate.zoomViewController(self, scrollViewDidScroll: scrollView)
    }
}
