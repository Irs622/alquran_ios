import Foundation

enum AppLogger {
    static func debug(_ message: String) {
        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] != "1" {
            print("[DEBUG] \(message)")
        }
    }

    static func info(_ message: String) {
        print("[INFO] \(message)")
    }

    static func warning(_ message: String) {
        print("[WARN] \(message)")
    }

    static func error(_ message: String) {
        print("[ERROR] \(message)")
    }
}
