import Foundation

protocol AudioPermissionStatusProviding: Sendable {
    func currentPermissionStatus() async -> SetupStatusItem
}

#if canImport(AVFoundation)
import AVFoundation

enum AudioCaptureError: LocalizedError {
    case microphonePermissionDenied
    case recorderUnavailable
    case noRecordingData

    var errorDescription: String? {
        switch self {
        case .microphonePermissionDenied:
            return "Microphone access is required to record dictation."
        case .recorderUnavailable:
            return "Audio recording is not available right now."
        case .noRecordingData:
            return "No audio was recorded."
        }
    }
}

actor SystemAudioCaptureService: AudioCaptureServicing {
    private var recorder: AVAudioRecorder?
    private var recordingURL: URL?

    func startCapture() async throws {
        try await ensurePermission()

        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, mode: .spokenAudio, options: [.defaultToSpeaker, .allowBluetooth])
        try session.setActive(true)

        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("flowtype-\(UUID().uuidString)")
            .appendingPathExtension("m4a")

        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44_100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        let recorder = try AVAudioRecorder(url: outputURL, settings: settings)
        recorder.isMeteringEnabled = false
        guard recorder.prepareToRecord(), recorder.record() else {
            throw AudioCaptureError.recorderUnavailable
        }

        self.recorder = recorder
        self.recordingURL = outputURL
    }

    func stopCapture() async throws -> AudioCaptureResult {
        guard let recorder, let recordingURL else {
            throw AudioCaptureError.recorderUnavailable
        }

        let duration = recorder.currentTime
        recorder.stop()

        self.recorder = nil
        self.recordingURL = nil

        let data = try Data(contentsOf: recordingURL)
        try? FileManager.default.removeItem(at: recordingURL)
        try? AVAudioSession.sharedInstance().setActive(false)

        guard !data.isEmpty else {
            throw AudioCaptureError.noRecordingData
        }

        return AudioCaptureResult(
            audioPayload: data,
            durationSeconds: duration,
            fileExtension: recordingURL.pathExtension.isEmpty ? "m4a" : recordingURL.pathExtension
        )
    }

    private func ensurePermission() async throws {
        switch AVAudioSession.sharedInstance().recordPermission {
        case .granted:
            return
        case .denied:
            throw AudioCaptureError.microphonePermissionDenied
        case .undetermined:
            let granted = await withCheckedContinuation { continuation in
                AVAudioSession.sharedInstance().requestRecordPermission { allowed in
                    continuation.resume(returning: allowed)
                }
            }
            if !granted {
                throw AudioCaptureError.microphonePermissionDenied
            }
        @unknown default:
            throw AudioCaptureError.microphonePermissionDenied
        }
    }
}

extension SystemAudioCaptureService: AudioPermissionStatusProviding {
    func currentPermissionStatus() async -> SetupStatusItem {
        switch AVAudioSession.sharedInstance().recordPermission {
        case .granted:
            return SetupStatusItem(
                state: .ready,
                detail: "Microphone access is granted."
            )
        case .denied:
            return SetupStatusItem(
                state: .failed(message: "Microphone access denied."),
                detail: "Enable microphone access in Settings to record dictation."
            )
        case .undetermined:
            return SetupStatusItem(
                state: .unavailable,
                detail: "Microphone permission has not been requested yet."
            )
        @unknown default:
            return SetupStatusItem(
                state: .failed(message: "Unknown microphone status."),
                detail: "Microphone permission could not be determined."
            )
        }
    }
}
#else
enum AudioCaptureError: LocalizedError {
    case recorderUnavailable

    var errorDescription: String? {
        "Audio recording requires AVFoundation support."
    }
}

struct SystemAudioCaptureService: AudioCaptureServicing {
    func startCapture() async throws {
        throw AudioCaptureError.recorderUnavailable
    }

    func stopCapture() async throws -> AudioCaptureResult {
        throw AudioCaptureError.recorderUnavailable
    }
}

extension SystemAudioCaptureService: AudioPermissionStatusProviding {
    func currentPermissionStatus() async -> SetupStatusItem {
        SetupStatusItem(
            state: .failed(message: "AVFoundation unavailable."),
            detail: "Microphone diagnostics require AVFoundation support."
        )
    }
}
#endif
