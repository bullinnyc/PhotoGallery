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
    private var backgroundAnimation: UIViewPropertyAnimator?
    
    // MARK: - Deinitializers
    deinit {
        print("**** DEINIT: \(self)")
    }
    
    // MARK: - Public Methods
    func didPanWith(gestureRecognizer: UIPanGestureRecognizer) {
        guard let transitionContext = transitionContext,
              let animator = animator as? ZoomAnimator,
              let transitionImageView = animator.transitionImageView,
              let fromReferenceImageView = animator.fromDelegate.referenceImageView(for: animator),
              let toReferenceImageView = animator.toDelegate.referenceImageView(for: animator),
              let backgroundAnimation = backgroundAnimation
        else { return }
        
        fromReferenceImageView.isHidden = true
        toReferenceImageView.isHidden = true
        
        let translation = gestureRecognizer.translation(in: nil)
        let translationVertical = translation.y
        let percentageComplete = percentageComplete(forVerticalDrag: translationVertical)
        let transitionImageScale = transitionImageScaleFor(percentageComplete: percentageComplete)
        
        switch gestureRecognizer.state {
        case .possible, .began:
            break
        case .cancelled, .failed:
            completeTransition(didCancel: true)
        case .changed:
            transitionImageView.transform = .identity
                .scaledBy(x: transitionImageScale, y: transitionImageScale)
                .translatedBy(x: translation.x, y: translation.y)
            
            transitionContext.updateInteractiveTransition(percentageComplete)
            backgroundAnimation.fractionComplete = percentageComplete
        case .ended:
            let shouldComplete = percentageComplete > 0.1
            completeTransition(didCancel: !shouldComplete)
        default:
            break
        }
    }
    
    // MARK: - Private Methods
    private func completeTransition(didCancel: Bool) {
        guard let transitionContext = transitionContext,
              let animator = self.animator as? ZoomAnimator,
              let transitionImageView = animator.transitionImageView,
              let fromReferenceImageView = animator.fromDelegate.referenceImageView(for: animator),
              let toReferenceImageView = animator.toDelegate.referenceImageView(for: animator),
              let fromReferenceImageViewFrame = self.fromReferenceImageViewFrame,
              let toReferenceImageViewFrame = self.toReferenceImageViewFrame,
              let backgroundAnimation = backgroundAnimation
        else { return }
        
        backgroundAnimation.isReversed = didCancel
        
        let completionDuration: Double
        let completionDamping: CGFloat
        
        if didCancel {
            completionDuration = 0.5
            completionDamping = 0.9
        } else {
            completionDuration = 0.25
            completionDamping = 0.9
        }
        
        let foregroundAnimation = UIViewPropertyAnimator(
            duration: completionDuration,
            dampingRatio: completionDamping
        ) {
            if didCancel {
                transitionImageView.frame = fromReferenceImageViewFrame
            } else {
                transitionImageView.frame = animator.toDelegate.referenceImageViewFrameInTransitioningView(
                    for: animator
                ) ?? toReferenceImageViewFrame
            }
        }
        
        foregroundAnimation.addCompletion { _ in
            toReferenceImageView.isHidden = false
            fromReferenceImageView.isHidden = false
            transitionImageView.removeFromSuperview()
            animator.transitionImageView = nil
            animator.toDelegate.transitionDidEndWith(zoomAnimator: animator)
            animator.fromDelegate.transitionDidEndWith(zoomAnimator: animator)
            
            if didCancel {
                transitionContext.cancelInteractiveTransition()
            } else {
                transitionContext.finishInteractiveTransition()
            }
            
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            self.transitionContext = nil
        }
        
        let durationFactor = CGFloat(foregroundAnimation.duration / backgroundAnimation.duration)
        
        backgroundAnimation.continueAnimation(
            withTimingParameters: nil,
            durationFactor: durationFactor
        )
        
        foregroundAnimation.startAnimation()
    }
    
    /// Percentage complete for the transition for a given vertical offset.
    /// 0pts -> 0%,  20pts -> 10%, 100pts -> 50%, 200pts -> 100%.
    private func percentageComplete(forVerticalDrag verticalDrag: CGFloat) -> CGFloat {
        let maximumDelta: CGFloat = 200
        return scaleAndShift(
            value: verticalDrag,
            inRange: (min: 0, max: maximumDelta)
        )
    }
    
    /// The transition image scales down from 100% to a minimum of 68%,
    /// based on the percentage-complete of the gesture.
    private func transitionImageScaleFor(percentageComplete: CGFloat) -> CGFloat {
        let minScale: CGFloat = 0.68
        let result = 1 - (1 - minScale) * percentageComplete
        return result
    }
    
    /// Returns the value, scaled-and-shifted to the targetRange.
    /// If no target range is provided, we assume the unit range (0, 1).
    private func scaleAndShift(value: CGFloat, inRange: (min: CGFloat, max: CGFloat), toRange: (min: CGFloat, max: CGFloat) = (min: 0, max: 1)) -> CGFloat {
        assert(inRange.max > inRange.min)
        assert(toRange.max > toRange.min)
        
        if value < inRange.min {
            return toRange.min
        } else if value > inRange.max {
            return toRange.max
        } else {
            let ratio = (value - inRange.min) / (inRange.max - inRange.min)
            return toRange.min + ratio * (toRange.max - toRange.min)
        }
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
        
        containerView.insertSubview(
            toViewController.view,
            belowSubview: fromViewController.view
        )
        
        guard let referenceImage = fromReferenceImageView.image else { return }
        
        if animator.transitionImageView == nil {
            let transitionImageView = animator.getTransitionImageView(
                image: referenceImage,
                frame: fromReferenceImageViewFrame
            )
            
            containerView.addSubview(transitionImageView)
            animator.transitionImageView = transitionImageView
        }
        
        let animation = UIViewPropertyAnimator(
            duration: 0.5,
            dampingRatio: 1,
            animations: {
                fromViewController.view.alpha = 0
                toViewController.tabBarController?.tabBar.alpha = 1
            }
        )
        
        backgroundAnimation = animation
    }
}
