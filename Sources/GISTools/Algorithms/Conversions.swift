#if canImport(CoreLocation)
import CoreLocation
#endif
import Foundation

// Ported from https://github.com/Turfjs/turf/tree/master/packages/turf-helpers

// MARK: Measurements

extension GISTool {

    /// Unit of measurement.
    public enum Unit: Sendable {
        /// Acres.
        case acres
        /// Centimeters.
        case centimeters
        /// Centimetres.
        case centimetres
        /// Latitude
        case degrees
        /// Feet.
        case feet
        /// Inches.
        case inches
        /// Kilometers.
        case kilometers
        /// Kilometres.
        case kilometres
        /// Meters.
        case meters
        /// Metres.
        case metres
        /// Miles.
        case miles
        /// Millimeters.
        case millimeters
        /// Millimetres.
        case millimetres
        /// Nautical miles.
        case nauticalMiles
        /// Radians.
        case radians
        /// Yards.
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
        case .nauticalMiles: return earthRadius / 1852.0
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
        case .nauticalMiles: return 1.0 / 1852.0
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
        case .miles: return 0.000000386
        case .millimeters, .millimetres: return 1_000_000.0
        case .yards: return 1.195990046
        default: return nil
        }
    }

    /// Converts a length to the requested unit.
    /// Valid units: miles, nauticalMiles, inches, yards, meters, metres, kilometers, centimeters, feet
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

    /// Converts a length value from any unit to meters.
    ///
    /// ```swift
    /// GISTool.convertToMeters(5, .kilometers) // 5000.0
    /// GISTool.convertToMeters(1, .miles)      // 1609.344
    /// ```
    /// - Parameter value: The value to convert.
    /// - Parameter unit: The unit of `value`. Note that `.degrees` is supported
    ///   as a convenience for test code, but it only approximates equatorial
    ///   longitude — 1° of longitude at the equator ≈ 111.325 km, whereas 1°
    ///   of latitude is constant (~111.325 km) and 1° of longitude shrinks
    ///   toward the poles (0 km at 90°). For latitude-aware conversions use
    ///   Haversine distance (``Coordinate3D/distance(to:)``) instead.
    /// - Returns: The value converted to meters.
    ///
    /// - note: Mainly for tests.
    public static func convertToMeters(
        _ value: Double,
        _ unit: Unit
    ) -> Double {
        switch unit {
        case .millimeters, .millimetres: return value / 1000.0
        case .centimeters, .centimetres: return value / 100.0
        case .meters, .metres: return value
        case .kilometers, .kilometres: return value * 1000.0
        case .inches: return value / 39.370
        case .feet: return value / 3.28084
        case .yards: return value / 1.0936
        case .miles: return value * 1609.344
        case .nauticalMiles: return value * 1852.0
        case .degrees: return value * 111_325.0
        default: return value
        }
    }

}

// MARK: - Pixels

extension GISTool {

    /// Converts pixel coordinates to a coordinate at the given zoom level.
    ///
    /// - Parameter pixelX: The x pixel coordinate.
    /// - Parameter pixelY: The y pixel coordinate.
    /// - Parameter zoom: The zoom level.
    /// - Parameter tileSideLength: The tile side length in pixels.
    /// - Parameter projection: The projection to use.
    /// - Returns: The coordinate for the pixel position.
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
    ///
    /// - Returns: The coordinate for the pixel position.
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
    ///
    /// - Returns: The resolution in meters per pixel.
    public static func metersPerPixel(
        atZoom zoom: Int,
        latitude: CLLocationDegrees = 0.0, // equator
        tileSideLength: Double = GISTool.tileSideLength
    ) -> Double {
        (cos(latitude * Double.pi / 180.0) * 2.0 * Double.pi * GISTool.equatorialRadius / tileSideLength) / pow(2.0, Double(zoom))
    }

}

// MARK: - Meters/latitude

extension GISTool {

    /// Converts a distance in meters to degrees at a given latitude.
    ///
    /// - Parameter meters: The distance in meters.
    /// - Parameter latitude: The latitude at which to calculate the conversion.
    /// - Returns: A tuple of latitude degrees and longitude degrees.
    @available(*, deprecated, renamed: "degrees(fromMeters:atLatitude:)")
    public static func convertToDegrees(
        fromMeters meters: Double,
        atLatitude latitude: CLLocationDegrees
    ) -> (latitudeDegrees: CLLocationDegrees, longitudeDegrees: CLLocationDegrees) {
        degrees(fromMeters: meters, atLatitude: latitude)
    }

    /// Converts a distance in meters to degrees at a given latitude.
    ///
    /// - Parameter meters: The distance in meters
    /// - Parameter latitude: The latitude at which to calculate the conversion
    ///
    /// - Returns: A tuple of latitude degrees and longitude degrees.
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

    /// Converts a distance in degrees to meters at a given latitude.
    ///
    /// - Parameter latitudeDegrees: The latitude distance in degrees.
    /// - Parameter longitudeDegrees: The longitude distance in degrees.
    /// - Parameter latitude: The latitude at which to calculate the conversion.
    ///
    /// - Returns: A tuple of latitude meters and longitude meters.
    public static func meters(
        fromDegrees latitudeDegrees: CLLocationDegrees,
        longitudeDegrees: CLLocationDegrees,
        atLatitude latitude: CLLocationDegrees
    ) -> (latitudeMeters: CLLocationDistance, longitudeMeters: CLLocationDistance) {
        let oneDegreeLatitudeDistance: CLLocationDistance = GISTool.earthCircumference / 360.0
        let oneDegreeLongitudeDistance: CLLocationDistance = cos(latitude * Double.pi / 180.0) * oneDegreeLatitudeDistance

        let latitudeMeters = latitudeDegrees * oneDegreeLatitudeDistance
        let longitudeMeters = longitudeDegrees * oneDegreeLongitudeDistance

        return (latitudeMeters, longitudeMeters)
    }

}

extension Coordinate3D {

    /// Converts a distance in meters to degrees at the receiver's latitude.
    ///
    /// - Parameter meters: The distance in meters
    ///
    /// - Returns: A tuple of latitude degrees and longitude degrees.
    public func degrees(
        fromMeters meters: CLLocationDistance
    ) -> (latitudeDegrees: CLLocationDegrees, longitudeDegrees: CLLocationDegrees) {
        GISTool.degrees(fromMeters: meters, atLatitude: latitude)
    }

    /// Converts a distance in degrees to meters at the receiver's latitude.
    ///
    /// - Parameter latitudeDegrees: The latitude distance in degrees.
    /// - Parameter longitudeDegrees: The longitude distance in degrees.
    ///
    /// - Returns: A tuple of latitude meters and longitude meters.
    public func meters(
        fromDegrees latitudeDegrees: CLLocationDegrees,
        longitudeDegrees: CLLocationDegrees
    ) -> (latitudeMeters: CLLocationDistance, longitudeMeters: CLLocationDistance) {
        GISTool.meters(fromDegrees: latitudeDegrees, longitudeDegrees: longitudeDegrees, atLatitude: latitude)
    }

}
