import Foundation
import Speech
import AVFoundation
import Observation

@MainActor
@Observable
final class SpeechService {

    // MARK: - Published state

    var transcript: String = ""
    var isRecording: Bool = false
    var errorMessage: String?
    var selectedLocale: Locale

    var supportedLocales: [Locale] {
        [Locale(identifier: "en-US"), Locale(identifier: "bn-BD")]
    }

    // MARK: - Private

    private var audioEngine: AVAudioEngine?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?

    // MARK: - Init

    init() {
        let lang = Locale.current.language.languageCode?.identifier ?? "en"
        selectedLocale = (lang == "bn") ? Locale(identifier: "bn-BD") : Locale(identifier: "en-US")
    }

    // MARK: - Permissions

    func requestPermissions() async -> Bool {
        let speechStatus = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }
        guard speechStatus == .authorized else {
            self.errorMessage = "Speech recognition permission denied."
            return false
        }

        #if os(iOS)
        let micGranted = await AVAudioApplication.requestRecordPermission()
        guard micGranted else {
            self.errorMessage = "Microphone permission denied."
            return false
        }
        #else
        let micGranted = await AVCaptureDevice.requestAccess(for: .audio)
        guard micGranted else {
            self.errorMessage = "Microphone permission denied."
            return false
        }
        #endif

        return true
    }

    // MARK: - Recording

    func startRecording() {
        guard !isRecording else { return }

        self.errorMessage = nil
        self.transcript = ""

        let recognizer = SFSpeechRecognizer(locale: selectedLocale)
        guard let recognizer, recognizer.isAvailable else {
            self.errorMessage = "Speech recognition unavailable for \(self.selectedLocale.identifier)."
            return
        }

        let engine = AVAudioEngine()
        self.audioEngine = engine

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        self.recognitionRequest = request

        #if os(iOS)
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.record, mode: .measurement, options: .duckOthers)
            try session.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            self.errorMessage = "Audio session error: \(error.localizedDescription)"
            cleanup()
            return
        }
        #endif

        let inputNode = engine.inputNode
        let format = inputNode.outputFormat(forBus: 0)
        guard format.sampleRate > 0 else {
            self.errorMessage = "Invalid audio format."
            cleanup()
            return
        }

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
            Task { @MainActor [weak self] in
                self?.recognitionRequest?.append(buffer)
            }
        }

        recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, error in
            Task { @MainActor [weak self] in
                guard let self else { return }
                if let result {
                    self.transcript = result.bestTranscription.formattedString
                }
                if error != nil, self.isRecording {
                    self.errorMessage = error?.localizedDescription
                    self.stopRecording()
                }
            }
        }

        do {
            engine.prepare()
            try engine.start()
            self.isRecording = true
        } catch {
            self.errorMessage = "Audio engine error: \(error.localizedDescription)"
            cleanup()
        }
    }

    func stopRecording() {
        guard isRecording else { return }
        isRecording = false
        cleanup()
    }

    // MARK: - Cleanup

    private func cleanup() {
        if let engine = audioEngine {
            engine.stop()
            engine.inputNode.removeTap(onBus: 0)
        }
        audioEngine = nil

        recognitionRequest?.endAudio()
        recognitionRequest = nil

        recognitionTask?.cancel()
        recognitionTask = nil

        #if os(iOS)
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        #endif
    }

    deinit {
        // Safe synchronous cleanup
    }
}
