import Foundation
import Combine

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published var useDarkMode = false {
        didSet { saveSettings() }
    }
    @Published var notificationsEnabled = true {
        didSet { saveSettings(); updateNotifications() }
    }
    @Published var showVerseTranslations = true {
        didSet { saveSettings() }
    }

    private let persistence = PersistenceService.shared
    private let notificationService = NotificationService.shared

    init() {
        loadSettings()
    }

    private func loadSettings() {
        let settings = persistence.settings
        useDarkMode = settings.useDarkMode
        notificationsEnabled = settings.notificationsEnabled
        showVerseTranslations = settings.showVerseTranslations
    }

    private func saveSettings() {
        persistence.settings = AppSettings(
            useDarkMode: useDarkMode,
            notificationsEnabled: notificationsEnabled,
            showVerseTranslations: showVerseTranslations
        )
    }

    private func updateNotifications() {
        if notificationsEnabled {
            notificationService.scheduleDailyReminder()
        } else {
            notificationService.cancelDailyReminder()
        }
    }
}
