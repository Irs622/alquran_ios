import Foundation

enum QuranAPIError: Error, LocalizedError {
    case invalidURL
    case requestFailed(Error)
    case decodingFailed(Error)
    case unexpectedResponse

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid API endpoint."
        case .requestFailed(let error):
            return "Network request failed: \(error.localizedDescription)"
        case .decodingFailed(let error):
            return "Unable to parse Quran data: \(error.localizedDescription)"
        case .unexpectedResponse:
            return "Unexpected response from the Quran service."
        }
    }
}

final class QuranAPIService {
    static let shared = QuranAPIService()
    private let baseURL = URL(string: "https://equran.id/api/v2")!
    private let session: URLSession
    private let cache = QuranCacheManager.shared
    private let decoder: JSONDecoder

    private init() {
        let config = URLSessionConfiguration.default
        config.requestCachePolicy = .returnCacheDataElseLoad
        config.urlCache = URLCache(memoryCapacity: 64 * 1024 * 1024, diskCapacity: 256 * 1024 * 1024)
        session = URLSession(configuration: config)
        decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        decoder.keyDecodingStrategy = .convertFromSnakeCase
    }

    func fetchSurahList() async throws -> [Surah] {
        let endpoint = apiURL("surah")
        let data = try await requestData(from: endpoint, cacheKey: "surahList")
        let result = try decoder.decode(EQuranSurahListResponse.self, from: data)
        return result.data.map { summary in
            Surah(
                id: summary.number,
                number: summary.number,
                arabicName: summary.name,
                englishName: summary.englishName,
                translation: summary.englishNameTranslation,
                ayahCount: summary.numberOfAyahs,
                revelationPlace: RevelationPlace(rawValue: summary.revelationType) ?? .mecca,
                metadata: summary.metadata,
                audioSources: nil,
                lastSyncedAt: summary.updatedAt,
                ayahs: nil,
                remoteVersion: summary.updatedAt?.description
            )
        }
    }

    func fetchSurahDetail(number: Int, edition: QuranEdition = .arabicUthmani) async throws -> Surah {
        let endpoint = apiURL("surah/\(number)?edition=\(edition.rawValue)")
        let data = try await requestData(from: endpoint, cacheKey: "surah-detail-\(number)-\(edition.rawValue)")
        let result = try JSONDecoder().decode(EQuranSurahDetailResponse.self, from: data)
        let ayahs = result.data.ayahs.map { apiAyah in
            Ayah(
                ayahNumber: apiAyah.numberInSurah ?? apiAyah.number,
                surahNumber: result.data.number,
                text: apiAyah.text,
                transliteration: apiAyah.transliteration,
                translation: apiAyah.translation,
                juz: apiAyah.juz,
                page: apiAyah.page,
                tafsir: apiAyah.tafsir,
                audioResourceURL: apiAyah.audioURL,
                hizbQuarter: apiAyah.hizbQuarter,
                ruku: apiAyah.ruku,
                lastUpdatedAt: apiAyah.updatedAt
            )
        }

        return Surah(
            id: result.data.number,
            number: result.data.number,
            arabicName: result.data.name,
            englishName: result.data.englishName,
            translation: result.data.englishNameTranslation,
            ayahCount: result.data.numberOfAyahs,
            revelationPlace: RevelationPlace(rawValue: result.data.revelationType) ?? .mecca,
            metadata: result.data.metadata,
            audioSources: result.data.audioSources,
            lastSyncedAt: result.data.updatedAt,
            ayahs: ayahs,
            remoteVersion: result.data.updatedAt?.description
        )
    }

    func fetchSurahMetadata(number: Int) async throws -> SurahMetadata {
        let endpoint = apiURL("surah/\(number)/metadata")
        let data = try await requestData(from: endpoint, cacheKey: "surah-metadata-\(number)")
        let result = try JSONDecoder().decode(EQuranSurahMetadataResponse.self, from: data)
        return result.data
    }

    func fetchAudioSources(forSurah number: Int) async throws -> [QuranAudioSource] {
        let endpoint = apiURL("surah/\(number)/audio")
        let data = try await requestData(from: endpoint, cacheKey: "surah-audio-\(number)")
        let result = try JSONDecoder().decode(EQuranAudioResponse.self, from: data)
        return result.data
    }

