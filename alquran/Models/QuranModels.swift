import Foundation
import SwiftUI

enum RevelationPlace: String, CaseIterable, Codable, Identifiable {
    case mecca = "Meccan"
    case medina = "Medinan"

    var id: String { rawValue }

    var displayName: String {
        rawValue
    }
}

struct SurahMetadata: Codable {
    let chapters: Int?
    let rukus: Int?
    let sajdaCount: Int?
    let revelationOrder: Int?
    let translationLanguage: String?
    let bismillahPre: Bool?
}

struct QuranAudioSource: Codable, Identifiable {
    let id = UUID()
    let reciter: String
    let language: String
    let url: URL
    let description: String?
}

struct Surah: Identifiable, Codable {
    let id: Int
    let number: Int
    let arabicName: String
    let englishName: String
    let translation: String
    let ayahCount: Int
    let revelationPlace: RevelationPlace
    let metadata: SurahMetadata?
    let audioSources: [QuranAudioSource]?
    let lastSyncedAt: Date?
    let ayahs: [Ayah]?
    let remoteVersion: String?

    init(
        id: Int,
        number: Int,
        arabicName: String,
        englishName: String,
        translation: String,
        ayahCount: Int,
        revelationPlace: RevelationPlace,
        metadata: SurahMetadata? = nil,
        audioSources: [QuranAudioSource]? = nil,
        lastSyncedAt: Date? = nil,
        ayahs: [Ayah]? = nil,
        remoteVersion: String? = nil
    ) {
        self.id = id
        self.number = number
        self.arabicName = arabicName
        self.englishName = englishName
        self.translation = translation
        self.ayahCount = ayahCount
        self.revelationPlace = revelationPlace
        self.metadata = metadata
        self.audioSources = audioSources
        self.lastSyncedAt = lastSyncedAt
        self.ayahs = ayahs
        self.remoteVersion = remoteVersion
    }

    var description: String {
        "\(englishName) • \(ayahCount) ayahs"
    }

    func audioURL(for ayah: Ayah) -> URL? {
        audioSources?.first?.url ?? Reciter.alafasy.audioURL(surah: number, ayah: ayah.ayahNumber)
    }

    static func loadFallbackSurahs() -> [Surah] {
        guard let url = Bundle.main.url(forResource: "QuranSample", withExtension: "json") else {
            AppLogger.warning("Fallback sample file not found")
            return []
        }
        do {
            let data = try Data(contentsOf: url)
            let sample = try JSONDecoder().decode(SampleSurahResponse.self, from: data)
            return sample.surahs.map { $0.asSurah() }
        } catch {
            AppLogger.error("Failed to load fallback sample: \(error)")
            return []
        }
    }
}

struct Ayah: Identifiable, Codable {
    let id = UUID()
    let ayahNumber: Int
    let surahNumber: Int
    let text: String
    let transliteration: String?
    let translation: String?
    let juz: Int?
    let page: Int?
    let tafsir: String?
    let audioResourceURL: URL?
    let hizbQuarter: Int?
    let ruku: Int?
    let lastUpdatedAt: Date?

    init(
        ayahNumber: Int,
        surahNumber: Int,
        text: String,
        transliteration: String? = nil,
        translation: String? = nil,
        juz: Int? = nil,
        page: Int? = nil,
        tafsir: String? = nil,
        audioResourceURL: URL? = nil,
        hizbQuarter: Int? = nil,
        ruku: Int? = nil,
        lastUpdatedAt: Date? = nil
    ) {
        self.ayahNumber = ayahNumber
        self.surahNumber = surahNumber
        self.text = text
        self.transliteration = transliteration
        self.translation = translation
        self.juz = juz
        self.page = page
        self.tafsir = tafsir
        self.audioResourceURL = audioResourceURL
        self.hizbQuarter = hizbQuarter
        self.ruku = ruku
        self.lastUpdatedAt = lastUpdatedAt
    }

