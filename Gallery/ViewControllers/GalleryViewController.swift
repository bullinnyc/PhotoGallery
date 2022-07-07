//
//  GalleryViewController.swift
//  Gallery
//
//  Created by Dmitry Kononchuk on 23.06.2022.
//

import UIKit

class GalleryViewController: UIViewController {
    // MARK: - IB Outlets
    @IBOutlet weak var collectionView: UICollectionView!
    
    // MARK: - Public Properties
    var currentLeftSafeAreaInset: CGFloat = 0
    var currentRightSafeAreaInset: CGFloat = 0
    
    // MARK: - Private Properties
    private var images: [UIImage] = []
    private var selectedIndexPath: IndexPath!
    
    private var sectionInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    private var rowsSpacing: CGFloat = 2
    private var horizontalRowsCount: CGFloat {
        if UIDevice.current.orientation.isLandscape { return 5 }
        
        return 3
    }
    
    // MARK: - Deinitializers
    deinit {
        print("**** DEINIT: \(self)")
    }
    
    // MARK: - Override Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        tabBarController?.tabBar.isHidden = false
        navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    override func viewSafeAreaInsetsDidChange() {
        currentLeftSafeAreaInset = view.safeAreaInsets.left
        currentRightSafeAreaInset = view.safeAreaInsets.right
    }
    
    override func viewWillLayoutSubviews() {
        view.frame = CGRect(
            origin: CGPoint(x: 0, y: 0),
            size: view.bounds.size
        )
        
        collectionView.frame = CGRect(
            origin: CGPoint(x: 0, y: 0),
            size: view.bounds.size
        )
        
        collectionView.contentInsetAdjustmentBehavior = .never
        
        let statusBarHeight = view.window?.windowScene?.statusBarManager?.statusBarFrame.height ?? 0
        let navigationBarHeight: CGFloat = navigationController?.navigationBar.frame.height ?? 0
        let tabBarHeight = tabBarController?.tabBar.frame.height ?? 0
        
        if UIDevice.current.orientation.isLandscape {
            collectionView.contentInset = UIEdgeInsets(
                top: (navigationBarHeight) + statusBarHeight,
                left: currentLeftSafeAreaInset,
                bottom: tabBarHeight,
                right: currentRightSafeAreaInset
            )
        } else {
            collectionView.contentInset = UIEdgeInsets(
                top: (navigationBarHeight) + statusBarHeight,
                left: 0,
                bottom: tabBarHeight,
                right: 0
            )
        }
    }
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ShowGalleryContainerView" {
            guard let containerViewController = segue.destination as? GalleryContainerViewController else { return }
            
            navigationController?.delegate = containerViewController.transitionController
            containerViewController.transitionController.fromDelegate = self
            containerViewController.transitionController.toDelegate = containerViewController
            containerViewController.delegate = self
            containerViewController.currentIndex = selectedIndexPath.row
            containerViewController.images = images
        }
    }
    
    // MARK: - Private Methods
    private func setupUI() {
        for _ in 0..<8 {
            images.append(UIImage(named: "Moscow")!)
            images.append(UIImage(named: "NewYork")!)
        }
    }
}

// MARK: - Ext. UICollectionViewDataSource
extension GalleryViewController: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return images.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: "\(GalleryCollectionViewCell.self)",
            for: indexPath
        ) as? GalleryCollectionViewCell else { fatalError() }
        
        cell.imageView.image = images[indexPath.row]
        return cell
    }
}

// MARK: - Ext. UICollectionViewDelegate
extension GalleryViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        selectedIndexPath = indexPath
        performSegue(withIdentifier: "ShowGalleryContainerView", sender: self)
    }
}

// MARK: - Ext. UICollectionViewDelegateFlowLayout
extension GalleryViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let itemPadding = max(0, horizontalRowsCount - 1) * rowsSpacing
        let availableWidth = collectionView.bounds.width - itemPadding - sectionInsets.left - sectionInsets.right
        let widthPerItem = availableWidth / horizontalRowsCount
        let heightPerItem = widthPerItem
        
        return CGSize(width: widthPerItem, height: heightPerItem)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(
            top: sectionInsets.top,
            left: sectionInsets.left,
            bottom: sectionInsets.bottom,
            right: sectionInsets.right
        )
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return rowsSpacing
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return rowsSpacing
    }
}

