//
//  Extension + CGSize.swift
//  Gallery
//
//  Created by Dmitry Kononchuk on 17.07.2022.
//

import UIKit

extension CGSize {
    // MARK: - Public Properties
    var pixelSize: CGSize {
        let scale = UIScreen.main.scale
        return CGSize(width: self.width * scale, height: self.height * scale)
    }
}
