//
//  PreExamView.swift
//  AAC
//
//  Created by Arjunan on 18/04/26.
//


// PreExamView.swift
import SwiftUI

struct PreExamView: View {
    @ObservedObject var session: ProctorSession

    var body: some View {
        VStack(spacing: 32) {
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 64))
                .foregroundStyle(.blue)

            VStack(spacing: 8) {
                Text("Digi Exam")
                    .font(.largeTitle.bold())
                Text("Your session will be recorded.\nEnsure you are in a well-lit room.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            VStack(alignment: .leading, spacing: 12) {
                RequirementRow(icon: "video.fill",
                               text: "Camera access required")
                RequirementRow(icon: "mic.fill",
                               text: "Microphone access required")
                RequirementRow(icon: "record.circle",
                               text: "Screen will be recorded")
                RequirementRow(icon: "person.fill.viewfinder",
                               text: "Face must remain visible")
            }
            .padding()
         //   .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))

            Button {
                Task { await session.begin() }
            } label: {
                Label("Start Exam", systemImage: "play.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
        }
        .padding(24)
    }
}

struct RequirementRow: View {
    let icon: String
    let text: String
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(.blue)
                .frame(width: 24)
            Text(text)
                .font(.subheadline)
        }
    }
}
