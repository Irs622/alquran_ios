import SwiftUI

struct AudioPlayerControlsView: View {
    let title: String
    let subtitle: String
    let isPlaying: Bool
    let isBuffering: Bool
    let progress: Double
    let duration: Double
    let playbackRate: Float
    let selectedReciter: Reciter
    let downloadStatus: AudioDownloadStatus
    let cacheInfo: String

    let playSurahAction: () -> Void
    let pauseAction: () -> Void
    let resumeAction: () -> Void
    let seekAction: (Double) -> Void
    let changeRateAction: (Float) -> Void
    let selectReciterAction: (Reciter) -> Void
    let downloadCurrentAyahAction: () -> Void
    let downloadSurahAction: () -> Void
    let clearCacheAction: () -> Void
    let skipNextAction: () -> Void
    let skipPreviousAction: () -> Void

    private var durationText: String {
        guard duration.isFinite && duration > 0 else { return "--:--" }
        return timeString(from: duration)
    }

    private var progressText: String {
        guard progress.isFinite else { return "00:00" }
        return timeString(from: progress)
    }

    var body: some View {
        VStack(spacing: 18) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.companionText)
                        .lineLimit(2)
                    Text(subtitle)
                        .font(.footnote)
                        .foregroundColor(.companionTextSecondary)
                }
                Spacer()
                Menu {
                    ForEach(Reciter.allCases) { reciter in
                        Button(reciter.displayName) {
                            selectReciterAction(reciter)
                        }
                    }
                } label: {
                    Label(selectedReciter.displayName, systemImage: "person.crop.circle")
                        .font(.caption)
                        .foregroundColor(.companionAccent)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(RoundedRectangle(cornerRadius: 16).fill(Color.companionCard))
                }
            }

            VStack(spacing: 10) {
                Slider(value: Binding(
                    get: { progress },
                    set: { seekAction($0) }
                ), in: 0 ... max(duration, 1))
                HStack {
                    Text(progressText)
                    Spacer()
                    Text(durationText)
                }
                .font(.caption.monospaced())
                .foregroundColor(.companionTextSecondary)
            }

            HStack(spacing: 32) {
                Button(action: skipPreviousAction) {
                    Image(systemName: "backward.fill")
                        .font(.title2)
                        .foregroundColor(.companionAccent)
                        .padding(12)
                        .background(Circle().fill(Color.companionCard))
                }
                Button(action: isPlaying ? pauseAction : resumeAction) {
                    Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                        .font(.largeTitle)
                        .foregroundColor(.white)
                        .padding(18)
                        .background(Circle().fill(Color.companionAccent))
                }
                Button(action: skipNextAction) {
                    Image(systemName: "forward.fill")
                        .font(.title2)
                        .foregroundColor(.companionAccent)
                        .padding(12)
                        .background(Circle().fill(Color.companionCard))
                }
            }

            if isBuffering {
                ProgressView("Buffering…")
                    .progressViewStyle(CircularProgressViewStyle(tint: .companionEmerald))
            }

            HStack {
                Text("Speed")
                    .font(.caption)
                    .foregroundColor(.companionTextSecondary)
                Spacer()
                Stepper(value: Binding(
                    get: { playbackRate },
                    set: { changeRateAction($0) }
                ), in: 0.75...2.0, step: 0.25) {
                    Text(String(format: "%.2fx", playbackRate))
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.companionText)
                }
            }

            Button(action: playSurahAction) {
                Label("Play Full Surah", systemImage: "play.circle")
                    .font(.footnote.weight(.semibold))
                    .foregroundColor(.companionAccent)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.95)))
            }

            VStack(spacing: 10) {
                HStack {
                    Button(action: downloadCurrentAyahAction) {
                        Label("Download Ayah", systemImage: "square.and.arrow.down")
                            .font(.footnote.weight(.semibold))
                            .foregroundColor(.companionAccent)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.95)))
                    }
                    Button(action: downloadSurahAction) {
                        Label("Download Surah", systemImage: "tray.and.arrow.down")
                            .font(.footnote.weight(.semibold))
                            .foregroundColor(.companionAccent)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.95)))
                    }
                }
                HStack {
                    Text(downloadStatus.description)
                        .font(.caption)
                        .foregroundColor(.companionTextSecondary)
                    Spacer()
                    Button(action: clearCacheAction) {
                        Text(cacheInfo)
                            .font(.caption2)
                            .foregroundColor(.companionAccent)
                    }
                }
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 28).fill(Color.companionCard.opacity(0.88)))
        .overlay(RoundedRectangle(cornerRadius: 28).stroke(Color.companionTeal.opacity(0.08), lineWidth: 1))
    }

    private func timeString(from interval: Double) -> String {
        let time = Int(interval)
        let minutes = time / 60
        let seconds = time % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

enum AudioDownloadStatus: Equatable {
    case idle
    case downloading(progress: Double)
    case completed
    case failed(String)
}

extension AudioDownloadStatus {
    var description: String {
        switch self {
        case .idle: return "Offline status available"
        case .downloading(let progress): return String(format: "Downloading %.0f%%", progress * 100)
        case .completed: return "Downloaded for offline listening"
        case .failed(let message): return "Download failed: \(message)"
        }
    }
}

#Preview {
    AudioPlayerControlsView(
        title: "Surah 1 • Ayah 1",
        subtitle: "Mishary Rashid Alafasy",
        isPlaying: false,
        isBuffering: false,
        progress: 0,
        duration: 210,
        playbackRate: 1.0,
        selectedReciter: .alafasy,
        downloadStatus: .idle,
        cacheInfo: "10.2 MB cached",
        playSurahAction: {},
        pauseAction: {},
        resumeAction: {},
        seekAction: { _ in },
        changeRateAction: { _ in },
        selectReciterAction: { _ in },
        downloadCurrentAyahAction: {},
        downloadSurahAction: {},
        clearCacheAction: {},
        skipNextAction: {},
        skipPreviousAction: {}
    )
}
