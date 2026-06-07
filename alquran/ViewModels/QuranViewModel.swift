import Foundation
import Combine
import SwiftUI

@MainActor
final class QuranViewModel: ObservableObject {
    @Published var searchText = ""
    @Published var isLoading = true
    @Published var surahs: [Surah] = []
    @Published var errorMessage: String?

    private let repository = QuranRepository.shared

    var filteredSurahs: [Surah] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return surahs }
        return surahs.filter {
            $0.englishName.localizedCaseInsensitiveContains(query) ||
            $0.arabicName.localizedCaseInsensitiveContains(query) ||
            $0.translation.localizedCaseInsensitiveContains(query)
        }
    }

    init() {
        Task { await loadSurahs() }
    }

    func loadSurahs() async {
        isLoading = true
        do {
            surahs = try await repository.loadSurahSummaries()
        } catch {
            AppLogger.warning("Surah list fetch failed: \(error)")
            if let cached: [Surah] = CacheService.shared.load([Surah].self, for: "surahList") {
                surahs = cached
            } else {
                surahs = Surah.loadFallbackSurahs()
            }
            errorMessage = (error as? LocalizedError)?.errorDescription
        }
        isLoading = false
    }
}
