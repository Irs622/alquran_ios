import Foundation

final class CacheService {
    static let shared = CacheService()

    private let fileManager = FileManager.default
    private lazy var cacheDirectory: URL = {
        let directory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
        let cacheURL = directory.appendingPathComponent("QuranCompanionCache", isDirectory: true)
        if !fileManager.fileExists(atPath: cacheURL.path) {
            try? fileManager.createDirectory(at: cacheURL, withIntermediateDirectories: true)
        }
        return cacheURL
    }()

    private init() {}

    func store<T: Codable>(_ value: T, for key: String) {
        let url = cacheDirectory.appendingPathComponent("\(key).json")
        do {
            let data = try JSONEncoder().encode(value)
            try data.write(to: url, options: .atomic)
            AppLogger.debug("Cache saved for key: \(key)")
        } catch {
            AppLogger.error("Failed to cache \(key): \(error)")
        }
    }

    func load<T: Codable>(_ type: T.Type, for key: String) -> T? {
        let url = cacheDirectory.appendingPathComponent("\(key).json")
        guard fileManager.fileExists(atPath: url.path) else {
            AppLogger.debug("Cache miss for key: \(key)")
            return nil
        }

        do {
            let data = try Data(contentsOf: url)
            let value = try JSONDecoder().decode(type, from: data)
            AppLogger.debug("Cache loaded for key: \(key)")
            return value
        } catch {
            AppLogger.error("Failed to read cache for \(key): \(error)")
            return nil
        }
    }

    func clearCache() {
        do {
            let contents = try fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil)
            for url in contents {
                try fileManager.removeItem(at: url)
            }
            AppLogger.info("Cache cleared")
        } catch {
            AppLogger.error("Failed to clear cache: \(error)")
        }
    }

    func localURL(forAudioURL url: URL) -> URL {
        let safeName = url.absoluteString
            .addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? UUID().uuidString
        return cacheDirectory.appendingPathComponent("audio-\(safeName)")
    }

    func audioCacheURLs() -> [URL] {
        (try? fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil)) ?? []
    }

    func audioCacheSize() -> Int64 {
        let urls = audioCacheURLs()
        let fileSizes = urls.compactMap { url -> Int64? in
            (try? url.resourceValues(forKeys: [.fileSizeKey]))?.fileSize.map { Int64($0) }
        }
        return fileSizes.reduce(0, +)
    }

    func clearAudioCache() {
        let urls = audioCacheURLs()
        for url in urls {
            try? fileManager.removeItem(at: url)
        }
        AppLogger.info("Audio cache cleared")
    }
}
