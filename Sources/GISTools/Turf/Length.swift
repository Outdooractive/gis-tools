#if !os(Linux)
import CoreLocation
#endif
import Foundation

// Ported from https://github.com/Turfjs/turf/tree/master/packages/turf-length

extension LineSegment {

    /// Returns the length of the *LineSegment*, in meters.
    public var length: CLLocationDistance {
        first.distance(from: second)
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

}
