import Foundation

extension Polygon {

    /// Returns the Minkowski sum of the receiver with a pattern polygon.
    ///
    /// The Minkowski sum of two sets A and B is the set of all points a + b
    /// where a ∈ A and b ∈ B. This is useful for morphological dilation,
    /// generating offset shapes, and path planning.
    ///
    /// - Parameter pattern: The pattern polygon to add.
    /// - Parameter gridSize: Snap coordinates to a grid of the given size before computing (default `nil`).
    /// - Returns: A ``PolygonGeometry`` representing the Minkowski sum, or `nil` if empty.
    public func minkowskiSum(
        with pattern: PolygonGeometry,
        gridSize: Double? = nil
    ) -> PolygonGeometry? {
        let a = gridSize.map { self.snappedToGrid(tolerance: $0) } ?? self
        let b = gridSize.map { pattern.snappedToGrid(tolerance: $0) } ?? pattern
        let bPolygons = b.polygons
        return Minkowski.computeSum(a, bPolygons)
    }

    /// Returns the Minkowski difference of the receiver and a pattern polygon.
    ///
    /// The Minkowski difference is A ⊕ (−B), i.e. the Minkowski sum with the
    /// pattern reflected through the origin. Useful for morphological erosion.
    ///
    /// - Parameter pattern: The pattern polygon to subtract.
    /// - Parameter gridSize: Snap coordinates to a grid of the given size before computing (default `nil`).
    /// - Returns: A ``PolygonGeometry`` representing the Minkowski difference, or `nil` if empty.
    public func minkowskiDifference(
        with pattern: PolygonGeometry,
        gridSize: Double? = nil
    ) -> PolygonGeometry? {
        let a = gridSize.map { self.snappedToGrid(tolerance: $0) } ?? self
        let b = gridSize.map { pattern.snappedToGrid(tolerance: $0) } ?? pattern
        let reflected = b.projected(to: b.projection)  // keep projection
        let reflectedPolygons = reflected.polygons.map { $0.reflectedThroughOrigin() }
        return Minkowski.computeSum(a, reflectedPolygons)
    }

}

extension MultiPolygon {

    /// Returns the Minkowski sum of the receiver with a pattern polygon.
    ///
    /// - Parameter pattern: The pattern polygon to add.
    /// - Parameter gridSize: Snap coordinates to a grid of the given size before computing (default `nil`).
    /// - Returns: A ``PolygonGeometry`` representing the Minkowski sum, or `nil` if empty.
    public func minkowskiSum(
        with pattern: PolygonGeometry,
        gridSize: Double? = nil
    ) -> PolygonGeometry? {
        let a = gridSize.map { self.snappedToGrid(tolerance: $0) } ?? self
        let b = gridSize.map { pattern.snappedToGrid(tolerance: $0) } ?? pattern
        let bPolygons = b.polygons
        return Minkowski.computeSum(a, bPolygons)
    }

    /// Returns the Minkowski difference of the receiver and a pattern polygon.
    ///
    /// - Parameter pattern: The pattern polygon to subtract.
    /// - Parameter gridSize: Snap coordinates to a grid of the given size before computing (default `nil`).
    /// - Returns: A ``PolygonGeometry`` representing the Minkowski difference, or `nil` if empty.
    public func minkowskiDifference(
        with pattern: PolygonGeometry,
        gridSize: Double? = nil
    ) -> PolygonGeometry? {
        let a = gridSize.map { self.snappedToGrid(tolerance: $0) } ?? self
        let b = gridSize.map { pattern.snappedToGrid(tolerance: $0) } ?? pattern
        let reflectedPolygons = b.polygons.map { $0.reflectedThroughOrigin() }
        return Minkowski.computeSum(a, reflectedPolygons)
    }

}

// MARK: - Implementation

private enum Minkowski {

    /// Compute the Minkowski sum of a polygon/polygon-coverage and a pattern.
    static func computeSum(
        _ geoJson: GeoJson,
        _ patterns: [Polygon]
    ) -> PolygonGeometry? {
        guard patterns.isNotEmpty else { return nil }
        guard let sourcePolygons = (geoJson as? PolygonGeometry)?.polygons,
              sourcePolygons.isNotEmpty
        else { return nil }

        let projection = sourcePolygons.first!.projection

        // Tessellate source and pattern into convex triangles
        let sourceParts = tessellateConvex(sourcePolygons, projection: projection)
        let patternParts = tessellateConvex(patterns, projection: projection)

        guard sourceParts.isNotEmpty,
              patternParts.isNotEmpty
        else { return nil }

        // Compute convex Minkowski sum for each pair and collect results
        var results: [Polygon] = []
        for sa in sourceParts {
            for sb in patternParts {
                if let sum = convexSum(sa, sb) {
                    results.append(sum)
                }
            }
        }

        guard results.isNotEmpty else { return nil }

        // Union all partial results
        guard let union = Union.unionPolygons(results) else { return nil }

        let projected = union.projected(to: projection)
        if projected.polygons.count == 1 {
            return projected.polygons[0]
        }
        return projected
    }

    /// Decompose polygons into convex triangles.
    private static func tessellateConvex(
        _ polygons: [Polygon],
        projection: Projection
    ) -> [Polygon] {
        var parts: [Polygon] = []
        for poly in polygons {
            if !poly.isConcave() {
                parts.append(poly)
            }
            else {
                let triangles = poly.tesselated()
                for f in triangles.features {
                    if let t = f.geometry as? Polygon {
                        parts.append(t)
                    }
                }
            }
        }
        return parts
    }

    /// Compute Minkowski sum of two convex polygons using pairwise vertex sums
    /// plus convex hull.
    private static func convexSum(_ a: Polygon, _ b: Polygon) -> Polygon? {
        let coordsA = a.allCoordinates
        let coordsB = b.allCoordinates
        guard coordsA.isNotEmpty,
              coordsB.isNotEmpty
        else { return nil }

        var sums: [Coordinate3D] = []
        sums.reserveCapacity(coordsA.count * coordsB.count)

        for va in coordsA {
            for vb in coordsB {
                let coord = Coordinate3D(
                    x: va.x + vb.x,
                    y: va.y + vb.y,
                    z: nil,
                    projection: va.projection)
                sums.append(coord)
            }
        }

        // Compute convex hull of the sums
        let temp = FeatureCollection(sums.map { Feature(Point($0)) })
        return temp.convexHull()
    }

}

// MARK: - Reflection

extension Polygon {

    /// Reflect the polygon through the origin (negate all coordinates).
    fileprivate func reflectedThroughOrigin() -> Polygon {
        let reflectedRings: [[Coordinate3D]] = rings.map { ring in
            ring.coordinates.map { coord in
                Coordinate3D(
                    x: -coord.x,
                    y: -coord.y,
                    z: coord.altitude,
                    projection: coord.projection)
            }
        }
        return Polygon(unchecked: reflectedRings)
    }

}
