//
//  ZoomTransition.swift
//  Gallery
//
//  Created by Dmitry Kononchuk on 24.06.2022.
//

import UIKit

class ZoomTransition: NSObject {
    // MARK: - Public Properties
    var isInteractive = false
    
    weak var fromDelegate: ZoomAnimatorDelegate!
    weak var toDelegate: ZoomAnimatorDelegate!
    
    // MARK: - Private Properties
    private let animator: ZoomAnimator
    private let interactionController: ZoomInteraction
    
    // MARK: - Initializers
    override init() {
        animator = ZoomAnimator()
        interactionController = ZoomInteraction()
        
        super.init()
    }
    
    // MARK: - Deinitializers
    deinit {
        print("**** DEINIT: \(self)")
    }
    
    // MARK: - Public Methods
    func didPanWith(gestureRecognizer: UIPanGestureRecognizer) {
        interactionController.didPanWith(gestureRecognizer: gestureRecognizer)
    }
}

// MARK: - Ext. UIViewControllerTransitioningDelegate
extension ZoomTransition: UIViewControllerTransitioningDelegate {
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        animator.isPresenting = true
        animator.fromDelegate = fromDelegate
        animator.toDelegate = toDelegate
        return animator
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        animator.isPresenting = false
        
        let tmp = fromDelegate
        
        animator.fromDelegate = toDelegate
        animator.toDelegate = tmp
        return animator
    }
    
    func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        if !isInteractive { return nil }
        
        interactionController.animator = animator
        return interactionController
    }
}

// MARK: - Ext. UINavigationControllerDelegate
extension ZoomTransition: UINavigationControllerDelegate {
    func navigationController(_ navigationController: UINavigationController, animationControllerFor operation: UINavigationController.Operation, from fromVC: UIViewController, to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        if operation == .push {
            animator.isPresenting = true
            animator.fromDelegate = fromDelegate
            animator.toDelegate = toDelegate
        } else {
            animator.isPresenting = false
            
            let tmp = fromDelegate
            
            animator.fromDelegate = toDelegate
            animator.toDelegate = tmp
        }
        
        return animator
    }
    
    func navigationController(_ navigationController: UINavigationController, interactionControllerFor animationController: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        if !isInteractive { return nil }
        
        interactionController.animator = animator
        return interactionController
    }
}
