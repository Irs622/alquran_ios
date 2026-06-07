import SwiftUI

struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()

    var body: some View {
        Form {
            Section(header: Text("Display")) {
                Toggle(isOn: $viewModel.useDarkMode) {
                    Label("Dark Mode", systemImage: "moon.fill")
                }
                Toggle(isOn: $viewModel.showVerseTranslations) {
                    Label("Verse Translations", systemImage: "text.book.closed")
                }
            }

            Section(header: Text("Preferences")) {
                Toggle(isOn: $viewModel.notificationsEnabled) {
                    Label("Daily reminders", systemImage: "bell.fill")
                }
            }

            Section(header: Text("About")) {
                HStack {
                    Text("App")
                    Spacer()
                    Text("Quran Companion")
                        .foregroundColor(.secondary)
                }
                HStack {
                    Text("Version")
                    Spacer()
                    Text("1.0")
                        .foregroundColor(.secondary)
                }
                Text("A calm, modern companion app for Quran study and reflection.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.companionBackground.ignoresSafeArea())
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    SettingsView()
}
