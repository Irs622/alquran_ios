import Foundation
import Combine
import SwiftUI

@MainActor
final class BookmarksViewModel: ObservableObject {
    @Published var bookmarks: [Bookmark] = []

    private let persistence = PersistenceService.shared

    init() {
        bookmarks = persistence.bookmarks
    }

    func removeBookmark(at offsets: IndexSet) {
        bookmarks.remove(atOffsets: offsets)
        persistence.bookmarks = bookmarks
    }
}
