import Foundation

enum QuranDataError: Error, LocalizedError {
    case invalidRemotePayload(String)
    case missingLocalData(number: Int)
    case syncFailed(String)

    var errorDescription: String? {
        switch self {
        case .invalidRemotePayload(let message):
            return "Quran sync failed: \(message)"
        case .missingLocalData(let number):
            return "Quran data is missing for Surah \(number)."
        case .syncFailed(let message):
            return "Quran sync failed: \(message)"
        }
    }
}

final class QuranSyncManager {
    static let shared = QuranSyncManager()

    private let apiService = QuranAPIService.shared
    private let store = try! QuranDataStore.shared
    private let persistence = PersistenceService.shared
    private let cacheManager = QuranCacheManager.shared
    private let requiredEditionTranslations: [QuranEdition] = [.indonesianKemenag, .englishSaheeh, .englishClear, .transliteration]
    private let syncInterval: TimeInterval = 60 * 60 * 24

    private init() {}

    func performInitialSync() async throws {
        let summaries = try await apiService.fetchSurahList()
        guard summaries.count == 114 else {
            throw QuranDataError.invalidRemotePayload("Expected 114 surahs, received \(summaries.count)")
        }

        try await store.saveSurahSummaries(summaries)
        try await syncAllSurahs(from: summaries)
        persistence.quranDataLastSync = Date()
    }

    func updateIfNeeded() async throws {
        guard let lastSync = persistence.quranDataLastSync else {
            try await performInitialSync()
            return
        }

        if Date().timeIntervalSince(lastSync) > syncInterval {
            try await syncIncrementalChanges()
            persistence.quranDataLastSync = Date()
        }
    }

    func syncSurah(number: Int, defaultTranslation: QuranEdition = .englishSaheeh) async throws -> Surah {
        let arabicSurah = try await apiService.fetchSurahDetail(number: number, edition: .arabicUthmani)
        let metadata = try await apiService.fetchSurahMetadata(number: number)
        let audioSources = try await apiService.fetchAudioSources(forSurah: number)
        let translationPayloads = try await buildTranslationPayloads(for: number)

        let syncedSurah = Surah(
            id: arabicSurah.id,
            number: arabicSurah.number,
            arabicName: arabicSurah.arabicName,
            englishName: arabicSurah.englishName,
            translation: arabicSurah.translation,
            ayahCount: arabicSurah.ayahCount,
            revelationPlace: arabicSurah.revelationPlace,
            metadata: metadata,
            audioSources: audioSources,
            lastSyncedAt: Date(),
            ayahs: arabicSurah.ayahs,
            remoteVersion: arabicSurah.remoteVersion
        )

        try QuranDataValidator.validate(surah: syncedSurah, translations: translationPayloads)
        try await store.save(surah: syncedSurah, translations: translationPayloads)
        return try await store.fetchSurahDetail(number: number, defaultTranslation: defaultTranslation) ?? syncedSurah
    }

    private func syncAllSurahs(from summaries: [Surah]) async throws {
        try await withThrowingTaskGroup(of: Void.self) { group in
            for summary in summaries {
                group.addTask { [requiredEditionTranslations, weak self] in
                    guard let self = self else { return }
                    _ = try await self.syncSurah(number: summary.number)
                }
            }
            try await group.waitForAll()
        }
    }

    private func syncIncrementalChanges() async throws {
        let remoteSummaries = try await apiService.fetchSurahList()
        let localSummaries = await store.fetchSurahSummaries()
        let localByNumber = Dictionary(uniqueKeysWithValues: localSummaries.map { ($0.number, $0) })

        let updatedSurahNumbers = remoteSummaries.compactMap { remote -> Int? in
            guard let local = localByNumber[remote.number] else { return remote.number }
            return local.remoteVersion != remote.remoteVersion ? remote.number : nil
        }

        guard !updatedSurahNumbers.isEmpty else { return }

        try await withThrowingTaskGroup(of: Void.self) { group in
            for number in updatedSurahNumbers {
                group.addTask { [weak self] in
                    guard let self = self else { return }
                    _ = try await self.syncSurah(number: number)
                }
            }
            try await group.waitForAll()
        }
    }

    private func buildTranslationPayloads(for number: Int) async throws -> [QuranTranslationPayload] {
        var payloads: [QuranTranslationPayload] = []

        for edition in requiredEditionTranslations {
            let editionSurah = try await apiService.fetchSurahDetail(number: number, edition: edition)
            for ayah in editionSurah.ayahs ?? [] {
                let translatorName: String?
                let language: String

                switch edition {
                case .indonesianKemenag:
                    translatorName = "Indonesian Ministry of Religious Affairs"
                    language = "id"
                case .englishSaheeh:
                    translatorName = "Saheeh International"
                    language = "en"
                case .englishClear:
                    translatorName = "Clear Quran"
                    language = "en"
                case .transliteration:
                    translatorName = "Uthmani Transliteration"
                    language = "en"
                default:
                    translatorName = nil
                    language = edition.isTranslation ? "en" : "ar"
                }

                payloads.append(QuranTranslationPayload(
                    ayahKey: "\(number):\(ayah.ayahNumber)",
                    edition: edition,
                    language: language,
                    translatorName: translatorName,
                    text: ayah.text
                ))
            }
        }

        return payloads
    }
}
