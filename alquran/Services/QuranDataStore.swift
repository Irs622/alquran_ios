import Foundation
import SwiftData

@available(iOS 17.0, *)
@Model
final class QuranSurahEntity: Identifiable {
    @Attribute(.unique) var number: Int
    var arabicName: String
    var englishName: String
    var englishTranslation: String
    var revelationPlace: RevelationPlace
    var ayahCount: Int
    var metadataData: Data?
    var audioSourcesData: Data?
    var lastSyncedAt: Date?
    var remoteVersion: String?
    @Relationship var ayahs: [QuranAyahEntity] = []

    init(number: Int, arabicName: String, englishName: String, englishTranslation: String, revelationPlace: RevelationPlace, ayahCount: Int) {
        self.number = number
        self.arabicName = arabicName
        self.englishName = englishName
        self.englishTranslation = englishTranslation
        self.revelationPlace = revelationPlace
        self.ayahCount = ayahCount
    }

    var metadata: SurahMetadata? {
        guard let data = metadataData else { return nil }
        return try? JSONDecoder().decode(SurahMetadata.self, from: data)
    }

    var audioSources: [QuranAudioSource]? {
        guard let data = audioSourcesData else { return nil }
        return try? JSONDecoder().decode([QuranAudioSource].self, from: data)
    }
}

@available(iOS 17.0, *)
@Model
final class QuranAyahEntity: Identifiable {
    @Attribute(.unique) var key: String
    var ayahNumber: Int
    var arabicText: String
    var transliteration: String?
    var juz: Int?
    var page: Int?
    var hizbQuarter: Int?
    var ruku: Int?
    var tafsir: String?
    var audioUrlString: String?
    var lastUpdatedAt: Date?
    @Relationship(inverse: \QuranSurahEntity.ayahs) var surah: QuranSurahEntity?
    @Relationship var translations: [QuranTranslationEntity] = []

    init(key: String, ayahNumber: Int, arabicText: String, transliteration: String? = nil, juz: Int? = nil, page: Int? = nil, hizbQuarter: Int? = nil, ruku: Int? = nil, tafsir: String? = nil, audioUrlString: String? = nil) {
        self.key = key
        self.ayahNumber = ayahNumber
        self.arabicText = arabicText
        self.transliteration = transliteration
        self.juz = juz
        self.page = page
        self.hizbQuarter = hizbQuarter
        self.ruku = ruku
        self.tafsir = tafsir
        self.audioUrlString = audioUrlString
    }

    var audioURL: URL? {
        if let audioUrlString = audioUrlString {
            return URL(string: audioUrlString)
        }
        return nil
    }
}

@available(iOS 17.0, *)
@Model
final class QuranTranslationEntity: Identifiable {
    @Attribute(.unique) var key: String
    var edition: QuranEdition
    var language: String
    var translatorName: String?
    var text: String
    @Relationship(inverse: \QuranAyahEntity.translations) var ayah: QuranAyahEntity?

    init(key: String, edition: QuranEdition, language: String, translatorName: String?, text: String) {
        self.key = key
        self.edition = edition
        self.language = language
        self.translatorName = translatorName
        self.text = text
    }
}

@available(iOS 17.0, *)
final class QuranDataStore {
    static let shared = try! QuranDataStore()

    private let container: ModelContainer
    private let context: ModelContext

    private init() throws {
        container = try ModelContainer(for: QuranSurahEntity.self, QuranAyahEntity.self, QuranTranslationEntity.self)
        context = container.mainContext
    }

    @MainActor
    func hasSurahData() -> Bool {
        let request = FetchDescriptor<QuranSurahEntity>()
        let stored = (try? context.fetch(request)) ?? []
        return !stored.isEmpty
    }

    @MainActor
    func fetchSurahSummaries() -> [Surah] {
        let request = FetchDescriptor<QuranSurahEntity>(sortBy: [SortDescriptor(\.number)])
        let entities = (try? context.fetch(request)) ?? []
        return entities.map { entity in
            Surah(
                id: entity.number,
                number: entity.number,
                arabicName: entity.arabicName,
                englishName: entity.englishName,
                translation: entity.englishTranslation,
                ayahCount: entity.ayahCount,
                revelationPlace: entity.revelationPlace,
                metadata: entity.metadata,
                audioSources: entity.audioSources,
                lastSyncedAt: entity.lastSyncedAt,
                ayahs: nil,
                remoteVersion: entity.remoteVersion
            )
        }
    }

