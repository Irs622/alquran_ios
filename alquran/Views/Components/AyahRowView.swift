import SwiftUI

struct AyahRowView: View {
    let ayah: Ayah
    let mode: ReaderMode
    let fontSize: Double
    let lineSpacing: Double
    let isHighlighted: Bool
    let noteSummary: String?
    let tapAction: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 16) {
                Text("\(ayah.ayahNumber)")
                    .font(.caption.weight(.bold))
                    .foregroundColor(mode.themeAccent)
                    .padding(10)
                    .background(Circle().fill(mode.themeAccent.opacity(0.18)))
                VStack(alignment: .leading, spacing: 8) {
                    Text(ayah.text)
                        .font(.custom("UthmaniHafs", size: fontSize, relativeTo: .title3))
                        .foregroundColor(mode.textColor)
                        .multilineTextAlignment(.trailing)
                        .lineSpacing(lineSpacing)
                        .frame(maxWidth: .infinity, alignment: .trailing)

                    if mode.showTranslation, let translation = ayah.translation {
                        Text(translation)
                            .font(.system(size: max(14, fontSize - 4)))
                            .foregroundColor(mode.textColor.opacity(0.78))
                            .lineSpacing(lineSpacing * 0.9)
                    }

                    if mode.showTransliteration, let transliteration = ayah.transliteration {
                        Text(transliteration)
                            .font(.system(size: max(13, fontSize - 6), weight: .medium, design: .default))
                            .foregroundColor(mode.textColor.opacity(0.72))
                            .lineSpacing(lineSpacing * 0.8)
                    }

                    if let note = noteSummary {
                        HStack(alignment: .center, spacing: 8) {
                            Image(systemName: "note.text")
                                .font(.caption)
                                .foregroundColor(mode.themeAccent)
                            Text(note)
                                .font(.caption)
                                .foregroundColor(mode.textColor.opacity(0.66))
                                .lineLimit(1)
                        }
                        .padding(.top, 4)
                    }
                }
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 24).fill(isHighlighted ? mode.themeAccent.opacity(0.16) : Color.companionCard))
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(isHighlighted ? mode.themeAccent.opacity(0.35) : Color.clear, lineWidth: 1.5)
        )
        .onTapGesture(perform: tapAction)
    }
}

private extension ReaderMode {
    var themeAccent: Color {
        switch self {
        case .arabicOnly: return .companionEmerald
        case .arabicTranslation: return .companionAccent
        case .arabicTransliteration: return .companionGold
        case .full: return .companionEmerald
        }
    }

    var textColor: Color {
        switch self {
        case .arabicOnly, .full: return .companionText
        case .arabicTranslation: return .companionText
        case .arabicTransliteration: return .companionText
        }
    }
}

#Preview {
    AyahRowView(
        ayah: Ayah(
            ayahNumber: 1,
            surahNumber: 1,
            text: "بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ",
            transliteration: "Bismillah ar-Rahman ar-Raheem",
            translation: "In the name of Allah, the Most Compassionate, Most Merciful.",
            juz: 1,
            page: 1
        ),
        mode: .full,
        fontSize: 22,
        lineSpacing: 8,
        isHighlighted: true,
        noteSummary: "Reflect on mercy",
        tapAction: { print("play") }
    )
}
