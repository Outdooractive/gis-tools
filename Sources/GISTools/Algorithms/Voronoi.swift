import Foundation

// Ported from https://github.com/Turfjs/turf/tree/master/packages/turf-voronoi

extension FeatureCollection {

    /// Computes a Voronoi diagram from the receiver's points within a bounding box.
    ///
    /// Each distinct input ``Point`` site produces one ``Polygon`` cell
    /// representing the region closer to that site than to any other input
    /// site. The cells are clipped to the given bounding box.
    ///
    /// Duplicate sites (coordinates equal within ``GISTool/equalityDelta``)
    /// are collapsed to their first occurrence. The returned cell keeps that
    /// first feature's `id`, `properties` and foreign members; later duplicate
    /// features do not produce additional cells.
    ///
    /// Fewer than three distinct sites are supported by direct half-plane
    /// clipping, and collinear sites produce parallel strip cells. An empty
    /// collection (or a collection without point features) produces an empty
    /// result.
    ///
    /// All projections are supported. The algorithm uses Cartesian math on
    /// native XY values.
    ///
    /// - Parameter boundingBox: The bounding box to which all cells are clipped.
    /// - Parameter gridSize: Snap coordinates to a grid of the given size before computing (default `nil`).
    /// - Returns: A ``FeatureCollection`` of ``Polygon`` features, one per
    ///   distinct input point site.
    public func voronoiDiagram(
        boundingBox: BoundingBox,
        gridSize: Double? = nil
    ) -> FeatureCollection {
        guard features.isNotEmpty else { return FeatureCollection() }

        let snapped = gridSize.map { self.snappedToGrid(tolerance: $0) } ?? self

        // ECEF is not a map plane: compute the diagram in geographic space and
        // project the cells back into the source CRS.
        if let sourceProjection = snapped.features
            .compactMap({ ($0.geometry as? Point)?.coordinate.projection })
            .first,
            sourceProjection.isGeocentric
        {
            let geographicFeatures: [Feature] = snapped.features.map { feature in
                guard let point = feature.geometry as? Point else { return feature }
                return Feature(
                    Point(point.coordinate.projected(to: .epsg4326)),
                    id: feature.id,
                    properties: feature.properties)
            }
            let geographicBox = boundingBox.projected(to: .epsg4326)
            let geographicResult = FeatureCollection(geographicFeatures).voronoiDiagram(
                boundingBox: geographicBox)

            return FeatureCollection(geographicResult.features.map { feature in
                guard let polygon = feature.geometry as? Polygon else { return feature }
                return Feature(
                    polygon.projected(to: sourceProjection),
                    id: feature.id,
                    properties: feature.properties)
            })
        }

        let (siteFeatures, points) = Voronoi.uniqueSites(in: snapped.features)
        guard points.isNotEmpty else { return FeatureCollection() }

        let (unwrappedPoints, unwrappedBox) = Voronoi.unwrapped(
            points: points,
            boundingBox: boundingBox)

        return Voronoi.diagram(
            features: siteFeatures,
            points: unwrappedPoints,
            boundingBox: unwrappedBox)
    }

}

// MARK: - Implementation

private enum Voronoi {

    fileprivate struct SiteKey: Hashable {
        let x: Int64
        let y: Int64
    }

    static func diagram(
        features inputFeatures: [Feature],
        points: [Coordinate3D],
        boundingBox: BoundingBox
    ) -> FeatureCollection {
        let projection = points.first?.projection ?? boundingBox.projection
        let pts = points.map { Pt(x: $0.longitude, y: $0.latitude) }
        let triangles = Triangulator.triangulate(pts)

        // Build edge counts to identify adjacency and boundary edges
        var edgeCount: [String: Int] = [:]
        var edgeEndpoints: [String: (a: Pt, b: Pt)] = [:]

        for t in triangles {
            let edges = [(t.a, t.b), (t.b, t.c), (t.c, t.a)]
            for (a, b) in edges {
                let key = Voronoi.edgeKey(a, b)
                edgeCount[key, default: 0] += 1
                edgeEndpoints[key] = (a, b)
            }
        }

        // Build neighbor list for each point
        var neighbors: [Int: Set<Int>] = [:]
        for (key, _) in edgeCount {
            guard let edge = edgeEndpoints[key],
                  let ia = pts.firstIndex(where: { $0.x == edge.a.x && $0.y == edge.a.y }),
                  let ib = pts.firstIndex(where: { $0.x == edge.b.x && $0.y == edge.b.y })
            else { continue }

            neighbors[ia, default: []].insert(ib)
            neighbors[ib, default: []].insert(ia)
        }

        // Build bounding box polygon (CCW)
        let bboxPolygon = Voronoi.bboxPolygon(boundingBox)

        // Compute Voronoi cell for each point. Delaunay neighbours are a
        // sufficient clipping set for a non-degenerate triangulation; when the
        // triangulation is empty (fewer than three sites, duplicate-free
        // collinear sites or a degenerate triangulation) clip against every
        // other site instead.
        var features: [Feature] = []
        for (i, point) in points.enumerated() {
            let allOtherIndices = points.indices.filter { $0 != i }
            let neighborIndices = (neighbors[i]?.count ?? 0) >= 2
                ? Array(neighbors[i] ?? [])
                : allOtherIndices

            var cell = Voronoi.computeCell(
                point: point,
                neighborIndices: neighborIndices,
                allPoints: points,
                bboxPolygon: bboxPolygon,
                projection: projection)

            // A numerically fragile Delaunay adjacency can leave a site
            // without a cell. Retry against every site before giving up.
            if cell == nil, neighborIndices.count != allOtherIndices.count {
                cell = Voronoi.computeCell(
                    point: point,
                    neighborIndices: allOtherIndices,
                    allPoints: points,
                    bboxPolygon: bboxPolygon,
                    projection: projection)
            }

            guard let cell else { continue }

            let source = inputFeatures[i]
            let normalizedCell = Polygon(unchecked: cell.coordinates.map { ring in
                ring.map { $0.normalized() }
            })
            var feature = Feature(
                normalizedCell,
                id: source.id,
                properties: source.properties)
            feature.foreignMembers = source.foreignMembers
            features.append(feature)
        }

        return FeatureCollection(features)
    }

