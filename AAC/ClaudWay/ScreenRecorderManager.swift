//
//  ScreenRecorderManager.swift
//  AAC
//
//  Created by Arjunan on 18/04/26.
//

import AVFoundation
import Photos

#if os(iOS)
import ReplayKit
#endif

class ScreenRecorderManager: NSObject {
    private var assetWriter: AVAssetWriter?
    private var videoInput: AVAssetWriterInput?
    private var audioInput: AVAssetWriterInput?
    private var isWriting = false
    private var currentOutputURL: URL?

    private func makeOutputURL() -> URL {
        let docs = FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        )[0]
        return docs.appendingPathComponent(
            "proctor_\(Date().timeIntervalSince1970).mp4"
        )
    }

    // MARK: - Start

    func startRecording() {
        currentOutputURL = makeOutputURL()

#if os(iOS)
        startIOSRecording()
#elseif os(macOS)
        startMacRecording()
#endif
    }

#if os(iOS)
    private func startIOSRecording() {
        let recorder = RPScreenRecorder.shared()
        recorder.isMicrophoneEnabled = true

        recorder.startCapture(handler: { [weak self] buffer, bufferType, error in
            guard error == nil else {
                print("Capture error: \(error!)")
                return
            }
            self?.handleBuffer(buffer, type: bufferType)
        }) { error in
            if let error { print("Start capture error: \(error)") }
        }
    }
#endif

#if os(macOS)
    private var macCaptureSession: AVCaptureSession?
    private var macMovieOutput: AVCaptureMovieFileOutput?

    private func startMacRecording() {
        let captureSession = AVCaptureSession()

        // Screen input
        guard let screenInput = AVCaptureScreenInput(displayID: CGMainDisplayID()) else {
            print("❌ Cannot get screen input")
            return
        }
        screenInput.capturesCursor = true
        screenInput.capturesMouseClicks = true

        // Audio input
        if let audioDevice = AVCaptureDevice.default(for: .audio),
           let audioInput = try? AVCaptureDeviceInput(device: audioDevice),
           captureSession.canAddInput(audioInput) {
            captureSession.addInput(audioInput)
        }

        if captureSession.canAddInput(screenInput) {
            captureSession.addInput(screenInput)
        }

        let movieOutput = AVCaptureMovieFileOutput()
        if captureSession.canAddOutput(movieOutput) {
            captureSession.addOutput(movieOutput)
        }

        macCaptureSession = captureSession
        macMovieOutput = movieOutput

        captureSession.startRunning()

        if let url = currentOutputURL {
            movieOutput.startRecording(
                to: url,
                recordingDelegate: self
            )
            print("✅ macOS recording started at: \(url.path)")
        }
    }
#endif

    // MARK: - Buffer handling (iOS)

#if os(iOS)
    private func handleBuffer(_ buffer: CMSampleBuffer,
                               type: RPSampleBufferType) {
        if assetWriter == nil && type == .video {
            setupWriter(with: buffer)
        }

        guard let writer = assetWriter,
              writer.status == .writing else { return }

        switch type {
        case .video:
            if videoInput?.isReadyForMoreMediaData == true {
                videoInput?.append(buffer)
            }
        case .audioMic:
            if audioInput?.isReadyForMoreMediaData == true {
                audioInput?.append(buffer)
            }
        default:
            break
        }
    }

    private func setupWriter(with buffer: CMSampleBuffer) {
        guard !isWriting, let url = currentOutputURL else { return }
        isWriting = true

        try? FileManager.default.removeItem(at: url)

        guard let writer = try? AVAssetWriter(outputURL: url,
                                              fileType: .mp4) else {
            print("❌ Failed to create AVAssetWriter")
            return
        }

        let videoSettings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: 390,
            AVVideoHeightKey: 844
        ]
        let vInput = AVAssetWriterInput(mediaType: .video,
                                        outputSettings: videoSettings)
        vInput.expectsMediaDataInRealTime = true

        let audioSettings: [String: Any] = [
            AVFormatIDKey: kAudioFormatMPEG4AAC,
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 2,
            AVEncoderBitRateKey: 128000
        ]
        let aInput = AVAssetWriterInput(mediaType: .audio,
                                        outputSettings: audioSettings)
        aInput.expectsMediaDataInRealTime = true

        if writer.canAdd(vInput) { writer.add(vInput) }
        if writer.canAdd(aInput) { writer.add(aInput) }

        assetWriter = writer
        videoInput = vInput
        audioInput = aInput

        writer.startWriting()
        writer.startSession(
            atSourceTime: CMSampleBufferGetPresentationTimeStamp(buffer)
        )
        print("✅ iOS writer started at: \(url.path)")
    }
#endif

    // MARK: - Stop

    func stopRecording(completion: @escaping (URL?) -> Void) {
#if os(iOS)
        stopIOSRecording(completion: completion)
#elseif os(macOS)
        stopMacRecording(completion: completion)
#endif
    }

#if os(iOS)
    private func stopIOSRecording(completion: @escaping (URL?) -> Void) {
        RPScreenRecorder.shared().stopCapture { [weak self] error in
            guard let self else { return }
            if let error { print("Stop error: \(error)") }

            self.videoInput?.markAsFinished()
            self.audioInput?.markAsFinished()

            self.assetWriter?.finishWriting { [weak self] in
                guard let self, let url = self.currentOutputURL else { return }
                let size = (try? FileManager.default
                    .attributesOfItem(atPath: url.path)[.size] as? Int) ?? 0

                print("✅ File size: \(size) bytes")

                if size > 0 {
                    self.saveToPhotos(url: url, completion: completion)
                } else {
                    completion(nil)
                }

                self.resetState()
            }
        }
    }
