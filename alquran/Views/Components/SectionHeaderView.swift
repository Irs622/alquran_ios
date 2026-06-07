import SwiftUI

struct SectionHeaderView: View {
    let title: String
    let subtitle: String

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.companionText)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.companionTextSecondary)
            }
            Spacer()
        }
    }
}

#Preview {
    SectionHeaderView(title: "Recently Accessed", subtitle: "Your latest chapters")
}
