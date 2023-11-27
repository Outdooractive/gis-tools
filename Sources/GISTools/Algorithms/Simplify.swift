#if !os(Linux)
import CoreLocation
#endif
import Foundation

// Ported from https://github.com/Turfjs/turf/blob/master/packages/turf-simplify
// and https://github.com/Turfjs/turf/blob/master/packages/turf-simplify/lib/simplify.js

extension GeoJson {

    /// Returns a simplified GeoJson.
    ///
    /// **Important**: This method expects tolerance in meters. Use the *Simplify* struct directly if your GeoJSON is not in WGS84.
    ///
    /// - Parameters:
    ///    - tolerance: Affects the amount of simplification (in meters)
    ///    - highQuality: Excludes distance-based preprocessing step which leads to highest quality simplification but runs ~10-20 times slower
    ///
    /// - Returns: A new simplified GeoJson
    public func simplified(
        tolerance: CLLocationDistance = 1.0,
        highQuality: Bool = false)
        -> Self
    {
        switch self {
        case let lineString as LineString:
            var newLineString = LineString(Simplify.simplify(coordinates: lineString.coordinates, toleranceInMeters: tolerance, highQuality: highQuality)) ?? lineString
            newLineString.boundingBox = lineString.boundingBox
            newLineString.foreignMembers = lineString.foreignMembers
            return newLineString as! Self

        case let multiLineString as MultiLineString:
            var newMultiLineString = MultiLineString(multiLineString.lineStrings.map({
                $0.simplified(tolerance: tolerance, highQuality: highQuality)
            })) ?? multiLineString
            newMultiLineString.boundingBox = multiLineString.boundingBox
            newMultiLineString.foreignMembers = multiLineString.foreignMembers
            return newMultiLineString as! Self

        case let polygon as Polygon:
            var newPolygon = Polygon(polygon.rings.map({
                $0.simplified(tolerance: tolerance, highQuality: highQuality)
            })) ?? polygon
            newPolygon.boundingBox = polygon.boundingBox
            newPolygon.foreignMembers = polygon.foreignMembers
            return newPolygon as! Self

        case let multiPolygon as MultiPolygon:
            var newMultiPolygon = MultiPolygon(multiPolygon.polygons.map({
                $0.simplified(tolerance: tolerance, highQuality: highQuality)
            })) ?? multiPolygon
            newMultiPolygon.boundingBox = multiPolygon.boundingBox
            newMultiPolygon.foreignMembers = multiPolygon.foreignMembers
            return newMultiPolygon as! Self

        case let geometryCollection as GeometryCollection:
            var newGeometryCollection = GeometryCollection(geometryCollection.geometries.map({
                $0.simplified(tolerance: tolerance, highQuality: highQuality)
            }))
            newGeometryCollection.boundingBox = geometryCollection.boundingBox
            newGeometryCollection.foreignMembers = geometryCollection.foreignMembers
            return newGeometryCollection as! Self

        case let feature as Feature:
            var newFeature = Feature(feature.geometry.simplified(tolerance: tolerance, highQuality: highQuality), id: feature.id, properties: feature.properties)
            newFeature.boundingBox = feature.boundingBox
            newFeature.foreignMembers = feature.foreignMembers
            return newFeature as! Self

        case let featureCollection as FeatureCollection:
            var newFeatureCollection = FeatureCollection(featureCollection.features.map({
                $0.simplified(tolerance: tolerance, highQuality: highQuality)
            }))
            newFeatureCollection.boundingBox = featureCollection.boundingBox
            newFeatureCollection.foreignMembers = featureCollection.foreignMembers
            return newFeatureCollection as! Self

        default:
            return self
        }
    }

    /// Simplifies the GeoJson.
    ///
    /// **Important**: This method expects tolerance in meters. Use the *Simplify* struct directly if your GeoJSON is not in WGS84.
    ///
    /// - Parameters:
    ///    - tolerance: Affects the amount of simplification (in meters)
    ///    - highQuality: Excludes distance-based preprocessing step which leads to highest quality simplification but runs ~10-20 times slower
    ///
    /// - returns: A new simplified GeoJson
    public mutating func simplify(
        tolerance: CLLocationDistance = 1.0,
        highQuality: Bool = false)
    {
        self = simplified(
            tolerance: tolerance,
            highQuality: highQuality)
    }

}

extension Ring {

    fileprivate func simplified(
        tolerance: CLLocationDistance = 1.0,
        highQuality: Bool = false)
        -> Ring
    {
        guard coordinates.count > 3,
              tolerance > 0.0
        else { return self }

        var simplificationtolerance = tolerance
        var simplifiedCoordinates = Simplify.simplify(coordinates: coordinates, toleranceInMeters: simplificationtolerance, highQuality: highQuality)

        // if this is not a valid polygon ring anymore: reduce the tolerance until we have at least a triangle
        while !Ring.validCoordinates(simplifiedCoordinates) {
            // Prevent an endless loop
            guard simplificationtolerance >= (tolerance / 2.0) else { return self }

            simplificationtolerance *= 0.9
            simplifiedCoordinates = Simplify.simplify(coordinates: coordinates, toleranceInMeters: simplificationtolerance, highQuality: highQuality)
        }

        if let first = simplifiedCoordinates.first,
           let last = simplifiedCoordinates.last,
           first != last
        {
            simplifiedCoordinates.append(first)
        }

        return Ring(simplifiedCoordinates) ?? self
    }

    fileprivate static func validCoordinates(_ coordinates: [Coordinate3D]) -> Bool {
        guard coordinates.count >= 3 else { return false }

        if coordinates.count == 3,
           coordinates[0] == coordinates[2]
        {
            return false
        }

        return true
    }

}

// MARK: - Simplify

