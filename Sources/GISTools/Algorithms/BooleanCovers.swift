import Foundation

// Ported from GEOS Covers / CoveredBy

extension GeoJson {

    /// Compares two geometries and returns `true` if the receiver covers the
    /// other geometry.
    ///
    /// "A covers B" means that no point of B lies in the exterior of A. Unlike
    /// ``contains(_:)``, points on the boundary of A are covered. This matches
    /// OGC `ST_Covers`.
    ///
    /// The other geometry is projected to the receiver's projection. Antimeridian-
    /// crossing geometries are cut at ±180° before the check. Altitude
    /// differences are ignored.
    ///
    /// - Parameter other: The other geometry
    /// - Returns: `true` if the receiver covers the other geometry
    ///
    /// - Note: A `FeatureCollection` is evaluated member-wise: the receiver must
    ///   contain/cover every feature on the other side. A FeatureCollection
    ///   receiver uses one of its features for the whole other geometry.
    /// - Note: A `GeometryCollection` covers `other` when each part of
    ///   `other` is covered by one of its members (member-wise, not union-wise).
    public func covers(_ other: GeoJson) -> Bool {
        if let fc1 = self as? FeatureCollection {
            if let union = BooleanCovers.polygonUnion(of: fc1) {
                return union.covers(other)
            }
            return fc1.features.contains { $0.covers(other) }
        }
        if let fc2 = other as? FeatureCollection {
            return fc2.features.allSatisfy { self.covers($0) }
        }

        let geom1: GeoJson = (self as? Feature)?.geometry ?? self
        let geom2: GeoJson = (other as? Feature)?.geometry ?? other

        // Work in the receiver's projection and project the other geometry into
        // it. Projecting everything to EPSG:4326 would collapse ECEF
        // geometries near the origin and lose precision for projected CRSs.
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

        return BooleanCovers.covers(containerParts, otherParts)
    }

    /// Compares two geometries and returns `true` if the receiver is covered by
    /// the other geometry.
    ///
    /// "A is covered by B" means that no points of A lie in the exterior of B.
    /// Unlike ``isWithin(_:)``, points on the boundary are considered covered.
    ///
    /// The other geometry is projected to the receiver's projection. Antimeridian-
    /// crossing geometries are cut at ±180° before the check. Altitude
    /// differences are ignored.
    ///
    /// - Parameter other: The other geometry
    /// - Returns: `true` if the receiver is covered by the other geometry
    public func coveredBy(_ other: GeoJson) -> Bool {
        other.covers(self)
    }

}

// MARK: - Coverage container

/// A geometry paired with the indexes used by coverage checks.
struct CoverageContainer {

    let geometry: GeoJsonGeometry
    let pointIndex: PreparedPolygon.PointIndex?
    let barriers: SegmentIndex

    init(geometry: GeoJsonGeometry) {
        self.geometry = geometry

        if let polygon = geometry as? Polygon {
            let prepared = PreparedPolygon(polygon)

            // Geocentric inputs are prepared in EPSG:4326. Keep the original
            // geometry and its segments when the prepared projection differs,
            // so coordinate and barrier frames stay consistent.
            if prepared.projection == polygon.projection,
               let part = prepared.coverageContainers.first
            {
                self.pointIndex = part.pointIndex
                self.barriers = part.barriers
                return
            }
        }

        self.pointIndex = nil
        self.barriers = SegmentIndex(geometry.lineSegments)
    }

    init(
        geometry: GeoJsonGeometry,
        pointIndex: PreparedPolygon.PointIndex,
        barriers: SegmentIndex
    ) {
        self.geometry = geometry
        self.pointIndex = pointIndex
        self.barriers = barriers
    }

    func location(of coordinate: Coordinate3D) -> PointLocation {
        if let pointIndex {
            return pointIndex.locate(coordinate)
        }
        return BooleanCovers.location(of: coordinate, in: geometry)
    }

    func splitParameters(of segment: LineSegment) -> [Double] {
        BooleanCovers.splitParameters(
            of: segment,
            against: barriers.candidates(for: segment))
    }

}

// MARK: - BooleanCovers namespace

enum BooleanCovers {

    /// Union of a collection's polygonal features, used to make a
    /// FeatureCollection receiver behave as the union of its members rather
    /// than member-wise.
    static func polygonUnion(of collection: FeatureCollection) -> MultiPolygon? {
        var polygons: [Polygon] = []
        for feature in collection.features {
            guard let geometry = feature.geometry as? PolygonGeometry else { return nil }
            polygons.append(contentsOf: geometry.polygons)
        }
        guard polygons.isNotEmpty else { return nil }
        return MultiPolygon(unchecked: polygons)
    }

    /// Returns `true` if every part of `others` is covered by at least one
    /// container part. Antimeridian cutting can produce multiple parts on
    /// either side.
    static func covers(
        _ containers: [GeoJsonGeometry],
        _ others: [GeoJsonGeometry]
    ) -> Bool {
        let preparedContainers = containers.map { CoverageContainer(geometry: $0) }

        return others.allSatisfy { other in
            preparedContainers.contains { covers($0, other) }
        }
    }

