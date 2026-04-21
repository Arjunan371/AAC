//
//  PermissionManager.swift
//  AAC
//
//  Created by Arjunan on 18/04/26.
//

import AVFoundation

#if os(iOS)
import UIKit
#endif

#if os(macOS)
import AppKit
#endif

// MARK: - Permission Status

enum PermissionStatus {
    case authorized
    case denied
    case notDetermined
    case restricted
}

// MARK: - Missing Permission Type

enum MissingPermission: CustomStringConvertible {
    case camera
    case microphone
    
    var description: String {
        switch self {
        case .camera: return "Camera"
        case .microphone: return "Microphone"
        }
    }
}

// MARK: - Permission Manager

struct PermissionManager {
    
    // MARK: - Request All Permissions
    
    static func requestAll(config: AssessmentConfig) async -> Bool {
        var results: [Bool] = []

        if config.enableCamera {
            results.append(await requestCameraIfNeeded())
        }

//        if config.enableMicrophone {
//            results.append(await requestMicrophoneIfNeeded())
//        }
        let missing = PermissionManager.missingPermissions(config: config)
           print("❌ Missing:", missing)
        return results.allSatisfy { $0 }
    }
    
    // MARK: - Check Missing Permissions
    
    static func missingPermissions(config: AssessmentConfig) -> [MissingPermission] {
        var missing: [MissingPermission] = []

        if config.enableCamera {
            if cameraStatus() != .authorized {
                missing.append(.camera)
            }
        }

        if config.enableMicrophone {
            if microphoneStatus() != .authorized {
                missing.append(.microphone)
            }
        }

        return missing
    }
    
    // MARK: - Individual Status
    
    static func cameraStatus() -> PermissionStatus {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:    return .authorized
        case .denied:        return .denied
        case .notDetermined: return .notDetermined
        case .restricted:    return .restricted
        @unknown default:    return .denied
        }
    }

    static func microphoneStatus() -> PermissionStatus {
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized:    return .authorized
        case .denied:        return .denied
        case .notDetermined: return .notDetermined
        case .restricted:    return .restricted
        @unknown default:    return .denied
        }
    }

    // MARK: - Open Settings
    
    #if os(iOS)
    @discardableResult
    static func openAppSettings() -> Bool {
        guard let url = URL(string: UIApplication.openSettingsURLString),
              UIApplication.shared.canOpenURL(url) else { return false }
        
        UIApplication.shared.open(url)
        return true
    }
    #elseif os(macOS)
    @discardableResult
    static func openPrivacySettings() -> Bool {
        let urls = [
            "x-apple.systempreferences:com.apple.preference.security?Privacy_Camera",
            "x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone"
        ]

        for urlString in urls {
            if let url = URL(string: urlString) {
                NSWorkspace.shared.open(url)
            }
        }

        return true
    }
    #endif

    // MARK: - Internal Request Helpers
    
    private static func requestCameraIfNeeded() async -> Bool {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            return true
            
        case .notDetermined:
            return await AVCaptureDevice.requestAccess(for: .video)
            
        case .denied, .restricted:
            return false
            
        @unknown default:
            return false
        }
    }

    private static func requestMicrophoneIfNeeded() async -> Bool {
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized:
            return true
            
        case .notDetermined:
            return await AVCaptureDevice.requestAccess(for: .audio)
            
        case .denied, .restricted:
            return false
            
        @unknown default:
            return false
        }
    }
}
