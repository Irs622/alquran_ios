import Foundation
import Combine

@MainActor
final class SearchViewModel: ObservableObject {
    @Published var query = ""
    @Published var selectedField: SearchField = .all
    @Published var selectedTopic: String?
    @Published var selectedJuz: String = ""
    @Published var selectedPage: String = ""
    @Published var selectedRevelation: RevelationPlace?
    @Published private(set) var allSurahs: [Surah] = []
    @Published private(set) var recommendedVerses: [SearchResult] = []
    @Published private(set) var dailyReflection: DailyAyah?
    @Published private(set) var insights: [DiscoveryInsight] = []
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?

    private let discoveryService = QuranDiscoveryService.shared

    var availableTopics: [String] {
        discoveryService.discoveryTopics
    }

    var selectedJuzValue: Int? {
        Int(selectedJuz)
    }

    var selectedPageValue: Int? {
        Int(selectedPage)
    }

    var filteredResults: [SearchResult] {
        discoveryService.search(
            query: query,
            field: selectedField,
            topic: selectedTopic,
            juz: selectedJuzValue,
            page: selectedPageValue,
            revelationPlace: selectedRevelation
        )
    }

    init() {
        Task { await prepareDiscovery() }
    }

    func prepareDiscovery() async {
        isLoading = true
        await discoveryService.loadIndex()
        allSurahs = discoveryService.allSurahs
        insights = discoveryService.readingInsights()
        dailyReflection = await discoveryService.dailyReflection()
        recommendedVerses = await discoveryService.recommendedAyahs()
        isLoading = false
    }

    func clearFilters() {
        selectedField = .all
        selectedTopic = nil
        selectedJuz = ""
        selectedPage = ""
        selectedRevelation = nil
    }

    func loadSurahDetailIfNeeded(_ surahNumber: Int) async {
        await discoveryService.loadSurahDetailIfNeeded(for: surahNumber)
        allSurahs = discoveryService.allSurahs
    }

    func relatedAyahs(for ayah: Ayah, surah: Surah) -> [SearchResult] {
        discoveryService.relatedAyahs(for: ayah, surah: surah)
    }
}