    /// Splits a geometry at the antimeridian. Non-wrapping projections and
    /// non-crossing geometries are returned unchanged.
    static func parts(of geometry: GeoJsonGeometry) -> [GeoJsonGeometry] {
        switch geometry {
        case let polygon as Polygon:
            return polygon.cutAtAntimeridian().features.compactMap(\.geometry)

        case let multiPolygon as MultiPolygon:
            return multiPolygon.polygons.flatMap { parts(of: $0) }

        case let lineString as LineString:
            return lineString.cutAtAntimeridian().features.compactMap(\.geometry)

        case let multiLineString as MultiLineString:
            return multiLineString.lineStrings.flatMap { parts(of: $0) }

        case let multiPoint as MultiPoint:
            return multiPoint.points.map { $0 }

        case let geometryCollection as GeometryCollection:
            return geometryCollection.geometries.flatMap { parts(of: $0) }

        default:
            return [geometry]
        }
    }

    /// Returns `true` if no point of `other` lies in the exterior of `container`.
    static func covers(
        _ container: GeoJsonGeometry,
        _ other: GeoJsonGeometry
    ) -> Bool {
        covers(CoverageContainer(geometry: container), other)
    }

    static func covers(
        _ container: CoverageContainer,
        _ other: GeoJsonGeometry
    ) -> Bool {
        if let bbox1 = container.geometry.boundingBox,
           let bbox2 = other.boundingBox,
           !bbox1.contains(bbox2)
        {
            return false
        }

        switch other {
        case let point as Point:
            return container.location(of: point.coordinate) != .exterior

        case let multiPoint as MultiPoint:
            return multiPoint.points.allSatisfy {
                container.location(of: $0.coordinate) != .exterior
            }

        case let lineString as LineString:
            return lineStringsCovered([lineString], by: container)

        case let multiLineString as MultiLineString:
            return lineStringsCovered(multiLineString.lineStrings, by: container)

        case let polygon as Polygon:
            return polygonsCovered([polygon], by: container)

        case let multiPolygon as MultiPolygon:
            return polygonsCovered(multiPolygon.polygons, by: container)

        case let geometryCollection as GeometryCollection:
            return geometryCollection.geometries.allSatisfy { covers(container, $0) }

        default:
            return false
        }
    }

    /// Coverage against a prepared polygonal geometry.
    static func covers(
        _ prepared: PreparedPolygon,
        _ other: PolygonGeometry
    ) -> Bool {
        let projected = other.projected(to: prepared.projection)
        let otherParts = parts(of: projected)
        let containers = prepared.coverageContainers

        return otherParts.allSatisfy { otherPart in
            containers.contains { covers($0, otherPart) }
        }
    }

}

// MARK: - Point location

extension BooleanCovers {

    /// Determines where `coordinate` lies relative to `geometry`, following
    /// OGC/GEOS point-location rules (including line endpoints and the mod-2
    /// boundary rule for MultiLineStrings).
    static func location(
        of coordinate: Coordinate3D,
        in geometry: GeoJsonGeometry
    ) -> PointLocation {
        switch geometry {
        case let point as Point:
            return point.coordinate.isCoincident(to: coordinate) ? .interior : .exterior

        case let multiPoint as MultiPoint:
            return multiPoint.points.contains {
                $0.coordinate.isCoincident(to: coordinate)
            } ? .interior : .exterior

        case let lineString as LineString:
            return location(of: coordinate, in: lineString)

        case let multiLineString as MultiLineString:
            return location(of: coordinate, in: multiLineString)

        case let polygonGeometry as PolygonGeometry:
            return polygonGeometry.locate(coordinate, gridSize: nil)

        case let geometryCollection as GeometryCollection:
            var isOnBoundary = false
            for member in geometryCollection.geometries {
                switch location(of: coordinate, in: member) {
                case .interior:
                    return .interior

                case .boundary:
                    isOnBoundary = true

                case .exterior:
                    continue
                }
            }
            return isOnBoundary ? .boundary : .exterior

        default:
            return .exterior
        }
    }

    /// Location in a LineString. Endpoints are boundary for open lines; a
    /// closed line has an empty boundary.
    private static func location(
        of coordinate: Coordinate3D,
        in lineString: LineString
    ) -> PointLocation {
        guard lineString.checkIsOnLine(coordinate) else { return .exterior }

        let coordinates = lineString.coordinates
        guard let first = coordinates.first,
              let last = coordinates.last
        else { return .exterior }

        if first.isCoincident(to: last) {
            return .interior
        }
        if coordinate.isCoincident(to: first) || coordinate.isCoincident(to: last) {
            return .boundary
        }
        return .interior
    }