/// Static methods for simplifiying geometries.
public enum Simplify {

    /// Returns an array of simplified coordinates.
    ///
    /// - Parameters:
    ///    - coordinates: An array of Coordinate3D
    ///    - tolerance: Affects the amount of simplification (in units of the coordinates coordinate system)
    ///    - highQuality: Skip the distance-based preprocessing step which leads to highest quality simplification but runs quite a bit times slower
    ///
    /// - Returns: Returns an array of simplified coordinates
    public static func simplify(
        coordinates: [Coordinate3D],
        tolerance: CLLocationDegrees,
        highQuality: Bool = false)
        -> [Coordinate3D]
    {
        guard coordinates.count > 2 else { return coordinates }

        let sqTolerance: Double = tolerance * tolerance

        if highQuality {
            return simplifyDouglasPeucker(
                coordinates: coordinates,
                tolerance: sqTolerance)
        }
        else {
            return simplifyDouglasPeucker(
                coordinates: simplifyRadialDistance(coordinates: coordinates, tolerance: sqTolerance),
                tolerance: sqTolerance)
        }
    }

    fileprivate static func simplify(
        coordinates: [Coordinate3D],
        toleranceInMeters: CLLocationDistance = 1.0,
        highQuality: Bool = false)
        -> [Coordinate3D]
    {
        guard coordinates.count > 2,
              let firstCoordinate = coordinates.first
        else { return coordinates }

        switch firstCoordinate.projection {
        case .epsg3857, .noSRID:
            return simplify(
                coordinates: coordinates,
                tolerance: toleranceInMeters,
                highQuality: highQuality)

        case .epsg4326:
            let oneDegreeLongitudeDistanceInMeters: CLLocationDistance = (cos(firstCoordinate.longitude * .pi / 180.0) * 111.0) * 1000.0
            let toleranceInDegrees: CLLocationDegrees = toleranceInMeters / oneDegreeLongitudeDistanceInMeters

            return simplify(
                coordinates: coordinates,
                tolerance: toleranceInDegrees,
                highQuality: highQuality)
        }
    }

    // simplification using Ramer-Douglas-Peucker algorithm
    private static func simplifyDouglasPeucker(
        coordinates: [Coordinate3D],
        tolerance: Double)
        -> [Coordinate3D]
    {
        guard coordinates.count > 2 else { return coordinates }

        let last: Int = coordinates.count - 1
        var simplified: [Coordinate3D] = [coordinates[0]]

        simplifyDPStep(
            coordinates: coordinates,
            first: 0,
            last: last,
            tolerance: tolerance,
            simplified: &simplified)

        simplified.append(coordinates[last])

        return simplified
    }

    private static func simplifyRadialDistance(
        coordinates: [Coordinate3D],
        tolerance: Double)
        -> [Coordinate3D]
    {
        guard var previousCoordinate = coordinates.first else { return coordinates }

        var newCoordinates: [Coordinate3D] = [previousCoordinate]
        var coordinate: Coordinate3D = coordinates[0]

        for index in 1 ..< coordinates.count {
            coordinate = coordinates[index]

            let distance = getSqDist(p1: coordinate, p2: previousCoordinate)
            if distance > tolerance {
                newCoordinates.append(coordinate)
                previousCoordinate = coordinate
            }
        }

        if previousCoordinate != coordinate {
            newCoordinates.append(coordinate)
        }

        return newCoordinates
    }

    private static func simplifyDPStep(
        coordinates: [Coordinate3D],
        first: Int,
        last: Int,
        tolerance: Double,
        simplified: inout [Coordinate3D])
    {
        guard last - first > 1 else { return }

        var maxSqDistance: Double = tolerance
        var index: Int = 0

        for i in (first + 1) ..< last {
            let sqDist = getSQSegDist(
                p: coordinates[i],
                p1: coordinates[first],
                p2: coordinates[last])

            if sqDist > maxSqDistance {
                index = i
                maxSqDistance = sqDist
            }
        }

        if maxSqDistance > tolerance {
            if index - first > 1 {
                simplifyDPStep(
                    coordinates: coordinates,
                    first: first,
                    last: index,
                    tolerance: tolerance,
                    simplified: &simplified)
            }

            simplified.append(coordinates[index])

            if last - index > 1 {
                simplifyDPStep(
                    coordinates: coordinates,
                    first: index,
                    last: last,
                    tolerance: tolerance,
                    simplified: &simplified)
            }
        }
    }

    // square distance from a point to a segment
    private static func getSQSegDist(
        p: Coordinate3D,
        p1: Coordinate3D,
        p2: Coordinate3D)
        -> Double
    {
        var longitude: CLLocationDegrees = p1.longitude
        var latitude: CLLocationDegrees = p1.latitude
        var dLongitude: CLLocationDegrees = p2.longitude - longitude
        var dLatitude: CLLocationDegrees = p2.latitude - latitude

        if dLongitude != 0.0 || dLatitude != 0.0 {
            let t = ((p.longitude - longitude) * dLongitude + (p.latitude - latitude) * dLatitude) / ((dLongitude * dLongitude) + (dLatitude * dLatitude))
            if t > 1 {
                longitude = p2.longitude
                latitude = p2.latitude
            }
            else if t > 0 {
                longitude += dLongitude * t
                latitude += dLatitude * t
            }
        }

        dLongitude = p.longitude - longitude
        dLatitude = p.latitude - latitude

        return (dLongitude * dLongitude) + (dLatitude * dLatitude)
    }

    // square distance between 2 points
    private static func getSqDist(
        p1: Coordinate3D,
        p2: Coordinate3D)
        -> Double
    {
        let dx = p1.longitude - p2.longitude
        let dy = p1.latitude - p2.latitude
        return (dx * dx) + (dy * dy)
    }

}
