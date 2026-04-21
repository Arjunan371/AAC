//
//  RecordingManager.swift
//  AAC
//
//  Created by Arjunan on 15/04/26.
//


import Foundation
import AVFoundation
import ReplayKit
import SwiftUI
import Combine

// MARK: - RecordingManager

final class RecordingManager: NSObject, ObservableObject {

    // MARK: - Published State

    @Published private(set) var isScreenRecording: Bool = false
    @Published private(set) var isCameraRecording: Bool = false
    @Published private(set) var cameraPreviewLayer: AVCaptureVideoPreviewLayer?
    @Published var errorMessage: String?
    @Published private(set) var cameraFileURL: URL?
    @Published private(set) var screenFileURL: URL?

    // MARK: - Screen

    private let screenRecorder = RPScreenRecorder.shared()
    private let screenQueue = DispatchQueue(label: "com.app.screen.queue", qos: .userInitiated)
    private var screenWriter: AVAssetWriter?
    private var screenWriterInput: AVAssetWriterInput?
    private var screenStartTime: CMTime?

    // MARK: - Camera
    // ALL camera writer state is touched ONLY on cameraQueue (serial). Never elsewhere.

    private var cameraSession: AVCaptureSession?
    private let cameraQueue = DispatchQueue(label: "com.app.camera.queue", qos: .userInitiated)
    private var cameraWriter: AVAssetWriter?
    private var cameraWriterInput: AVAssetWriterInput?
    private var cameraStartTime: CMTime?

    // MARK: - Public API

    func startAll() {
        startCameraRecording()
        startScreenRecording()
    }

    func stopAll() {
        stopCameraRecording()
        stopScreenRecording()
    }

    // MARK: - Helpers

    private func makeTempURL(name: String) -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(name)_\(Int(Date().timeIntervalSince1970)).mov")
        try? FileManager.default.removeItem(at: url)
        return url
    }

    // MARK: - Camera Recording

    func startCameraRecording() {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        switch status {
        case .authorized:
            setupAndStartCamera()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                if granted {
                    self?.setupAndStartCamera()
                } else {
                    DispatchQueue.main.async {
                        self?.errorMessage = "Camera access denied."
                    }
                }
            }
        default:
            DispatchQueue.main.async {
                self.errorMessage = "Camera not authorized. Enable in Settings > Privacy > Camera."
            }
        }
    }

    private func setupAndStartCamera() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self else { return }

            // Tear down any existing session
            self.cameraSession?.stopRunning()
            self.cameraSession = nil

            do {
                let (session, preview) = try self.buildCameraSession()

                // ✅ Publish preview layer BEFORE startRunning.
                // The custom PreviewUIView.layoutSubviews() will correctly
                // size it when SwiftUI lays out the view — fixing black screen.
                DispatchQueue.main.async {
                    self.cameraPreviewLayer = preview
                }

                // Start the session — frames begin flowing into delegate
                session.startRunning()
                self.cameraSession = session

                DispatchQueue.main.async {
                    self.isCameraRecording = true
                    self.errorMessage = nil
                }

            } catch {
                DispatchQueue.main.async {
                    self.isCameraRecording = false
                    self.errorMessage = "Camera setup failed: \(error.localizedDescription)"
                }
            }
        }
    }

    private func buildCameraSession() throws -> (AVCaptureSession, AVCaptureVideoPreviewLayer) {
        let session = AVCaptureSession()
        session.beginConfiguration()
        session.sessionPreset = .hd1280x720

        guard let device = AVCaptureDevice.default(
            .builtInWideAngleCamera, for: .video, position: .front
        ) else {
            throw NSError(domain: "RecordingManager", code: 1,
                          userInfo: [NSLocalizedDescriptionKey: "Front camera unavailable."])
        }

        let deviceInput = try AVCaptureDeviceInput(device: device)
        guard session.canAddInput(deviceInput) else {
            throw NSError(domain: "RecordingManager", code: 2,
                          userInfo: [NSLocalizedDescriptionKey: "Cannot add camera input."])
        }
        session.addInput(deviceInput)

        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.alwaysDiscardsLateVideoFrames = true
        videoOutput.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
        ]
        // Delegate callbacks land on cameraQueue — writer state is safe here
        videoOutput.setSampleBufferDelegate(self, queue: cameraQueue)

        guard session.canAddOutput(videoOutput) else {
            throw NSError(domain: "RecordingManager", code: 3,
                          userInfo: [NSLocalizedDescriptionKey: "Cannot add video output."])
        }
        session.addOutput(videoOutput)

