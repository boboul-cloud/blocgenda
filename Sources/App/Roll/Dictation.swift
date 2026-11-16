import AVFoundation
import Foundation
import Observation
import Speech
import UIKit

/// La dictée : un micro autonome, qui écrit dans la barre sans faire monter
/// le clavier. On parle, la ligne se remplit ; on la relit, puis on imprime.
/// Rien n'est imprimé tout seul : la parole n'est qu'une façon d'écrire.
@Observable
@MainActor
final class Dictation {
    private(set) var isRecording = false
    /// Ce qu'il faut dire à qui a refusé le micro ou la reconnaissance.
    private(set) var message: String?
    /// Vrai quand seul un tour par les Réglages peut débloquer la situation.
    private(set) var needsSettings = false

    private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "fr_FR"))
    private let engine = AVAudioEngine()
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?
    private var silence: Timer?

    /// Le bouton ne s'affiche que si l'appareil sait écouter le français.
    var isAvailable: Bool { recognizer != nil }

    // MARK: - Marche et arrêt

    /// `onText` reçoit la transcription complète à chaque mot compris.
    func start(_ onText: @escaping (String) -> Void) {
        guard !isRecording else { return }
        message = nil
        needsSettings = false
        authorize { [weak self] granted in
            guard let self, granted else { return }
            self.listen(onText)
        }
    }

    func stop() {
        silence?.invalidate()
        silence = nil
        if engine.isRunning {
            engine.stop()
            engine.inputNode.removeTap(onBus: 0)
        }
        request?.endAudio()
        task?.cancel()
        request = nil
        task = nil
        if isRecording {
            isRecording = false
            UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
        }
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    func openSettings() {
        guard needsSettings, let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }

    // MARK: - Autorisations

    private func authorize(_ done: @escaping (Bool) -> Void) {
        SFSpeechRecognizer.requestAuthorization { status in
            Task { @MainActor in
                guard status == .authorized else {
                    self.refuse("Blocgenda n'a pas l'autorisation de transcrire la parole.",
                                settled: status != .notDetermined)
                    done(false)
                    return
                }
                AVAudioApplication.requestRecordPermission { granted in
                    Task { @MainActor in
                        guard granted else {
                            self.refuse("Blocgenda n'a pas accès au micro.", settled: true)
                            done(false)
                            return
                        }
                        done(true)
                    }
                }
            }
        }
    }

    private func refuse(_ reason: String, settled: Bool) {
        needsSettings = settled
        message = settled ? "\(reason) Touchez ici pour l'autoriser dans les Réglages." : reason
    }

    // MARK: - Écoute

    private func listen(_ onText: @escaping (String) -> Void) {
        guard let recognizer, recognizer.isAvailable else {
            message = "La dictée est indisponible pour le moment."
            return
        }
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.record, mode: .measurement, options: .duckOthers)
            try session.setActive(true, options: .notifyOthersOnDeactivation)

            let request = SFSpeechAudioBufferRecognitionRequest()
            request.shouldReportPartialResults = true
            // Sur l'appareil dès que c'est possible : la parole ne part nulle part.
            request.requiresOnDeviceRecognition = recognizer.supportsOnDeviceRecognition
            request.addsPunctuation = true
            self.request = request

            let input = engine.inputNode
            input.removeTap(onBus: 0)
            input.installTap(onBus: 0, bufferSize: 1024, format: input.outputFormat(forBus: 0)) { buffer, _ in
                request.append(buffer)
            }
            engine.prepare()
            try engine.start()

            isRecording = true
            armSilence()
            UIImpactFeedbackGenerator(style: .soft).impactOccurred()

            task = recognizer.recognitionTask(with: request) { [weak self] result, error in
                let heard = result?.bestTranscription.formattedString
                let isFinal = result?.isFinal ?? false
                let failed = error != nil
                Task { @MainActor in
                    guard let self, self.isRecording else { return }
                    if let heard, !heard.isEmpty {
                        onText(heard)
                        self.armSilence()
                    }
                    if isFinal || failed { self.stop() }
                }
            }
        } catch {
            message = "Le micro n'a pas pu démarrer."
            stop()
        }
    }

    /// Deux secondes sans un mot : la phrase est finie, on rend la main.
    /// Sans cela, le micro resterait ouvert jusqu'à ce qu'on y repense.
    private func armSilence() {
        silence?.invalidate()
        silence = Timer.scheduledTimer(withTimeInterval: 2.2, repeats: false) { [weak self] _ in
            Task { @MainActor in self?.stop() }
        }
    }
}
