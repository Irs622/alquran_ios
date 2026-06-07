import SwiftUI

struct SurahDetailView: View {
    @StateObject private var viewModel: SurahDetailViewModel
    @ObservedObject private var audioService = AudioPlayerService.shared
    @State private var focusMode = false
    @State private var showCustomization = false
    @State private var editingNoteAyah: Ayah?
    @State private var noteDraft = ""

    init(surah: Surah) {
        _viewModel = StateObject(wrappedValue: SurahDetailViewModel(surah: surah))
    }

    var body: some View {
        ZStack {
            viewModel.readerSettings.background.gradient
                .ignoresSafeArea()

            if viewModel.isLoading {
                loadingView
            } else if let message = viewModel.errorMessage {
                EmptyStateView(title: "Unable to load surah", message: message)
            } else {
                ScrollViewReader { proxy in
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 20) {
                            if !focusMode {
                                header
                            }

                            readerSummary

                            AudioPlayerControlsView(
                                title: audioService.currentAyah.map { "Surah \($0.surahNumber) • Ayah \($0.ayahNumber)" } ?? viewModel.surah.description,
                                subtitle: audioService.currentAyah?.surahName ?? "Ready to play",
                                isPlaying: audioService.isPlaying,
                                isBuffering: audioService.isBuffering,
                                progress: audioService.progress,
                                duration: audioService.duration,
                                playbackRate: audioService.playbackRate,
                                selectedReciter: audioService.audioSettings.selectedReciter,
                                downloadStatus: audioService.downloadStatus,
                                cacheInfo: audioService.cachedAudioSizeDisplay(),
                                playSurahAction: { viewModel.playSurah() },
                                pauseAction: viewModel.pause,
                                resumeAction: viewModel.resume,
                                seekAction: audioService.seek,
                                changeRateAction: viewModel.setPlaybackRate,
                                selectReciterAction: viewModel.selectReciter,
                                downloadCurrentAyahAction: { Task { await viewModel.downloadCurrentAyah() } },
                                downloadSurahAction: { Task { await viewModel.downloadSurah() } },
                                clearCacheAction: viewModel.clearAudioCache,
                                skipNextAction: viewModel.skipToNextAyah,
                                skipPreviousAction: viewModel.skipToPreviousAyah
                            )

                            VStack(spacing: 18) {
                                ForEach(viewModel.ayahs, id: \.ayahNumber) { ayah in
                                    ayahRow(for: ayah)
                                }
                            }
                        }
                        .padding()
                        .onChange(of: viewModel.ayahs.count) { _ in
                            if let lastRead = PersistenceService.shared.lastRead?.ayahNumber {
                                withAnimation(.easeInOut) {
                                    proxy.scrollTo(lastRead, anchor: .center)
                                }
                            }
                        }
                    }
                    .accessibilityElement(children: .contain)
                }
            }

