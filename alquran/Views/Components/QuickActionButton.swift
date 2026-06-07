import SwiftUI

struct QuickActionButton: View {
    let action: QuickAction

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: action.symbol)
                    .foregroundColor(.white)
                    .frame(width: 28, height: 28)
                    .background(action.tintColor)
                    .cornerRadius(10)
                Spacer()
            }
            Text(action.title)
                .font(.headline)
                .foregroundColor(.companionText)
            Text(action.subtitle)
                .font(.footnote)
                .foregroundColor(.companionTextSecondary)
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 22, style: .continuous).fill(Color.companionCard))
    }
}

#Preview {
    QuickActionButton(action: MockData.quickActions[0])
}
