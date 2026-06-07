import Foundation
import Combine
import SwiftUI

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var greeting = "Assalamu Alaikum"
    @Published var continueTitle = "Al-Fatiha"
    @Published var continueProgress = "2 of 7 ayahs"
    @Published var dailyVerse = MockData.dailyVerse
    @Published var quickActions = MockData.quickActions
    @Published var recentSurahs = MockData.surahs
    @Published var continueSurah: Surah = MockData.surahs[0]
    @Published var analytics = PersistenceService.shared.readingAnalytics

    private let apiService = QuranAPIService.shared

    var greetingSubtitle: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good morning, may today be peaceful."
        case 12..<17: return "Good afternoon, keep your heart centered."
        case 17..<21: return "Good evening, reflect gently."
        default: return "May this evening bring calm and clarity."
        }
    }

    init() {
        Task { await refreshHome() }
    }

    func refreshHome() async {
        analytics = PersistenceService.shared.readingAnalytics

        if let lastRead = PersistenceService.shared.lastRead {
            if let fallbackSurah = Surah.loadFallbackSurahs().first(where: { $0.number == lastRead.surahNumber }) {
                continueSurah = fallbackSurah
                continueTitle = fallbackSurah.englishName
                continueProgress = "Ayah \(lastRead.ayahNumber)"
            }
        }

        do {
            let daily = try await apiService.fetchDailyVerse()
            dailyVerse = daily
        } catch {
            AppLogger.warning("Failed to load daily verse: \(error)")
        }

        do {
            let allSurahs = try await apiService.fetchSurahList()
            recentSurahs = Array(allSurahs.prefix(4))
        } catch {
            AppLogger.warning("Failed to update recent surahs: \(error)")
            recentSurahs = Array(Surah.loadFallbackSurahs().prefix(4))
        }
    }
}
