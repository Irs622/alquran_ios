import Foundation

final class QuranDiscoveryService {
    static let shared = QuranDiscoveryService()

    private let apiService = QuranAPIService.shared
    private let cacheService = CacheService.shared

    private(set) var allSurahs: [Surah] = []
    private(set) var discoveryTopics: [String] = [
        "Mercy", "Faith", "Patience", "Guidance", "Prayer", "Forgiveness", "Healing", "Gratitude", "Strength", "Wisdom"
    ]
    private var indexedAyahs: [SearchIndexEntry] = []

    private init() {}

    func loadIndex() async {
        if let cached: [Surah] = cacheService.load([Surah].self, for: "discoverySurahList") {
            allSurahs = cached
        }

        do {
            let fetched = try await apiService.fetchSurahList()
            allSurahs = mergeSummaries(fetched)
            cacheService.store(allSurahs, for: "discoverySurahList")
        } catch {
            allSurahs = mergeSummaries(Surah.loadFallbackSurahs())
        }

        buildIndex()
    }

    func loadSurahDetailIfNeeded(for surahNumber: Int) async {
        if let existing = allSurahs.first(where: { $0.number == surahNumber && $0.ayahs != nil }),
           existing.ayahs?.isEmpty == false {
            return
        }

        do {
            let detail = try await apiService.fetchSurahDetail(number: surahNumber)
            if let index = allSurahs.firstIndex(where: { $0.number == surahNumber }) {
                allSurahs[index] = detail
            } else {
                allSurahs.append(detail)
            }
            cacheService.store(allSurahs, for: "discoverySurahList")
            buildIndex()
        } catch {
            AppLogger.warning("Unable to load surah details for discovery: \(error)")
        }
    }

    func search(
        query: String,
        field: SearchField,
        topic: String? = nil,
        juz: Int? = nil,
        page: Int? = nil,
        revelationPlace: RevelationPlace? = nil
    ) -> [SearchResult] {
        let normalizedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let shouldSearchAll = normalizedQuery.isEmpty && field == .all

        func matchesSurah(_ surah: Surah) -> Bool {
            if let revelationPlace = revelationPlace, surah.revelationPlace != revelationPlace {
                return false
            }
            if let topic = topic, !topic.isEmpty {
                return topicMatchesSurah(surah, topic: topic)
            }
            switch field {
            case .all, .surahName:
                return normalizedQuery.isEmpty ||
                    surah.englishName.lowercased().contains(normalizedQuery) ||
                    surah.arabicName.lowercased().contains(normalizedQuery) ||
                    surah.translation.lowercased().contains(normalizedQuery)
            case .arabicText, .translationText, .keyword, .topic, .juz, .page, .revelationPlace:
                return field == .topic && topicMatchesSurah(surah, topic: normalizedQuery)
            }
        }

        func matchesAyah(_ ayah: Ayah) -> Bool {
            if let juz = juz, ayah.juz != juz { return false }
            if let page = page, ayah.page != page { return false }
            let searchText = ayah.searchText
            if let topic = topic, !topic.isEmpty {
                return topicMatchesAyah(ayah, topic: topic)
            }
            let hasActiveFilter = juz != nil || page != nil || revelationPlace != nil || (topic != nil && !(topic ?? "").isEmpty)
            guard !normalizedQuery.isEmpty || hasActiveFilter else {
                return false
            }

            switch field {
            case .all:
                return searchText.contains(normalizedQuery) || ayah.transliteration?.lowercased().contains(normalizedQuery) == true || ayah.translation?.lowercased().contains(normalizedQuery) == true || keywordMatch(ayah, query: normalizedQuery)
            case .surahName:
                return false
            case .arabicText:
                return ayah.text.lowercased().contains(normalizedQuery)
            case .translationText:
                return ayah.translation?.lowercased().contains(normalizedQuery) ?? false
            case .keyword:
                return keywordMatch(ayah, query: normalizedQuery)
            case .topic:
                return topicMatchesAyah(ayah, topic: normalizedQuery)
            case .juz:
                return juz == nil ? false : ayah.juz == juz
            case .page:
                return page == nil ? false : ayah.page == page
            case .revelationPlace:
                return false
            }
        }

        let surahResults = allSurahs.filter(matchesSurah).map {
            SearchResult(resultType: .surah($0), highlights: ["Surah discovery"], topic: topic)
        }

        let ayahResults: [SearchResult] = allSurahs.flatMap { surah in
            (surah.ayahs ?? []).compactMap { ayah -> SearchResult? in
                guard matchesAyah(ayah) else { return nil }
                return SearchResult(resultType: .ayah(ayah, surah: surah), highlights: ["\(surah.englishName) Ayah \(ayah.ayahNumber)"], topic: topic)
            }
        }

        let results = (surahResults + ayahResults)
        if results.isEmpty && !normalizedQuery.isEmpty && field == .all {
            return fuzzySearch(query: normalizedQuery, topic: topic, juz: juz, page: page, revelationPlace: revelationPlace)
        }

        return results
    }

    func recommendedAyahs(for query: String? = nil, limit: Int = 5) async -> [SearchResult] {
        if let query = query?.trimmingCharacters(in: .whitespacesAndNewlines), !query.isEmpty {
            return search(query: query, field: .all).prefix(limit).map { $0 }
        }

        if indexedAyahs.isEmpty {
            buildIndex()
        }

        let sorted = indexedAyahs.shuffled().prefix(limit).map { entry in
            SearchResult(resultType: .ayah(entry.ayah, surah: entry.surah), highlights: entry.topics, topic: entry.topics.first)
        }

        return sorted
    }

