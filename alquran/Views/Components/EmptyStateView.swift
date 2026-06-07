import SwiftUI

struct EmptyStateView: View {
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: "book.closed")
                .font(.system(size: 42))
                .foregroundColor(.companionAccent)
                .padding(20)
                .background(Circle().fill(Color.companionAccent.opacity(0.14)))
            Text(title)
                .font(.headline)
                .foregroundColor(.companionText)
            Text(message)
                .font(.subheadline)
                .foregroundColor(.companionTextSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 24).fill(Color.companionCard))
        .padding()
    }
}

#Preview {
    EmptyStateView(title: "No results", message: "Try a different search term.")
}
