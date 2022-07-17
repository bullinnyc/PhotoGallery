//
//  PhotoManager.swift
//  Gallery
//
//  Created by Dmitry Kononchuk on 17.07.2022.
//

import UIKit
import Photos

class PhotoManager {
    // MARK: - Private Properties
    private static let requestOptions: PHImageRequestOptions = {
        let requestOptions = PHImageRequestOptions()
        requestOptions.isSynchronous = true
        return requestOptions
    }()
    
    private static let fetchOptions: PHFetchOptions = {
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [
            NSSortDescriptor(key: "creationDate", ascending: true)
        ]
        
        return fetchOptions
    }()
    
    // MARK: - Public Methods
    static func fetchResult() -> PHFetchResult<PHAsset> {
        let fetchResult = PHAsset.fetchAssets(
            with: .image,
            options: fetchOptions
        )
        
        return fetchResult
    }
    
    static func requestImage(asset: PHAsset, targetSize: CGSize, contentMode: PHImageContentMode, completion: @escaping (UIImage) -> Void) {
        PHImageManager.default().requestImage(
            for: asset,
            targetSize: targetSize,
            contentMode: contentMode,
            options: requestOptions
        ) { image, info in
            guard let image = image else { return }
            completion(image)
        }
    }
    
    static func fetchPhotos(limitedPhotos count: Int = 0, targetSize: CGSize, contentMode: PHImageContentMode, completion: @escaping ([UIImage]) -> Void) {
        var images: [UIImage] = []
        
        let fetchResult = fetchResult()
        
        if count != .zero {
            fetchOptions.fetchLimit = count
        }
        
        let iterationCount = count != .zero
        ? min(fetchResult.count, count)
        : fetchResult.count
        
        for index in 0..<iterationCount {
            PHImageManager.default().requestImage(
                for: fetchResult.object(at: index) as PHAsset,
                targetSize: targetSize,
                contentMode: contentMode,
                options: requestOptions,
                resultHandler: { image, _ in
                    guard let image = image else { return }
                    images.append(image)
                }
            )
        }
        
        completion(images)
    }
}
