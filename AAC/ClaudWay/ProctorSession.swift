//
//  ProctorSession 2.swift
//  AAC
//
//  Created by Arjunan on 18/04/26.
//


import SwiftUI
import Combine

#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

@MainActor
class ProctorSession: ObservableObject {
    @Published var phase: SessionPhase = .idle
    @Published var violations: [Violation] = []
    @Published var elapsedSeconds: Int = 0
    @Published var faceStatus: FaceStatus = .ok
    @Published var recordingURL: URL?

    let config: AssessmentConfig
    let faceMonitor = FaceMonitor()
//#if os(iOS)
//private let screenRecorder = ScreenRecorderManager()
//#elseif os(macOS)
//private let screenRecorder = MacScreenRecorder()
//#endif
    private let screenRecorder = ScreenRecorderManager()
    private var timer: Timer?

    enum SessionPhase: Equatable {
        case idle, requestingPermissions, permissionDenied
        case lockdown, active, ended
    }

    enum FaceStatus { case ok, missing, multiple }

    struct Violation: Identifiable {
        let id = UUID()
        let timestamp: Date
        let reason: String
    }

    init(config: AssessmentConfig) {
        self.config = config
    }

    func begin() async {
        phase = .requestingPermissions

        let granted = await PermissionManager.requestAll(config: config)
        guard granted else {
            phase = .permissionDenied
            return
        }

        phase = .lockdown

#if os(iOS)
        if config.enableGuidedAccess {
            LockdownManager.enableGuidedAccess()
        }
#elseif os(macOS)
        LockdownManager.enableKioskMode()
#endif

        phase = .active
        startMonitoring()
    }

    private func startMonitoring() {
        if config.enableScreenRecord {
            screenRecorder.startRecording()
        }

        faceMonitor.onViolation = { [weak self] reason in
            Task { @MainActor in
                self?.logViolation(reason)
                self?.faceStatus = reason.contains("Multiple") ? .multiple : .missing
            }
        }
        faceMonitor.onFaceRestored = { [weak self] in
            Task { @MainActor in self?.faceStatus = .ok }
        }

        if config.enableFaceDetection { faceMonitor.start() }

        LockdownManager.monitorAppState { [weak self] in
            Task { @MainActor in self?.logViolation("App sent to background") }
        }
        LockdownManager.monitorScreenshot { [weak self] in
            Task { @MainActor in self?.logViolation("Screenshot taken") }
        }
        LockdownManager.monitorExternalScreenRecord { [weak self] in
            Task { @MainActor in
                self?.logViolation("External screen recording detected")
            }
        }

        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.elapsedSeconds += 1 }
        }
    }

    func end() {
        timer?.invalidate()
        faceMonitor.stop()
        LockdownManager.removeAllObservers()
        phase = .ended

#if os(iOS)
        UIAccessibility.requestGuidedAccessSession(enabled: false) { _ in }
#elseif os(macOS)
        LockdownManager.disableKioskMode()
#endif

        screenRecorder.stopRecording { [weak self] url in
            Task { @MainActor in self?.recordingURL = url }
        }
    }

    private func logViolation(_ reason: String) {
        violations.append(Violation(timestamp: Date(), reason: reason))
    }
}