    @MainActor
    func fetchSurahDetail(number: Int, defaultTranslation: QuranEdition = .englishSaheeh) -> Surah? {
        guard let entity = findSurahEntity(number: number) else { return nil }

        let ayahs = entity.ayahs
            .sorted(by: { $0.ayahNumber < $1.ayahNumber })
            .map { ayah in
                Ayah(
                    ayahNumber: ayah.ayahNumber,
                    surahNumber: number,
                    text: ayah.arabicText,
                    transliteration: ayah.transliteration,
                    translation: translationText(for: ayah, edition: defaultTranslation),
                    juz: ayah.juz,
                    page: ayah.page,
                    tafsir: ayah.tafsir,
                    audioResourceURL: ayah.audioURL,
                    hizbQuarter: ayah.hizbQuarter,
                    ruku: ayah.ruku,
                    lastUpdatedAt: ayah.lastUpdatedAt
                )
            }

        return Surah(
            id: entity.number,
            number: entity.number,
            arabicName: entity.arabicName,
            englishName: entity.englishName,
            translation: entity.englishTranslation,
            ayahCount: entity.ayahCount,
            revelationPlace: entity.revelationPlace,
            metadata: entity.metadata,
            audioSources: entity.audioSources,
            lastSyncedAt: entity.lastSyncedAt,
            ayahs: ayahs,
            remoteVersion: entity.remoteVersion
        )
    }

    @MainActor
    func saveSurahSummaries(_ summaries: [Surah]) throws {
        for summary in summaries {
            let entity: QuranSurahEntity
            if let existing = findSurahEntity(number: summary.number) {
                entity = existing
            } else {
                entity = QuranSurahEntity(
                    number: summary.number,
                    arabicName: summary.arabicName,
                    englishName: summary.englishName,
                    englishTranslation: summary.translation,
                    revelationPlace: summary.revelationPlace,
                    ayahCount: summary.ayahCount
                )
                context.insert(entity)
            }
            entity.arabicName = summary.arabicName
            entity.englishName = summary.englishName
            entity.englishTranslation = summary.translation
            entity.revelationPlace = summary.revelationPlace
            entity.ayahCount = summary.ayahCount
            entity.lastSyncedAt = summary.lastSyncedAt
            entity.remoteVersion = summary.remoteVersion
        }
        try context.save()
    }

