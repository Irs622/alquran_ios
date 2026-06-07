import SwiftUI

struct BookmarksView: View {
    @StateObject private var viewModel = BookmarksViewModel()

    var body: some View {
        Group {
            if viewModel.bookmarks.isEmpty {
                EmptyStateView(title: "No bookmarks yet", message: "Save ayahs and surahs to find them quickly later.")
            } else {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        SectionHeaderView(title: "Bookmarks", subtitle: "Your saved passages")
                            .padding(.horizontal)

                        ForEach(viewModel.bookmarks) { bookmark in
                            HStack {
                                Image(systemName: bookmark.icon)
                                    .foregroundColor(.companionGold)
                                    .font(.title3)
                                    .frame(width: 44, height: 44)
                                    .background(Color.companionAccent.opacity(0.14))
                                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(bookmark.title)
                                        .font(.headline)
                                        .foregroundColor(.companionText)
                                    Text(bookmark.subtitle)
                                        .font(.subheadline)
                                        .foregroundColor(.companionTextSecondary)
                                }
                                Spacer()
                                Text(bookmark.progress)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundColor(.companionAccent)
                            }
                            .padding()
                            .background(RoundedRectangle(cornerRadius: 20).fill(Color.companionCard))
                            .padding(.horizontal)
                        }
                    }
                    .padding(.vertical)
                }
            }
        }
        .background(Color.companionBackground.ignoresSafeArea())
        .navigationTitle("Bookmarks")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    BookmarksView()
}
