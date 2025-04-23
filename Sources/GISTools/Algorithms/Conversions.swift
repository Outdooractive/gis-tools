#if !os(Linux)
import CoreLocation
#endif
import Foundation

// Ported from https://github.com/Turfjs/turf/tree/master/packages/turf-helpers

// MARK: Measurements

extension GISTool {

    /// Unit of measurement.
    public enum Unit: Sendable {
        case acres
        case centimeters
        case centimetres
        /// Latitude
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
        case .degrees: return earthRadius / (GISTool.earthCircumference / 360.0)
        case .feet: return earthRadius * 3.28084
        case .inches: return earthRadius * 39.370
        case .kilometers, .kilometres: return earthRadius / 1000.0
        case .meters, .metres: return earthRadius
        case .miles: return earthRadius / 1609.344
        case .millimeters, .millimetres: return earthRadius * 1000.0
        case .nauticalmiles: return earthRadius / 1852.0
        case .radians: return 1.0
        case .yards: return earthRadius / (1.0 / 1.0936)
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
        case .centimeters, .centimetres: return 10_000.0
        case .feet: return 10.763910417
        case .inches: return 1550.003100006
        case .kilometers, .kilometres: return 0.000001
        case .meters, .metres: return 1.0
        case .miles: return 3.86e-7
        case .millimeters, .millimetres: return 1_000_000.0
        case .yards: return 1.195990046
        default: return nil
        }
    }

    /// Converts a length to the requested unit.
    /// Valid units: miles, nauticalmiles, inches, yards, meters, metres, kilometers, centimeters, feet
    public static func convert(
        length: Double,
        from originalUnit: Unit,
        to finalUnit: Unit
    ) -> Double? {
        guard length >= 0 else { return nil }
        return length.lengthToRadians(unit: originalUnit)?.radiansToLength(unit: finalUnit)
    }

    /// Converts a area to the requested unit.
    /// Valid units: kilometers, kilometres, meters, metres, centimetres, millimeters, acres, miles, yards, feet, inches
    public static func convert(
        area: Double,
        from originalUnit: Unit,
        to finalUnit: Unit
    ) -> Double? {
        guard area >= 0,
              let startFactor = areaFactor(for: originalUnit),
              let finalFactor = areaFactor(for: finalUnit)
        else { return nil }

        return (area / startFactor) * finalFactor
    }

}

// MARK: - Pixels

extension GISTool {

    @available(*, deprecated, renamed: "coordinate(fromPixelX:pixelY:zoom:tileSideLength:projection:)")
    public static func convertToCoordinate(
        fromPixelX pixelX: Double,
        pixelY: Double,
        atZoom zoom: Int,
        tileSideLength: Double = GISTool.tileSideLength,
        projection: Projection = .epsg4326
    ) -> Coordinate3D {
        coordinate(fromPixelX: pixelX,
                   pixelY: pixelY,
                   zoom: zoom,
                   tileSideLength: tileSideLength,
                   projection: projection)
    }

    /// Converts pixel coordinates in a given zoom level to a coordinate.
    public static func coordinate(
        fromPixelX pixelX: Double,
        pixelY: Double,
        zoom: Int,
        tileSideLength: Double = GISTool.tileSideLength,
        projection: Projection = .epsg4326
    ) -> Coordinate3D {
        let resolution = metersPerPixel(atZoom: zoom, tileSideLength: tileSideLength)

        let coordinateXY = Coordinate3D(
            x: pixelX * resolution - GISTool.originShift,
            y: pixelY * resolution - GISTool.originShift)

        if projection == .epsg4326 {
            return coordinateXY.projected(to: projection)
        }

        return coordinateXY
    }

    /// Resolution (meters/pixel) for a given zoom level (measured at `latitude`, defaults to the equator).
    public static func metersPerPixel(
        atZoom zoom: Int,
        latitude: CLLocationDegrees = 0.0, // equator
        tileSideLength: Double = GISTool.tileSideLength)
        -> Double
    {
        (cos(latitude * Double.pi / 180.0) * 2.0 * Double.pi * GISTool.equatorialRadius / tileSideLength) / pow(2.0, Double(zoom))
    }

}

// MARK: - Meters/latitude

extension GISTool {

    @available(*, deprecated, renamed: "degrees(fromMeters:atLatitude:)")
    public static func convertToDegrees(
        fromMeters meters: Double,
        atLatitude latitude: CLLocationDegrees
    ) -> (latitudeDegrees: CLLocationDegrees, longitudeDegrees: CLLocationDegrees) {
        degrees(fromMeters: meters, atLatitude: latitude)
    }

    public static func degrees(
        fromMeters meters: CLLocationDistance,
        atLatitude latitude: CLLocationDegrees
    ) -> (latitudeDegrees: CLLocationDegrees, longitudeDegrees: CLLocationDegrees) {
        // Length of one minute at this latitude
        let oneDegreeLatitudeDistance: CLLocationDistance = GISTool.earthCircumference / 360.0 // ~111 km
        let oneDegreeLongitudeDistance: CLLocationDistance = cos(latitude * Double.pi / 180.0) * oneDegreeLatitudeDistance

        let longitudeDistance: Double = (meters / oneDegreeLongitudeDistance)
        let latitudeDistance: Double = (meters / oneDegreeLatitudeDistance)

        return (latitudeDistance, longitudeDistance)
    }

}

extension Coordinate3D {

    public func degrees(
        fromMeters meters: CLLocationDistance
    ) -> (latitudeDegrees: CLLocationDegrees, longitudeDegrees: CLLocationDegrees) {
        GISTool.degrees(fromMeters: meters, atLatitude: latitude)
    }

}
