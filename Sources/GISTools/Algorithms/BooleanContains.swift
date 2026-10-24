#if canImport(CoreLocation)
import CoreLocation
#endif
import Foundation

// Ported from https://github.com/Turfjs/turf/blob/master/packages/turf-boolean-contains

extension GeoJson {

    /// Compares two geometries and returns true if the receiver contains the
    /// other geometry.
    ///
    /// "A contains B" means that no points of B lie in the exterior of A, and
    /// at least one point of B lies in the interior of A. This matches OGC
    /// `ST_Contains`; use `covers(_:)` to include boundary points.
    ///
    /// The other geometry is projected to the receiver's projection. Antimeridian-
    /// crossing geometries are cut at ±180° before the check. Altitude
    /// differences are ignored.
    ///
    /// - Parameter other: The other geometry
    /// - Returns: `true` if the receiver contains the other geometry
    ///
    /// - Note: A `FeatureCollection` is evaluated member-wise: the receiver must
    ///   contain/cover every feature on the other side. A FeatureCollection
    ///   receiver uses one of its features for the whole other geometry.
    /// - Note: A `GeometryCollection` contains `other` when each part of
    ///   `other` is covered by one of its members and the interiors of at
    ///   least one pair intersect (member-wise, not union-wise).
    public func contains(_ other: GeoJson) -> Bool {
        if let fc1 = self as? FeatureCollection {
            if let union = BooleanCovers.polygonUnion(of: fc1) {
                return union.contains(other)
            }
            return fc1.features.contains { $0.contains(other) }
        }
        if let fc2 = other as? FeatureCollection {
            return fc2.features.allSatisfy { self.contains($0) }
        }

        let geom1: GeoJson = (self as? Feature)?.geometry ?? self
        let geom2: GeoJson = (other as? Feature)?.geometry ?? other

        let normalised1 = geom1
        let normalised2 = geom2.projected(to: normalised1.projection)

        guard let geometry1 = normalised1 as? GeoJsonGeometry,
              let geometry2 = normalised2 as? GeoJsonGeometry
        else { return false }

        // A polygonal receiver is one union, not a set of independent
        // containers: a geometry may span two adjacent polygons.
        let containerParts: [GeoJsonGeometry] =
            geometry1 is PolygonGeometry
            ? [geometry1]
            : BooleanCovers.parts(of: geometry1)
        let otherParts = BooleanCovers.parts(of: geometry2)

        return BooleanContains.contains(containerParts, otherParts)
    }

    /// Compares two geometries and returns true if the receiver is within the
    /// other geometry.
    ///
    /// "A is within B" means that no points of A lie in the exterior of B, and
    /// at least one point of A lies in the interior of B. This is the converse
    /// of `contains(_:)` (OGC `ST_Within`).
    ///
    /// - Parameter other: The other geometry
    /// - Returns: `true` if the receiver is within the other geometry
    public func isWithin(_ other: GeoJson) -> Bool {
        other.contains(self)
    }

}

// MARK: - BooleanContains namespace

enum BooleanContains {

    /// OGC `ST_Contains`: the containers cover `other` and their interiors
    /// intersect. Antimeridian cutting can produce multiple parts on either
    /// side.
    static func contains(
        _ containers: [GeoJsonGeometry],
        _ others: [GeoJsonGeometry]
    ) -> Bool {
        guard BooleanCovers.covers(containers, others) else { return false }

        for container in containers {
            for other in others where BooleanCovers.covers(container, other) {
                if interiorsIntersect(container, other) {
                    return true
                }
            }
        }

        return false
    }

}

// MARK: - Interior intersection

extension BooleanContains {

    private static func interiorsIntersect(
        _ container: GeoJsonGeometry,
        _ other: GeoJsonGeometry
    ) -> Bool {
        switch other {
        case let point as Point:
            return BooleanCovers.location(of: point.coordinate, in: container) == .interior

        case let multiPoint as MultiPoint:
            return multiPoint.points.contains {
                BooleanCovers.location(of: $0.coordinate, in: container) == .interior
            }

        case let lineString as LineString:
            return lineInteriorsIntersect([lineString], container)

        case let multiLineString as MultiLineString:
            return lineInteriorsIntersect(multiLineString.lineStrings, container)

        case let polygon as Polygon:
            return arealInteriorsIntersect([polygon], container)

        case let multiPolygon as MultiPolygon:
            return arealInteriorsIntersect(multiPolygon.polygons, container)

        case let geometryCollection as GeometryCollection:
            return geometryCollection.geometries.contains {
                interiorsIntersect(container, $0)
            }

        default:
            return false
        }
    }

