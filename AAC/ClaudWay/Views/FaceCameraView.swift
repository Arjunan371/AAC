//
//  FaceCameraView.swift
//  AAC
//
//  Created by Arjunan on 18/04/26.
//


// FaceCameraView.swift
import SwiftUI

struct FaceCameraView: View {
    @ObservedObject var session: ProctorSession
    let faceMonitor: FaceMonitor

    var body: some View {
        ZStack(alignment: .bottom) {
            CamerasPreviewView(session: faceMonitor.captureSession)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(borderColor, lineWidth: 3)
                )

            // Status badge at bottom
            statusBadge
                .padding(.bottom, 8)
        }
        .frame(width: 120, height: 160)
        .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
    }

    // MARK: - Status badge
    private var statusBadge: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(dotColor)
                .frame(width: 7, height: 7)
            Text(statusText)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(.black.opacity(0.6))
        .clipShape(Capsule())
    }

    // MARK: - Computed style helpers
    private var borderColor: Color {
        switch session.faceStatus {
        case .ok:       return .green
        case .missing:  return .red
        case .multiple: return .orange
        }
    }

    private var dotColor: Color {
        switch session.faceStatus {
        case .ok:       return .green
        case .missing:  return .red
        case .multiple: return .orange
        }
    }

    private var statusText: String {
        switch session.faceStatus {
        case .ok:       return "Face OK"
        case .missing:  return "No Face"
        case .multiple: return "Multiple"
        }
    }
}