            if focusMode {
                focusOverlay
            }
        }
        .navigationTitle(viewModel.surah.englishName)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarHidden(focusMode)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Button(action: { focusMode.toggle() }) {
                    Image(systemName: focusMode ? "eye" : "eye.slash")
                }
                .accessibilityLabel(focusMode ? "Exit focus mode" : "Enter focus mode")

                Button(action: { showCustomization.toggle() }) {
                    Image(systemName: "paintbrush")
                }
                .accessibilityLabel("Open reader settings")
            }
        }
        .sheet(isPresented: $showCustomization) {
            readerCustomizationSheet
        }
        .sheet(item: $editingNoteAyah) { ayah in
            noteEditor(for: ayah)
        }
    }

    private var loadingView: some View {
        VStack(spacing: 18) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .companionEmerald))
            Text("Loading surah…")
                .foregroundColor(.companionTextSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var readerSummary: some View {
        VStack(spacing: 14) {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Reading Analytics")
                        .font(.headline)
                        .foregroundColor(.companionText)
                    Text("Streak: \(viewModel.analytics.dailyStreak) days • Month: \(viewModel.analytics.monthlyProgress) verses • Total: \(viewModel.analytics.totalVersesRead)")
                        .font(.subheadline)
                        .foregroundColor(.companionTextSecondary)
                }
                Spacer()
                Button(action: { showCustomization = true }) {
                    Label("Customize", systemImage: "slider.horizontal.3")
                        .font(.footnote.weight(.semibold))
                        .foregroundColor(.companionAccent)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.85)))
                }
            }
            .padding()
            .background(RoundedRectangle(cornerRadius: 30).fill(Color.white.opacity(0.52)))
            .overlay(RoundedRectangle(cornerRadius: 30).stroke(Color.companionTeal.opacity(0.08), lineWidth: 1))
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 16) {
                Text(viewModel.surah.arabicName)
                    .font(.custom("UthmaniHafs", size: 42, relativeTo: .largeTitle))
                    .foregroundColor(viewModel.readerSettings.theme.textColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                Spacer()
                Text(viewModel.surah.revelationPlace.displayName.uppercased())
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.companionGold)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(Capsule().fill(Color.companionCard))
            }

            Text(viewModel.surah.translation)
                .font(.headline)
                .foregroundColor(.companionEmerald)

            HStack(spacing: 12) {
                statChip(label: "Ayahs", value: "\(viewModel.surah.ayahCount)")
                statChip(label: "Mode", value: viewModel.readerSettings.mode.title)
                Spacer()
            }

            Picker("Mode", selection: $viewModel.readerSettings.mode) {
                ForEach(ReaderMode.allCases) { mode in
                    Text(mode.title).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: viewModel.readerSettings.mode) { newMode in
                viewModel.updateReaderSettings(viewModel.readerSettings)
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 30, style: .continuous).fill(Color.companionCard.opacity(0.9)))
        .overlay(RoundedRectangle(cornerRadius: 30, style: .continuous).stroke(Color.companionTeal.opacity(0.08), lineWidth: 1))
    }

    private var focusOverlay: some View {
        VStack {
            HStack {
                Button(action: { focusMode = false }) {
                    Label("Exit Focus", systemImage: "xmark.circle.fill")
                        .padding(12)
                        .background(Color.black.opacity(0.35))
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                }
                Spacer()
            }
            .padding()
            Spacer()
        }
    }

    private func statChip(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundColor(.companionTextSecondary)
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.companionText)
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Color.companionSurface))
    }

    private var readerCustomizationSheet: some View {
        NavigationStack {
            Form {
                Section("Text") {
                    HStack {
                        Text("Font size")
                        Slider(value: $viewModel.readerSettings.fontSize, in: 16...32, step: 1)
                    }
                    HStack {
                        Text("Line spacing")
                        Slider(value: $viewModel.readerSettings.lineSpacing, in: 4...16, step: 1)
                    }
                }

                Section("Theme") {
                    Picker("Theme", selection: $viewModel.readerSettings.theme) {
                        ForEach(ReaderTheme.allCases) { theme in
                            Text(theme.rawValue.capitalized).tag(theme)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Background") {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 120), spacing: 12)], spacing: 12) {
                        ForEach(ReaderBackground.allCases) { background in
                            Button(action: {
                                viewModel.readerSettings.background = background
                                viewModel.updateReaderSettings(viewModel.readerSettings)
                            }) {
                                Text(background.title)
                                    .foregroundColor(.companionText)
                                    .frame(maxWidth: .infinity, minHeight: 50)
                                    .background(RoundedRectangle(cornerRadius: 16).fill(background.gradient))
                            }
                        }
                    }
                }
            }
            .navigationTitle("Reader Settings")
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { showCustomization = false } } }
            .onDisappear { viewModel.updateReaderSettings(viewModel.readerSettings) }
        }
    }

    private func ayahRow(for ayah: Ayah) -> some View {
        let ayahReference = "\(ayah.surahNumber)-\(ayah.ayahNumber)"
        let noteSummary = viewModel.readerNotes.first(where: { $0.surahNumber == ayah.surahNumber && $0.ayahNumber == ayah.ayahNumber })?.text
        let isHighlighted = viewModel.highlightedAyahIDs.contains(ayahReference)

        return AnyView(
            AyahRowView(
                ayah: ayah,
                mode: viewModel.readerSettings.mode,
                fontSize: viewModel.readerSettings.fontSize,
                lineSpacing: viewModel.readerSettings.lineSpacing,
                isHighlighted: isHighlighted,
                noteSummary: noteSummary,
                tapAction: {
                    viewModel.playAyah(ayah)
                    viewModel.saveProgress(ayah: ayah)
                }
            )
            .id(ayah.ayahNumber)
            .contextMenu {
                Button(action: { viewModel.toggleBookmark(ayah) }) {
                    Label("Bookmark ayah", systemImage: "bookmark")
                }
                Button(action: { viewModel.toggleHighlight(ayah) }) {
                    Label(isHighlighted ? "Remove highlight" : "Highlight ayah", systemImage: "highlighter")
                }
                Button(action: {
                    editingNoteAyah = ayah
                    noteDraft = noteSummary ?? ""
                }) {
                    Label("Add note", systemImage: "note.text")
                }
                Menu {
                    ForEach(viewModel.collections) { collection in
                        Button(collection.title) {
                            viewModel.addToCollection(ayah, collection: collection)
                        }
                    }
                } label: {
                    Label("Save to collection", systemImage: "folder")
                }
            }
        )
    }

    private func noteEditor(for ayah: Ayah) -> some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text("Note for Ayah \(ayah.ayahNumber)")
                    .font(.headline)
                    .padding(.top)
                TextEditor(text: $noteDraft)
                    .frame(minHeight: 180)
                    .padding(12)
                    .background(RoundedRectangle(cornerRadius: 16).fill(Color.companionCard))
                Spacer()
            }
            .padding()
            .navigationTitle("Add Note")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        viewModel.saveNote(for: ayah, text: noteDraft)
                        editingNoteAyah = nil
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { editingNoteAyah = nil }
                }
            }
        }
    }
}

#Preview {
    SurahDetailView(surah: MockData.surahs[0])
}