//        if let conn = videoOutput.connection(with: .video) {
//            if conn.isVideoOrientationSupported   { conn.videoOrientation = .portrait }
//            if conn.isVideoMirroringSupported     { conn.isVideoMirrored = true }
//        }
        if let conn = videoOutput.connection(with: .video) {

            if #available(macOS 14.0, iOS 17.0, *) {
                if conn.isVideoRotationAngleSupported(0) {
                    conn.videoRotationAngle = 0
                }
            } else {
                if conn.isVideoOrientationSupported {
                    conn.videoOrientation = .portrait
                }
            }

            if conn.isVideoMirroringSupported {
                conn.isVideoMirrored = true
            }
        }

        session.commitConfiguration()

        let preview = AVCaptureVideoPreviewLayer(session: session)
        preview.videoGravity = .resizeAspectFill
        return (session, preview)
    }

    func stopCameraRecording() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self else { return }
            self.cameraSession?.stopRunning()
            DispatchQueue.main.async { self.isCameraRecording = false }
            self.cameraQueue.async { self.finalizeCameraWriter() }
        }
    }

    // MARK: - Camera Writer  (ONLY called on cameraQueue)

    private func setupCameraWriter(formatDesc: CMFormatDescription) throws {
        let dims = CMVideoFormatDescriptionGetDimensions(formatDesc)
        let url  = makeTempURL(name: "camera")
        let writer = try AVAssetWriter(outputURL: url, fileType: .mov)

        let settings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: max(1, Int(dims.width)),
            AVVideoHeightKey: max(1, Int(dims.height)),
            AVVideoCompressionPropertiesKey: [
                AVVideoAverageBitRateKey: 2_000_000,
                AVVideoProfileLevelKey: AVVideoProfileLevelH264HighAutoLevel
            ]
        ]

        let input = AVAssetWriterInput(mediaType: .video, outputSettings: settings)
        input.expectsMediaDataInRealTime = true
        input.transform = CGAffineTransform(scaleX: -1, y: 1) // mirror front cam

        guard writer.canAdd(input) else {
            throw NSError(domain: "RecordingManager", code: 10,
                          userInfo: [NSLocalizedDescriptionKey: "Cannot add camera writer input."])
        }
        writer.add(input)
        cameraWriter = writer
        cameraWriterInput = input
        cameraStartTime = nil
        DispatchQueue.main.async { self.cameraFileURL = url }
    }

    private func finalizeCameraWriter() {
        guard let writer = cameraWriter, let input = cameraWriterInput,
              writer.status == .writing else {
            cameraWriter = nil; cameraWriterInput = nil; return
        }
        input.markAsFinished()
        writer.finishWriting { [weak self] in
            DispatchQueue.main.async {
                self?.cameraWriter = nil
                self?.cameraWriterInput = nil
                self?.cameraStartTime = nil
            }
        }
    }

    // MARK: - Screen Recording

    func startScreenRecording() {
        guard screenRecorder.isAvailable else {
            DispatchQueue.main.async {
                self.isScreenRecording = false
                self.errorMessage = "Screen recording blocked by AAC. Tap the broadcast button to use the Broadcast Extension instead."
            }
            return
        }

        screenQueue.async { [weak self] in
            self?.screenWriter = nil
            self?.screenWriterInput = nil
            self?.screenStartTime = nil
        }

        screenRecorder.isMicrophoneEnabled = false

        screenRecorder.startCapture { [weak self] sample, type, error in
            guard let self else { return }
            if let error {
                DispatchQueue.main.async {
                    self.errorMessage = "Screen capture: \(error.localizedDescription)"
                }
                return
            }
            guard type == .video, CMSampleBufferDataIsReady(sample) else { return }
            self.screenQueue.async { self.processScreenSample(sample) }

        } completionHandler: { [weak self] error in
            DispatchQueue.main.async {
                if let error {
                    self?.errorMessage = "Screen start failed: \(error.localizedDescription)"
                    self?.isScreenRecording = false
                } else {
                    self?.isScreenRecording = true
                }
            }
        }
    }

    private func processScreenSample(_ sample: CMSampleBuffer) {
        if screenWriter == nil {
            guard let fmt = CMSampleBufferGetFormatDescription(sample) else { return }
            do {
                try setupScreenWriter(formatDesc: fmt)
                let ts = CMSampleBufferGetPresentationTimeStamp(sample)
                screenStartTime = ts
                screenWriter?.startWriting()
                screenWriter?.startSession(atSourceTime: ts)
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = "Screen writer setup: \(error.localizedDescription)"
                }
                return
            }
        }
        guard let writer = screenWriter, writer.status == .writing,
              let input = screenWriterInput, input.isReadyForMoreMediaData else { return }
        input.append(sample)
    }

    private func setupScreenWriter(formatDesc: CMFormatDescription) throws {
        let dims = CMVideoFormatDescriptionGetDimensions(formatDesc)
        let url  = makeTempURL(name: "screen")
        let writer = try AVAssetWriter(outputURL: url, fileType: .mov)
        let settings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: max(1, Int(dims.width)),
            AVVideoHeightKey: max(1, Int(dims.height))
        ]
        let input = AVAssetWriterInput(mediaType: .video, outputSettings: settings)
        input.expectsMediaDataInRealTime = true
        guard writer.canAdd(input) else {
            throw NSError(domain: "RecordingManager", code: 11,
                          userInfo: [NSLocalizedDescriptionKey: "Cannot add screen writer input."])
        }
        writer.add(input)
        screenWriter = writer
        screenWriterInput = input
        DispatchQueue.main.async { self.screenFileURL = url }
    }

    func stopScreenRecording() {
        guard isScreenRecording || screenRecorder.isRecording else { return }
        screenRecorder.stopCapture { [weak self] error in
            guard let self else { return }
            if let error {
                DispatchQueue.main.async {
                    self.errorMessage = "Screen stop: \(error.localizedDescription)"
                }
            }
            self.screenQueue.async { self.finalizeScreenWriter() }
            DispatchQueue.main.async { self.isScreenRecording = false }
        }
    }

    private func finalizeScreenWriter() {
        guard let writer = screenWriter, let input = screenWriterInput,
              writer.status == .writing else {
            screenWriter = nil; screenWriterInput = nil; return
        }
        input.markAsFinished()
        writer.finishWriting { [weak self] in
            DispatchQueue.main.async {
                self?.screenWriter = nil
                self?.screenWriterInput = nil
                self?.screenStartTime = nil
            }
        }
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate

extension RecordingManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        // On cameraQueue — writer state is fully safe
        guard CMSampleBufferDataIsReady(sampleBuffer),
              let fmt = CMSampleBufferGetFormatDescription(sampleBuffer) else { return }

        if cameraWriter == nil {
            do {
                try setupCameraWriter(formatDesc: fmt)
                let ts = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
                cameraStartTime = ts
                cameraWriter?.startWriting()
                cameraWriter?.startSession(atSourceTime: ts)
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = "Camera writer init: \(error.localizedDescription)"
                }
                return
            }
        }

        guard let writer = cameraWriter, writer.status == .writing,
              let input = cameraWriterInput, input.isReadyForMoreMediaData else {
            if cameraWriter?.status == .failed {
                let msg = cameraWriter?.error?.localizedDescription ?? "unknown"
                DispatchQueue.main.async { self.errorMessage = "Camera writer failed: \(msg)" }
            }
            return
        }
        input.append(sampleBuffer)
    }
}
