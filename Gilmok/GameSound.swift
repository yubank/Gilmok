import AVFoundation

enum GameCue {
    case upgradeStart
    case upgradeDone
    case place
    case merge
    case mine
    case boom
    case wave
    case boss
    case recall
    case win
    case lose
    case dog
    case robotRoar
    case tankFire
    case ufo
}

final class GameAudio {
    static let shared = GameAudio()

    private let engine = AVAudioEngine()
    private let format = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 1)
    private let musicNode = AVAudioPlayerNode()
    private var nodes: [AVAudioPlayerNode] = []
    private var buffers: [GameCue: AVAudioPCMBuffer] = [:]
    private var cursor = 0
    private var ready = false
    private var lastBoom: TimeInterval = 0
    private var lastTank: TimeInterval = 0

    private let musicVolume: Float = 1
    private(set) var effectsEnabled: Bool
    private(set) var musicEnabled: Bool

    private init() {
        let defaults = UserDefaults.standard
        effectsEnabled = defaults.object(forKey: "gilmok.effectsEnabled") as? Bool ?? true
        musicEnabled = defaults.object(forKey: "gilmok.musicEnabled") as? Bool ?? true
    }

    func setEffectsEnabled(_ enabled: Bool) {
        effectsEnabled = enabled
        UserDefaults.standard.set(enabled, forKey: "gilmok.effectsEnabled")
    }

    func setMusicEnabled(_ enabled: Bool) {
        musicEnabled = enabled
        UserDefaults.standard.set(enabled, forKey: "gilmok.musicEnabled")
        prepare()
        musicNode.volume = enabled ? musicVolume : 0
    }

    func startMusic() {
        prepare()
        musicNode.volume = musicEnabled ? musicVolume : 0
    }

    func play(_ cue: GameCue) {
        guard effectsEnabled else { return }
        if cue == .boom {
            let now = CACurrentMediaTime()
            if now - lastBoom < 0.12 { return }
            lastBoom = now
        }
        if cue == .tankFire {
            let now = CACurrentMediaTime()
            if now - lastTank < 0.35 { return }
            lastTank = now
        }
        prepare()
        guard let buffer = buffers[cue], !nodes.isEmpty else { return }
        let node = nodes[cursor % nodes.count]
        cursor += 1
        node.scheduleBuffer(buffer, completionHandler: nil)
    }

    private func prepare() {
        guard !ready, let format else { return }
        ready = true
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.ambient, options: [.mixWithOthers])
        try? session.setActive(true)
        for _ in 0..<4 {
            let node = AVAudioPlayerNode()
            engine.attach(node)
            engine.connect(node, to: engine.mainMixerNode, format: format)
            nodes.append(node)
        }
        engine.attach(musicNode)
        engine.connect(musicNode, to: engine.mainMixerNode, format: format)
        let cues: [GameCue] = [
            .upgradeStart, .upgradeDone, .place, .merge, .mine, .boom, .wave, .boss, .recall, .win, .lose,
            .dog, .robotRoar, .tankFire, .ufo,
        ]
        for cue in cues {
            if let buffer = pcm(render(cue)) { buffers[cue] = buffer }
        }
        do {
            try engine.start()
            nodes.forEach { $0.play() }
            if let music = pcm(backgroundMusic()) {
                musicNode.scheduleBuffer(music, at: nil, options: .loops)
                musicNode.volume = musicEnabled ? musicVolume : 0
                musicNode.play()
            }
        } catch {
            nodes.removeAll()
        }
    }

    private func render(_ cue: GameCue) -> [Float] {
        switch cue {
        case .upgradeStart:
            return chain([(523, 0.07, 0.22), (659, 0.12, 0.24)])
        case .upgradeDone:
            return chain([(784, 0.08, 0.2), (988, 0.08, 0.22), (1175, 0.18, 0.2)])
        case .place:
            return chain([(494, 0.05, 0.16)])
        case .merge:
            return chain([(523, 0.07, 0.18), (659, 0.07, 0.2), (784, 0.16, 0.22)])
        case .mine:
            return chain([(196, 0.1, 0.26)])
        case .boom:
            return noiseBurst(seconds: 0.16, gain: 0.28)
        case .wave:
            return sweep(from: 320, to: 740, seconds: 0.16, gain: 0.14)
        case .boss:
            return chain([(196, 0.12, 0.26), (156, 0.18, 0.28)])
        case .recall:
            return chain([(698, 0.06, 0.14), (523, 0.11, 0.16)])
        case .win:
            return chain([(523, 0.1, 0.18), (659, 0.1, 0.18), (784, 0.1, 0.2), (1046, 0.24, 0.2)])
        case .lose:
            return chain([(392, 0.12, 0.2), (349, 0.12, 0.18), (262, 0.24, 0.2)])
        case .dog:
            return chain([(620, 0.05, 0.13), (430, 0.09, 0.18)])
        case .robotRoar:
            return growl(seconds: 0.42, gain: 0.28)
        case .tankFire:
            return noiseBurst(seconds: 0.24, gain: 0.34)
        case .ufo:
            return sweep(from: 980, to: 420, seconds: 0.36, gain: 0.16)
        }
    }

    private func backgroundMusic() -> [Float] {
        let rate: Float = 44_100
        let beat: Float = 60 / 108
        let bar = beat * 4
        let count = Int(rate * bar * 2)
        let mi: Float = 41.2
        let doh: Float = 32.7
        return (0..<count).map { index in
            let time = Float(index) / rate
            let barIndex = min(1, Int(time / bar))
            let withinBar = time - Float(barIndex) * bar
            let root: Float = barIndex == 0 ? mi : doh
            let beatAge = time - Float(Int(time / beat)) * beat
            return bassGuitar(root, withinBar) + kick(beatAge)
        }
    }

    private func bassGuitar(_ frequency: Float, _ age: Float) -> Float {
        let attack = min(1, age / 0.012)
        let body = sin(2 * Float.pi * frequency * age) * 0.7
            + sin(4 * Float.pi * frequency * age) * 0.22
            + sin(6 * Float.pi * frequency * age) * 0.08
        let held = exp(-age * 0.28)
        let pick = sin(2 * Float.pi * 180 * age) * exp(-age * 70) * 0.14
        return (body * attack * (0.64 + 0.36 * held) + pick) * 0.4
    }

    private func kick(_ age: Float) -> Float {
        guard age >= 0, age < 0.22 else { return 0 }
        let tau: Float = 0.035
        let phase = 2 * Float.pi * (42 * age + (128 - 42) * tau * (1 - exp(-age / tau)))
        let env = exp(-age * 11)
        let beater = exp(-age * 90) * 0.28
        return (sin(phase) * 0.9 + beater) * env * 0.5
    }

    private func growl(seconds: Float, gain: Float) -> [Float] {
        let count = Int(44_100 * seconds)
        var phase: Float = 0
        return (0..<count).map { index in
            let progress = Float(index) / Float(max(1, count - 1))
            let frequency = 92 + 42 * sin(progress * Float.pi)
            phase += 2 * Float.pi * frequency / 44_100
            let rough = sin(phase) + 0.45 * sin(phase * 2.03) + 0.2 * sin(phase * 3.91)
            return rough * gain * sin(Float.pi * progress)
        }
    }

    private func chain(_ notes: [(Float, Float, Float)]) -> [Float] {
        notes.flatMap { note($0.0, $0.1, $0.2) }
    }

    private func note(_ frequency: Float, _ seconds: Float, _ gain: Float) -> [Float] {
        let count = Int(44_100 * seconds)
        guard count > 0 else { return [] }
        return (0..<count).map { index in
            let time = Float(index) / 44_100
            let attack = min(1, time / 0.008)
            let envelope = attack * exp(-3.2 * time / seconds)
            return sin(2 * Float.pi * frequency * time) * gain * envelope
        }
    }

    private func sweep(from start: Float, to end: Float, seconds: Float, gain: Float) -> [Float] {
        let count = Int(44_100 * seconds)
        guard count > 1 else { return [] }
        var phase: Float = 0
        return (0..<count).map { index in
            let progress = Float(index) / Float(count - 1)
            let frequency = start + (end - start) * progress
            phase += 2 * Float.pi * frequency / 44_100
            let envelope = sin(Float.pi * progress)
            return sin(phase) * gain * envelope
        }
    }

    private func noiseBurst(seconds: Float, gain: Float) -> [Float] {
        let count = Int(44_100 * seconds)
        var seed: UInt32 = 0x12345678
        return (0..<count).map { index in
            seed = seed &* 1664525 &+ 1013904223
            let noise = Float(Int32(bitPattern: seed)) / Float(Int32.max)
            let time = Float(index) / 44_100
            let thump = sin(2 * Float.pi * 90 * time)
            let envelope = exp(-7 * time / seconds)
            return (noise * 0.55 + thump * 0.45) * gain * envelope
        }
    }

    private func pcm(_ samples: [Float]) -> AVAudioPCMBuffer? {
        guard let format, let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(samples.count)) else { return nil }
        buffer.frameLength = AVAudioFrameCount(samples.count)
        guard let channel = buffer.floatChannelData?[0] else { return nil }
        for index in samples.indices { channel[index] = samples[index] }
        return buffer
    }
}
