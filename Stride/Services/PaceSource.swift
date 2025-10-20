import Foundation

/// Source of pace data for cadence calculation
enum PaceSource: String, CaseIterable, Identifiable {
    case manual = "Manual"
    case gps = "GPS"

    var id: String { rawValue }
}