    func dailyReflection() async -> DailyAyah {
        do {
            return try await apiService.fetchDailyVerse()
        } catch {
            AppLogger.warning("Daily reflection fetch failed: \(error)")
            return DailyAyah(text: "Seek guidance in every verse.", translation: "Reflect on the words of mercy and patience.", reference: "Al-Fatiha 1", surahName: "Al-Fatiha")
        }
    }

    func relatedAyahs(for ayah: Ayah, surah: Surah, limit: Int = 4) -> [SearchResult] {
        let currentTopics = topicMatchesText(ayah.searchText)
        let currentJuz = ayah.juz

        return indexedAyahs
            .filter { entry in
                guard entry.ayah.surahNumber != ayah.surahNumber || entry.ayah.ayahNumber != ayah.ayahNumber else { return false }
                if !currentTopics.isEmpty {
                    return !Set(entry.topics).isDisjoint(with: currentTopics)
                }
                if let juz = currentJuz { return entry.ayah.juz == juz }
                return entry.surah.number == surah.number
            }
            .prefix(limit)
            .map { SearchResult(resultType: .ayah($0.ayah, surah: $0.surah), highlights: $0.topics, topic: $0.topics.first) }
    }

    func readingInsights() -> [DiscoveryInsight] {
        let meccan = allSurahs.filter { $0.revelationPlace == .mecca }.count
        let medinan = allSurahs.filter { $0.revelationPlace == .medina }.count
        let total = allSurahs.count
        return [
            DiscoveryInsight(title: "Deep discovery", detail: "Search across Arabic text, translation, Juz, page, and revelation place for faster study.", icon: "magnifyingglass.circle"),
            DiscoveryInsight(title: "Context aware", detail: "\(total) chapters available with Meccan and Medinan filters to guide your study path.", icon: "map"),
            DiscoveryInsight(title: "Daily growth", detail: "Use the daily reflection card to stay grounded with a new verse every time you open Search.", icon: "sunrise")
        ]
    }

    private func mergeSummaries(_ summaries: [Surah]) -> [Surah] {
        let fallback = Surah.loadFallbackSurahs()
        return summaries.map { summary in
            if let fallbackSurah = fallback.first(where: { $0.number == summary.number }) {
                return Surah(
                    id: summary.id,
                    number: summary.number,
                    arabicName: summary.arabicName,
                    englishName: summary.englishName,
                    translation: summary.translation,
                    ayahCount: summary.ayahCount,
                    revelationPlace: summary.revelationPlace,
                    ayahs: fallbackSurah.ayahs
                )
            }
            return summary
        }
    }

    private func buildIndex() {
        indexedAyahs = allSurahs.flatMap { surah in
            (surah.ayahs ?? []).map { ayah in
                SearchIndexEntry(
                    surah: surah,
                    ayah: ayah,
                    topics: topicMatchesText(ayah.searchText),
                    searchText: ayah.searchText
                )
            }
        }
    }

    private func fuzzySearch(
        query: String,
        topic: String? = nil,
        juz: Int? = nil,
        page: Int? = nil,
        revelationPlace: RevelationPlace? = nil
    ) -> [SearchResult] {
        indexedAyahs
            .filter { entry in
                if let revelationPlace = revelationPlace, entry.surah.revelationPlace != revelationPlace { return false }
                if let juz = juz, entry.ayah.juz != juz { return false }
                if let page = page, entry.ayah.page != page { return false }
                if let topic = topic, !topic.isEmpty, !entry.topics.contains(where: { $0.lowercased().contains(topic.lowercased()) }) { return false }
                return entry.searchText.contains(query)
            }
            .prefix(30)
            .map { SearchResult(resultType: .ayah($0.ayah, surah: $0.surah), highlights: $0.topics, topic: $0.topics.first) }
    }

    private func keywordMatch(_ ayah: Ayah, query: String) -> Bool {
        let tokens = query.split(separator: " ").map(String.init)
        return tokens.allSatisfy { token in
            ayah.searchText.contains(token) || ayah.translation?.lowercased().contains(token) == true
        }
    }

    private func topicMatchesSurah(_ surah: Surah, topic: String) -> Bool {
        let normalizedTopic = topic.lowercased()
        return topicMatchesText([surah.englishName, surah.arabicName, surah.translation].joined(separator: " ")).contains(where: { $0.lowercased().contains(normalizedTopic) })
    }

    private func topicMatchesAyah(_ ayah: Ayah, topic: String) -> Bool {
        let normalizedTopic = topic.lowercased()
        return topicMatchesText(ayah.searchText).contains(where: { $0.lowercased().contains(normalizedTopic) })
    }

    private func topicMatchesText(_ rawText: String) -> [String] {
        let lowercased = rawText.lowercased()
        return discoveryTopics.filter { topic in
            topicKeywords[topic]?.contains(where: { lowercased.contains($0) }) == true
        }
    }

    private var topicKeywords: [String: [String]] {
        [
            "Mercy": ["mercy", "رحمة", "رحيم", "compassion"],
            "Faith": ["faith", "iman", "belief", "believe", "إيمان"],
            "Patience": ["patience", "صبر", "steadfast"],
            "Guidance": ["guidance", "hidayah", "هدى", "guide"],
            "Prayer": ["prayer", "salat", "salah", "du'a", "دعاء"],
            "Forgiveness": ["forgiveness", "غفران", "forgive", "pardoned"],
            "Healing": ["healing", "شفاء", "shifa"],
            "Gratitude": ["gratitude", "shukr", "thanks", "الحمد"],
            "Strength": ["strength", "قوة", "power", "strong"],
            "Wisdom": ["wisdom", "حكمة", "wisdom" ]
        ]
    }
}

private struct SearchIndexEntry {
    let surah: Surah
    let ayah: Ayah
    let topics: [String]
    let searchText: String
}
