//
//  LockdownManager.swift
//  AAC
//
//  Created by Arjunan on 18/04/26.
//


import Foundation

#if os(iOS)
import UIKit

class LockdownManager {

    static func enableGuidedAccess() {
        UIAccessibility.requestGuidedAccessSession(enabled: true) { success in
            print("Guided Access enabled: \(success)")
        }
    }

    static func disableGuidedAccess() {
        UIAccessibility.requestGuidedAccessSession(enabled: false) { _ in }
    }

    static func preventScreenshots(in view: UIView) {
        let secureField = UITextField()
        secureField.isSecureTextEntry = true
        secureField.isUserInteractionEnabled = false
        view.addSubview(secureField)
        secureField.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            secureField.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            secureField.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
        if let secureLayer = secureField.layer.sublayers?.first {
            secureLayer.frame = view.bounds
            view.layer.superlayer?.addSublayer(secureLayer)
            secureLayer.addSublayer(view.layer)
        }
    }

    static func monitorAppState(onViolation: @escaping () -> Void) {
        NotificationCenter.default.addObserver(
            forName: UIApplication.willResignActiveNotification,
            object: nil,
            queue: .main
        ) { _ in onViolation() }
    }

    static func monitorScreenshot(onViolation: @escaping () -> Void) {
        NotificationCenter.default.addObserver(
            forName: UIApplication.userDidTakeScreenshotNotification,
            object: nil,
            queue: .main
        ) { _ in onViolation() }
    }

    static func monitorExternalScreenRecord(onViolation: @escaping () -> Void) {
        NotificationCenter.default.addObserver(
            forName: UIScreen.capturedDidChangeNotification,
            object: nil,
            queue: .main
        ) { _ in
            if UIScreen.main.isCaptured { onViolation() }
        }
    }

    static func removeAllObservers() {
        NotificationCenter.default.removeObserver(
            self,
            name: UIApplication.willResignActiveNotification,
            object: nil
        )
        NotificationCenter.default.removeObserver(
            self,
            name: UIApplication.userDidTakeScreenshotNotification,
            object: nil
        )
        NotificationCenter.default.removeObserver(
            self,
            name: UIScreen.capturedDidChangeNotification,
            object: nil
        )
    }
}

#elseif os(macOS)
import AppKit

class LockdownManager {

    static func enableKioskMode() {
        guard let window = NSApp.windows.first else { return }
        window.toggleFullScreen(nil)
        
        NSApp.presentationOptions = [
            .hideDock,
            .hideMenuBar,
            .disableForceQuit,
            .disableSessionTermination,
            .disableHideApplication
        ]
        print("macOS kiosk mode enabled")
    }

    static func disableKioskMode() {
        guard let window = NSApp.windows.first else { return }
        window.toggleFullScreen(false)
        NSApp.presentationOptions = []
    }

    static func monitorAppState(onViolation: @escaping () -> Void) {
        NotificationCenter.default.addObserver(
            forName: NSApplication.didResignActiveNotification,
            object: nil,
            queue: .main
        ) { _ in onViolation() }
    }

    static func monitorScreenshot(onViolation: @escaping () -> Void) {
        NotificationCenter.default.addObserver(
            forName: NSApplication.didResignActiveNotification,
            object: nil,
            queue: .main
        ) { _ in onViolation() }
    }

    static func monitorExternalScreenRecord(onViolation: @escaping () -> Void) {
        if !CGPreflightScreenCaptureAccess() {
            print("Screen capture access not granted")
        }
        NotificationCenter.default.addObserver(
            forName: NSApplication.didResignActiveNotification,
            object: nil,
            queue: .main
        ) { _ in onViolation() }
    }

    static func removeAllObservers() {
        NotificationCenter.default.removeObserver(
            self,
            name: NSApplication.didResignActiveNotification,
            object: nil
        )
    }
}
#endif
