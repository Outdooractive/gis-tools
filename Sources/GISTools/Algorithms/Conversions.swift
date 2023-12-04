#if !os(Linux)
import CoreLocation
#endif
import Foundation

// Ported from https://github.com/Turfjs/turf/tree/master/packages/turf-helpers

extension GISTool {

    /// Unit of measurement.
    public enum Unit {
        case acres
        case centimeters
        case centimetres
        case degrees
        case feet
        case inches
        case kilometers
        case kilometres
        case meters
        case metres
        case miles
        case millimeters
        case millimetres
        case nauticalmiles
        case radians
        case yards
    }

    /// Unit of measurement factors using a spherical (non-ellipsoid) earth radius.
    public static func factor(for unit: Unit) -> Double? {
        switch unit {
        case .centimeters, .centimetres: return earthRadius * 100.0
        case .degrees: return earthRadius / 111_325.0
        case .feet: return earthRadius * 3.28084
        case .inches: return earthRadius * 39.370
        case .kilometers, .kilometres: return earthRadius / 1000.0
        case .meters, .metres: return earthRadius
        case .miles: return earthRadius / 1609.344
        case .millimeters, .millimetres: return earthRadius * 1000.0
        case .nauticalmiles: return earthRadius / 1852.0
        case .radians: return 1.0
        case .yards: return earthRadius / 1.0936
        default: return nil
        }
    }

    /// Units of measurement factors based on 1 meter.
    public static func unitsFactor(for unit: Unit) -> Double? {
        switch unit {
        case .centimeters, .centimetres: return 100.0
        case .degrees: return 1.0 / 111_325.0
        case .feet: return 3.28084
        case .inches: return 39.370
        case .kilometers, .kilometres: return 1.0 / 1000.0
        case .meters, .metres: return 1.0
        case .miles: return 1.0 / 1609.344
        case .millimeters, .millimetres: return 1000.0
        case .nauticalmiles: return 1.0 / 1852.0
        case .radians: return 1.0 / earthRadius
        case .yards: return 1.0 / 1.0936
        default: return nil
        }
    }

    /// Area of measurement factors based on 1 square meter.
    public static func areaFactor(for unit: Unit) -> Double? {
        switch unit {
        case .acres: return 0.000247105
        case .centimeters, .centimetres: return 10000.0
        case .feet: return 10.763910417
        case .inches: return 1550.003100006
        case .kilometers, .kilometres: return 0.000001
        case .meters, .metres: return 1.0
        case .miles: return 3.86e-7
        case .millimeters, .millimetres: return 1_000_000
        case .yards: return 1.195990046
        default: return nil
        }
    }

    /// Converts a length to the requested unit.
    /// Valid units: miles, nauticalmiles, inches, yards, meters, metres, kilometers, centimeters, feet
    public static func convert(length: Double, from originalUnit: Unit, to finalUnit: Unit) -> Double? {
        guard length >= 0 else { return nil }
        return length.lengthToRadians(unit: originalUnit)?.radiansToLength(unit: finalUnit)
    }

    /// Converts a area to the requested unit.
    /// Valid units: kilometers, kilometres, meters, metres, centimetres, millimeters, acres, miles, yards, feet, inches
    public static func convert(area: Double, from originalUnit: Unit, to finalUnit: Unit) -> Double? {
        guard area >= 0,
              let startFactor = areaFactor(for: originalUnit),
              let finalFactor = areaFactor(for: finalUnit)
        else { return nil }

        return (area / startFactor) * finalFactor
    }

}