    /// A line's interior intersects the container when an interior sample
    /// point of the line lies in the container's interior. Segments are split
    /// at container boundaries so that chords and crossings are detected.
    private static func lineInteriorsIntersect(
        _ lineStrings: [LineString],
        _ container: GeoJsonGeometry
    ) -> Bool {
        let barriers = container.lineSegments

        for lineString in lineStrings {
            let coordinates = lineString.coordinates
            let isClosed = coordinates.count > 1
                && coordinates[0].isCoincident(to: coordinates[coordinates.count - 1])

            for (index, coordinate) in coordinates.enumerated() {
                let isBoundaryVertex = !isClosed
                    && (index == 0 || index == coordinates.count - 1)
                guard !isBoundaryVertex else { continue }

                if BooleanCovers.location(of: coordinate, in: container) == .interior {
                    return true
                }
            }

            for segment in lineString.lineSegments {
                let parameters = BooleanCovers.splitParameters(
                    of: segment,
                    against: barriers)

                for index in 1 ..< parameters.count {
                    let lower = parameters[index - 1]
                    let upper = parameters[index]
                    guard (upper - lower) > GISTool.intersectionEpsilon else { continue }

                    let middle = BooleanCovers.point(
                        on: segment,
                        at: (lower + upper) / 2.0)
                    if BooleanCovers.location(of: middle, in: container) == .interior {
                        return true
                    }
                }

                // A single crossing point can be the only common interior
                // point of two lines.
                for parameter in parameters where parameter > 0.0 && parameter < 1.0 {
                    let crossing = BooleanCovers.point(on: segment, at: parameter)
                    if BooleanCovers.location(of: crossing, in: container) == .interior {
                        return true
                    }
                }
            }
        }

        return false
    }

    /// For valid areal geometries, coverage implies that their interiors
    /// intersect: a polygon with positive area cannot lie entirely on another
    /// geometry's boundary.
    private static func arealInteriorsIntersect(
        _ polygons: [Polygon],
        _ container: GeoJsonGeometry
    ) -> Bool {
        guard container is PolygonGeometry else { return false }

        return polygons.contains { $0.area > 0.0 }
    }

}

// MARK: - ContainsProperly

extension GeoJson {

    /// Returns `true` if the receiver contains `other` strictly in its interior.
    ///
    /// This is OGC `ST_ContainsProperly`: `other` must be covered by the
    /// receiver and may not touch the receiver's boundary.
    ///
    /// - Parameter other: The geometry to test
    /// - Returns: `true` if `other` is contained in the receiver's interior
    public func containsProperly(_ other: GeoJson) -> Bool {
        if let first = self as? PolygonGeometry,
           let second = other as? PolygonGeometry
        {
            guard let intersectionArea = PolygonPredicateHelpers.intersectionArea(first, second),
                  AreaComparison.areEqual(intersectionArea, PolygonPredicateHelpers.area(second))
            else { return false }
            guard let boundary = topologicalBoundary else { return true }

            return !boundary.intersects(other)
        }

        guard contains(other) else { return false }
        guard let boundary = topologicalBoundary else { return true }

        return !boundary.intersects(other)
    }

    /// The topological boundary used by ``containsProperly(_:)``.
    ///
    /// Polygon boundaries include all rings, unlike ``Polygon/boundary`` which
    /// exposes only the outer ring.
    private var topologicalBoundary: GeoJsonGeometry? {
        switch self {
        case let point as Point:
            return point.boundary

        case let multiPoint as MultiPoint:
            return multiPoint.boundary

        case let lineString as LineString:
            return lineString.boundary

        case let multiLineString as MultiLineString:
            return multiLineString.boundary

        case let polygon as Polygon:
            let lines = polygon.rings.map(\.lineString)
            return lines.isEmpty ? nil : MultiLineString(unchecked: lines)

        case let multiPolygon as MultiPolygon:
            let lines = multiPolygon.polygons.flatMap { polygon in
                polygon.rings.map(\.lineString)
            }
            return lines.isEmpty ? nil : MultiLineString(unchecked: lines)

        case let geometryCollection as GeometryCollection:
            let boundaries = geometryCollection.geometries.compactMap {
                $0.topologicalBoundary
            }
            return boundaries.isEmpty ? nil : GeometryCollection(boundaries)

        case let feature as Feature:
            return feature.geometry?.topologicalBoundary

        case let featureCollection as FeatureCollection:
            let boundaries = featureCollection.features.compactMap {
                $0.geometry?.topologicalBoundary
            }
            return boundaries.isEmpty ? nil : GeometryCollection(boundaries)

        default:
            return nil
        }
    }

}
