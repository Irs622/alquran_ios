import SwiftUI

struct SearchView: View {
    @StateObject private var viewModel = SearchViewModel()

    var body: some View {
        List {
            searchHeader
            if let reflection = viewModel.dailyReflection {
                Section(header: Text("Daily Reflection")) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(reflection.text)
                            .font(.body.weight(.semibold))
                            .foregroundColor(.companionText)
                        Text(reflection.translation)
                            .font(.caption)
                            .foregroundColor(.companionTextSecondary)
                        Text(reflection.reference)
                            .font(.caption2)
                            .foregroundColor(.companionAccent)
                    }
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 20).fill(Color.companionCard))
                }
            }

            if !viewModel.recommendedVerses.isEmpty {
                Section(header: Text("Verse Recommendations")) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(viewModel.recommendedVerses) { result in
                                recommendedCard(for: result)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }

            if viewModel.filteredResults.isEmpty {
                Section {
                    EmptyStateView(
                        title: "No discovery results",
                        message: "Try searching by surah name, Arabic text, translation, keyword, topic, Juz, page, or revelation place."
                    )
                }
            } else {
                Section(header: Text("Results")) {
                    ForEach(viewModel.filteredResults) { result in
                        searchResultRow(result)
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                    }
                }
            }

            if !viewModel.insights.isEmpty {
                Section(header: Text("Reading Insights")) {
                    ForEach(viewModel.insights) { insight in
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: insight.icon)
                                .foregroundColor(.companionAccent)
                                .font(.title3)
                                .frame(width: 36, height: 36)
                                .background(Circle().fill(Color.companionCard))
                            VStack(alignment: .leading, spacing: 4) {
                                Text(insight.title)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundColor(.companionText)
                                Text(insight.detail)
                                    .font(.caption)
                                    .foregroundColor(.companionTextSecondary)
                            }
                        }
                        .padding(.vertical, 6)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Color.companionBackground.ignoresSafeArea())
        .navigationTitle("Discovery")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var searchHeader: some View {
        Section {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.companionTextSecondary)
                TextField("Search the Quran", text: $viewModel.query)
                    .textInputAutocapitalization(.never)
                    .disableAutocorrection(true)
            }
            .padding(12)
            .background(RoundedRectangle(cornerRadius: 16).fill(Color.companionCard))

            scrollableFieldChips

            VStack(spacing: 12) {
                HStack {
                    Picker("Topic", selection: Binding(
                        get: { viewModel.selectedTopic ?? "" },
                        set: { viewModel.selectedTopic = $0.isEmpty ? nil : $0 }
                    )) {
                        Text("Any topic").tag("")
                        ForEach(viewModel.availableTopics, id: \.self) { topic in
                            Text(topic).tag(topic)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())

                    Picker("Revelation", selection: Binding(
                        get: { viewModel.selectedRevelation },
                        set: { viewModel.selectedRevelation = $0 }
                    )) {
                        Text("Any place").tag(RevelationPlace?.none)
                        ForEach(RevelationPlace.allCases) { place in
                            Text(place.displayName).tag(Optional(place))
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }

                HStack(spacing: 12) {
                    TextField("Juz", text: $viewModel.selectedJuz)
                        .keyboardType(.numberPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    TextField("Page", text: $viewModel.selectedPage)
                        .keyboardType(.numberPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
            }
        }
    }

    private var scrollableFieldChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(SearchField.allCases) { field in
                    Button(action: {
                        viewModel.selectedField = field
                        if field != .topic {
                            viewModel.selectedTopic = nil
                        }
                    }) {
                        Text(field.displayName)
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(viewModel.selectedField == field ? Color.companionAccent : Color.companionCard)
                            )
                            .foregroundColor(viewModel.selectedField == field ? .white : .companionText)
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }

    @ViewBuilder
    private func searchResultRow(_ result: SearchResult) -> some View {
        switch result.resultType {
        case .surah(let surah):
            NavigationLink(destination: SurahDetailView(surah: surah)) {
                SurahRowView(surah: surah)
            }
            .buttonStyle(PlainButtonStyle())
        case .ayah(let ayah, let surah):
            NavigationLink(destination: SurahDetailView(surah: surah)) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(ayah.text)
                        .font(.body)
                        .foregroundColor(.companionText)
                        .lineLimit(2)
                    Text(ayah.translation ?? surah.translation)
                        .font(.caption)
                        .foregroundColor(.companionTextSecondary)
                    Text(result.caption)
                        .font(.caption2)
                        .foregroundColor(.companionAccent)
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: 20).fill(Color.companionCard))
            }
            .buttonStyle(PlainButtonStyle())
        }
    }

    private func recommendedCard(for result: SearchResult) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(result.title)
                .font(.headline)
                .foregroundColor(.companionText)
                .lineLimit(2)
            Text(result.subtitle)
                .font(.caption)
                .foregroundColor(.companionTextSecondary)
            if let topic = result.topic {
                Label(topic, systemImage: "tag.fill")
                    .font(.caption2)
                    .padding(8)
                    .background(RoundedRectangle(cornerRadius: 14).fill(Color.companionCard))
                    .foregroundColor(.companionAccent)
            }
        }
        .padding()
        .frame(width: 240, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 24).fill(Color.companionCard.opacity(0.92)))
    }
}

#Preview {
    SearchView()
}