    /// Location in a MultiLineString using the OGC mod-2 boundary rule: a
    /// coordinate is boundary when it is an endpoint of an odd number of
    /// component lines (closed components have no boundary).
    private static func location(
        of coordinate: Coordinate3D,
        in multiLineString: MultiLineString
    ) -> PointLocation {
        guard multiLineString.lineStrings.contains(where: { $0.checkIsOnLine(coordinate) }) else {
            return .exterior
        }

        var endpointCount = 0
        for lineString in multiLineString.lineStrings {
            let coordinates = lineString.coordinates
            guard let first = coordinates.first,
                  let last = coordinates.last,
                  !first.isCoincident(to: last)
            else { continue }

            if first.isCoincident(to: coordinate) {
                endpointCount += 1
            }
            if last.isCoincident(to: coordinate) {
                endpointCount += 1
            }
        }

        return (endpointCount % 2) == 1 ? .boundary : .interior
    }

}

// MARK: - Linear coverage

extension BooleanCovers {

    private static func lineStringsCovered(
        _ lineStrings: [LineString],
        by container: CoverageContainer
    ) -> Bool {
        lineStrings.allSatisfy { lineString in
            lineString.lineSegments.allSatisfy {
                segmentCovered($0, container: container)
            }
        }
    }

    /// A segment is covered when both endpoints are covered and every
    /// sub-segment between intersections with the container's boundaries has
    /// its midpoint inside or on the container.
    private static func segmentCovered(
        _ segment: LineSegment,
        container: CoverageContainer
    ) -> Bool {
        guard container.location(of: segment.first) != .exterior,
              container.location(of: segment.second) != .exterior
        else { return false }

        let parameters = container.splitParameters(of: segment)

        for index in 1 ..< parameters.count {
            let lower = parameters[index - 1]
            let upper = parameters[index]
            guard (upper - lower) > GISTool.intersectionEpsilon else { continue }

            let middle = point(on: segment, at: (lower + upper) / 2.0)
            if container.location(of: middle) == .exterior {
                return false
            }
        }

        return true
    }

}

// MARK: - Areal coverage

extension BooleanCovers {

    private static func polygonsCovered(
        _ polygons: [Polygon],
        by container: CoverageContainer
    ) -> Bool {
        polygons.allSatisfy { polygon in
            let preparedPolygon = PreparedPolygon(polygon)

            // The whole boundary must be covered.
            guard polygon.rings.allSatisfy({ ring in
                ring.lineSegments.allSatisfy {
                    segmentCovered($0, container: container)
                }
            })
            else { return false }

            // The interior must be covered as well.
            guard let interior = interiorPoint(of: polygon),
                  container.location(of: interior) != .exterior
            else { return false }

            // A hole or a gap between container components must not fall
            // inside the polygon, otherwise the polygon's interior contains
            // points in the container's exterior.
            if let polygonal = container.geometry as? PolygonGeometry {
                for coordinate in polygonal.allCoordinates
                    where preparedPolygon.contains(coordinate)
                {
                    return false
                }
            }

            return true
        }
    }

    /// Returns a coordinate guaranteed to be in the polygon's interior.
    private static func interiorPoint(of polygon: Polygon) -> Coordinate3D? {
        if let centroid = polygon.centroid?.coordinate,
           polygon.locate(centroid) == .interior
        {
            return centroid
        }
        return polygon.poleOfInaccessibility()?.coordinate
    }

}

// MARK: - Segment splitting

extension BooleanCovers {

    /// Parameters along `segment` at which it meets any of the `barriers`,
    /// including 0 and 1. Collinear overlaps add the barrier endpoints.
    static func splitParameters(
        of segment: LineSegment,
        against barriers: [LineSegment]
    ) -> [Double] {
        var parameters: [Double] = [0.0, 1.0]

        for barrier in barriers {
            if let intersection = segment.intersection(barrier, epsilon: GISTool.intersectionEpsilon),
               let parameter = parameter(of: intersection, on: segment)
            {
                parameters.append(parameter)
            }

            guard segment.intersects(barrier, epsilon: GISTool.intersectionEpsilon) else { continue }

            for endpoint in [barrier.first, barrier.second]
                where segment.checkIsOnSegment(endpoint)
            {
                if let parameter = parameter(of: endpoint, on: segment) {
                    parameters.append(parameter)
                }
            }
        }

        return parameters.sorted()
    }

    static func point(on segment: LineSegment, at parameter: Double) -> Coordinate3D {
        let latitude = segment.first.latitude
            + ((segment.second.latitude - segment.first.latitude) * parameter)
        let longitude = segment.first.longitude
            + ((segment.second.longitude - segment.first.longitude) * parameter)

        let altitude: Double?
        if let first = segment.first.altitude,
           let second = segment.second.altitude
        {
            altitude = first + ((second - first) * parameter)
        }
        else {
            altitude = nil
        }

        return Coordinate3D(
            x: longitude,
            y: latitude,
            z: altitude,
            projection: segment.projection)
    }

    private static func parameter(
        of point: Coordinate3D,
        on segment: LineSegment
    ) -> Double? {
        let dx = segment.second.longitude - segment.first.longitude
        let dy = segment.second.latitude - segment.first.latitude
        let lengthSquared = (dx * dx) + (dy * dy)
        guard lengthSquared > GISTool.intersectionEpsilon else { return nil }

        let px = point.longitude - segment.first.longitude
        let py = point.latitude - segment.first.latitude
        let value = ((px * dx) + (py * dy)) / lengthSquared
        return min(max(value, 0.0), 1.0)
    }

}
