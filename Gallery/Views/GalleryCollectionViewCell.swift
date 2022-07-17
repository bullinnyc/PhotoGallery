//
//  GalleryCollectionViewCell.swift
//  Gallery
//
//  Created by Dmitry Kononchuk on 23.06.2022.
//

import UIKit
import Photos

class GalleryCollectionViewCell: UICollectionViewCell {
    // MARK: - IB Outlets
    @IBOutlet weak var imageView: UIImageView!
    
    // MARK: - Public Properties
    var asset: PHAsset? {
        didSet {
            setImage(image: nil, fromAsset: asset)
        }
    }
    
    // MARK: - Public Methods
    func setImage(image: UIImage?, fromAsset: PHAsset?) {
        guard let asset = self.asset, let fromAsset = fromAsset else {
            imageView.image = nil
            return
        }
        
        guard asset.localIdentifier == fromAsset.localIdentifier else { return }
        imageView.image = image
    }
}
