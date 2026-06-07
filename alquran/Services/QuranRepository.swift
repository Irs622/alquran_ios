import Foundation

@MainActor
final class QuranRepository {
    static let shared = QuranRepository()

    private let store = try! QuranDataStore.shared
    private let syncManager = QuranSyncManager.shared

    private init() {}

    func loadSurahSummaries() async throws -> [Surah] {
        if await store.hasSurahData() {
            return await store.fetchSurahSummaries()
        }

        try await syncManager.performInitialSync()
        return await store.fetchSurahSummaries()
    }

    func loadSurahDetail(number: Int, defaultTranslation: QuranEdition = .englishSaheeh) async throws -> Surah {
        if let local = await store.fetchSurahDetail(number: number, defaultTranslation: defaultTranslation) {
            return local
        }

        return try await syncManager.syncSurah(number: number, defaultTranslation: defaultTranslation)
    }

    func refreshSurahDetail(number: Int, defaultTranslation: QuranEdition = .englishSaheeh) async throws -> Surah {
        return try await syncManager.syncSurah(number: number, defaultTranslation: defaultTranslation)
    }

    func refreshIfNeeded() async throws {
        try await syncManager.updateIfNeeded()
    }

    func searchAyahs(query: String, translation: QuranEdition = .englishSaheeh) async throws -> [Ayah] {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return []
        }

        return await store.searchAyahs(query: query, translation: translation)
    }
}