    /// Collapses duplicate sites while preserving the first feature's metadata.
    fileprivate static func uniqueSites(
        in features: [Feature]
    ) -> (features: [Feature], points: [Coordinate3D]) {
        var uniqueFeatures: [Feature] = []
        var uniquePoints: [Coordinate3D] = []
        var buckets: [SiteKey: [Int]] = [:]

        for feature in features {
            guard let point = feature.geometry as? Point else { continue }
            let coordinate = point.coordinate
            let key = Voronoi.siteKey(for: coordinate)

            // A coordinate can fall into an adjacent quantized bucket while
            // still being within `equalityDelta` of an existing site, so
            // inspect the 3x3 neighbourhood before adding it.
            var isDuplicate = false
            search: for dx in -1 ... 1 {
                for dy in -1 ... 1 {
                    let neighborKey = SiteKey(x: key.x + Int64(dx), y: key.y + Int64(dy))
                    for index in buckets[neighborKey] ?? [] {
                        if uniquePoints[index].equals(
                            other: coordinate,
                            includingAltitude: false
                        ) {
                            isDuplicate = true
                            break search
                        }
                    }
                }
            }
            guard !isDuplicate else { continue }

            buckets[key, default: []].append(uniquePoints.count)
            uniqueFeatures.append(feature)
            uniquePoints.append(coordinate)
        }

        return (uniqueFeatures, uniquePoints)
    }

    /// Horizontal site identity, canonicalized across the wraparound axis.
    fileprivate static func siteKey(for point: Coordinate3D) -> SiteKey {
        var x = point.longitude

        if let extent = point.projection.wraparoundExtent, extent > 0.0 {
            let period = 2.0 * extent
            x = x.truncatingRemainder(dividingBy: period)
            if x <= -extent { x += period }
            if x > extent { x -= period }
            if x == extent { x = -extent }
        }

        return SiteKey(
            x: Int64((x / GISTool.equalityDelta).rounded()),
            y: Int64((point.latitude / GISTool.equalityDelta).rounded()))
    }

    /// Unwraps the points and bounding box around the projection's wraparound
    /// axis. A crossing bounding box such as `170 ... -170` becomes
    /// `170 ... 190`; points on the far side are shifted by whole world copies
    /// so the diagram uses the short span. Cell coordinates are normalized
    /// back when emitted.
    static func unwrapped(
        points: [Coordinate3D],
        boundingBox: BoundingBox
    ) -> ([Coordinate3D], BoundingBox) {
        guard let extent = (points.first?.projection ?? boundingBox.projection)
            .wraparoundExtent,
            extent > 0.0,
            let first = points.first
        else { return (points, boundingBox) }

        let period = 2.0 * extent
        var west = boundingBox.southWest.x
        var east = boundingBox.northEast.x

        if west > east {
            east += period
        }

        // Align the box with the first point; this also keeps a world-spanning
        // box stable while moving seam sites into the box's copy of the world.
        let center = (west + east) / 2.0
        let shift = ((first.x - center) / period).rounded() * period
        west += shift
        east += shift

        let unwrappedPoints = points.map { point -> Coordinate3D in
            let offset = ((center - point.x) / period).rounded() * period
            return Coordinate3D(
                x: point.x + offset,
                y: point.y,
                z: point.altitude,
                m: point.m,
                projection: point.projection)
        }

        let southWest = Coordinate3D(
            x: west,
            y: boundingBox.southWest.y,
            projection: boundingBox.projection)
        let northEast = Coordinate3D(
            x: east,
            y: boundingBox.northEast.y,
            projection: boundingBox.projection)

        return (unwrappedPoints, BoundingBox(
            southWest: southWest,
            northEast: northEast))
    }

