//
//  RequestPermission.swift
//  AAC
//
//  Created by Arjunan on 18/04/26.
//

import AVFoundation

#if os(macOS)
import AppKit

func configureMacWindow(isExamMode: Bool) {
    guard let window = NSApplication.shared.windows.first else { return }
    blockEscape(isExamMode)
    if isExamMode {
        if !window.styleMask.contains(.fullScreen) {
            window.toggleFullScreen(nil)
        }
    } else {
        if window.styleMask.contains(.fullScreen) {
            window.toggleFullScreen(nil)
        }
    }

    window.standardWindowButton(.closeButton)?.isEnabled = !isExamMode
    window.standardWindowButton(.miniaturizeButton)?.isEnabled = !isExamMode
    window.standardWindowButton(.zoomButton)?.isEnabled = !isExamMode

//    window.standardWindowButton(.closeButton)?.isHidden = isExamMode
//    window.standardWindowButton(.miniaturizeButton)?.isHidden = isExamMode
//    window.standardWindowButton(.zoomButton)?.isHidden = isExamMode

    if isExamMode {
        window.collectionBehavior = [.fullScreenPrimary, .fullScreenDisallowsTiling]
    } else {
        window.collectionBehavior = []
    }
}

var monitor: Any?

func blockEscape(_ enable: Bool) {
    if enable {
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            if event.keyCode == 53 { return nil }
            return event
        }
    } else {
        if let m = monitor {
            NSEvent.removeMonitor(m)
        }
        monitor = nil
    }
}
#endif



func requestCameraPermission() {
    let status = AVCaptureDevice.authorizationStatus(for: .video)

    switch status {
    case .authorized:
        print("Already granted ✅")

    case .notDetermined:
        AVCaptureDevice.requestAccess(for: .video) { granted in
            DispatchQueue.main.async {
                print(granted ? "Granted ✅" : "Denied ❌")
            }
        }

    case .denied, .restricted:
        print("Denied ❌ → Open Settings needed")

    @unknown default:
        break
    }
}

func requestAudioPermission() {
    let status = AVCaptureDevice.authorizationStatus(for: .audio)

    switch status {
    case .authorized:
        print("Already granted ✅")

    case .notDetermined:
        AVCaptureDevice.requestAccess(for: .audio) { granted in
            DispatchQueue.main.async {
                print(granted ? "Granted ✅" : "Denied ❌")
            }
        }

    case .denied, .restricted:
        print("Denied ❌ → Open Settings needed")

    @unknown default:
        break
    }
}
