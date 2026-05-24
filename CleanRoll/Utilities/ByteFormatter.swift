import Foundation

/// Converts raw byte counts into human-readable strings.
enum ByteFormatter {

    // MARK: - Shared Formatter (reuse for performance)
    private static let formatter: ByteCountFormatter = {
        let f = ByteCountFormatter()
        f.allowedUnits = [.useBytes, .useKB, .useMB, .useGB]
        f.countStyle = .file
        return f
    }()

    private static let compactFormatter: ByteCountFormatter = {
        let f = ByteCountFormatter()
        f.allowedUnits = [.useKB, .useMB, .useGB]
        f.countStyle = .file
        f.zeroPadsFractionDigits = false
        return f
    }()

    // MARK: - Public API

    /// Full format: "24.3 MB"
    static func string(fromBytes bytes: Int64) -> String {
        guard bytes > 0 else { return "Unknown" }
        return formatter.string(fromByteCount: bytes)
    }

    /// Compact format for badges: "24 MB" (fewer decimals)
    static func compactString(fromBytes bytes: Int64) -> String {
        guard bytes > 0 else { return "?" }
        return compactFormatter.string(fromByteCount: bytes)
    }

    /// Sum an array of byte counts and format as a total.
    static func totalString(fromBytes byteCounts: [Int64]) -> String {
        let total = byteCounts.reduce(0, +)
        return string(fromBytes: total)
    }
}
