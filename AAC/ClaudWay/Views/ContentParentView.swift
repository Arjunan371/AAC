//
//  ContentView.swift
//  AAC
//
//  Created by Arjunan on 18/04/26.
//


import SwiftUI

struct ContentParentView: View {
    @StateObject private var session = ProctorSession(
        config: AssessmentConfig(
            enableCamera: true,
            enableMicrophone: true,
            enableScreenRecord: true,
            enableFaceDetection: true,
            timeLimitSeconds: 3600,
            enableGuidedAccess: true
        )
    )
    
    var body: some View {
        Group {
            switch session.phase {
            case .idle:
                PreExamView(session: session)
            case .requestingPermissions:
                PermissionGateView()
            case .permissionDenied:
                PermissionDeniedView()
            case .lockdown:
                LockdownTransitionView()
            case .active:
                ExamView(session: session)
            case .ended:
                ResultView(session: session)
            }
        }
        .animation(.easeInOut, value: session.phase)
#if os(macOS)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
#endif
    }
}
