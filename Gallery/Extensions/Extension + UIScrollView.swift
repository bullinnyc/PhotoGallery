//
//  Extension + UIScrollView.swift
//  Gallery
//
//  Created by Dmitry Kononchuk on 07.08.2022.
//

import UIKit

extension UIScrollView {
    // MARK: - Public Properties
    func scrollToBottom(animated: Bool) {
        let bottomOffset = CGPoint(
            x: 0,
            y: contentSize.height - bounds.size.height + contentInset.bottom
        )
        
        setContentOffset(bottomOffset, animated: animated)
    }
}
