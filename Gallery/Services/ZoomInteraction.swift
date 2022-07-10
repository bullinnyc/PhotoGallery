//
//  ZoomInteraction.swift
//  Gallery
//
//  Created by Dmitry Kononchuk on 24.06.2022.
//

import UIKit

class ZoomInteraction: NSObject {
    // MARK: - Public Properties
    var animator: UIViewControllerAnimatedTransitioning?
    
    // MARK: - Private Properties
    private var transitionContext: UIViewControllerContextTransitioning?
    private var fromReferenceImageViewFrame: CGRect?
    private var toReferenceImageViewFrame: CGRect?
    
    // MARK: - Deinitializers
    deinit {
        print("**** DEINIT: \(self)")
    }
    
    // MARK: - Public Methods
    func didPanWith(gestureRecognizer: UIPanGestureRecognizer) {
        guard let transitionContext = transitionContext,
              let animator = animator as? ZoomAnimator,
              let transitionImageView = animator.transitionImageView,
              let fromViewController = transitionContext.viewController(forKey: .from),
              let toViewController = transitionContext.viewController(forKey: .to),
              let fromReferenceImageView = animator.fromDelegate.referenceImageView(for: animator),
              let toReferenceImageView = animator.toDelegate.referenceImageView(for: animator),
              let fromReferenceImageViewFrame = fromReferenceImageViewFrame,
              let toReferenceImageViewFrame = toReferenceImageViewFrame
        else { return }
        
        fromReferenceImageView.isHidden = true
        
        let anchorPoint = CGPoint(
            x: fromReferenceImageViewFrame.midX,
            y: fromReferenceImageViewFrame.midY
        )
        
        let translatedPoint = gestureRecognizer.translation(in: fromReferenceImageView)
        let verticalDelta: CGFloat = translatedPoint.y < 0
        ? 0
        : translatedPoint.y
        
        let backgroundAlpha = backgroundAlphaFor(
            view: fromViewController.view,
            withPanningVerticalDelta: verticalDelta
        )
        
        let scale = scaleFor(
            view: fromViewController.view,
            withPanningVerticalDelta: verticalDelta
        )
        
        fromViewController.view.alpha = backgroundAlpha
        transitionImageView.transform = CGAffineTransform(scaleX: scale, y: scale)
        
        let newCenter = CGPoint(
            x: anchorPoint.x + translatedPoint.x,
            y: anchorPoint.y + translatedPoint.y - transitionImageView.frame.height * (1 - scale) * 0.5
        )
        
        transitionImageView.center = newCenter
        toReferenceImageView.isHidden = true
        transitionContext.updateInteractiveTransition(1 - scale)
        toViewController.tabBarController?.tabBar.alpha = 1 - backgroundAlpha
        
        if gestureRecognizer.state == .ended {
            // Cancel animation
            let velocity = gestureRecognizer.velocity(in: fromViewController.view)
            
            if velocity.y < 0 || newCenter.y < anchorPoint.y {
                UIView.animate(
                    withDuration: 0.5,
                    delay: 0,
                    usingSpringWithDamping: 0.9,
                    initialSpringVelocity: 0,
                    options: [],
                    animations: {
                        transitionImageView.frame = fromReferenceImageViewFrame
                        fromViewController.view.alpha = 1
                        toViewController.tabBarController?.tabBar.alpha = 0
                    },
                    completion: { _ in
                        toReferenceImageView.isHidden = false
                        fromReferenceImageView.isHidden = false
                        transitionImageView.removeFromSuperview()
                        animator.transitionImageView = nil
                        transitionContext.cancelInteractiveTransition()
                        transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
                        animator.toDelegate.transitionDidEndWith(zoomAnimator: animator)
                        animator.fromDelegate.transitionDidEndWith(zoomAnimator: animator)
                        self.transitionContext = nil
                    }
                )
                
                return
            }
            
            // Start animation
            let finalTransitionSize = toReferenceImageViewFrame
            
            UIView.animate(
                withDuration: 0.25,
                delay: 0,
                options: [],
                animations: {
                    fromViewController.view.alpha = 0
                    transitionImageView.frame = finalTransitionSize
                    toViewController.tabBarController?.tabBar.alpha = 1
                },
                completion: { _ in
                    transitionImageView.removeFromSuperview()
                    toReferenceImageView.isHidden = false
                    fromReferenceImageView.isHidden = false
                    
                    self.transitionContext?.finishInteractiveTransition()
                    transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
                    animator.toDelegate.transitionDidEndWith(zoomAnimator: animator)
                    animator.fromDelegate.transitionDidEndWith(zoomAnimator: animator)
                    self.transitionContext = nil
                }
            )
        }
    }
    
    private func backgroundAlphaFor(view: UIView, withPanningVerticalDelta verticalDelta: CGFloat) -> CGFloat {
        let startingAlpha: CGFloat = 1
        let finalAlpha: CGFloat = 0
        let totalAvailableAlpha = startingAlpha - finalAlpha
        let maximumDelta = view.bounds.height / 4
        let deltaAsPercentageOfMaximun = min(abs(verticalDelta) / maximumDelta, 1)
        
        return startingAlpha - deltaAsPercentageOfMaximun * totalAvailableAlpha
    }
    
    private func scaleFor(view: UIView, withPanningVerticalDelta verticalDelta: CGFloat) -> CGFloat {
        let startingScale: CGFloat = 1
        let finalScale: CGFloat = 0.5
        let totalAvailableScale = startingScale - finalScale
        let maximumDelta = view.bounds.height * 0.5
        let deltaAsPercentageOfMaximun = min(abs(verticalDelta) / maximumDelta, 1)
        
        return startingScale - deltaAsPercentageOfMaximun * totalAvailableScale
    }
}

// MARK: - Ext. UIViewControllerInteractiveTransitioning
extension ZoomInteraction: UIViewControllerInteractiveTransitioning {
    func startInteractiveTransition(_ transitionContext: UIViewControllerContextTransitioning) {
        self.transitionContext = transitionContext
        
        let containerView = transitionContext.containerView
        
        guard let animator = animator as? ZoomAnimator,
              let fromViewController = transitionContext.viewController(forKey: .from),
              let toViewController = transitionContext.viewController(forKey: .to),
              let fromReferenceImageViewFrame = animator.fromDelegate.referenceImageViewFrameInTransitioningView(for: animator),
              let toReferenceImageViewFrame = animator.toDelegate.referenceImageViewFrameInTransitioningView(for: animator),
              let fromReferenceImageView = animator.fromDelegate.referenceImageView(for: animator)
        else { return }
        
        animator.fromDelegate.transitionWillStartWith(zoomAnimator: animator)
        animator.toDelegate.transitionWillStartWith(zoomAnimator: animator)
        
        self.fromReferenceImageViewFrame = fromReferenceImageViewFrame
        self.toReferenceImageViewFrame = toReferenceImageViewFrame
        
        let referenceImage = fromReferenceImageView.image
        
        containerView.insertSubview(
            toViewController.view,
            belowSubview: fromViewController.view
        )
        
        if animator.transitionImageView == nil {
            let transitionImageView = UIImageView(image: referenceImage)
            transitionImageView.contentMode = .scaleAspectFill
            transitionImageView.clipsToBounds = true
            transitionImageView.frame = fromReferenceImageViewFrame
            animator.transitionImageView = transitionImageView
            containerView.addSubview(transitionImageView)
        }
    }
}
