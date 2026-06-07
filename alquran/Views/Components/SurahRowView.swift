import SwiftUI

struct SurahRowView: View {
    let surah: Surah

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack {
                Text(String(surah.number))
                    .font(.headline.weight(.semibold))
                    .foregroundColor(.white)
            }
            .frame(width: 48, height: 48)
            .background(Color.companionAccent)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

            VStack(alignment: .leading, spacing: 8) {
                Text(surah.arabicName)
                    .font(.title3.weight(.semibold))
                    .foregroundColor(.companionText)
                Text(surah.englishName)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.companionTextSecondary)
                HStack(spacing: 12) {
                    Label(surah.revelationPlace.displayName, systemImage: "location.fill")
                        .font(.caption)
                        .foregroundColor(.companionTextSecondary)
                    Text("\(surah.ayahCount) ayahs")
                        .font(.caption)
                        .foregroundColor(.companionTextSecondary)
                }
            }
            Spacer()
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 20).fill(Color.companionCard))
    }
}

#Preview {
    SurahRowView(surah: MockData.surahs[0])
}
