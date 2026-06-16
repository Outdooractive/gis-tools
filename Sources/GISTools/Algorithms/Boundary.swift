import Foundation

// MARK: - Topological boundary (OGC Simple Features / DE-9IM)

extension Point {

    /// The topological boundary of a Point is empty.
    public var boundary: GeometryCollection {
        GeometryCollection([])
    }

}

extension MultiPoint {

    /// The topological boundary of a MultiPoint is empty.
    public var boundary: GeometryCollection {
        GeometryCollection([])
    }

}

extension LineString {

    /// The topological boundary of a LineString is its endpoints.
    /// Returns an empty `MultiPoint` if the line is closed (a ring).
    public var boundary: MultiPoint {
        if isClosed {
            return MultiPoint()
        }
        return MultiPoint(unchecked: [firstCoordinate, lastCoordinate].compactMap { $0 } as [Coordinate3D])
    }

}

extension MultiLineString {

    /// The topological boundary of a MultiLineString is the set of endpoints
    /// that appear an odd number of times across all constituent lines.
    public var boundary: MultiPoint {
        var counts: [Coordinate3D: Int] = [:]

        for line in lineStrings {
            if let first = line.firstCoordinate {
                counts[first, default: 0] += 1
            }
            if let last = line.lastCoordinate {
                counts[last, default: 0] += 1
            }
        }

        let result = counts.filter { $0.value % 2 == 1 }.map(\.key)
        return MultiPoint(unchecked: result as [Coordinate3D])
    }

}

extension Polygon {

    /// The topological boundary of a Polygon is its outer ring.
    /// For a polygon with holes only the exterior ring is returned,
    /// matching the OGC Simple Features definition.
    public var boundary: LineString? {
        guard let ring = outerRing else { return nil }
        return ring.lineString
    }

}

extension MultiPolygon {

    /// The topological boundary of a MultiPolygon is the union of the
    /// boundaries of all constituent polygons, returned as a ``MultiLineString``.
    public var boundary: MultiLineString? {
        let lines: [LineString] = polygons.compactMap { $0.boundary }
        guard lines.isNotEmpty else { return nil }
        return MultiLineString(lines)
    }

}

extension GeometryCollection {

    /// The topological boundary of a GeometryCollection is the union of the
    /// boundaries of all its contained geometries.
    public var boundary: GeometryCollection? {
        let boundaries: [GeoJsonGeometry] = geometries.compactMap { geo in
            if let p = geo as? Point { return p.boundary }
            if let mp = geo as? MultiPoint { return mp.boundary }
            if let ls = geo as? LineString { return ls.boundary }
            if let mls = geo as? MultiLineString { return mls.boundary }
            if let pg = geo as? Polygon { return pg.boundary }
            if let mpg = geo as? MultiPolygon { return mpg.boundary }
            if let gc = geo as? GeometryCollection { return gc.boundary }
            return nil
        }
        guard boundaries.isNotEmpty else { return nil }
        return GeometryCollection(boundaries)
    }

}

extension Feature {

    /// The topological boundary of a Feature is the boundary of its geometry.
    public var boundary: GeoJsonGeometry? {
        if let p = geometry as? Point { return p.boundary }
        if let mp = geometry as? MultiPoint { return mp.boundary }
        if let ls = geometry as? LineString { return ls.boundary }
        if let mls = geometry as? MultiLineString { return mls.boundary }
        if let pg = geometry as? Polygon { return pg.boundary }
        if let mpg = geometry as? MultiPolygon { return mpg.boundary }
        if let gc = geometry as? GeometryCollection { return gc.boundary }
        return nil
    }

}

extension FeatureCollection {

    /// The topological boundary of a FeatureCollection is the union of the
    /// boundaries of all its features' geometries.
    public var boundary: GeometryCollection? {
        let boundaries: [GeoJsonGeometry] = features.compactMap { $0.boundary }
        guard boundaries.isNotEmpty else { return nil }
        return GeometryCollection(boundaries)
    }

}