    @MainActor
    func save(surah: Surah, translations: [QuranTranslationPayload]) throws {
        guard let ayahs = surah.ayahs, !ayahs.isEmpty else { return }
        let entity: QuranSurahEntity
        if let existing = findSurahEntity(number: surah.number) {
            entity = existing
        } else {
            entity = QuranSurahEntity(
                number: surah.number,
                arabicName: surah.arabicName,
                englishName: surah.englishName,
                englishTranslation: surah.translation,
                revelationPlace: surah.revelationPlace,
                ayahCount: surah.ayahCount
            )
            context.insert(entity)
        }

        entity.arabicName = surah.arabicName
        entity.englishName = surah.englishName
        entity.englishTranslation = surah.translation
        entity.revelationPlace = surah.revelationPlace
        entity.ayahCount = surah.ayahCount
        entity.lastSyncedAt = surah.lastSyncedAt
        entity.remoteVersion = surah.remoteVersion
        if let metadata = surah.metadata {
            entity.metadataData = try? JSONEncoder().encode(metadata)
        }
        if let audioSources = surah.audioSources {
            entity.audioSourcesData = try? JSONEncoder().encode(audioSources)
        }

        let existingAyahs = Dictionary(uniqueKeysWithValues: entity.ayahs.map { ($0.key, $0) })
        var updatedAyahs: [QuranAyahEntity] = []

        let groupedTranslations = Dictionary(grouping: translations, by: \QuranTranslationPayload.ayahKey)

        for ayah in ayahs {
            let ayahKey = "\(surah.number):\(ayah.ayahNumber)"
            let ayahEntity = existingAyahs[ayahKey] ?? QuranAyahEntity(
                key: ayahKey,
                ayahNumber: ayah.ayahNumber,
                arabicText: ayah.text,
                transliteration: ayah.transliteration,
                juz: ayah.juz,
                page: ayah.page,
                hizbQuarter: ayah.hizbQuarter,
                ruku: ayah.ruku,
                tafsir: ayah.tafsir,
                audioUrlString: ayah.audioResourceURL?.absoluteString
            )

            ayahEntity.ayahNumber = ayah.ayahNumber
            ayahEntity.arabicText = ayah.text
            ayahEntity.transliteration = ayah.transliteration
            ayahEntity.juz = ayah.juz
            ayahEntity.page = ayah.page
            ayahEntity.hizbQuarter = ayah.hizbQuarter
            ayahEntity.ruku = ayah.ruku
            ayahEntity.tafsir = ayah.tafsir
            ayahEntity.audioUrlString = ayah.audioResourceURL?.absoluteString
            ayahEntity.lastUpdatedAt = ayah.lastUpdatedAt
            ayahEntity.surah = entity

            let translationEntities = Dictionary(uniqueKeysWithValues: ayahEntity.translations.map { ($0.key, $0) })
            let payloads = groupedTranslations[ayahKey] ?? []
            var updatedTranslations: [QuranTranslationEntity] = []

            for payload in payloads {
                let translationKey = "\(ayahKey):\(payload.edition.rawValue)"
                let translationEntity = translationEntities[translationKey] ?? QuranTranslationEntity(
                    key: translationKey,
                    edition: payload.edition,
                    language: payload.language,
                    translatorName: payload.translatorName,
                    text: payload.text
                )

                translationEntity.edition = payload.edition
                translationEntity.language = payload.language
                translationEntity.translatorName = payload.translatorName
                translationEntity.text = payload.text
                translationEntity.ayah = ayahEntity
                updatedTranslations.append(translationEntity)
            }

            ayahEntity.translations = updatedTranslations
            updatedAyahs.append(ayahEntity)
        }

        let preservedKeys = Set(updatedAyahs.map { $0.key })
        for obsolete in entity.ayahs where !preservedKeys.contains(obsolete.key) {
            context.delete(obsolete)
        }

        entity.ayahs = updatedAyahs.sorted(by: { $0.ayahNumber < $1.ayahNumber })
        try context.save()
    }

    @MainActor
    func translationText(for ayah: QuranAyahEntity, edition: QuranEdition) -> String? {
        ayah.translations.first(where: { $0.edition == edition })?.text
    }

    @MainActor
    func searchAyahs(query: String, translation: QuranEdition) -> [Ayah] {
        let request = FetchDescriptor<QuranAyahEntity>()
        let entities = (try? context.fetch(request)) ?? []
        return entities.compactMap { ayah in
            let translationText = translationText(for: ayah, edition: translation)
            let haystack = [ayah.arabicText, ayah.transliteration ?? "", translationText ?? ""].joined(separator: " ").lowercased()
            guard haystack.contains(query.lowercased()) else { return nil }
            guard let surahNumber = ayah.surah?.number else { return nil }
            return Ayah(
                ayahNumber: ayah.ayahNumber,
                surahNumber: surahNumber,
                text: ayah.arabicText,
                transliteration: ayah.transliteration,
                translation: translationText,
                juz: ayah.juz,
                page: ayah.page,
                tafsir: ayah.tafsir,
                audioResourceURL: ayah.audioURL,
                hizbQuarter: ayah.hizbQuarter,
                ruku: ayah.ruku,
                lastUpdatedAt: ayah.lastUpdatedAt
            )
        }
    }

    private func findSurahEntity(number: Int) -> QuranSurahEntity? {
        let request = FetchDescriptor<QuranSurahEntity>(predicate: #Predicate { $0.number == number })
        return (try? context.fetch(request))?.first
    }
}
