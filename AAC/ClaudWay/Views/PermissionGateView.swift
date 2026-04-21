//
//  PermissionGateView.swift
//  AAC
//
//  Created by Arjunan on 18/04/26.
//

import SwiftUI

struct PermissionGateView: View {
    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Requesting permissions...")
                .font(.headline)
                .foregroundStyle(.secondary)
        }
    }
}

struct PermissionDeniedView: View {
    @Environment(\.openURL) var openURL
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "xmark.shield.fill")
                .font(.system(size: 56))
                .foregroundStyle(.red)
            Text("Permissions Required")
                .font(.title2.bold())
            Text("Camera and microphone access are required to start the exam. Please enable them in Settings.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            Button("Open Settings") {
                openSettings()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(32)
    }
    
    private func openSettings() {
        #if os(iOS)
        if let url = URL(string: UIApplication.openSettingsURLString) {
            openURL(url)
        }

        #elseif os(macOS)
        let urls = [
            "x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone",
//            "x-apple.systempreferences:com.apple.preference.security?Privacy_Camera"
        ]

        var opened = false

        for urlString in urls {
            if let url = URL(string: urlString) {
                openURL(url)
                opened = true
            }
        }

        if !opened {
            if let url = URL(string: "x-apple.systempreferences:") {
                openURL(url)
            }
        }
        #endif
    }
}

struct LockdownTransitionView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "lock.fill")
                .font(.system(size: 56))
                .foregroundStyle(.orange)
            Text("Enabling secure mode...")
                .font(.headline)
            ProgressView()
        }
    }
}
