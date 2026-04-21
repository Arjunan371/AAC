//
//  ResultView.swift
//  AAC
//
//  Created by Arjunan on 18/04/26.
//


import SwiftUI

struct ResultView: View {
    @ObservedObject var session: ProctorSession

    var body: some View {
        NavigationStack {
            List {
                Section("Session Summary") {
                    LabeledContent("Duration",
                        value: "\(session.elapsedSeconds / 60) min")
                    LabeledContent("Violations",
                        value: "\(session.violations.count)")
                    LabeledContent("Status",
                        value: session.violations.isEmpty ? "Clean" : "Flagged")
                }

                if !session.violations.isEmpty {
                    Section("Violations") {
                        ForEach(session.violations) { v in
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundStyle(.orange)
                                VStack(alignment: .leading) {
                                    Text(v.reason)
                                        .font(.subheadline)
                                    Text(v.timestamp.formatted(date: .omitted,
                                                               time: .standard))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Exam Complete")
        }
    }
}
