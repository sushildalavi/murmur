import Foundation
#if canImport(AVFoundation)
import AVFoundation
#endif

public struct AudioLevelMeter {
    public init() {}

    public static func normalizedLevel(from decibels: Float) -> Double {
        guard decibels.isFinite else { return 0 }
        if decibels <= -80 { return 0 }
        let linearLevel = pow(10.0, Double(decibels) / 20.0)
        return min(max(linearLevel, 0), 1)
    }

    public static func normalizedLevel(from amplitudes: [Float]) -> Double {
        guard !amplitudes.isEmpty else { return 0 }
        let average = amplitudes.reduce(0) { $0 + abs(Double($1)) } / Double(amplitudes.count)
        return min(max(average, 0), 1)
    }

    #if canImport(AVFoundation)
    public static func normalizedLevel(from buffer: AVAudioPCMBuffer) -> Double {
        guard let floatChannelData = buffer.floatChannelData else { return 0 }
        let frameLength = Int(buffer.frameLength)
        guard frameLength > 0 else { return 0 }

        var total: Double = 0
        for channel in 0..<Int(buffer.format.channelCount) {
            let samples = floatChannelData[channel]
            for index in 0..<frameLength {
                total += abs(Double(samples[index]))
            }
        }

        let divisor = Double(frameLength * max(Int(buffer.format.channelCount), 1))
        return min(max(total / divisor, 0), 1)
    }
    #endif
}
