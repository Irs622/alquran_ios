import Foundation
import Combine
import SwiftUI

@MainActor
final class SurahDetailViewModel: ObservableObject {
    @Published private(set) var surah: Surah
    @Published var ayahs: [Ayah] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var selectedAyah: Ayah?
    @Published var isPlaying = false
    @Published var readerSettings = PersistenceService.shared.readerSettings
    @Published var highlightedAyahIDs: Set<String> = []
    @Published var readerNotes: [ReaderNote] = []
    @Published var collections: [BookmarkCollection] = []
    @Published var analytics = PersistenceService.shared.readingAnalytics

    private let repository = QuranRepository.shared
    private let persistence = PersistenceService.shared
    private let audioService = AudioPlayerService.shared

    init(surah: Surah) {
        self.surah = surah
        self.ayahs = surah.ayahs ?? []
        loadReaderState()
        Task { await loadDetail() }
    }

    func loadDetail() async {
        isLoading = true
        do {
            if let cached = try? await repository.loadSurahDetail(number: surah.number) {
                self.surah = cached
                self.ayahs = cached.ayahs ?? []
            }
            let updated = try await repository.refreshSurahDetail(number: surah.number)
            self.surah = updated
            self.ayahs = updated.ayahs ?? []
        } catch {
            self.errorMessage = (error as? LocalizedError)?.errorDescription ?? "Unable to load surah details."
            AppLogger.error("Surah detail failed: \(error)")
        }
        isLoading = false
    }

    func playSurah(from index: Int = 0) {
        guard !ayahs.isEmpty else { return }
        audioService.playSurah(surah, fromAyah: index)
        selectedAyah = ayahs[index]
        isPlaying = true
    }

    func playAyah(_ ayah: Ayah) {
        audioService.playAyah(ayah)
        selectedAyah = ayah
        isPlaying = true
    }

    func pause() {
        audioService.pause()
        isPlaying = false
    }

    func resume() {
        audioService.resume()
        isPlaying = true
    }

    func setPlaybackRate(_ rate: Float) {
        audioService.setPlaybackRate(rate)
    }

    func selectReciter(_ reciter: Reciter) {
        audioService.selectReciter(reciter)
    }

    func downloadCurrentAyah() async {
        await audioService.downloadCurrentAyah()
    }

    func downloadSurah() async {
        await audioService.downloadSurah(surah)
    }

    func clearAudioCache() {
        audioService.clearAudioCache()
    }

    func skipToNextAyah() {
        audioService.skipToNext()
    }

    func skipToPreviousAyah() {
        audioService.skipToPrevious()
    }

    func toggleBookmark(_ ayah: Ayah) {
        let bookmark = Bookmark(
            surahNumber: ayah.surahNumber,
            ayahNumber: ayah.ayahNumber,
            title: "\(surah.englishName) Ayah \(ayah.ayahNumber)",
            subtitle: ayah.text,
            createdAt: Date()
        )
        var bookmarks = persistence.bookmarks
        if let existing = bookmarks.firstIndex(where: { $0.surahNumber == bookmark.surahNumber && $0.ayahNumber == bookmark.ayahNumber }) {
            bookmarks.remove(at: existing)
        } else {
            bookmarks.insert(bookmark, at: 0)
        }
        persistence.bookmarks = bookmarks
    }

    func saveProgress(ayah: Ayah) {
        persistence.lastRead = ReadingProgress(surahNumber: surah.number, ayahNumber: ayah.ayahNumber, updatedAt: Date())
        recordReading(ayah: ayah)
    }

    func updateReaderSettings(_ settings: ReaderSettings) {
        readerSettings = settings
        persistence.readerSettings = settings
    }

    func toggleHighlight(_ ayah: Ayah, note: String? = nil) {
        let reference = "\(ayah.surahNumber)-\(ayah.ayahNumber)"
        if highlightedAyahIDs.contains(reference) {
            highlightedAyahIDs.remove(reference)
            persistence.ayahHighlights.removeAll { $0.reference == reference }
        } else {
            highlightedAyahIDs.insert(reference)
            var highlights = persistence.ayahHighlights
            highlights.append(AyahHighlight(surahNumber: ayah.surahNumber, ayahNumber: ayah.ayahNumber, note: note))
            persistence.ayahHighlights = highlights
        }
    }

    func saveNote(for ayah: Ayah, text: String) {
        var notes = persistence.readerNotes
        notes.removeAll { $0.surahNumber == ayah.surahNumber && $0.ayahNumber == ayah.ayahNumber }
        let note = ReaderNote(surahNumber: ayah.surahNumber, ayahNumber: ayah.ayahNumber, text: text)
        notes.append(note)
        persistence.readerNotes = notes
        readerNotes = notes
    }

    func addToCollection(_ ayah: Ayah, collection: BookmarkCollection) {
        var collections = persistence.bookmarkCollections
        guard let index = collections.firstIndex(where: { $0.id == collection.id }) else { return }
        let reference = AyahReference(surahNumber: ayah.surahNumber, ayahNumber: ayah.ayahNumber)
        if collections[index].items.contains(reference) == false {
            collections[index].items.append(reference)
        }
        persistence.bookmarkCollections = collections
        self.collections = collections
    }

    private func recordReading(ayah: Ayah) {
        var sessions = persistence.readingSessions
        sessions.append(ReadingSession(surahNumber: ayah.surahNumber, ayahNumber: ayah.ayahNumber, versesRead: 1))
        persistence.readingSessions = sessions
        updateAnalytics()
    }

    private func loadReaderState() {
        readerSettings = persistence.readerSettings
        highlightedAyahIDs = Set(persistence.ayahHighlights.map(\.reference))
        readerNotes = persistence.readerNotes
        collections = persistence.bookmarkCollections
        analytics = persistence.readingAnalytics
    }

    private func updateAnalytics() {
        analytics = persistence.readingAnalytics
    }
}
