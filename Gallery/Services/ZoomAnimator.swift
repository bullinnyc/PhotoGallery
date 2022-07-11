//
//  ZoomAnimator.swift
//  Gallery
//
//  Created by Dmitry Kononchuk on 23.06.2022.
//

import UIKit

protocol ZoomAnimatorDelegate: AnyObject {
    func transitionWillStartWith(zoomAnimator: ZoomAnimator)
    func transitionDidEndWith(zoomAnimator: ZoomAnimator)
    func referenceImageView(for zoomAnimator: ZoomAnimator) -> UIImageView?
    func referenceImageViewFrameInTransitioningView(for zoomAnimator: ZoomAnimator) -> CGRect?
}

class ZoomAnimator: NSObject {
    // MARK: - Public Properties
    var transitionImageView: UIImageView?
    var isPresenting = true
    
    weak var fromDelegate: ZoomAnimatorDelegate!
    weak var toDelegate: ZoomAnimatorDelegate!
    
    // MARK: - Deinitializers
    deinit {
        print("**** DEINIT: \(self)")
    }
    
    // MARK: - Private Methods
    private func animateZoomInTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let containerView = transitionContext.containerView
        
        guard let toViewController = transitionContext.viewController(forKey: .to),
              let fromViewController = transitionContext.viewController(forKey: .from),
              let fromReferenceImageView = fromDelegate.referenceImageView(for: self),
              let toReferenceImageView = toDelegate.referenceImageView(for: self),
              let fromReferenceImageViewFrame = fromDelegate.referenceImageViewFrameInTransitioningView(for: self)
        else { return }
        
        fromDelegate.transitionWillStartWith(zoomAnimator: self)
        toDelegate.transitionWillStartWith(zoomAnimator: self)
        
        toViewController.view.alpha = 0
        toReferenceImageView.isHidden = true
        containerView.addSubview(toViewController.view)
        
        guard let referenceImage = fromReferenceImageView.image else { return }
        
        if transitionImageView == nil {
            let transitionImageView = UIImageView(image: referenceImage)
            transitionImageView.contentMode = .scaleAspectFill
            transitionImageView.clipsToBounds = true
            transitionImageView.frame = fromReferenceImageViewFrame
            containerView.addSubview(transitionImageView)
            
            self.transitionImageView = transitionImageView
        }
        
        fromReferenceImageView.isHidden = true
        
        let finalTransitionSize = calculateZoomInImageFrame(
            image: referenceImage,
            forView: toViewController.view
        )
        
        UIView.animate(
            withDuration: transitionDuration(using: transitionContext),
            delay: 0,
            usingSpringWithDamping: 0.8,
            initialSpringVelocity: 0,
            options: [UIView.AnimationOptions.transitionCrossDissolve],
            animations: {
                self.transitionImageView?.frame = finalTransitionSize
                toViewController.view.alpha = 1
                fromViewController.tabBarController?.tabBar.alpha = 0
            },
            completion: { _ in
                self.transitionImageView?.removeFromSuperview()
                toReferenceImageView.isHidden = false
                fromReferenceImageView.isHidden = false
                
                self.transitionImageView = nil
                
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
                self.toDelegate.transitionDidEndWith(zoomAnimator: self)
                self.fromDelegate.transitionDidEndWith(zoomAnimator: self)
            }
        )
    }
    
    private func animateZoomOutTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let containerView = transitionContext.containerView
        
        guard let toViewController = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.to),
              let fromViewController = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.from),
              let fromReferenceImageView = fromDelegate.referenceImageView(for: self),
              let toReferenceImageView = toDelegate.referenceImageView(for: self),
              let fromReferenceImageViewFrame = fromDelegate.referenceImageViewFrameInTransitioningView(for: self),
              let toReferenceImageViewFrame = toDelegate.referenceImageViewFrameInTransitioningView(for: self)
        else { return }
        
        fromDelegate.transitionWillStartWith(zoomAnimator: self)
        toDelegate.transitionWillStartWith(zoomAnimator: self)
        
        toReferenceImageView.isHidden = true
        
        let referenceImage = fromReferenceImageView.image
        
        if transitionImageView == nil {
            let transitionImageView = UIImageView(image: referenceImage)
            transitionImageView.contentMode = .scaleAspectFill
            transitionImageView.clipsToBounds = true
            transitionImageView.frame = fromReferenceImageViewFrame
            containerView.addSubview(transitionImageView)
            
            self.transitionImageView = transitionImageView
        }
        
        containerView.insertSubview(
            toViewController.view,
            belowSubview: fromViewController.view
        )
        
        fromReferenceImageView.isHidden = true
        
        let finalTransitionSize = toReferenceImageViewFrame
        
        UIView.animate(
            withDuration: transitionDuration(using: transitionContext),
            delay: 0,
            options: [],
            animations: {
                fromViewController.view.alpha = 0
                self.transitionImageView?.frame = finalTransitionSize
                toViewController.tabBarController?.tabBar.alpha = 1
            },
            completion: { _ in
                self.transitionImageView?.removeFromSuperview()
                toReferenceImageView.isHidden = false
                fromReferenceImageView.isHidden = false
                
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
                self.toDelegate.transitionDidEndWith(zoomAnimator: self)
                self.fromDelegate.transitionDidEndWith(zoomAnimator: self)
            }
        )
    }
    
    private func calculateZoomInImageFrame(image: UIImage, forView view: UIView) -> CGRect {
        let viewRatio = view.frame.size.width / view.frame.size.height
        let imageRatio = image.size.width / image.size.height
        let touchesSides = (imageRatio > viewRatio)
        
        if touchesSides {
            let height = view.frame.width / imageRatio
            let yPoint = view.frame.minY + (view.frame.height - height) * 0.5
            return CGRect(x: 0, y: yPoint, width: view.frame.width, height: height)
        } else {
            let width = view.frame.height * imageRatio
            let xPoint = view.frame.minX + (view.frame.width - width) * 0.5
            return CGRect(x: xPoint, y: 0, width: width, height: view.frame.height)
        }
    }
}

// MARK: - Ext. UIViewControllerAnimatedTransitioning
extension ZoomAnimator: UIViewControllerAnimatedTransitioning {
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        if isPresenting {
            return 0.5
        } else {
            return 0.25
        }
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        if isPresenting {
            animateZoomInTransition(using: transitionContext)
        } else {
            animateZoomOutTransition(using: transitionContext)
        }
    }
}
