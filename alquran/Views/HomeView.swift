import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                headerSection
                continueCard
                analyticsCard
                dailyVerseCard
                quickActionSection
                recentSurahsSection
            }
            .padding()
        }
        .background(Color.companionBackground.ignoresSafeArea())
        .navigationTitle("Quran Companion")
        .navigationBarTitleDisplayMode(.large)
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(viewModel.greeting)
                .font(.companionTitle())
                .foregroundColor(.companionText)
            Text(viewModel.greetingSubtitle)
                .font(.subheadline)
                .foregroundColor(.companionTextSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var continueCard: some View {
        NavigationLink(destination: SurahDetailView(surah: viewModel.continueSurah)) {
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color.companionAccent.opacity(0.12))
                VStack(alignment: .leading, spacing: 12) {
                    Text("Continue Reading")
                        .font(.headline)
                        .foregroundColor(.companionText)
                    Text(viewModel.continueTitle)
                        .font(.title2.weight(.bold))
                        .foregroundColor(.companionText)
                    Text(viewModel.continueProgress)
                        .font(.subheadline)
                        .foregroundColor(.companionTextSecondary)
                    HStack {
                        Spacer()
                        Label("Resume", systemImage: "play.fill")
                            .font(.footnote.weight(.semibold))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(Color.companionAccent)
                            .foregroundColor(.white)
                            .cornerRadius(14)
                    }
                }
                .padding()
            }
            .frame(height: 170)
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var analyticsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Reading Analytics")
                    .font(.headline)
                    .foregroundColor(.companionText)
                Spacer()
                Image(systemName: "chart.bar.fill")
                    .foregroundColor(.companionAccent)
            }
            HStack(spacing: 12) {
                analyticsChip(title: "Streak", value: "\(viewModel.analytics.dailyStreak) days")
                analyticsChip(title: "This month", value: "\(viewModel.analytics.monthlyProgress) verses")
                analyticsChip(title: "Total", value: "\(viewModel.analytics.totalVersesRead)")
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 24, style: .continuous).fill(Color.companionCard))
    }

    private func analyticsChip(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.companionTextSecondary)
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.companionText)
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color.companionBackground))
    }

    private var dailyVerseCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Daily Verse")
                    .font(.headline)
                    .foregroundColor(.companionText)
                Spacer()
                Image(systemName: "sparkles")
                    .foregroundColor(.companionGold)
            }

            Text("“\(viewModel.dailyVerse.text)”")
                .font(.title3.weight(.semibold))
                .foregroundColor(.companionText)
                .lineLimit(3)
            Text(viewModel.dailyVerse.reference)
                .font(.footnote.weight(.medium))
                .foregroundColor(.companionAccent)
            Text(viewModel.dailyVerse.translation)
                .font(.subheadline)
                .foregroundColor(.companionTextSecondary)
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 24, style: .continuous).fill(Color.companionCard))
    }

    private var quickActionSection: some View {
        VStack(spacing: 16) {
            SectionHeaderView(title: "Quick Access", subtitle: "Jump straight into your favorite actions")
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 160), spacing: 16)], spacing: 16) {
                ForEach(viewModel.quickActions) { action in
                    QuickActionButton(action: action)
                }
            }
        }
    }

    private var recentSurahsSection: some View {
        VStack(spacing: 16) {
            SectionHeaderView(title: "Recently Accessed", subtitle: "Your latest chapters")
            ForEach(viewModel.recentSurahs.prefix(4)) { surah in
                SurahRowView(surah: surah)
            }
        }
    }
}

#Preview {
    HomeView()
}
