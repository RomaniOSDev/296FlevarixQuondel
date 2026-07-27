import UIKit
import AVFoundation

enum HapticService {
    private static let soundKey = "app_sound_enabled"
    private static let hapticsKey = "app_haptics_enabled"

    private static var player: AVAudioPlayer?
    private static var sessionReady = false

    enum Tone {
        case click
        case success
        case warning
    }

    static var soundEnabled: Bool {
        get {
            if UserDefaults.standard.object(forKey: soundKey) == nil { return true }
            return UserDefaults.standard.bool(forKey: soundKey)
        }
        set { UserDefaults.standard.set(newValue, forKey: soundKey) }
    }

    static var hapticsEnabled: Bool {
        get {
            if UserDefaults.standard.object(forKey: hapticsKey) == nil { return true }
            return UserDefaults.standard.bool(forKey: hapticsKey)
        }
        set { UserDefaults.standard.set(newValue, forKey: hapticsKey) }
    }

    static func light() {
        if hapticsEnabled {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
        play(.click)
    }

    static func medium() {
        if hapticsEnabled {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        }
        play(.click)
    }

    static func success() {
        if hapticsEnabled {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
        play(.success)
    }

    static func warning() {
        if hapticsEnabled {
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
        }
        play(.warning)
    }

    static func play(_ tone: Tone) {
        guard soundEnabled else { return }
        prepareSession()
        let data = wavData(for: tone)
        do {
            player = try AVAudioPlayer(data: data)
            player?.volume = 0.55
            player?.prepareToPlay()
            player?.play()
        } catch {
            // Silent fallback — never crash on audio init.
        }
    }

    /// Legacy numeric IDs map to click for any leftover call sites.
    static func play(_ id: UInt32) {
        _ = id
        play(.click)
    }

    private static func prepareSession() {
        guard !sessionReady else { return }
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.ambient, mode: .default, options: [.mixWithOthers])
        try? session.setActive(true)
        sessionReady = true
    }

    private static func wavData(for tone: Tone) -> Data {
        switch tone {
        case .click:
            return synthesizeWAV(frequency: 880, duration: 0.045, volume: 0.35)
        case .success:
            return synthesizeChordWAV(frequencies: [660, 990], duration: 0.12, volume: 0.4)
        case .warning:
            return synthesizeWAV(frequency: 320, duration: 0.14, volume: 0.4)
        }
    }

    private static func synthesizeWAV(frequency: Double, duration: Double, volume: Double) -> Data {
        let sampleRate = 22050.0
        let sampleCount = Int(sampleRate * duration)
        var samples = [Int16]()
        samples.reserveCapacity(sampleCount)
        for i in 0..<sampleCount {
            let t = Double(i) / sampleRate
            let envelope = exp(-t * 28)
            let value = sin(2 * .pi * frequency * t) * envelope * volume
            samples.append(Int16(max(-1, min(1, value)) * Double(Int16.max)))
        }
        return buildWAV(samples: samples, sampleRate: Int(sampleRate))
    }

    private static func synthesizeChordWAV(frequencies: [Double], duration: Double, volume: Double) -> Data {
        let sampleRate = 22050.0
        let sampleCount = Int(sampleRate * duration)
        var samples = [Int16]()
        samples.reserveCapacity(sampleCount)
        let amp = volume / Double(max(frequencies.count, 1))
        for i in 0..<sampleCount {
            let t = Double(i) / sampleRate
            let envelope = exp(-t * 16)
            var mixed = 0.0
            for frequency in frequencies {
                mixed += sin(2 * .pi * frequency * t)
            }
            let value = mixed * amp * envelope
            samples.append(Int16(max(-1, min(1, value)) * Double(Int16.max)))
        }
        return buildWAV(samples: samples, sampleRate: Int(sampleRate))
    }

    private static func buildWAV(samples: [Int16], sampleRate: Int) -> Data {
        let dataSize = samples.count * 2
        var data = Data()
        data.append(contentsOf: Array("RIFF".utf8))
        data.append(uint32: UInt32(36 + dataSize))
        data.append(contentsOf: Array("WAVE".utf8))
        data.append(contentsOf: Array("fmt ".utf8))
        data.append(uint32: 16)
        data.append(uint16: 1)
        data.append(uint16: 1)
        data.append(uint32: UInt32(sampleRate))
        data.append(uint32: UInt32(sampleRate * 2))
        data.append(uint16: 2)
        data.append(uint16: 16)
        data.append(contentsOf: Array("data".utf8))
        data.append(uint32: UInt32(dataSize))
        for sample in samples {
            var value = sample.littleEndian
            Swift.withUnsafeBytes(of: &value) { data.append(contentsOf: $0) }
        }
        return data
    }
}

private extension Data {
    mutating func append(uint16 value: UInt16) {
        var v = value.littleEndian
        Swift.withUnsafeBytes(of: &v) { append(contentsOf: $0) }
    }

    mutating func append(uint32 value: UInt32) {
        var v = value.littleEndian
        Swift.withUnsafeBytes(of: &v) { append(contentsOf: $0) }
    }
}
