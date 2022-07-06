//
//  TabBarViewController.swift
//  Gallery
//
//  Created by Dmitry Kononchuk on 24.06.2022.
//

import UIKit

class TabBarViewController: UITabBarController {
    // MARK: - Override Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupViewControllers()
    }
    
    // MARK: - Private Methods
    private func setupViewControllers() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let galleryViewController = storyboard.instantiateViewController(
            withIdentifier: "\(GalleryViewController.self)"
        )
        
        viewControllers = [
            createNavigationController(
                viewController: galleryViewController,
                title: "Gallery",
                image: UIImage(systemName: "photo.fill") ?? UIImage()
            )
        ]
    }
    
    private func createNavigationController(viewController: UIViewController, title: String, image: UIImage) -> UIViewController {
        let navigationController = UINavigationController(rootViewController: viewController)
        navigationController.tabBarItem.title = title
        navigationController.tabBarItem.image = image
        
        viewController.navigationItem.title = title
        return navigationController
    }
}
