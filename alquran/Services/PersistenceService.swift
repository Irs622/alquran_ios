import Foundation

struct AppSettings: Codable {
    var useDarkMode: Bool = false
    var notificationsEnabled: Bool = true
    var showVerseTranslations: Bool = true
}

struct ReadingProgress: Codable {
    let surahNumber: Int
    let ayahNumber: Int
    let updatedAt: Date
}

final class PersistenceService {
    static let shared = PersistenceService()
    private let defaults = UserDefaults.standard

    private enum Keys {
        static let bookmarks = "bookmarks"
        static let lastRead = "lastRead"
        static let settings = "userSettings"
        static let readerSettings = "readerSettings"
        static let audioSettings = "audioSettings"
        static let highlights = "ayahHighlights"
        static let notes = "readerNotes"
        static let collections = "bookmarkCollections"
        static let sessions = "readingSessions"
        static let dailyAyah = "dailyAyah"
        static let dailyAyahDate = "dailyAyahDate"
        static let quranDataLastSync = "quranDataLastSync"
    }

    private init() {}

    private func loadValue<T: Codable>(forKey key: String, defaultValue: T) -> T {
        guard let data = defaults.data(forKey: key),
              let value = try? JSONDecoder().decode(T.self, from: data) else {
            return defaultValue
        }
        return value
    }

    private func loadOptionalValue<T: Codable>(forKey key: String) -> T? {
        guard let data = defaults.data(forKey: key),
              let value = try? JSONDecoder().decode(T.self, from: data) else {
            return nil
        }
        return value
    }

    private func saveValue<T: Codable>(_ value: T?, forKey key: String) {
        if let value = value,
           let data = try? JSONEncoder().encode(value) {
            defaults.set(data, forKey: key)
        } else {
            defaults.removeObject(forKey: key)
        }
    }

    var settings: AppSettings {
        get { loadValue(forKey: Keys.settings, defaultValue: AppSettings()) }
        set { saveValue(newValue, forKey: Keys.settings) }
    }

    var readerSettings: ReaderSettings {
        get { loadValue(forKey: Keys.readerSettings, defaultValue: ReaderSettings()) }
        set { saveValue(newValue, forKey: Keys.readerSettings) }
    }

    var audioSettings: AudioSettings {
        get { loadValue(forKey: Keys.audioSettings, defaultValue: AudioSettings()) }
        set { saveValue(newValue, forKey: Keys.audioSettings) }
    }

    var lastRead: ReadingProgress? {
        get { loadOptionalValue(forKey: Keys.lastRead) }
        set { saveValue(newValue, forKey: Keys.lastRead) }
    }

    var bookmarks: [Bookmark] {
        get { loadValue(forKey: Keys.bookmarks, defaultValue: []) }
        set { saveValue(newValue, forKey: Keys.bookmarks) }
    }

    var ayahHighlights: [AyahHighlight] {
        get { loadValue(forKey: Keys.highlights, defaultValue: []) }
        set { saveValue(newValue, forKey: Keys.highlights) }
    }

    var readerNotes: [ReaderNote] {
        get { loadValue(forKey: Keys.notes, defaultValue: []) }
        set { saveValue(newValue, forKey: Keys.notes) }
    }

    var bookmarkCollections: [BookmarkCollection] {
        get { loadValue(forKey: Keys.collections, defaultValue: [BookmarkCollection(title: "Saved Verses")]) }
        set { saveValue(newValue, forKey: Keys.collections) }
    }

    var readingSessions: [ReadingSession] {
        get { loadValue(forKey: Keys.sessions, defaultValue: []) }
        set { saveValue(newValue, forKey: Keys.sessions) }
    }

    var readingAnalytics: ReadingAnalytics {
        let sessions = readingSessions
        let calendar = Calendar.current
        let totalVerses = sessions.reduce(0) { $0 + $1.versesRead }
        let monthlyVerses = sessions
            .filter { calendar.isDate($0.createdAt, equalTo: Date(), toGranularity: .month) }
            .reduce(0) { $0 + $1.versesRead }
        var streak = 0
        var currentDay = calendar.startOfDay(for: Date())
        let sessionDays = Set(sessions.map { calendar.startOfDay(for: $0.createdAt) })
        while sessionDays.contains(currentDay) {
            streak += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: currentDay) else { break }
            currentDay = previous
        }
        return ReadingAnalytics(dailyStreak: streak, monthlyProgress: monthlyVerses, totalVersesRead: totalVerses)
    }

    var dailyAyah: DailyAyah? {
        get { loadOptionalValue(forKey: Keys.dailyAyah) }
        set { saveValue(newValue, forKey: Keys.dailyAyah) }
    }

    var dailyAyahDate: Date? {
        get { defaults.object(forKey: Keys.dailyAyahDate) as? Date }
        set { defaults.set(newValue, forKey: Keys.dailyAyahDate) }
    }

    var quranDataLastSync: Date? {
        get { defaults.object(forKey: Keys.quranDataLastSync) as? Date }
        set { defaults.set(newValue, forKey: Keys.quranDataLastSync) }
    }
}
