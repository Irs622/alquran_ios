import SwiftUI

struct SurahCardView: View {
    let surah: Surah

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text(surah.arabicName)
                        .font(.title3.weight(.bold))
                        .foregroundColor(.companionText)
                    Text(surah.englishName)
                        .font(.footnote.weight(.semibold))
                        .foregroundColor(.companionTextSecondary)
                }
                Spacer()
                Text("S\(surah.number)")
                    .font(.headline.weight(.bold))
                    .foregroundColor(.companionAccent)
            }

            HStack(spacing: 12) {
                Label("\(surah.ayahCount) ayahs", systemImage: "list.number")
                    .font(.caption)
                    .foregroundColor(.companionTextSecondary)
                Spacer()
                Text(surah.revelationPlace.displayName)
                    .font(.caption)
                    .foregroundColor(.companionTextSecondary)
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 24).fill(Color.companionCard))
    }
}

#Preview {
    SurahCardView(surah: MockData.surahs[1])
}
