import SwiftUI

struct QuranView: View {
    @StateObject private var viewModel = QuranViewModel()

    var body: some View {
        VStack(spacing: 0) {
            searchBar
            content
        }
        .background(Color.companionBackground.ignoresSafeArea())
        .navigationTitle("Quran")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.companionTextSecondary)
            TextField("Search surah, translation...", text: $viewModel.searchText)
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 16).fill(Color.companionCard))
        .padding(.horizontal)
        .padding(.top)
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading {
            VStack(spacing: 20) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .companionAccent))
                Text("Preparing your Quran library…")
                    .foregroundColor(.companionTextSecondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if viewModel.filteredSurahs.isEmpty {
            EmptyStateView(title: "No surahs found", message: "Try a different keyword or return to the library.")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    ForEach(viewModel.filteredSurahs) { surah in
                        NavigationLink(destination: SurahDetailView(surah: surah)) {
                            SurahCardView(surah: surah)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding()
            }
        }
    }
}

#Preview {
    QuranView()
}
