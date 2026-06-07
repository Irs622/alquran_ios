import Foundation

enum MockData {
    static let surahs: [Surah] = [
        Surah(
            id: 1,
            number: 1,
            arabicName: "الفاتحة",
            englishName: "Al-Fatiha",
            translation: "The Opening",
            ayahCount: 7,
            revelationPlace: .mecca,
            ayahs: [
                Ayah(ayahNumber: 1, surahNumber: 1, text: "بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ", transliteration: "Bismillah ar-Rahman ar-Raheem", translation: "In the name of Allah, the Most Compassionate, Most Merciful.", juz: 1, page: 1),
                Ayah(ayahNumber: 2, surahNumber: 1, text: "الْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ", transliteration: "Alhamdu lillahi rabbil 'alamin", translation: "All praise is due to Allah, Lord of all the worlds.", juz: 1, page: 1)
            ]
        ),
        Surah(
            id: 2,
            number: 2,
            arabicName: "البقرة",
            englishName: "Al-Baqarah",
            translation: "The Cow",
            ayahCount: 286,
            revelationPlace: .medina
        )
    ]

    static let dailyVerse = DailyAyah(
        text: "In the remembrance of Allah do hearts find rest.",
        translation: "Indeed, in the remembrance of Allah do hearts find rest.",
        reference: "13:28",
        surahName: "Ar-Ra'd"
    )

    static let quickActions: [QuickAction] = [
        QuickAction(title: "Continue", subtitle: "Resume recitation", symbol: "play.fill", tint: .emerald),
        QuickAction(title: "Surah", subtitle: "Browse chapters", symbol: "book.closed.fill", tint: .sage),
        QuickAction(title: "Verse", subtitle: "Save an ayah", symbol: "bookmark.fill", tint: .gold),
        QuickAction(title: "Reflect", subtitle: "Daily reflection", symbol: "sparkles", tint: .sand)
    ]

    static let bookmarks: [Bookmark] = [
        Bookmark(surahNumber: 1, ayahNumber: 3, title: "Al-Fatiha", subtitle: "Ayah 3 — First lesson", createdAt: Date().addingTimeInterval(-12000)),
        Bookmark(surahNumber: 2, ayahNumber: 255, title: "Al-Baqarah", subtitle: "Ayah 255 — Ayat al-Kursi", createdAt: Date().addingTimeInterval(-86400))
    ]
}