// MARK: - Ext. GalleryContainerViewControllerDelegate
extension GalleryViewController: GalleryContainerViewControllerDelegate {
    func containerViewController(_ containerViewController: GalleryContainerViewController, indexDidUpdate currentIndex: Int) {
        selectedIndexPath = IndexPath(row: currentIndex, section: 0)
        collectionView.scrollToItem(
            at: selectedIndexPath,
            at: .centeredVertically,
            animated: false
        )
    }
}

// MARK: - Ext. ZoomAnimatorDelegate
extension GalleryViewController: ZoomAnimatorDelegate {
    func transitionWillStartWith(zoomAnimator: ZoomAnimator) {
        // Before the transition animation
    }
    
    func transitionDidEndWith(zoomAnimator: ZoomAnimator) {
        // After the transition animation
        guard let cell = collectionView.cellForItem(at: selectedIndexPath) as? GalleryCollectionViewCell else { return }
        
        let cellFrame = collectionView.convert(cell.frame, to: view)
        
        if cellFrame.minY < collectionView.contentInset.top {
            collectionView.scrollToItem(
                at: selectedIndexPath,
                at: .top,
                animated: false
            )
        } else if cellFrame.maxY > view.frame.height - collectionView.contentInset.bottom {
            collectionView.scrollToItem(
                at: selectedIndexPath,
                at: .bottom,
                animated: false
            )
        }
    }
    
    func referenceImageView(for zoomAnimator: ZoomAnimator) -> UIImageView? {
        let referenceImageView = getImageViewFromCollectionViewCell(for: selectedIndexPath)
        return referenceImageView
    }
    
    func referenceImageViewFrameInTransitioningView(for zoomAnimator: ZoomAnimator) -> CGRect? {
        view.layoutIfNeeded()
        collectionView.layoutIfNeeded()
        
        let unconvertedFrame = getFrameFromCollectionViewCell(for: selectedIndexPath)
        let cellFrame = collectionView.convert(unconvertedFrame, to: view)
        
        if cellFrame.minY < collectionView.contentInset.top {
            return CGRect(
                x: cellFrame.minX,
                y: collectionView.contentInset.top,
                width: cellFrame.width,
                height: cellFrame.height - (collectionView.contentInset.top - cellFrame.minY)
            )
        }
        
        return cellFrame
    }
    
    private func getImageViewFromCollectionViewCell(for selectedIndexPath: IndexPath) -> UIImageView {
        let visibleCells = collectionView.indexPathsForVisibleItems
        
        if !visibleCells.contains(selectedIndexPath) {
            collectionView.scrollToItem(
                at: selectedIndexPath,
                at: .centeredVertically,
                animated: false
            )
            
            collectionView.reloadItems(at: collectionView.indexPathsForVisibleItems)
            collectionView.layoutIfNeeded()
            
            guard let cell = collectionView.cellForItem(at: selectedIndexPath) as? GalleryCollectionViewCell else {
                return UIImageView(
                    frame: CGRect(
                        x: UIScreen.main.bounds.midX,
                        y: UIScreen.main.bounds.midY,
                        width: 100,
                        height: 100
                    )
                )
            }
            
            return cell.imageView
        } else {
            guard let cell = collectionView.cellForItem(at: selectedIndexPath) as? GalleryCollectionViewCell else {
                return UIImageView(
                    frame: CGRect(
                        x: UIScreen.main.bounds.midX,
                        y: UIScreen.main.bounds.midY,
                        width: 100,
                        height: 100
                    )
                )
            }
            
            return cell.imageView
        }
    }
    
    private func getFrameFromCollectionViewCell(for selectedIndexPath: IndexPath) -> CGRect {
        let visibleCells = collectionView.indexPathsForVisibleItems
        
        if !visibleCells.contains(selectedIndexPath) {
            collectionView.scrollToItem(
                at: selectedIndexPath,
                at: .centeredVertically,
                animated: false
            )
            
            collectionView.reloadItems(at: collectionView.indexPathsForVisibleItems)
            collectionView.layoutIfNeeded()
            
            guard let cell = collectionView.cellForItem(at: selectedIndexPath) as? GalleryCollectionViewCell else {
                return CGRect(
                    x: UIScreen.main.bounds.midX,
                    y: UIScreen.main.bounds.midY,
                    width: 100,
                    height: 100
                )
            }
            
            return cell.frame
        } else {
            guard let cell = collectionView.cellForItem(at: selectedIndexPath) as? GalleryCollectionViewCell else {
                return CGRect(
                    x: UIScreen.main.bounds.midX,
                    y: UIScreen.main.bounds.midY,
                    width: 100,
                    height: 100
                )
            }
            
            return cell.frame
        }
    }
}
