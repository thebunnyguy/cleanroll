import Foundation

/// Formats video durations from seconds into human-readable strings.
enum DurationFormatter {

    // MARK: - Public API

    /// Compact format for grid badges: "0:32", "5:04", "1:23:45"
    static func compactString(from seconds: Double) -> String {
        guard seconds > 0 else { return "" }

        let totalSeconds = Int(seconds.rounded())
        let hrs = totalSeconds / 3600
        let mins = (totalSeconds % 3600) / 60
        let secs = totalSeconds % 60

        if hrs > 0 {
            return String(format: "%d:%02d:%02d", hrs, mins, secs)
        } else {
            return String(format: "%d:%02d", mins, secs)
        }
    }

    /// Descriptive format for detail views: "5 min 4 sec", "1 hr 23 min"
    static func descriptiveString(from seconds: Double) -> String {
        guard seconds > 0 else { return "—" }

        let totalSeconds = Int(seconds.rounded())
        let hrs = totalSeconds / 3600
        let mins = (totalSeconds % 3600) / 60
        let secs = totalSeconds % 60

        var parts: [String] = []
        if hrs > 0 { parts.append("\(hrs) hr") }
        if mins > 0 { parts.append("\(mins) min") }
        if secs > 0 || parts.isEmpty { parts.append("\(secs) sec") }

        return parts.joined(separator: " ")
    }
}
