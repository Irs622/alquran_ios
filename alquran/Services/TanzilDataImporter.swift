import Foundation

enum TanzilDataImporterError: Error {
    case missingResource
    case invalidFormat(String)
}

final class TanzilDataImporter {
    static func importArabicQuran(from fileURL: URL) throws -> [Surah] {
        let content = try String(contentsOf: fileURL, encoding: .utf8)
        var surahMap: [Int: [Ayah]] = [:]

        for line in content.split(whereSeparator: \Character.isNewline).map({ String($0) }) {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { continue }
            let pieces = trimmed.split(separator: " ", maxSplits: 1)
            guard pieces.count == 2, let key = pieces.first else {
                throw TanzilDataImporterError.invalidFormat("Invalid line: \(line)")
            }

            let reference = key.split(separator: ":")
            guard reference.count == 2,
                  let surahNumber = Int(reference[0]),
                  let ayahNumber = Int(reference[1]) else {
                throw TanzilDataImporterError.invalidFormat("Invalid ayah reference: \(key)")
            }

            let text = String(pieces[1]).trimmingCharacters(in: .whitespaces)
            let ayah = Ayah(ayahNumber: ayahNumber, surahNumber: surahNumber, text: text)
            surahMap[surahNumber, default: []].append(ayah)
        }

        return surahMap.keys.sorted().map { number in
            let ayahs = surahMap[number]!.sorted(by: { $0.ayahNumber < $1.ayahNumber })
            let arabicName = "Surah \(number)"
            let englishName = "Surah \(number)"
            let translation = "Imported from Tanzil"
            let revelationPlace: RevelationPlace = .mecca

            return Surah(
                id: number,
                number: number,
                arabicName: arabicName,
                englishName: englishName,
                translation: translation,
                ayahCount: ayahs.count,
                revelationPlace: revelationPlace,
                ayahs: ayahs
            )
        }
    }
}
