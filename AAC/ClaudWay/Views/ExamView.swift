//
//  ExamView.swift
//  AAC
//
//  Created by Arjunan on 18/04/26.
//

// ExamView.swift
import SwiftUI

struct ExamView: View {
    @ObservedObject var session: ProctorSession
    @State private var showViolationAlert = false

    var body: some View {
        ZStack(alignment: .topTrailing) {
//            VStack(spacing: 0) {
//
//                HStack {
//                    FaceStatusIndicator(status: session.faceStatus)
//                    Spacer()
//                    TimerView(
//                        seconds: session.elapsedSeconds,
//                        limit: session.config.timeLimitSeconds
//                    )
//                    Spacer()
//                    ViolationBadge(count: session.violations.count)
//                }
//                .padding(.horizontal)
//                .padding(.vertical, 12)
//                .background(Color(.gray))
//
//                Divider()
//
//                ScrollView {
//                    VStack(alignment: .leading, spacing: 20) {
//                        Text("Question 1")
//                            .font(.title2.bold())
//                        Text("What is the primary purpose of the Vision framework in iOS?")
//                            .font(.body)
//                    }
//                    .padding(24)
//                }
//
//                Divider()
//
//                Button(role: .destructive) {
//                    session.end()
//                } label: {
//                    Label("Submit Exam", systemImage: "checkmark.seal.fill")
//                        .font(.headline)
//                        .frame(maxWidth: .infinity)
//                        .padding()
//                        .background(Color.red.opacity(0.1))
//                        .foregroundStyle(.red)
//                        .clipShape(RoundedRectangle(cornerRadius: 14))
//                        .padding()
//                }
//            }
//
//            FaceCameraView(
//                session: session,
//                faceMonitor: session.faceMonitor
//            )
//            .padding(.top, 70)
//            .padding(.trailing, 16)
            if let url = URL(string: "https://digiassess-nonprod.gcp.digivalitsolutions.com/staging-deweb/auth/student/system-check") {
                WebViewRepresentable(url: url)
            }
        }
        .ignoresSafeArea()
        .onReceive(NotificationCenter.default.publisher(for: .submitExam)) { output in
            if let status = output.userInfo?["status"] {
                session.end()
            }
        }
//        .onChange(of: session.faceStatus) { newStatus in
//            if newStatus != .ok {
//                showViolationAlert = true
//            }
//        }
//        .alert(alertTitle, isPresented: $showViolationAlert) {
//            Button("OK") { showViolationAlert = false }
//        } message: {
//            Text(alertMessage)
//        }
    }

    private var alertTitle: String {
        session.faceStatus == .multiple
            ? "Multiple faces detected"
            : "Face not visible"
    }

    private var alertMessage: String {
        session.faceStatus == .multiple
            ? "Only one person is allowed during the exam."
            : "Please keep your face visible in the camera at all times."
    }
}

struct FaceStatusIndicator: View {
    let status: ProctorSession.FaceStatus

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 10, height: 10)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var color: Color {
        switch status {
        case .ok: return .green
        case .missing: return .red
        case .multiple: return .orange
        }
    }

    private var label: String {
        switch status {
        case .ok: return "Face detected"
        case .missing: return "No face"
        case .multiple: return "Multiple faces"
        }
    }
}

struct TimerView: View {
    let seconds: Int
    let limit: Int

    private var remaining: Int { limit - seconds }

    var body: some View {
        Text(timeString(remaining))
            .font(.system(.body, design: .monospaced).bold())
            .foregroundStyle(remaining < 300 ? .red : .primary)
    }

    private func timeString(_ s: Int) -> String {
        let h = s / 3600
        let m = (s % 3600) / 60
        let sec = s % 60
        return String(format: "%02d:%02d:%02d", h, m, sec)
    }
}

struct ViolationBadge: View {
    let count: Int

    var body: some View {
        Label("\(count)", systemImage: "exclamationmark.triangle.fill")
            .font(.caption.bold())
            .foregroundStyle(count > 0 ? .orange : .secondary)
    }
}
