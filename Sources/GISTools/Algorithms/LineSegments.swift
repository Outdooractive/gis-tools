#if !os(Linux)
import CoreLocation
#endif
import Foundation

extension BoundingBox {

    /// Returns the receiver as *LineSegment*s.
    public var lineSegments: [LineSegment] {
        [
            LineSegment(first: northWest, second: northEast),
            LineSegment(first: northEast, second: southEast),
            LineSegment(first: southEast, second: southWest),
            LineSegment(first: southWest, second: northWest),
        ]
    }

}

extension GeoJson {

    /// Returns line segments for the geometry.
    ///
    /// For Point, MultiPoint: returns an empty array.
    ///
    /// For LineString, MultiLineString: returns overlapping coordinate pairs.
    ///
    /// For Polygon, MultiPolygon: returns overlapping pairs for all rings.
    ///
    /// Everything else: returns the contained geometries' coordinate pairs.
    public var lineSegments: [LineSegment] {
        switch self {
        case is MultiPoint, is Point:
            return []

        case let lineString as LineString:
            return lineString.coordinates.overlappingPairs().compactMap { (first, second) in
                guard let second else { return nil }
                return LineSegment(first: first, second: second)
            }

        case let multiLineString as MultiLineString:
            return multiLineString.lineStrings.flatMap { $0.lineSegments }

        case let polygon as Polygon:
            return polygon.rings.flatMap({ (ring) in
                ring.coordinates.overlappingPairs().compactMap { (first, second) in
                    guard let second else { return nil }
                    return LineSegment(first: first, second: second)
                }
            })

        case let multiPolygon as MultiPolygon:
            return multiPolygon.polygons.flatMap { $0.lineSegments }

        case let geometryCollection as GeometryCollection:
            return geometryCollection.geometries.flatMap { $0.lineSegments }

        case let feature as Feature:
            return feature.geometry.lineSegments

        case let featureCollection as FeatureCollection:
            return featureCollection.features.flatMap { $0.lineSegments }

        default:
            return []
        }
    }

}
