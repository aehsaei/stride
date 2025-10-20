import Foundation

// MARK: - Speed Unit

enum SpeedUnit: String, CaseIterable, Identifiable {
    case mph = "mph"
    case kmh = "km/h"

    var id: String { rawValue }

    func toMetersPerSecond(_ value: Double) -> Double {
        switch self {
        case .mph:
            return value * 0.44704  // 1 mph = 0.44704 m/s
        case .kmh:
            return value / 3.6      // 1 km/h = 1/3.6 m/s
        }
    }

    func fromMetersPerSecond(_ mps: Double) -> Double {
        switch self {
        case .mph:
            return mps / 0.44704
        case .kmh:
            return mps * 3.6
        }
    }
}

// MARK: - Pace Unit (min/km or min/mi)

enum PaceUnit: String, CaseIterable, Identifiable {
    case minPerKm = "min/km"
    case minPerMi = "min/mi"

    var id: String { rawValue }

    /// Convert speed in m/s to pace (minutes per distance unit)
    func fromMetersPerSecond(_ mps: Double) -> Double {
        guard mps > 0 else { return 0 }
        switch self {
        case .minPerKm:
            return (1000.0 / mps) / 60.0  // minutes per km
        case .minPerMi:
            return (1609.344 / mps) / 60.0  // minutes per mile
        }
    }

    /// Format pace as MM:SS
    func formatPace(_ pace: Double) -> String {
        guard pace > 0 && pace.isFinite else { return "--:--" }
        let totalSeconds = pace * 60.0
        let minutes = Int(totalSeconds / 60.0)
        let seconds = Int(totalSeconds.truncatingRemainder(dividingBy: 60.0))
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Height Unit

enum HeightUnit: String, CaseIterable, Identifiable {
    case cm = "cm"
    case ftIn = "ft/in"

    var id: String { rawValue }

    func toMeters(_ value: Double) -> Double {
        switch self {
        case .cm:
            return value / 100.0
        case .ftIn:
            // Value is stored as decimal feet (e.g., 5.75 = 5'9")
            return value * 0.3048
        }
    }

    func fromMeters(_ meters: Double) -> Double {
        switch self {
        case .cm:
            return meters * 100.0
        case .ftIn:
            // Convert to decimal feet
            return meters / 0.3048
        }
    }

    /// Convert total inches to decimal feet for internal storage
    static func inchesToFeet(_ feet: Int, _ inches: Int) -> Double {
        return Double(feet) + (Double(inches) / 12.0)
    }

    /// Convert decimal feet to feet and inches for display
    static func feetToComponents(_ decimalFeet: Double) -> (feet: Int, inches: Int) {
        let totalInches = decimalFeet * 12.0
        let feet = Int(totalInches / 12.0)
        let inches = Int(totalInches.truncatingRemainder(dividingBy: 12.0))
        return (feet, inches)
    }
}

// MARK: - Weight Unit

enum WeightUnit: String, CaseIterable, Identifiable {
    case kg = "kg"
    case lbs = "lbs"

    var id: String { rawValue }

    func toKilograms(_ value: Double) -> Double {
        switch self {
        case .kg:
            return value
        case .lbs:
            return value * 0.453592
        }
    }

    func fromKilograms(_ kg: Double) -> Double {
        switch self {
        case .kg:
            return kg
        case .lbs:
            return kg / 0.453592
        }
    }
}