    // MARK: - Cell computation

    /// Compute the Voronoi cell for a single point by clipping the bounding box
    /// against the perpendicular bisectors of its Delaunay neighbors.
    private static func computeCell(
        point: Coordinate3D,
        neighborIndices: [Int],
        allPoints: [Coordinate3D],
        bboxPolygon: [Coordinate3D],
        projection: Projection
    ) -> Polygon? {
        // Start with the bounding box as the clipping polygon
        var cell = bboxPolygon

        let px = point.longitude
        let py = point.latitude
        let pSq = px * px + py * py

        for ni in neighborIndices {
            let q = allPoints[ni]
            let qx = q.longitude
            let qy = q.latitude
            let qSq = qx * qx + qy * qy

            // Bisector coefficients: line where distance(p) == distance(q)
            // 2*(qx-px)*x + 2*(qy-py)*y = qSq - pSq
            let a = 2.0 * (qx - px)
            let b = 2.0 * (qy - py)
            let c = qSq - pSq

            // Clip cell to the half-plane containing point p
            cell = Voronoi.clipPolygonByHalfPlane(polygon: cell, a: a, b: b, c: c, projection: projection)
            guard cell.count >= 3 else { return nil }
        }

        guard cell.count >= 3 else { return nil }

        // Close the polygon
        var coords = cell
        coords.append(cell[0])
        return Polygon([coords])
    }

    // MARK: - Half-plane clipping (Sutherland-Hodgman)

    /// Clip a polygon (CCW) by the half-plane a*x + b*y <= c.
    /// The polygon is represented as an array of coordinates (not closed).
    private static func clipPolygonByHalfPlane(
        polygon: [Coordinate3D],
        a: Double,
        b: Double,
        c: Double,
        projection: Projection
    ) -> [Coordinate3D] {
        guard polygon.count >= 3 else { return polygon }

        var result: [Coordinate3D] = []

        let count = polygon.count
        for i in 0 ..< count {
            let current = polygon[i]
            let previous = polygon[(i + count - 1) % count]

            let dCurrent = a * current.longitude + b * current.latitude - c
            let dPrevious = a * previous.longitude + b * previous.latitude - c

            let currentInside = dCurrent <= 0
            let previousInside = dPrevious <= 0

            if currentInside {
                if !previousInside {
                    // Entering: add intersection
                    if let intersection = Voronoi.lineIntersection(
                        p1: previous,
                        p2: current,
                        a: a,
                        b: b,
                        c: c,
                        projection: projection)
                    {
                        result.append(intersection)
                    }
                }
                result.append(current)
            }
            else if previousInside {
                // Exiting: add intersection
                if let intersection = Voronoi.lineIntersection(
                    p1: previous,
                    p2: current,
                    a: a,
                    b: b,
                    c: c,
                    projection: projection)
                {
                    result.append(intersection)
                }
            }
        }

        return result
    }

    /// Find intersection of segment (p1-p2) with line a*x + b*y = c.
    private static func lineIntersection(
        p1: Coordinate3D,
        p2: Coordinate3D,
        a: Double,
        b: Double,
        c: Double,
        projection: Projection
    ) -> Coordinate3D? {
        let x1 = p1.longitude
        let y1 = p1.latitude
        let x2 = p2.longitude
        let y2 = p2.latitude

        let denom = a * (x2 - x1) + b * (y2 - y1)
        guard abs(denom) > GISTool.determinantEpsilon else { return nil }

        let t = (c - a * x1 - b * y1) / denom
        guard t >= 0, t <= 1 else { return nil }

        return Coordinate3D(
            x: x1 + t * (x2 - x1),
            y: y1 + t * (y2 - y1),
            projection: projection)
    }

    // MARK: - Helpers

    /// Build a CCW polygon from the bounding box.
    private static func bboxPolygon(_ bbox: BoundingBox) -> [Coordinate3D] {
        let sw = bbox.southWest
        let nw = bbox.northWest
        let ne = bbox.northEast
        let se = bbox.southEast
        return [sw, nw, ne, se]
    }

    /// Canonical string key for an undirected edge.
    private static func edgeKey(_ a: Pt, _ b: Pt) -> String {
        let ax = "\(a.x),\(a.y)"
        let bx = "\(b.x),\(b.y)"
        return ax < bx ? "\(ax)-\(bx)" : "\(bx)-\(ax)"
    }

}