#endif

#if os(macOS)
    private func stopMacRecording(completion: @escaping (URL?) -> Void) {
        macMovieOutput?.stopRecording()
        macCaptureSession?.stopRunning()

        // Give a moment for file to finalize
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let url = self?.currentOutputURL else {
                completion(nil)
                return
            }
            let exists = FileManager.default.fileExists(atPath: url.path)
            let size = (try? FileManager.default
                .attributesOfItem(atPath: url.path)[.size] as? Int) ?? 0

            print("macOS recording saved: \(exists), size: \(size) bytes")
            self?.resetState()
            completion(exists && size > 0 ? url : nil)
        }
    }
#endif

    // MARK: - Save to Photos (iOS only)

#if os(iOS)
    private func saveToPhotos(url: URL, completion: @escaping (URL?) -> Void) {
        PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
            guard status == .authorized || status == .limited else {
                print("❌ Photos permission denied")
                completion(url)
                return
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                PHPhotoLibrary.shared().performChanges {
                    PHAssetChangeRequest
                        .creationRequestForAssetFromVideo(atFileURL: url)
                } completionHandler: { success, error in
                    if success {
                        print("✅ Saved to Photos")
                    } else {
                        print("❌ Photos error: \(error?.localizedDescription ?? "")")
                    }
                    completion(url)
                }
            }
        }
    }
#endif

    private func resetState() {
        assetWriter = nil
        videoInput = nil
        audioInput = nil
        isWriting = false
        currentOutputURL = nil
    }
}

// MARK: - macOS movie file delegate
#if os(macOS)
extension ScreenRecorderManager: AVCaptureFileOutputRecordingDelegate {
    func fileOutput(_ output: AVCaptureFileOutput,
                    didFinishRecordingTo outputFileURL: URL,
                    from connections: [AVCaptureConnection],
                    error: Error?) {
        if let error {
            print("❌ macOS recording error: \(error)")
        } else {
            print("✅ macOS recording finished: \(outputFileURL.path)")
        }
    }
}
#endif


#if os(macOS)
import Foundation
import ScreenCaptureKit
import AVFoundation
import CoreMedia

final class MacScreenRecorder: NSObject {

    private var stream: SCStream?
    private var writer: AVAssetWriter?
    private var videoInput: AVAssetWriterInput?
    private var startTime: CMTime?

    private var outputURL: URL?

    // MARK: - Start Recording

    func startRecording() {
        Task {
            do {
                try await setupAndStart()
            } catch {
                print("❌ Start failed:", error)
            }
        }
    }

    private func makeURL() -> URL {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return dir.appendingPathComponent("mac_record_\(Date().timeIntervalSince1970).mp4")
    }

    private func setupWriter(width: Int, height: Int) throws {
        let url = makeURL()
        outputURL = url

        try? FileManager.default.removeItem(at: url)

        writer = try AVAssetWriter(outputURL: url, fileType: .mp4)

        let settings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: width,
            AVVideoHeightKey: height
        ]

        videoInput = AVAssetWriterInput(mediaType: .video, outputSettings: settings)
        videoInput?.expectsMediaDataInRealTime = true

        if let input = videoInput, writer!.canAdd(input) {
            writer!.add(input)
        }

        writer?.startWriting()
    }

    private func setupAndStart() async throws {

        // Get display
        let content = try await SCShareableContent.current
        guard let display = content.displays.first else {
            throw NSError(domain: "No display", code: -1)
        }

        // Stream config
        let config = SCStreamConfiguration()
        config.width = display.width
        config.height = display.height
        config.minimumFrameInterval = CMTime(value: 1, timescale: 30)
        config.queueDepth = 5

        // Content filter (full display)
        let filter = SCContentFilter(display: display, excludingWindows: [])

        try setupWriter(width: Int(display.width), height: Int(display.height))

        stream = SCStream(filter: filter, configuration: config, delegate: self)

        try stream?.addStreamOutput(self, type: .screen, sampleHandlerQueue: DispatchQueue(label: "screen.queue"))

        try await stream?.startCapture()

        print("✅ macOS Screen recording started")
    }

    // MARK: - Stop Recording

    func stopRecording(completion: @escaping (URL?) -> Void) {
        Task {
            do {
                try await stream?.stopCapture()
            } catch {
                print("❌ Stop capture error:", error)
            }

            videoInput?.markAsFinished()

            writer?.finishWriting { [weak self] in
                guard let url = self?.outputURL else {
                    completion(nil)
                    return
                }

                let size = (try? FileManager.default.attributesOfItem(atPath: url.path)[.size] as? Int) ?? 0
                print("📦 File size:", size)

                completion(size > 0 ? url : nil)
            }

            stream = nil
        }
    }
}

extension MacScreenRecorder: SCStreamOutput {
    func stream(_ stream: SCStream,
                didOutputSampleBuffer sampleBuffer: CMSampleBuffer,
                of outputType: SCStreamOutputType) {

        guard outputType == .screen,
              CMSampleBufferIsValid(sampleBuffer),
              CMSampleBufferDataIsReady(sampleBuffer) else { return }

        if startTime == nil {
            startTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
            writer?.startSession(atSourceTime: startTime!)
        }

        if videoInput?.isReadyForMoreMediaData == true {
            videoInput?.append(sampleBuffer)
        }
    }
}

extension MacScreenRecorder: SCStreamDelegate {
    func stream(_ stream: SCStream, didStopWithError error: Error) {
        print("❌ Stream stopped:", error)
    }
}

#endif
