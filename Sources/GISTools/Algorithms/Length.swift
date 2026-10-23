#if canImport(CoreLocation)
import CoreLocation
#endif
import Foundation

// Ported from https://github.com/Turfjs/turf/tree/master/packages/turf-length

extension LineSegment {

    /// Returns the length of the *LineSegment*, in meters.
    public var length: CLLocationDistance {
        first.distance(from: second)
    }

    /// Returns the segment's length converted to the requested unit.
    ///
    /// - Parameter unit: The target length unit
    /// - Returns: The converted length, or `nil` if `unit` is not a length unit
    public func length(in unit: GISTool.Unit) -> Double? {
        DistanceUnitConverter.fromMeters(
            length,
            projection: first.projection,
            unit: unit)
    }

}

extension GeoJson {

    /// Returns the receiver's length, in meters.
    ///
    /// For *Point*, *MultiPoint*: returns 0
    ///
    /// For *LineString*, *MultiLineString*: returns the length of the line(s)
    ///
    /// For *Polygon*, *MultiPolygon*: returns the length of all rings
    ///
    /// Everything else: returns the length of the contained geometries
    public var length: CLLocationDistance {
        lineSegments.reduce(0.0) { $0 + $1.length }
    }

    /// Returns the receiver's length converted to the requested unit.
    ///
    /// - Parameter unit: The target length unit
    /// - Returns: The converted length, or `nil` if `unit` is not a length unit
    public func length(in unit: GISTool.Unit) -> Double? {
        DistanceUnitConverter.fromMeters(
            length,
            projection: projection,
            unit: unit)
    }

}
