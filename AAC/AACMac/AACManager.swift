//
//  AACManager.swift
//  AAC
//
//  Created by Arjunan on 15/04/26.
//


import SwiftUI
import AutomaticAssessmentConfiguration
import Combine
import ReplayKit
import AVFoundation

class AACManager: NSObject, ObservableObject, AEAssessmentSessionDelegate {

    private var session:           AEAssessmentSession?
    private let recordingManager = RecordingManager()
//    let broadcastManager         = BroadcastManager()
    private var cancellables     = Set<AnyCancellable>()
    @Published var screenRec = ScreenRecManager()
    @Published var isSessionActive:    Bool = false
    @Published var errorMessage:       String?
    @Published var isCameraRecording:  Bool = false
    @Published var cameraPreviewLayer: AVCaptureVideoPreviewLayer?

    override init() {
        super.init()
        recordingManager.$isCameraRecording
            .receive(on: DispatchQueue.main).assign(to: &$isCameraRecording)
        recordingManager.$cameraPreviewLayer
            .receive(on: DispatchQueue.main).assign(to: &$cameraPreviewLayer)
        recordingManager.$errorMessage
            .receive(on: DispatchQueue.main)
            .compactMap { $0 }
            .sink { [weak self] m in self?.errorMessage = m }
            .store(in: &cancellables)
    }

    func startSession(){
        screenRec.startRecording()
        let config = AEAssessmentConfiguration()
        #if os(iOS)
        config.allowsContinuousPathKeyboard = true
        config.allowsDictation              = true
        config.allowsSpellCheck             = true
        config.allowsPredictiveKeyboard     = true
        #endif
        let s = AEAssessmentSession(configuration: config)
        s.delegate = self
        session = s
        s.begin()
    }

    func stopSession() {
        recordingManager.stopAll()
//        broadcastManager.stopObserving()
        screenRec.stopRecording()
        session?.end()
//        { url in
//            print("url====>, \(url)")
//        }
    }

    func assessmentSessionDidBegin(_ session: AEAssessmentSession) {
        DispatchQueue.main.async {
            self.isSessionActive = true
            self.errorMessage    = nil
            self.recordingManager.startCameraRecording()
//            self.broadcastManager.startObserving()
        }
    }

    func assessmentSession(_ session: AEAssessmentSession, didFailWithError error: Error) {
        DispatchQueue.main.async {
            self.isSessionActive = false
            self.errorMessage    = "AAC failed: \(error.localizedDescription)"
        }
    }

    func assessmentSessionDidEnd(_ session: AEAssessmentSession) {
        DispatchQueue.main.async {
            self.isSessionActive = false
            self.recordingManager.stopAll()
//            self.broadcastManager.stopObserving()
        }
    }
}