    var audioURL: URL? {
        audioResourceURL ?? Reciter.alafasy.audioURL(surah: surahNumber, ayah: ayahNumber)
    }

    var reference: String {
        "\(surahNumber)-\(ayahNumber)"
    }

    var surahName: String {
        "Surah \(surahNumber)"
    }

    var searchText: String {
        [text, transliteration ?? "", translation ?? "", tafsir ?? ""].joined(separator: " ").lowercased()
    }

    func audioURL(for reciter: Reciter) -> URL? {
        reciter.audioURL(surah: surahNumber, ayah: ayahNumber)
    }
}

struct DailyAyah: Identifiable, Codable {
    let id = UUID()
    let text: String
    let translation: String
    let reference: String
    let surahName: String
}

struct QuickAction: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let symbol: String
    let tint: ColorPalette
}

struct Bookmark: Identifiable, Codable, Equatable {
    var id = UUID()
    let surahNumber: Int
    let ayahNumber: Int
    let title: String
    let subtitle: String
    let createdAt: Date

    var icon: String { "bookmark.fill" }
    var progress: String { createdAt.formatted(.dateTime.month().day().hour().minute()) }

    init(id: UUID = UUID(), surahNumber: Int, ayahNumber: Int, title: String, subtitle: String, createdAt: Date = Date()) {
        self.id = id
        self.surahNumber = surahNumber
        self.ayahNumber = ayahNumber
        self.title = title
        self.subtitle = subtitle
        self.createdAt = createdAt
    }
}

enum QuranEdition: String, CaseIterable, Codable {
    case arabicUthmani = "quran-uthmani"
    case transliteration = "en.transliteration"
    case indonesianKemenag = "id.kemenag"
    case englishSaheeh = "en.sahih"
    case englishClear = "en.clear"

    var displayName: String {
        switch self {
        case .arabicUthmani:
            return "Arabic Uthmani"
        case .transliteration:
            return "Transliteration"
        case .indonesianKemenag:
            return "Indonesian (MORA)"
        case .englishSaheeh:
            return "English Saheeh International"
        case .englishClear:
            return "English Clear Quran"
        }
    }

    var isTranslation: Bool {
        switch self {
        case .arabicUthmani, .transliteration:
            return false
        default:
            return true
        }
    }
}

enum ReaderMode: String, CaseIterable, Codable, Identifiable {
    case arabicOnly
    case arabicTranslation
    case arabicTransliteration
    case full

    var id: String { rawValue }

    var title: String {
        switch self {
        case .arabicOnly: return "Arabic Only"
        case .arabicTranslation: return "Arabic + Translation"
        case .arabicTransliteration: return "Arabic + Transliteration"
        case .full: return "Full Mode"
        }
    }

    var showTranslation: Bool {
        switch self {
        case .arabicTranslation, .full:
            return true
        default:
            return false
        }
    }

    var showTransliteration: Bool {
        switch self {
        case .arabicTransliteration, .full:
            return true
        default:
            return false
        }
    }
}

enum ReaderTheme: String, CaseIterable, Codable, Identifiable {
    case classic
    case calm
    case midnight
    case sepia

    var id: String { rawValue }
    var accent: Color {
        switch self {
        case .classic: return .companionAccent
        case .calm: return .companionEmerald
        case .midnight: return .white
        case .sepia: return .yellow
        }
    }
    var backgroundColor: Color {
        switch self {
        case .classic: return .companionBackground
        case .calm: return Color(red: 0.91, green: 0.94, blue: 0.91)
        case .midnight: return Color(red: 0.06, green: 0.08, blue: 0.14)
        case .sepia: return Color(red: 0.98, green: 0.94, blue: 0.87)
        }
    }
    var textColor: Color {
        switch self {
        case .midnight: return .white
        default: return .companionText
        }
    }
}

enum ReaderBackground: String, CaseIterable, Codable, Identifiable {
    case linen
    case dusk
    case forest
    case warm

