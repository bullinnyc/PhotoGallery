//
//  GalleryContainerViewController.swift
//  Gallery
//
//  Created by Dmitry Kononchuk on 23.06.2022.
//

import UIKit

protocol GalleryContainerViewControllerDelegate: AnyObject {
    func containerViewController(_ viewController: GalleryContainerViewController, indexDidUpdate currentIndex: Int)
}

class GalleryContainerViewController: UIViewController {
    // MARK: - Enums
    enum ScreenMode {
        case full, normal
    }
    
    // MARK: - Override Properties
    override var prefersStatusBarHidden: Bool {
        hideStatusBar
    }
    
    // MARK: - Public Properties
    var images: [UIImage]!
    var currentIndex = 0
    let transitionController = ZoomTransition()
    
    weak var delegate: GalleryContainerViewControllerDelegate!
    
    // MARK: - Private Properties
    private var currentMode: ScreenMode = .normal
    private var nextIndex: Int?
    
    private var hideStatusBar: Bool = false {
        didSet {
            setNeedsStatusBarAppearanceUpdate()
        }
    }
    
    private var pageViewController: UIPageViewController {
        return children.first as! UIPageViewController
    }
    
    private var currentViewController: ZoomViewController {
        return pageViewController.viewControllers?.first as! ZoomViewController
    }
    
    lazy var singleTapGesture: UITapGestureRecognizer = {
        let singleTapGesture = UITapGestureRecognizer(
            target: self,
            action: #selector(didSingleTapWith)
        )
        
        singleTapGesture.require(toFail: currentViewController.zoomingTapGesture)
        return singleTapGesture
    }()
    
    lazy var panGesture: UIPanGestureRecognizer = {
        let panGesture = UIPanGestureRecognizer(
            target: self,
            action: #selector(didPanWith)
        )
        
        panGesture.delegate = self
        return panGesture
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
    
    // MARK: - Private Methods
    private func setupUI() {
        title = "Photo"
        
        guard let zoomViewController = getZoomViewController() else { return }
        
        zoomViewController.delegate = self
        zoomViewController.index = currentIndex
        zoomViewController.image = images[currentIndex]
        
        pageViewController.delegate = self
        pageViewController.dataSource = self
        pageViewController.setViewControllers(
            [zoomViewController],
            direction: .forward,
            animated: true
        )
        
        pageViewController.view.addGestureRecognizer(singleTapGesture)
        pageViewController.view.addGestureRecognizer(panGesture)
    }
    
    private func getZoomViewController() -> ZoomViewController? {
        guard let zoomViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(
            withIdentifier: "\(ZoomViewController.self)"
        ) as? ZoomViewController else { return nil }
        
        return zoomViewController
    }
    
    private func changeScreenMode(to: ScreenMode) {
        if to == .full {
            navigationController?.isNavigationBarHidden = true
            hideStatusBar = true
            view.backgroundColor = .black
        } else {
            navigationController?.isNavigationBarHidden = false
            hideStatusBar = false
            view.backgroundColor = .systemBackground
        }
    }
    
    @objc private func didSingleTapWith(_ gestureRecognizer: UITapGestureRecognizer) {
        if currentMode == .full {
            changeScreenMode(to: .normal)
            currentMode = .normal
        } else {
            changeScreenMode(to: .full)
            currentMode = .full
        }
    }
    
    @objc private func didPanWith(_ gestureRecognizer: UIPanGestureRecognizer) {
        switch gestureRecognizer.state {
        case .began:
            currentViewController.scrollView.isScrollEnabled = false
            transitionController.isInteractive = true
            navigationController?.popViewController(animated: true)
        case .ended:
            if transitionController.isInteractive {
                currentViewController.scrollView.isScrollEnabled = true
                transitionController.isInteractive = false
                transitionController.didPanWith(gestureRecognizer: gestureRecognizer)
            }
        default:
            if transitionController.isInteractive {
                transitionController.didPanWith(gestureRecognizer: gestureRecognizer)
            }
        }
    }
}

// MARK: - Ext. UIPageViewControllerDataSource
extension GalleryContainerViewController: UIPageViewControllerDataSource {
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        if currentIndex == 0 { return nil }
        
        guard let zoomViewController = getZoomViewController() else { return nil }
        
        zoomViewController.delegate = self
        zoomViewController.image = images[currentIndex - 1]
        zoomViewController.index = currentIndex - 1
        
        singleTapGesture.require(toFail: zoomViewController.zoomingTapGesture)
        return zoomViewController
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        if currentIndex == images.count - 1 { return nil }
        
        guard let zoomViewController = getZoomViewController() else { return nil }
        
        zoomViewController.delegate = self
        zoomViewController.image = images[currentIndex + 1]
        zoomViewController.index = currentIndex + 1
        
        singleTapGesture.require(toFail: zoomViewController.zoomingTapGesture)
        return zoomViewController
    }
}

// MARK: - Ext. UIPageViewControllerDelegate
extension GalleryContainerViewController: UIPageViewControllerDelegate {
    func pageViewController(_ pageViewController: UIPageViewController, willTransitionTo pendingViewControllers: [UIViewController]) {
        guard let nextViewController = pendingViewControllers.first as? ZoomViewController else { return }
        nextIndex = nextViewController.index
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        if completed, nextIndex != nil {
            previousViewControllers.forEach { viewController in
                guard let zoomViewController = viewController as? ZoomViewController else { return }
                zoomViewController.scrollView.zoomScale = zoomViewController.scrollView.minimumZoomScale
            }
            
            currentIndex = nextIndex ?? 0
            delegate.containerViewController(self, indexDidUpdate: currentIndex)
        }
        
        nextIndex = nil
    }
}

// MARK: - Ext. UIGestureRecognizerDelegate
extension GalleryContainerViewController: UIGestureRecognizerDelegate {
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if let gestureRecognizer = gestureRecognizer as? UIPanGestureRecognizer {
            let velocity = gestureRecognizer.velocity(in: view)
            var velocityCheck = false
            
            if UIDevice.current.orientation.isLandscape {
                velocityCheck = velocity.x < 0
            } else {
                velocityCheck = velocity.y < 0
            }
            
            if velocityCheck {
                return false
            }
        }
        
        return true
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if otherGestureRecognizer == currentViewController.scrollView.panGestureRecognizer {
            if currentViewController.scrollView.contentOffset.y == 0 {
                return true
            }
        }
        
        return false
    }
}

// MARK: - Ext. ZoomViewControllerDelegate
extension GalleryContainerViewController: ZoomViewControllerDelegate {
    func zoomViewController(_ zoomViewController: ZoomViewController, scrollViewDidScroll scrollView: UIScrollView) {
        if scrollView.zoomScale != scrollView.minimumZoomScale && currentMode != .full {
            changeScreenMode(to: .full)
            currentMode = .full
        }
    }
}

// MARK: - Ext. ZoomAnimatorDelegate
extension GalleryContainerViewController: ZoomAnimatorDelegate {
    func transitionWillStartWith(zoomAnimator: ZoomAnimator) {
        // Before the transition animation
    }
    
    func transitionDidEndWith(zoomAnimator: ZoomAnimator) {
        // After the transition animation
    }
    
    func referenceImageView(for zoomAnimator: ZoomAnimator) -> UIImageView? {
        return currentViewController.imageView
    }
    
    func referenceImageViewFrameInTransitioningView(for zoomAnimator: ZoomAnimator) -> CGRect? {
        return currentViewController.scrollView.convert(
            currentViewController.imageView.frame,
            to: currentViewController.view
        )
    }
}
