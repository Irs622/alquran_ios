import Foundation
import Combine
import AVFoundation
import MediaPlayer
import SwiftUI
import UIKit

@MainActor
final class AudioPlayerService: NSObject, ObservableObject {
    static let shared = AudioPlayerService()

    @Published private(set) var isPlaying = false
    @Published private(set) var currentAyah: Ayah?
    @Published private(set) var progress: TimeInterval = 0
    @Published private(set) var duration: TimeInterval = 0
    @Published private(set) var playbackRate: Float = 1.0
    @Published private(set) var isBuffering = false
    @Published private(set) var downloadStatus: AudioDownloadStatus = .idle
    @Published private(set) var audioSettings: AudioSettings = PersistenceService.shared.audioSettings

    private let player = AVQueuePlayer()
    private var timeObserverToken: Any?
    private var currentSurah: Surah?
    private var itemMetadataMap: [String: Ayah] = [:]
    private var itemURLMap: [ObjectIdentifier: Ayah] = [:]
    private var interruptionObserver: Any?
    private var routeChangeObserver: Any?

    private override init() {
        super.init()
        playbackRate = audioSettings.playbackRate
        configureAudioSession()
        setupRemoteTransportControls()
        observePlayerProgress()
        observeAudioSessionNotifications()
    }

    deinit {
        if let token = timeObserverToken {
            player.removeTimeObserver(token)
        }
        if let observer = interruptionObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        if let observer = routeChangeObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    func selectReciter(_ reciter: Reciter) {
        audioSettings.selectedReciter = reciter
        persistAudioSettings()
        AppLogger.debug("Selected reciter: \(reciter.displayName)")
    }

    func setPlaybackRate(_ rate: Float) {
        playbackRate = rate
        audioSettings.playbackRate = rate
        persistAudioSettings()
        if isPlaying {
            player.rate = rate
        }
        updateNowPlayingInfo()
    }

    func playSurah(_ surah: Surah, fromAyah index: Int = 0) {
        guard let ayahs = surah.ayahs, !ayahs.isEmpty else { return }
        currentSurah = surah
        itemMetadataMap.removeAll()
        itemURLMap.removeAll()
        player.removeAllItems()

        let playlist = ayahs[index...].compactMap { ayah -> AVPlayerItem? in
            guard let url = audioURL(for: ayah) else { return nil }
            let item = AVPlayerItem(url: url)
            itemMetadataMap[ayah.reference] = ayah
            itemURLMap[ObjectIdentifier(item)] = ayah
            return item
        }

        for item in playlist {
            player.insert(item, after: nil)
        }

        if let firstItem = player.currentItem {
            updateCurrentAyah(from: firstItem)
            loadDuration(for: firstItem)
        }

        player.playImmediately(atRate: playbackRate)
        isPlaying = true
        if let firstAyah = ayahs[safe: index] {
            preloadNextAyahs(after: firstAyah)
        }
        updateNowPlayingInfo()
    }

    func playAyah(_ ayah: Ayah) {
        guard let url = audioURL(for: ayah) else { return }
        currentSurah = currentSurah ?? Surah(id: ayah.surahNumber, number: ayah.surahNumber, arabicName: "", englishName: "", translation: "", ayahCount: 0, revelationPlace: .mecca, ayahs: [ayah])
        let item = AVPlayerItem(url: url)
        itemMetadataMap[ayah.reference] = ayah
        itemURLMap[ObjectIdentifier(item)] = ayah
        player.removeAllItems()
        player.replaceCurrentItem(with: item)
        updateCurrentAyah(from: item)
        loadDuration(for: item)
        player.playImmediately(atRate: playbackRate)
        isPlaying = true
        preloadNextAyahs(after: ayah)
        updateNowPlayingInfo()
    }

    func pause() {
        player.pause()
        isPlaying = false
        updateNowPlayingInfo()
    }

    func resume() {
        player.playImmediately(atRate: playbackRate)
        isPlaying = true
        updateNowPlayingInfo()
    }

    func seek(to time: TimeInterval) {
        let target = CMTime(seconds: time, preferredTimescale: 600)
        player.seek(to: target)
    }

    func skipToNext() {
        player.advanceToNextItem()
        if let currentItem = player.currentItem {
            updateCurrentAyah(from: currentItem)
            loadDuration(for: currentItem)
        }
        updateNowPlayingInfo()
    }

    func skipToPrevious() {
        guard let currentAyah else {
            player.seek(to: .zero)
            return
        }
        guard let surah = currentSurah, let ayahs = surah.ayahs,
              let currentIndex = ayahs.firstIndex(where: { $0.reference == currentAyah.reference }),
              currentIndex > 0 else {
            player.seek(to: .zero)
            return
        }
        playSurah(surah, fromAyah: currentIndex - 1)
    }

    func downloadCurrentAyah() async {
        guard let ayah = currentAyah else { return }
        await downloadAyah(ayah)
    }

    func downloadSurah(_ surah: Surah) async {
        guard let ayahs = surah.ayahs else { return }
        downloadStatus = .downloading(progress: 0)

        for (index, ayah) in ayahs.enumerated() {
            await downloadAyah(ayah)
            let progress = Double(index + 1) / Double(ayahs.count)
            downloadStatus = .downloading(progress: progress)
        }

        downloadStatus = .completed
        AppLogger.info("Downloaded surah \(surah.number) for offline listening")
    }

    func clearAudioCache() {
        CacheService.shared.clearAudioCache()
    }

    func preloadNextAyahs(after current: Ayah, count: Int? = nil) {
        guard let surah = currentSurah, let ayahs = surah.ayahs,
              let currentIndex = ayahs.firstIndex(where: { $0.reference == current.reference }) else { return }
        let depth = count ?? audioSettings.preloadDepth
        let slice = ayahs.dropFirst(currentIndex + 1).prefix(depth)
        Task {
            for ayah in slice {
                if let url = ayah.audioURL(for: audioSettings.selectedReciter) {
                    try? await cacheAudio(url)
                }
            }
        }
    }

    func cachedAudioSizeDisplay() -> String {
        let bytes = CacheService.shared.audioCacheSize()
        let mb = Double(bytes) / 1_048_576
        return String(format: "%.1f MB cached", mb)
    }

    private func configureAudioSession() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playback, mode: .spokenAudio, options: [.allowBluetooth, .allowAirPlay, .mixWithOthers])
            try session.setActive(true)
        } catch {
            AppLogger.warning("Audio session configuration failed: \(error)")
        }
    }

    private func observeAudioSessionNotifications() {
        interruptionObserver = NotificationCenter.default.addObserver(
            forName: AVAudioSession.interruptionNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.handleAudioSessionInterruption(notification)
        }

        routeChangeObserver = NotificationCenter.default.addObserver(
            forName: AVAudioSession.routeChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.handleRouteChange(notification)
        }
    }

    private func handleAudioSessionInterruption(_ notification: Notification) {
        guard let info = notification.userInfo,
              let typeValue = info[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else { return }

        switch type {
        case .began:
            pause()
        case .ended:
            if let optionsValue = info[AVAudioSessionInterruptionOptionKey] as? UInt,
               AVAudioSession.InterruptionOptions(rawValue: optionsValue).contains(.shouldResume) {
                resume()
            }
        @unknown default:
            break
        }
    }

    private func handleRouteChange(_ notification: Notification) {
        guard let info = notification.userInfo,
              let reasonValue = info[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue) else { return }

        if reason == .oldDeviceUnavailable {
            pause()
        }
    }

    private func setupRemoteTransportControls() {
        let commandCenter = MPRemoteCommandCenter.shared()

        commandCenter.playCommand.addTarget { [weak self] _ in
            self?.resume()
            return .success
        }
        commandCenter.pauseCommand.addTarget { [weak self] _ in
            self?.pause()
            return .success
        }
        commandCenter.togglePlayPauseCommand.addTarget { [weak self] _ in
            guard let self else { return .commandFailed }
            if self.isPlaying { self.pause() } else { self.resume() }
            return .success
        }
        commandCenter.nextTrackCommand.addTarget { [weak self] _ in
            self?.skipToNext()
            return .success
        }
        commandCenter.previousTrackCommand.addTarget { [weak self] _ in
            self?.skipToPrevious()
            return .success
        }
        commandCenter.changePlaybackPositionCommand.addTarget { [weak self] event in
            guard let event = event as? MPChangePlaybackPositionCommandEvent else { return .commandFailed }
            self?.seek(to: event.positionTime)
            return .success
        }
    }

    private func observePlayerProgress() {
        let interval = CMTime(seconds: 0.5, preferredTimescale: 600)
        timeObserverToken = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            guard let self else { return }
            self.progress = CMTimeGetSeconds(time)
            self.duration = CMTimeGetSeconds(self.player.currentItem?.duration ?? .zero)
            self.updateNowPlayingInfo()
            self.syncCurrentAyahIfNeeded()
        }
    }

    private func updateCurrentAyah(from item: AVPlayerItem) {
        if let ayah = itemURLMap[ObjectIdentifier(item)] {
            currentAyah = ayah
        }
    }

    private func syncCurrentAyahIfNeeded() {
        guard let currentItem = player.currentItem,
              let ayah = itemURLMap[ObjectIdentifier(currentItem)],
              currentAyah?.reference != ayah.reference else {
            return
        }
        currentAyah = ayah
    }

    // itemURLMap replaces AVMetadataItem-based tracking (AVPlayerItem.externalMetadata
    // is not available on iOS). The map is keyed by ObjectIdentifier(item) so lookup
    // is O(1) and works correctly even when multiple items share the same URL.

    private func loadDuration(for item: AVPlayerItem) {
        item.asset.loadValuesAsynchronously(forKeys: ["duration"]) { [weak self] in
            DispatchQueue.main.async {
                guard let self else { return }
                self.duration = CMTimeGetSeconds(item.asset.duration)
                self.updateNowPlayingInfo()
            }
        }
    }

    private func audioURL(for ayah: Ayah) -> URL? {
        guard let remoteURL = ayah.audioURL(for: audioSettings.selectedReciter) else { return nil }
        let local = localAudioURL(for: remoteURL)
        if FileManager.default.fileExists(atPath: local.path) {
            return local
        }
        Task {
            try? await cacheAudio(remoteURL)
        }
        return remoteURL
    }

    private func localAudioURL(for remoteURL: URL) -> URL {
        CacheService.shared.localURL(forAudioURL: remoteURL)
    }

    private func downloadAyah(_ ayah: Ayah) async {
        guard let remoteURL = ayah.audioURL(for: audioSettings.selectedReciter) else { return }
        downloadStatus = .downloading(progress: 0)
        do {
            try await cacheAudio(remoteURL)
            downloadStatus = .completed
        } catch {
            downloadStatus = .failed(error.localizedDescription)
            AppLogger.warning("Download failed for ayah \(ayah.reference): \(error)")
        }
    }

    private func cacheAudio(_ url: URL) async throws {
        let local = localAudioURL(for: url)
        guard !FileManager.default.fileExists(atPath: local.path) else { return }
        let (data, _) = try await URLSession.shared.data(from: url)
        try data.write(to: local, options: .atomic)
        AppLogger.info("Cached audio \(url.absoluteString)")
    }

    private func persistAudioSettings() {
        PersistenceService.shared.audioSettings = audioSettings
    }

    private func updateNowPlayingInfo() {
        var info = [String: Any]()
        info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = progress
        info[MPMediaItemPropertyPlaybackDuration] = duration
        info[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? playbackRate : 0.0

        if let ayah = currentAyah {
            info[MPMediaItemPropertyTitle] = "Surah \(ayah.surahNumber) • Ayah \(ayah.ayahNumber)"
            info[MPMediaItemPropertyArtist] = ayah.surahName
            info[MPMediaItemPropertyAlbumTitle] = audioSettings.selectedReciter.displayName
        }

        if let artwork = UIImage(systemName: "waveform.path") {
            info[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: artwork.size) { _ in artwork }
        }

        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
