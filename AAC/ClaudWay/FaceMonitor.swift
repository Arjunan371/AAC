//
//  FaceMonitor.swift
//  AAC
//
//  Created by Arjunan on 18/04/26.
//

import Vision
import AVFoundation

class FaceMonitor: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    var onViolation: ((String) -> Void)?
    var onFaceRestored: (() -> Void)?

    let captureSession = AVCaptureSession()
    private var lastFaceStatus: FaceStatus = .ok

    enum FaceStatus { case ok, missing, multiple }

    func start() {
#if os(iOS)
        let position: AVCaptureDevice.Position = .front
#elseif os(macOS)
        let position: AVCaptureDevice.Position = .front
#endif
        guard let device = AVCaptureDevice.default(
            .builtInWideAngleCamera,
            for: .video,
            position: position),
            let input = try? AVCaptureDeviceInput(device: device) else {
            print("❌ Camera not available")
            return
        }

        let output = AVCaptureVideoDataOutput()
        output.setSampleBufferDelegate(self,
            queue: DispatchQueue(label: "face.queue"))

        captureSession.beginConfiguration()
        if captureSession.canAddInput(input)   { captureSession.addInput(input) }
        if captureSession.canAddOutput(output) { captureSession.addOutput(output) }
        captureSession.commitConfiguration()

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession.startRunning()
        }
    }

    func stop() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession.stopRunning()
        }
    }

    func captureOutput(_ output: AVCaptureOutput,
                       didOutput buffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(buffer) else { return }

        let request = VNDetectFaceRectanglesRequest { [weak self] req, _ in
            guard let self else { return }
            let faces = req.results as? [VNFaceObservation] ?? []

            let newStatus: FaceStatus
            if faces.isEmpty        { newStatus = .missing }
            else if faces.count > 1 { newStatus = .multiple }
            else                    { newStatus = .ok }

            guard newStatus != self.lastFaceStatus else { return }
            self.lastFaceStatus = newStatus

            switch newStatus {
            case .missing:  self.onViolation?("No face detected")
            case .multiple: self.onViolation?("Multiple faces detected")
            case .ok:       self.onFaceRestored?()
            }
        }

        try? VNImageRequestHandler(
            cvPixelBuffer: pixelBuffer,
            options: [:]
        ).perform([request])
    }
}
