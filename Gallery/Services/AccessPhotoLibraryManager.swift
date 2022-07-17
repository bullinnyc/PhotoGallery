//
//  AccessPhotoLibraryManager.swift
//  Gallery
//
//  Created by Dmitry Kononchuk on 16.07.2022.
//

import PhotosUI

class AccessPhotoLibraryManager {
    /// ** Update info.plist key: **
    /// for PHAccessLevel .addOnly: Privacy - Photo Library Additions Usage Description = "Need access to photo library for save"
    /// for PHAccessLevel .readWrite: Privacy - Photo Library Usage Description = "Need access to photo library"
    /// for PHPhotoLibrary.shared().presentLimitedLibraryPicker: Prevent limited photos access alert = YES

    // MARK: - Private Properties
    @available(iOS 14, *)
    private static let phAccessLevel: PHAccessLevel = .readWrite // Set PHAccessLevel

    // MARK: - Public Methods
    static func checkAccessPhotoLibrary(_ callingFunctionName: String = #function, from viewController: UIViewController, completion: @escaping () -> Void) {
        if #available(iOS 14, *) {
            let status = PHPhotoLibrary.authorizationStatus(for: phAccessLevel)
            
            switch status {
            case .notDetermined:
                requestAccessPhotoLibrary {
                    completion()
                }
            case .denied, .restricted:
                showAlertPhotoLibraryAccessNeeded()
            case .authorized:
                completion()
            case .limited:
                // For PHAccessLevel .readWrite only
                completion()
            default:
                print("\(callingFunctionName): unknown error")
                fatalError()
            }
        } else {
            let status = PHPhotoLibrary.authorizationStatus()

            switch status {
            case .notDetermined:
                requestAccessPhotoLibrary {
                    completion()
                }
            case .denied, .restricted:
                showAlertPhotoLibraryAccessNeeded()
            case .authorized:
                completion()
            default:
                print("\(callingFunctionName): unknown error")
                fatalError()
            }
        }
    }

    // MARK: - Private Methods
    private static func requestAccessPhotoLibrary(_ callingFunctionName: String = #function, completion: @escaping () -> Void) {
        if #available(iOS 14, *) {
            PHPhotoLibrary.requestAuthorization(for: phAccessLevel) { status in
                switch status {
                case .denied, .restricted:
                    break
                case .authorized:
                    DispatchQueue.main.async {
                        completion()
                    }
                case .limited:
                    // For PHAccessLevel .readWrite only
                    DispatchQueue.main.async {
                        completion()
                    }
                default:
                    print("\(callingFunctionName): unknown error")
                    fatalError()
                }
            }
        } else {
            PHPhotoLibrary.requestAuthorization { status in
                switch status {
                case .denied, .restricted:
                    break
                case .authorized:
                    DispatchQueue.main.async {
                        completion()
                    }
                default:
                    print("\(callingFunctionName): unknown error")
                    fatalError()
                }
            }
        }
    }
}

// MARK: - Ext. ShowAlert
extension AccessPhotoLibraryManager {
    /// For added more photos to press button from App (need to create a button).
    static func showAlertSelectMorePhotos(from viewController: UIViewController) {
        let alert = UIAlertController(
            title: "",
            message: "Select more photos?",
            preferredStyle: .alert
        )

        let cancelAction = UIAlertAction(
            title: "Cancel",
            style: .cancel
        )

        let okAction = UIAlertAction(
            title: "Ok",
            style: .default
        ) { _ in
            if #available(iOS 14, *) {
                PHPhotoLibrary.shared().presentLimitedLibraryPicker(from: viewController)
            }
        }
        
        alert.addAction(cancelAction)
        alert.addAction(okAction)

        viewController.present(alert, animated: true)
    }
    
    private static func showAlertPhotoLibraryAccessNeeded() {
        let alert = UIAlertController(
            title: "Need access to the photo library",
            message: "Allow access to the photo library in the settings app",
            preferredStyle: .alert
        )

        let cancelAction = UIAlertAction(
            title: "Cancel",
            style: .cancel
        )

        let okAction = UIAlertAction(
            title: "Ok",
            style: .default
        ) { _ in
            if let settingsApp = URL(string: UIApplication.openSettingsURLString),
               UIApplication.shared.canOpenURL(settingsApp)
            {
                UIApplication.shared.open(settingsApp)
            }
        }
        
        alert.addAction(cancelAction)
        alert.addAction(okAction)

        guard let topViewController = UIApplication.shared.windows.last?.rootViewController else { return }
        topViewController.present(alert, animated: true)
    }
}
