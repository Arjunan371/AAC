//
//  AutomaticAssessment.swift
//  AAC
//
//  Created by Arjunan on 15/04/26.
//

import SwiftUI

struct AutomaticAssessment: View {
    @StateObject private var aacManager = AACManager()
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.white
                .ignoresSafeArea()
            ViewThatFits(in: .vertical) {
                contentView
                ScrollView {
                    contentView
                }
            }
            if aacManager.isCameraRecording {
                cameraSection
            }
        }
    }
    
    private var contentView: some View {
        VStack(spacing: 20) {
            statusRow
                .background(Color.clear)
                .frame(maxWidth: .infinity, alignment: .leading)
            CustomWebView()
                .frame(maxHeight: .infinity)
            errorView
            controlButtons
        }
        .padding()
    }
    private var cameraSection: some View {
        ZStack {
            Color.black
                .frame(width: 150, height: 150)
            Group {
                if let layer = aacManager.cameraPreviewLayer {
                    CameraPreviewView(previewLayer: layer)
                }
            }
            .frame(width: 150, height: 150)
        }
        .frame(height: 150)
        .cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14)
            .stroke(aacManager.isCameraRecording ? Color.red.opacity(0.5) : Color.gray.opacity(0.3)))
        .padding([.trailing, .top], 12)
    }
    
    
    private var statusRow: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(aacManager.isSessionActive ? Color.green : Color.gray)
                .frame(width: 12, height: 12)
            Text(aacManager.isSessionActive ? "Assessment Active" : "Session Inactive")
                .font(.headline)
                .foregroundColor(aacManager.isSessionActive ? .primary : .secondary)
        }
    }
    
    
    @ViewBuilder
    private var errorView: some View {
        if let err = aacManager.errorMessage {
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill").foregroundColor(.orange)
                Text(err).font(.caption).foregroundColor(.secondary).multilineTextAlignment(.leading)
            }
            .padding(10).background(Color.orange.opacity(0.08)).cornerRadius(8)
        }
    }
    
    private func debugRow(label: String, value: String, ok: Bool) -> some View {
        HStack(alignment: .top, spacing: 4) {
            Text("\(label):")
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(.secondary)
                .frame(width: 140, alignment: .leading)
            Text(value)
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(ok ? .primary : .red)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
    
    
    private var controlButtons: some View {
        HStack(spacing: 16) {
            Button {
                aacManager.startSession()
#if os(macOS)
                configureMacWindow(isExamMode: true)
#endif
            } label: {
                HStack(spacing: 12) {
                    Text("Start Session")
                    Image(systemName: "play.fill")
                }
                .padding(12)
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent).disabled(aacManager.isSessionActive)
            
            Button {
                aacManager.stopSession()
#if os(macOS)
                configureMacWindow(isExamMode: false)
#endif
            } label: {
                HStack(spacing: 12) {
                    Text("Stop Session")
                    Image(systemName: "stop.fill")
                }
                .padding(12)
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered).tint(.red).disabled(!aacManager.isSessionActive)
        }
    }
}

#Preview {
    AutomaticAssessment()
}
