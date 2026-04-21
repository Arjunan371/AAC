//
//  ScreenRecManager.swift
//  AAC
//
//  Created by Arjunan on 16/04/26.
//

import Foundation
import ReplayKit
import AVFoundation
import Combine
import SwiftUI

class ScreenRecManager: NSObject, ObservableObject {
    
     let recorder = RPScreenRecorder.shared()
    
    @Published var isRecording = false
    
    override init() {
         
    }
    
    var onPreview: ((RPPreviewViewController) -> Void)?
    
    // MARK: Start Recording
    func startRecording() {
        guard !recorder.isRecording else {
            print("⚠️ Already recording")
            return
        }
        
        recorder.isMicrophoneEnabled = true
        
        recorder.startRecording { error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ Start error:", error.localizedDescription)
                    self.isRecording = false
                } else {
                    print("✅ Recording started")
                    self.isRecording = true
                }
            }
        }
    }
    
    // MARK: Stop Recording
    func stopRecording() {
        guard recorder.isRecording else {
            print("⚠️ Not recording — avoid crash")
            return
        }
        
        recorder.stopRecording { preview, error in
            DispatchQueue.main.async {
                self.isRecording = false
                
                if let error = error {
                    print("❌ Stop error:", error.localizedDescription)
                    return
                }
                
                if let preview = preview {
                    self.onPreview?(preview)
                }
            }
        }
    }
}
