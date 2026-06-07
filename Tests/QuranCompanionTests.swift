import XCTest
@testable import alquran

final class QuranCompanionTests: XCTestCase {
    func testSurahModelMapping() throws {
        let sample = Surah(
            id: 1,
            number: 1,
            arabicName: "الفاتحة",
            englishName: "Al-Fatiha",
            translation: "The Opening",
            ayahCount: 7,
            revelationPlace: .mecca,
            lastReadVerse: "Ayah 1",
            lastReadDate: Date(),
            ayahs: [Ayah(ayahNumber: 1, surahNumber: 1, text: "بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ", transliteration: "Bismillah", translation: "In the name of Allah", juz: 1, page: 1)]
        )
        XCTAssertEqual(sample.number, 1)
        XCTAssertEqual(sample.ayahs?.first?.translation, "In the name of Allah")
    }

    func testCacheServiceStoresAndLoads() throws {
        struct TestValue: Codable, Equatable {
            let name: String
        }
        let key = "testCache"
        let value = TestValue(name: "cache")
        CacheService.shared.store(value, for: key)
        let loaded = CacheService.shared.load(TestValue.self, for: key)
        XCTAssertEqual(loaded, value)
    }
}
