import Foundation

final class QuranCacheManager {
    static let shared = QuranCacheManager()

    private let fileManager = FileManager.default
    private lazy var cacheDirectory: URL = {
        let directory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
        let cacheURL = directory.appendingPathComponent("QuranCache", isDirectory: true)
        if !fileManager.fileExists(atPath: cacheURL.path) {
            try? fileManager.createDirectory(at: cacheURL, withIntermediateDirectories: true)
        }
        return cacheURL
    }()

    private init() {}

    func store<T: Codable>(_ value: T, for key: String) {
        let url = cacheDirectory.appendingPathComponent(key).appendingPathExtension("json")
        do {
            let data = try JSONEncoder().encode(value)
            try data.write(to: url, options: .atomic)
        } catch {
            AppLogger.error("QuranCacheManager failed to cache [\(key)]: \(error)")
        }
    }

    func load<T: Codable>(_ type: T.Type, for key: String) -> T? {
        let url = cacheDirectory.appendingPathComponent(key).appendingPathExtension("json")
        guard fileManager.fileExists(atPath: url.path) else { return nil }
        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode(type, from: data)
        } catch {
            AppLogger.error("QuranCacheManager failed to load [\(key)]: \(error)")
            return nil
        }
    }

    func storeRaw(_ data: Data, for key: String) {
        let url = cacheDirectory.appendingPathComponent(key).appendingPathExtension("bin")
        do {
            try data.write(to: url, options: .atomic)
        } catch {
            AppLogger.error("QuranCacheManager failed to cache raw data [\(key)]: \(error)")
        }
    }

    func loadRaw(for key: String) -> Data? {
        let url = cacheDirectory.appendingPathComponent(key).appendingPathExtension("bin")
        return try? Data(contentsOf: url)
    }

    func localAudioURL(for remoteURL: URL) -> URL {
        let safeName = remoteURL.absoluteString.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? UUID().uuidString
        return cacheDirectory.appendingPathComponent("audio-").appendingPathComponent(safeName)
    }

    func audioCacheURLs() -> [URL] {
        (try? fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil)) ?? []
    }

    func clearCache() {
        do {
            let contents = try fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil)
            for item in contents {
                try fileManager.removeItem(at: item)
            }
        } catch {
            AppLogger.error("QuranCacheManager failed to clear cache: \(error)")
        }
    }
}