    /// Returns a deterministic daily verse based on the current calendar day.
    /// The equran.id API does not expose a dedicated daily-verse endpoint, so we
    /// rotate through a curated pool of well-known ayahs using the day-of-year.
    func fetchDailyVerse() async throws -> DailyAyah {
        let pool: [(text: String, translation: String, reference: String, surahName: String)] = [
            ("بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ", "In the name of Allah, the Most Compassionate, Most Merciful.", "1:1", "Al-Fatiha"),
            ("الْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ", "All praise is due to Allah, Lord of all the worlds.", "1:2", "Al-Fatiha"),
            ("أَلَا بِذِكْرِ اللَّهِ تَطْمَئِنُّ الْقُلُوبُ", "Verily, in the remembrance of Allah do hearts find rest.", "13:28", "Ar-Ra'd"),
            ("فَإِنَّ مَعَ الْعُسْرِ يُسْرًا", "For indeed, with hardship will be ease.", "94:5", "Ash-Sharh"),
            ("وَهُوَ مَعَكُمْ أَيْنَ مَا كُنتُمْ", "And He is with you wherever you are.", "57:4", "Al-Hadid"),
            ("إِنَّ اللَّهَ مَعَ الصَّابِرِينَ", "Indeed, Allah is with the patient.", "2:153", "Al-Baqarah"),
            ("رَبِّ زِدْنِي عِلْمًا", "My Lord, increase me in knowledge.", "20:114", "Ta-Ha"),
            ("وَعَسَىٰ أَن تَكْرَهُوا شَيْئًا وَهُوَ خَيْرٌ لَّكُمْ", "But perhaps you hate a thing and it is good for you.", "2:216", "Al-Baqarah"),
            ("وَمَن يَتَوَكَّلْ عَلَى اللَّهِ فَهُوَ حَسْبُهُ", "And whoever relies upon Allah — then He is sufficient for him.", "65:3", "At-Talaq"),
            ("إِنَّ مَعَ الْعُسْرِ يُسْرًا", "Indeed, with hardship comes ease.", "94:6", "Ash-Sharh"),
            ("قُلْ هُوَ اللَّهُ أَحَدٌ", "Say: He is Allah, the One.", "112:1", "Al-Ikhlas"),
            ("وَاللَّهُ خَيْرُ الرَّازِقِينَ", "And Allah is the best of providers.", "62:11", "Al-Jumu'ah"),
        ]
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
        let entry = pool[(dayOfYear - 1) % pool.count]
        return DailyAyah(
            text: entry.text,
            translation: entry.translation,
            reference: entry.reference,
            surahName: entry.surahName
        )
    }

    func fetchAyahTafsir(surah: Int, ayah: Int) async throws -> String {
        let endpoint = apiURL("ayah/\(surah):\(ayah)/tafsir")
        let data = try await requestData(from: endpoint, cacheKey: "ayah-tafsir-\(surah)-\(ayah)")
        let result = try JSONDecoder().decode(EQuranTafsirResponse.self, from: data)
        return result.data.text
    }

    private func apiURL(_ path: String) -> URL {
        baseURL.appendingPathComponent(path)
    }

    private func requestData(from url: URL, cacheKey: String) async throws -> Data {
        AppLogger.debug("Requesting \(url)")
        var request = URLRequest(url: url)
        request.timeoutInterval = 30

        do {
            let (data, response) = try await session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse,
                  200..<300 ~= httpResponse.statusCode else {
                AppLogger.warning("Unexpected response for \(url)")
                throw QuranAPIError.unexpectedResponse
            }
            cache.storeRaw(data, for: cacheKey)
            return data
        } catch {
            if let cached = cache.loadRaw(for: cacheKey) {
                AppLogger.warning("Using cached data for \(cacheKey) after network failure.")
                return cached
            }
            throw QuranAPIError.requestFailed(error)
        }
    }
}

private struct EQuranSurahListResponse: Codable {
    let status: String
    let data: [EQuranSurahSummary]
}

private struct EQuranSurahDetailResponse: Codable {
    let status: String
    let data: EQuranSurahDetail
}

private struct EQuranSurahMetadataResponse: Codable {
    let status: String
    let data: SurahMetadata
}

private struct EQuranAudioResponse: Codable {
    let status: String
    let data: [QuranAudioSource]
}

private struct EQuranTafsirResponse: Codable {
    let status: String
    let data: APIAyahTafsir
}

private struct EQuranSurahSummary: Codable {
    let number: Int
    let name: String
    let englishName: String
    let englishNameTranslation: String
    let numberOfAyahs: Int
    let revelationType: String
    let updatedAt: Date?
    let metadata: SurahMetadata?
}

private struct EQuranSurahDetail: Codable {
    let number: Int
    let name: String
    let englishName: String
    let englishNameTranslation: String
    let numberOfAyahs: Int
    let revelationType: String
    let ayahs: [APIAyah]
    let metadata: SurahMetadata?
    let audioSources: [QuranAudioSource]?
    let updatedAt: Date?
}

private struct APIAyah: Codable {
    let number: Int
    let text: String
    let numberInSurah: Int?
    let transliteration: String?
    let translation: String?
    let juz: Int?
    let page: Int?
    let hizbQuarter: Int?
    let ruku: Int?
    let tafsir: String?
    let audioURL: URL?
    let updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case number
        case text
        case numberInSurah
        case transliteration
        case translation
        case juz
        case page
        case hizbQuarter
        case ruku
        case tafsir
        case audioURL = "audio_url"
        case updatedAt = "updated_at"
    }
}

private struct APIAyahTafsir: Codable {
    let text: String
}
