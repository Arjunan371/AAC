//
//  CameraPreviewView.swift
//  AAC
//
//  Created by Arjunan on 15/04/26.
//

import SwiftUI
import AVFoundation

#if os(iOS)
import UIKit

struct CameraPreviewView: UIViewRepresentable {
    let previewLayer: AVCaptureVideoPreviewLayer

    func makeUIView(context: Context) -> PreviewUIView {
        let view = PreviewUIView()
        view.backgroundColor = .black
        view.attach(previewLayer)
        return view
    }

    func updateUIView(_ uiView: PreviewUIView, context: Context) {
        uiView.attach(previewLayer)
    }

    final class PreviewUIView: UIView {
        private weak var attachedLayer: AVCaptureVideoPreviewLayer?

        func attach(_ layer: AVCaptureVideoPreviewLayer) {
            guard layer !== attachedLayer else { return }
            attachedLayer?.removeFromSuperlayer()
            attachedLayer = layer
            self.layer.insertSublayer(layer, at: 0)
            setNeedsLayout()
        }

        override func layoutSubviews() {
            super.layoutSubviews()
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            attachedLayer?.frame = bounds
            CATransaction.commit()
        }
    }
}

#elseif os(macOS)

import AppKit

struct CameraPreviewView: NSViewRepresentable {
    let previewLayer: AVCaptureVideoPreviewLayer

    func makeNSView(context: Context) -> PreviewNSView {
        let view = PreviewNSView()
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.black.cgColor
        view.attach(previewLayer)
        return view
    }

    func updateNSView(_ nsView: PreviewNSView, context: Context) {
        nsView.attach(previewLayer)
    }

    final class PreviewNSView: NSView {
        private weak var attachedLayer: AVCaptureVideoPreviewLayer?

        func attach(_ layer: AVCaptureVideoPreviewLayer) {
            guard layer !== attachedLayer else { return }
            attachedLayer?.removeFromSuperlayer()
            attachedLayer = layer
            self.layer?.addSublayer(layer)
            needsLayout = true
        }

        override func layout() {
            super.layout()
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            attachedLayer?.frame = bounds
            CATransaction.commit()
        }
    }
}

#endif


//func handleCameraPermission() {
//    let status = AVCaptureDevice.authorizationStatus(for: .video)
//
//    switch status {
//
//    case .authorized:
//        print("Access granted ✅")
//
//    case .notDetermined:
//        AVCaptureDevice.requestAccess(for: .video) { granted in
//            DispatchQueue.main.async {
//                print(granted ? "Granted ✅" : "Denied ❌")
//            }
//        }
//
//    case .denied, .restricted:
//        showSettingsAlert()
//
//    @unknown default:
//        break
//    }
//}

//func openSettings() {
//    if let url = URL(string: UIApplication.openSettingsURLString) {
//        UIApplication.shared.open(url)
//    }
//    
//    if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Camera") {
//        NSWorkspace.shared.open(url)
//    }
//}

//func requestCameraPermission() {
//    let status = AVCaptureDevice.authorizationStatus(for: .video)
//
//    switch status {
//    case .authorized:
//        print("Already granted ✅")
//
//    case .notDetermined:
//        AVCaptureDevice.requestAccess(for: .video) { granted in
//            DispatchQueue.main.async {
//                print(granted ? "Granted ✅" : "Denied ❌")
//            }
//        }
//
//    case .denied, .restricted:
//        print("Denied ❌")
//
//    @unknown default:
//        break
//    }
//}
//
//func requestAudioPermission() {
//    let status = AVCaptureDevice.authorizationStatus(for: .audio)
//
//    switch status {
//    case .authorized:
//        print("Already granted ✅")
//
//    case .notDetermined:
//        AVCaptureDevice.requestAccess(for: .audio) { granted in
//            DispatchQueue.main.async {
//                print(granted ? "Granted ✅" : "Denied ❌")
//            }
//        }
//
//    case .denied, .restricted:
//        print("Denied ❌")
//
//    @unknown default:
//        break
//    }
//}
