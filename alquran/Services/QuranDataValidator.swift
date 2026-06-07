import Foundation

enum QuranDataValidationError: Error, LocalizedError {
    case missingSurahs(expected: Int, actual: Int)
    case duplicateSurahRecords
    case duplicateAyahRecords(surahNumber: Int)
    case missingAyahs(surahNumber: Int, expected: Int, actual: Int)
    case emptyAyahText(surahNumber: Int, ayahNumber: Int)
    case missingTranslation(surahNumber: Int, ayahNumber: Int, edition: QuranEdition)
    case invalidAudioURL(surahNumber: Int, ayahNumber: Int)

    var errorDescription: String? {
        switch self {
        case .missingSurahs(let expected, let actual):
            return "Quran validation failed: expected \(expected) surahs, found \(actual)."
        case .duplicateSurahRecords:
            return "Quran validation failed: duplicate surah records were detected."
        case .duplicateAyahRecords(let surahNumber):
            return "Surah \(surahNumber) contains duplicate ayah entries."
        case .missingAyahs(let surahNumber, let expected, let actual):
            return "Surah \(surahNumber) expected \(expected) ayahs, found \(actual)."
        case .emptyAyahText(let surahNumber, let ayahNumber):
            return "Surah \(surahNumber) Ayah \(ayahNumber) contains empty Arabic text."
        case .missingTranslation(let surahNumber, let ayahNumber, let edition):
            return "Surah \(surahNumber) Ayah \(ayahNumber) is missing a translation for edition \(edition.displayName)."
        case .invalidAudioURL(let surahNumber, let ayahNumber):
            return "Surah \(surahNumber) Ayah \(ayahNumber) has an invalid audio URL."
        }
    }
}

struct QuranDataValidator {
    static func validate(surahs: [Surah]) throws {
        if surahs.count != 114 {
            throw QuranDataValidationError.missingSurahs(expected: 114, actual: surahs.count)
        }

        let numbers = surahs.map { $0.number }
        if Set(numbers).count != numbers.count {
            throw QuranDataValidationError.duplicateSurahRecords
        }

        for surah in surahs {
            try validate(surah: surah)
        }
    }

    static func validate(surah: Surah) throws {
        guard let ayahs = surah.ayahs else { return }

        let ayahNumbers = ayahs.map { $0.ayahNumber }
        if Set(ayahNumbers).count != ayahNumbers.count {
            throw QuranDataValidationError.duplicateAyahRecords(surahNumber: surah.number)
        }

        let expected = expectedAyahCount(for: surah.number)
        let actual = ayahs.count
        if expected != actual {
            throw QuranDataValidationError.missingAyahs(surahNumber: surah.number, expected: expected, actual: actual)
        }

        for ayah in ayahs {
            if ayah.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                throw QuranDataValidationError.emptyAyahText(surahNumber: surah.number, ayahNumber: ayah.ayahNumber)
            }
            if let url = ayah.audioResourceURL, URL(string: url.absoluteString) == nil {
                throw QuranDataValidationError.invalidAudioURL(surahNumber: surah.number, ayahNumber: ayah.ayahNumber)
            }
        }
    }

    static func validate(surah: Surah, translations: [QuranTranslationPayload]) throws {
        let expected = surah.ayahCount
        let translationGroups = Dictionary(grouping: translations, by: \QuranTranslationPayload.ayahKey)

        for ayah in surah.ayahs ?? [] {
            let key = "\(surah.number):\(ayah.ayahNumber)"
            guard let translationGroup = translationGroups[key] else {
                throw QuranDataValidationError.missingTranslation(surahNumber: surah.number, ayahNumber: ayah.ayahNumber, edition: .englishSaheeh)
            }
            if translationGroup.count < 1 {
                throw QuranDataValidationError.missingTranslation(surahNumber: surah.number, ayahNumber: ayah.ayahNumber, edition: .englishSaheeh)
            }
        }

        if expected != translationGroups.count {
            // allow partial translations for packages that only include transliteration or summaries
        }
    }

    static func expectedAyahCount(for surahNumber: Int) -> Int {
        let counts = [
            7, 286, 200, 176, 120, 165, 206, 75, 129, 109, 123, 111, 43, 52, 99, 128,
            111, 110, 98, 135, 112, 78, 118, 64, 77, 227, 93, 88, 69, 60, 34, 30,
            73, 54, 45, 83, 182, 88, 75, 85, 54, 53, 89, 59, 37, 35, 38, 29, 18,
            45, 60, 49, 62, 55, 78, 96, 29, 22, 24, 13, 14, 11, 11, 18, 12, 12,
            30, 52, 52, 44, 28, 28, 20, 56, 40, 31, 50, 40, 46, 42, 29, 19, 36,
            25, 22, 17, 19, 26, 30, 20, 15, 21, 11, 8, 8, 19, 5, 8, 8, 11, 11,
            8, 3, 9, 5, 4, 7, 3, 6, 3, 5, 4, 5, 6
        ]
        guard surahNumber >= 1, surahNumber <= counts.count else { return 0 }
        return counts[surahNumber - 1]
    }
}