    var id: String { rawValue }
    var title: String {
        switch self {
        case .linen: return "Linen"
        case .dusk: return "Dusk"
        case .forest: return "Forest"
        case .warm: return "Warm Glow"
        }
    }
    var gradient: LinearGradient {
        switch self {
        case .linen:
            return LinearGradient(colors: [Color(red: 0.99, green: 0.97, blue: 0.92), Color(red: 0.97, green: 0.94, blue: 0.88)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .dusk:
            return LinearGradient(colors: [Color(red: 0.08, green: 0.12, blue: 0.22), Color(red: 0.12, green: 0.18, blue: 0.30)], startPoint: .top, endPoint: .bottom)
        case .forest:
            return LinearGradient(colors: [Color(red: 0.16, green: 0.28, blue: 0.18), Color(red: 0.06, green: 0.14, blue: 0.12)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .warm:
            return LinearGradient(colors: [Color(red: 0.99, green: 0.93, blue: 0.80), Color(red: 0.90, green: 0.76, blue: 0.53)], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }
}

struct ReaderSettings: Codable {
    var mode: ReaderMode = .full
    var fontSize: Double = 22
    var lineSpacing: Double = 8
    var theme: ReaderTheme = .classic
    var background: ReaderBackground = .linen
}

enum Reciter: String, CaseIterable, Codable, Identifiable {
    case alafasy = "ar.alafasy"
    case abdulBasit = "ar.abdulbasitmurattal"
    case maher = "ar.maheralmuaiqly"
    case sudais = "ar.abdurrahmanalsudais"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .alafasy: return "Mishary Rashid Alafasy"
        case .abdulBasit: return "Abdul Basit"
        case .maher: return "Maher Al Muaiqly"
        case .sudais: return "Sudais"
        }
    }

    func audioURL(surah: Int, ayah: Int) -> URL? {
        URL(string: "https://cdn.islamic.network/quran/audio/128/\(rawValue)/\(surah)/\(ayah)")
    }
}

struct AudioSettings: Codable {
    var selectedReciter: Reciter = .alafasy
    var playbackRate: Float = 1.0
    var preloadDepth: Int = 3
}

struct AyahHighlight: Codable, Identifiable, Hashable {
    let id: UUID
    let surahNumber: Int
    let ayahNumber: Int
    let note: String?
    let createdAt: Date

    init(id: UUID = UUID(), surahNumber: Int, ayahNumber: Int, note: String? = nil, createdAt: Date = Date()) {
        self.id = id
        self.surahNumber = surahNumber
        self.ayahNumber = ayahNumber
        self.note = note
        self.createdAt = createdAt
    }

    var reference: String {
        "\(surahNumber)-\(ayahNumber)"
    }
}

struct ReaderNote: Codable, Identifiable {
    let id: UUID
    let surahNumber: Int
    let ayahNumber: Int
    let text: String
    let createdAt: Date

    init(id: UUID = UUID(), surahNumber: Int, ayahNumber: Int, text: String, createdAt: Date = Date()) {
        self.id = id
        self.surahNumber = surahNumber
        self.ayahNumber = ayahNumber
        self.text = text
        self.createdAt = createdAt
    }

    var reference: String {
        "\(surahNumber)-\(ayahNumber)"
    }
}

struct AyahReference: Codable, Identifiable, Hashable {
    let id: UUID
    let surahNumber: Int
    let ayahNumber: Int

    init(id: UUID = UUID(), surahNumber: Int, ayahNumber: Int) {
        self.id = id
        self.surahNumber = surahNumber
        self.ayahNumber = ayahNumber
    }

    static func == (lhs: AyahReference, rhs: AyahReference) -> Bool {
        lhs.surahNumber == rhs.surahNumber && lhs.ayahNumber == rhs.ayahNumber
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(surahNumber)
        hasher.combine(ayahNumber)
    }
}

struct BookmarkCollection: Identifiable, Codable {
    let id: UUID
    var title: String
    var items: [AyahReference]

    init(id: UUID = UUID(), title: String, items: [AyahReference] = []) {
        self.id = id
        self.title = title
        self.items = items
    }
}

struct ReadingSession: Codable, Identifiable {
    let id: UUID
    let surahNumber: Int
    let ayahNumber: Int
    let versesRead: Int
    let createdAt: Date

    init(id: UUID = UUID(), surahNumber: Int, ayahNumber: Int, versesRead: Int = 1, createdAt: Date = Date()) {
        self.id = id
        self.surahNumber = surahNumber
        self.ayahNumber = ayahNumber
        self.versesRead = versesRead
        self.createdAt = createdAt
    }
}

struct ReadingAnalytics: Codable {
    let dailyStreak: Int
    let monthlyProgress: Int
    let totalVersesRead: Int
}

enum SearchField: String, CaseIterable, Codable, Identifiable {
    case all = "All"
    case surahName = "Surah Name"
    case arabicText = "Arabic Text"
    case translationText = "Translation"
    case keyword = "Keyword"
    case topic = "Topic"
    case juz = "Juz"
    case page = "Page"
    case revelationPlace = "Revelation"

    var id: String { rawValue }
    var displayName: String { rawValue }
}

struct DiscoveryInsight: Identifiable {
    let id = UUID()
    let title: String
    let detail: String
    let icon: String
}

struct SearchResult: Identifiable {
    enum ResultType {
        case surah(Surah)
        case ayah(Ayah, surah: Surah)
    }

    let id = UUID()
    let resultType: ResultType
    let highlights: [String]
    let topic: String?

    var title: String {
        switch resultType {
        case .surah(let surah): return surah.englishName
        case .ayah(let ayah, let surah): return ayah.text
        }
    }

    var subtitle: String {
        switch resultType {
        case .surah(let surah): return surah.translation
        case .ayah(let ayah, _): return ayah.translation ?? ayah.text
        }
    }

    var caption: String {
        switch resultType {
        case .surah(let surah):
            return "Surah • \(surah.revelationPlace.displayName) • \(surah.ayahCount) ayahs"
        case .ayah(let ayah, let surah):
            let parts = ["Surah \(surah.englishName)", "Ayah \(ayah.ayahNumber)", ayah.juz.map { "Juz \($0)" }, ayah.page.map { "Page \($0)" }]
                .compactMap { $0 }
            return parts.joined(separator: " • ")
        }
    }
}

struct QuranTranslationPayload: Codable {
    let ayahKey: String
    let edition: QuranEdition
    let language: String
    let translatorName: String?
    let text: String
}

enum ColorPalette {
    case sage
    case gold
    case emerald
    case sand
}

private struct SampleSurahResponse: Codable {
    let surahs: [SampleSurah]
}

private struct SampleSurah: Codable {
    let number: Int
    let name: String
    let englishName: String
    let englishNameTranslation: String
    let numberOfAyahs: Int
    let revelationType: String
    let ayahs: [SampleAyah]

    func asSurah() -> Surah {
        let place = RevelationPlace(rawValue: revelationType) ?? .mecca
        return Surah(
            id: number,
            number: number,
            arabicName: name,
            englishName: englishName,
            translation: englishNameTranslation,
            ayahCount: numberOfAyahs,
            revelationPlace: place,
            ayahs: ayahs.map { $0.asAyah(surahNumber: number) }
        )
    }
}

private struct SampleAyah: Codable {
    let number: Int
    let text: String
    let numberInSurah: Int?
    let juz: Int?
    let page: Int?

    func asAyah(surahNumber: Int) -> Ayah {
        Ayah(
            ayahNumber: numberInSurah ?? number,
            surahNumber: surahNumber,
            text: text,
            transliteration: nil,
            translation: nil,
            juz: juz,
            page: page
        )
    }
}
