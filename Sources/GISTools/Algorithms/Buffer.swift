#if canImport(CoreLocation)
import CoreLocation
#endif
import Foundation

/// Controls how convex corners are joined during buffering.
/// The fidelity of rounded joins is controlled by the ``steps`` parameter.
public enum BufferJoinType: Sendable {

    /// Cut off mitered corners with a straight line at the buffer distance.
    case bevel

    /// Extend offset edges until they intersect, clamped by a miter limit.
    /// - Parameter limit: Maximum ratio of miter length to buffer distance (default `2.0`).
    case miter(limit: Double = 2.0)

    /// Round corners (fidelity controlled by ``steps``).
    case round

}

/// Controls how the ends of open buffer paths are terminated.
/// Fidelity of round ends is controlled by the ``steps`` parameter.
public enum BufferEndType: Sendable {

    /// Flat end at the last vertex, perpendicular to the line direction.
    case butt

    /// Closed polygon: the path forms a closed ring (no end caps).
    case polygon

    /// Rounded end cap (fidelity controlled by ``steps``).
    case round

    /// Extended by half the buffer width beyond the last vertex.
    case square

}

/// Options for how buffered parts are combined into the result.
public enum BufferUnionType: Sendable {

    /// Combine the buffered parts of each input geometry.
    case individual

    /// Return each buffered part as a separate polygon (no union).
    case none

    /// Combine all overlapping buffered parts across all input geometries.
    case overlapping

}

extension GeoJson {

    /// Returns the receiver with a buffer applied.
    ///
    /// Uses the segment‑rectangle + vertex‑circle approach: each segment is
    /// expanded into a rectangle, circles are added at vertices for rounded
    /// joins and end caps, and everything is merged via polygon union.
    ///
    /// - Parameter distance: The buffer distance, in meters. Positive expands,
    ///   negative shrinks (only for polygons and multi‑polygons).
    /// - Parameter endType: End cap style for open paths (default `.round`).
    /// - Parameter joinType: Corner join style (default `.round`).
    /// - Parameter unionType: How to combine the buffered parts (default `.individual`).
    /// - Parameter steps: Number of steps for circle approximation (default `64`).
    /// - Parameter gridSize: Snap coordinates to a grid before computing (default `nil`).
    /// - Returns: The buffered geometry, or `nil` if the buffer could not be computed.
    public func buffered(
        by distance: Double,
        endType: BufferEndType = .round,
        joinType: BufferJoinType = .round,
        unionType: BufferUnionType = .individual,
        steps: Int = 64,
        gridSize: Double? = nil
    ) -> MultiPolygon? {
        let geometry = gridSize.map { self.snappedToGrid(tolerance: $0) } ?? self
        guard distance != 0.0 else { return nil }

        if distance < 0.0 {
            return Self.inset(geometry, by: -distance, endType: endType, unionType: unionType, steps: steps)
        }
        return Self.buffer(geometry, by: distance, endType: endType, joinType: joinType, unionType: unionType, steps: steps)
    }

    private static func buffer(
        _ geometry: GeoJson,
        by distance: Double,
        endType: BufferEndType,
        joinType: BufferJoinType,
        unionType: BufferUnionType,
        steps: Int
    ) -> MultiPolygon? {
        let result: MultiPolygon?

        switch geometry {
        case let point as Point:
            guard let circle = point.circle(radius: distance, steps: steps) else { return nil }
            result = MultiPolygon([circle])

        case let multiPoint as MultiPoint:
            let bufferedPoints = multiPoint.points.compactMap { $0.circle(radius: distance, steps: steps) }
            guard bufferedPoints.isNotEmpty else { return nil }
            result = unionType == .overlapping
                ? Union.unionPolygons(bufferedPoints)
                : MultiPolygon(bufferedPoints)

        case let lineString as LineString:
            var polygons = lineString.lineSegments.flatMap { segment in
                segment.buffered(by: distance, endType: .butt, unionType: .none)?.polygons ?? []
            }
            var bufferCoordinates = lineString.coordinates
            guard bufferCoordinates.count >= 2 else {
                result = MultiPolygon(polygons)
                break
            }

            // Remove endpoint vertices so no circles are added there
            if case .butt = endType {
                bufferCoordinates.removeFirst()
                bufferCoordinates.removeLast()
            }
            else if case .square = endType {
                bufferCoordinates.removeFirst()
                bufferCoordinates.removeLast()
                let coords = lineString.coordinates
                let startBearing = coords[0].bearing(to: coords[1])
                let endBearing = coords[coords.count - 2].bearing(to: coords[coords.count - 1])
                Self.addSquareEndCap(at: coords[0], bearing: startBearing, tipDistance: distance * 0.5, width: distance, forward: false, to: &polygons)
                Self.addSquareEndCap(at: coords[coords.count - 1], bearing: endBearing, tipDistance: distance * 0.5, width: distance, forward: true, to: &polygons)
            }
            else if case .polygon = endType {
                // Bridge the gap between end and start to form a closed ring.
                // Circles at all coordinates (like .round) plus the bridge.
                let coords = lineString.coordinates
                let bridge = LineSegment(first: coords.last!, second: coords[0], index: 0)
                if let bp = bridge.buffered(by: distance, endType: .butt, unionType: .none) {
                    polygons.append(contentsOf: bp.polygons)
                }
            }

            let allCoords = lineString.coordinates
            for coordinate in bufferCoordinates {
                switch joinType {
                case .bevel, .miter:
                    if case .round = endType {
                        if coordinate != allCoords.first, coordinate != allCoords.last { continue }
                    }
                    else { continue }
                default: break
                }
                guard let circle = coordinate.circle(radius: distance, steps: steps) else { continue }
                polygons.append(circle)
            }

            switch joinType {
            case .bevel:
                if endType == .polygon {
                    let n = allCoords.count
                    for i in 0 ..< n {
                        let prev = allCoords[(i + n - 1) % n]
                        let curr = allCoords[i]
                        let next = allCoords[(i + 1) % n]
                        Self.addBevelJoin(at: prev, curr, next, distance: distance, to: &polygons)
                    }
                }
                else {
                    for i in 1 ..< allCoords.count - 1 {
                        Self.addBevelJoin(at: allCoords[i - 1], allCoords[i], allCoords[i + 1], distance: distance, to: &polygons)
                    }
                }

            case .miter(let limit):
                if endType == .polygon {
                    let n = allCoords.count
                    for i in 0 ..< n {
                        let prev = allCoords[(i + n - 1) % n]
                        let curr = allCoords[i]
                        let next = allCoords[(i + 1) % n]
                        Self.addMiterJoin(at: prev, curr, next, distance: distance, limit: limit, to: &polygons)
                    }
                }
                else {
                    for i in 1 ..< allCoords.count - 1 {
                        Self.addMiterJoin(at: allCoords[i - 1], allCoords[i], allCoords[i + 1], distance: distance, limit: limit, to: &polygons)
                    }
                }

            default:
                break
            }
            result = unionType.isIn([.individual, .overlapping])
                ? Union.unionPolygons(polygons)
                : MultiPolygon(polygons)

        case let multiLineString as MultiLineString:
            let buffered = multiLineString.lineStrings.compactMap {
                $0.buffered(by: distance, endType: endType, joinType: joinType, unionType: unionType, steps: steps)
            }.flatMap(\.polygons)
            guard buffered.isNotEmpty else { return nil }
            result = unionType == .overlapping
                ? Union.unionPolygons(buffered)
                : MultiPolygon(buffered)

        case let polygon as Polygon:
            let bufferCoordinates = polygon.allCoordinates
            guard bufferCoordinates.count >= 2 else { return nil }
            var polygons = polygon.lineSegments.flatMap { segment in
                segment.buffered(by: distance, endType: .butt, unionType: .none)?.polygons ?? []
            }
            switch joinType {
            case .bevel:
                if let outerRing = polygon.outerRing {
                    Self.addRingBevels(for: outerRing.coordinates, distance: distance, to: &polygons)
                }
                if let innerRings = polygon.innerRings {
                    for ring in innerRings {
                        Self.addRingBevels(for: ring.coordinates, distance: distance, to: &polygons)
                    }
                }

            case .miter(let limit):
                if let outerRing = polygon.outerRing {
                    Self.addRingMiters(for: outerRing.coordinates, distance: distance, limit: limit, to: &polygons)
                }
                if let innerRings = polygon.innerRings {
                    for ring in innerRings {
                        Self.addRingMiters(for: ring.coordinates, distance: distance, limit: limit, to: &polygons)
                    }
                }

            default:
                for coordinate in bufferCoordinates {
                    guard let circle = coordinate.circle(radius: distance, steps: steps) else { continue }
                    polygons.append(circle)
                }
            }

            polygons.append(polygon)
            result = unionType.isIn([.individual, .overlapping])
                ? Union.unionPolygons(polygons)
                : MultiPolygon(polygons)

        case let multiPolygon as MultiPolygon:
            let buffered = multiPolygon.polygons.compactMap {
                $0.buffered(by: distance, endType: endType, joinType: joinType, unionType: unionType, steps: steps)
            }.flatMap(\.polygons)
            guard buffered.isNotEmpty else { return nil }
            result = unionType == .overlapping
                ? Union.unionPolygons(buffered)
                : MultiPolygon(buffered)

        case let geometryCollection as GeometryCollection:
            let buffered = geometryCollection.geometries.compactMap {
                $0.buffered(by: distance, endType: endType, joinType: joinType, unionType: unionType, steps: steps)
            }.flatMap(\.polygons)
            guard buffered.isNotEmpty else { return nil }
            result = unionType == .overlapping
                ? Union.unionPolygons(buffered)
                : MultiPolygon(buffered)

        case let feature as Feature:
            return feature.geometry.buffered(by: distance, endType: endType, joinType: joinType, unionType: unionType, steps: steps)

        case let featureCollection as FeatureCollection:
            let buffered = featureCollection.features.compactMap {
                $0.geometry.buffered(by: distance, endType: endType, joinType: joinType, unionType: unionType, steps: steps)
            }.flatMap(\.polygons)
            guard buffered.isNotEmpty else { return nil }
            result = unionType == .overlapping
                ? Union.unionPolygons(buffered)
                : MultiPolygon(buffered)

        default:
            return nil
        }

        return Self.cutAtAntimeridianIfNeeded(result)
    }

    private static func inset(
        _ geometry: GeoJson,
        by distance: Double,
        endType: BufferEndType,
        unionType: BufferUnionType,
        steps: Int
    ) -> MultiPolygon? {
        let result: MultiPolygon?

        switch geometry {
        case let polygon as Polygon:
            guard let inset = Self.insetPolygon(polygon, by: distance) else { return nil }
            result = MultiPolygon([inset])

        case let multiPolygon as MultiPolygon:
            let insets = multiPolygon.polygons.compactMap { Self.insetPolygon($0, by: distance) }
            guard insets.isNotEmpty else { return nil }
            result = MultiPolygon(unchecked: insets)

        case let feature as Feature:
            return feature.geometry.buffered(by: -distance, endType: endType, unionType: unionType, steps: steps)

        case let featureCollection as FeatureCollection:
            let buffered = featureCollection.features.compactMap {
                $0.geometry.buffered(by: -distance, endType: endType, unionType: unionType, steps: steps)
            }.flatMap(\.polygons)
            guard buffered.isNotEmpty else { return nil }
            result = unionType == .overlapping
                ? Union.unionPolygons(buffered)
                : MultiPolygon(unchecked: buffered)

        case let geometryCollection as GeometryCollection:
            let buffered = geometryCollection.geometries.compactMap {
                $0.buffered(by: -distance, endType: endType, unionType: unionType, steps: steps)
            }.flatMap(\.polygons)
            guard buffered.isNotEmpty else { return nil }
            result = unionType == .overlapping
                ? Union.unionPolygons(buffered)
                : MultiPolygon(unchecked: buffered)

        default:
            return nil
        }

        return Self.cutAtAntimeridianIfNeeded(result)
    }

    private static func insetPolygon(
        _ polygon: Polygon,
        by distance: Double
    ) -> Polygon? {
        guard distance > 0.0 else { return polygon }

        let projected = polygon.projected(to: .epsg3857)
        guard let outerRing = projected.outerRing else { return nil }

        let outerCoords = outerRing.coordinates
        guard outerCoords.count >= 4 else { return nil }

        func inwardNormal(_ a: Coordinate3D, _ b: Coordinate3D) -> (dx: Double, dy: Double)? {
            let vx = b.x - a.x, vy = b.y - a.y
            let len = sqrt(vx * vx + vy * vy)
            guard len > 0 else { return nil }
            if outerRing.isClockwise { return (vy / len, -vx / len) }
            return (-vy / len, vx / len)
        }

        func outwardNormal(_ a: Coordinate3D, _ b: Coordinate3D, _ hcw: Bool) -> (dx: Double, dy: Double)? {
            let vx = b.x - a.x, vy = b.y - a.y
            let len = sqrt(vx * vx + vy * vy)
            guard len > 0 else { return nil }
            if hcw { return (-vy / len, vx / len) }
            return (vy / len, -vx / len)
        }

        func intersect(_ a1: Coordinate3D, _ a2: Coordinate3D, _ b1: Coordinate3D, _ b2: Coordinate3D) -> Coordinate3D? {
            let x1 = a1.x, y1 = a1.y, x2 = a2.x, y2 = a2.y
            let x3 = b1.x, y3 = b1.y, x4 = b2.x, y4 = b2.y
            let denom = (x1 - x2) * (y3 - y4) - (y1 - y2) * (x3 - x4)
            guard abs(denom) > GISTool.intersectionEpsilon else { return nil }
            let t = ((x1 - x3) * (y3 - y4) - (y1 - y3) * (x3 - x4)) / denom
            return Coordinate3D(x: x1 + t * (x2 - x1), y: y1 + t * (y2 - y1))
        }

        var newOuter: [Coordinate3D] = []
        let n = outerCoords.count - 1
        for i in 0..<n {
            let prev = outerCoords[(i + n - 1) % n],
                curr = outerCoords[i],
                next = outerCoords[(i + 1) % n]
            guard let n0 = inwardNormal(prev, curr),
                  let n1 = inwardNormal(curr, next)
            else { return nil }

            let oa1 = Coordinate3D(x: prev.x + distance * n0.dx, y: prev.y + distance * n0.dy)
            let oa2 = Coordinate3D(x: curr.x + distance * n0.dx, y: curr.y + distance * n0.dy)
            let ob1 = Coordinate3D(x: curr.x + distance * n1.dx, y: curr.y + distance * n1.dy)
            let ob2 = Coordinate3D(x: next.x + distance * n1.dx, y: next.y + distance * n1.dy)
            guard let intersection = intersect(oa1, oa2, ob1, ob2) else { return nil }

            newOuter.append(intersection)
        }
        newOuter.append(newOuter[0])

        guard let insetRing = Ring(newOuter),
              insetRing.area != 0.0,
              abs(insetRing.area) < abs(outerRing.area)
        else { return nil }

        var insetHoles: [Ring] = []
        if let innerRings = projected.innerRings {
            for hole in innerRings {
                let hc = hole.coordinates
                guard hc.count >= 4 else { return nil }

                var newHole: [Coordinate3D] = []
                let m = hc.count - 1
                for j in 0..<m {
                    let prev = hc[(j + m - 1) % m], curr = hc[j], next = hc[(j + 1) % m]
                    guard let n0 = outwardNormal(prev, curr, hole.isClockwise),
                          let n1 = outwardNormal(curr, next, hole.isClockwise)
                    else { return nil }

                    let oa1 = Coordinate3D(x: prev.x + distance * n0.dx, y: prev.y + distance * n0.dy)
                    let oa2 = Coordinate3D(x: curr.x + distance * n0.dx, y: curr.y + distance * n0.dy)
                    let ob1 = Coordinate3D(x: curr.x + distance * n1.dx, y: curr.y + distance * n1.dy)
                    let ob2 = Coordinate3D(x: next.x + distance * n1.dx, y: next.y + distance * n1.dy)
                    guard let intersection = intersect(oa1, oa2, ob1, ob2) else { return nil }

                    newHole.append(intersection)
                }
                newHole.append(newHole[0])

                if let holeRing = Ring(newHole),
                   holeRing.area != 0.0
                {
                    insetHoles.append(holeRing)
                }
            }
        }
        var insetRings = [insetRing]
        insetRings.append(contentsOf: insetHoles)
        let insetPolygon = Polygon(unchecked: insetRings)
        return insetPolygon.projected(to: polygon.projection)
    }

    /// Appends a square end‑cap rectangle extending past the endpoint.
    /// - Parameter bearing: Direction in which the tip is placed and from
    ///   which the left / right normals are derived.
    /// - Parameter tipDistance: How far past the endpoint the tip extends,
    ///   in meters (e.g. `distance × 0.5` for ``BufferEndType/square``).
    /// - Parameter width: The buffer / left‑right width, in meters.
    /// - Parameter forward: `true` for the end of the line, `false` for the start.
    private static func addSquareEndCap(
        at coordinate: Coordinate3D,
        bearing: CLLocationDegrees,
        tipDistance: Double,
        width: Double,
        forward: Bool,
        to polygons: inout [Polygon]
    ) {
        let tip = coordinate.destination(distance: tipDistance, bearing: bearing)
        let p = forward ? coordinate : tip
        let q = forward ? tip : coordinate
        let left = (bearing - 90.0).truncatingRemainder(dividingBy: 360.0)
        let right = (bearing + 90.0).truncatingRemainder(dividingBy: 360.0)
        if let rect = Polygon([[
            q.destination(distance: width, bearing: left),
            p.destination(distance: width, bearing: left),
            p.destination(distance: width, bearing: right),
            q.destination(distance: width, bearing: right),
            q.destination(distance: width, bearing: left),
        ]]) {
            polygons.append(rect)
        }
    }

    /// Adds a bevel triangle at an interior vertex of a LineString,
    /// filling the gap between adjacent segment rectangles on the
    /// outer side of the corner.
    private static func addBevelJoin(
        at prev: Coordinate3D,
        _ curr: Coordinate3D,
        _ next: Coordinate3D,
        distance: Double,
        to polygons: inout [Polygon]
    ) {
        guard let bevel = Self.bevelTriangle(from: prev, over: curr, to: next, distance: distance) else { return }
        polygons.append(bevel)
    }

    /// Adds a miter polygon at an interior vertex of a LineString,
    /// falling back to a bevel when the miter exceeds the limit.
    private static func addMiterJoin(
        at prev: Coordinate3D,
        _ curr: Coordinate3D,
        _ next: Coordinate3D,
        distance: Double,
        limit: Double,
        to polygons: inout [Polygon]
    ) {
        guard let miter = Self.miterFill(from: prev, over: curr, to: next, distance: distance, limit: limit) else { return }
        polygons.append(miter)
    }

    /// Adds bevel triangles for every vertex in a ring (polygon exterior or hole).
    private static func addRingBevels(
        for coordinates: [Coordinate3D],
        distance: Double,
        to polygons: inout [Polygon]
    ) {
        let n = coordinates.count - 1  // last coord is duplicate of first
        guard n >= 3 else { return }
        for i in 0 ..< n {
            let prev = coordinates[(i + n - 1) % n]
            let curr = coordinates[i]
            let next = coordinates[(i + 1) % n]
            Self.addBevelJoin(at: prev, curr, next, distance: distance, to: &polygons)
        }
    }

    /// Adds miter polygons for every vertex in a ring (polygon exterior or hole).
    private static func addRingMiters(
        for coordinates: [Coordinate3D],
        distance: Double,
        limit: Double,
        to polygons: inout [Polygon]
    ) {
        let n = coordinates.count - 1
        guard n >= 3 else { return }
        for i in 0 ..< n {
            let prev = coordinates[(i + n - 1) % n]
            let curr = coordinates[i]
            let next = coordinates[(i + 1) % n]
            Self.addMiterJoin(at: prev, curr, next, distance: distance, limit: limit, to: &polygons)
        }
    }

    /// Creates a bevel triangle at a vertex. The triangle spans from
    /// the two outer offset points (the bevel edge) to a point on the
    /// opposite side of the corner that lies deep inside the overlap
    /// region of both segment rectangles.  Only the outer bevel edge
    /// remains visible after union — the inner edges are hidden by
    /// the rectangle interiors.
    private static func bevelTriangle(
        from prev: Coordinate3D,
        over curr: Coordinate3D,
        to next: Coordinate3D,
        distance: Double
    ) -> Polygon? {
        let proj = curr.projection

        if proj == .epsg4326 {
            let bearingAB = prev.bearing(to: curr)
            let bearingBC = curr.bearing(to: next)
            var turnAngle = (bearingBC - bearingAB)
                .truncatingRemainder(dividingBy: 360)
            if turnAngle < 0 {
                turnAngle += 360
            }

            if turnAngle < 1
                || turnAngle > 359
                || abs(turnAngle - 180) < 1
            {
                return nil
            }

            let leftAB = ((bearingAB - 90)
                .truncatingRemainder(dividingBy: 360) + 360)
                .truncatingRemainder(dividingBy: 360)
            let rightAB = ((bearingAB + 90)
                .truncatingRemainder(dividingBy: 360) + 360)
                .truncatingRemainder(dividingBy: 360)
            let leftBC = ((bearingBC - 90)
                .truncatingRemainder(dividingBy: 360) + 360)
                .truncatingRemainder(dividingBy: 360)
            let rightBC = ((bearingBC + 90)
                .truncatingRemainder(dividingBy: 360) + 360)
                .truncatingRemainder(dividingBy: 360)

            if turnAngle < 180 {
                // Right turn: gap on left, overlap on right
                let p1 = curr.destination(distance: distance, bearing: leftAB)
                let p2 = curr.destination(distance: distance, bearing: leftBC)
                let opp1 = curr.destination(distance: distance, bearing: rightAB)
                let opp2 = curr.destination(distance: distance, bearing: rightBC)
                let inner = Coordinate3D(
                    x: (opp1.x + opp2.x) / 2.0,
                    y: (opp1.y + opp2.y) / 2.0,
                    projection: proj)
                return Polygon([[p1, inner, p2, p1]])
            }
            else {
                // Left turn: gap on right, overlap on left
                let p1 = curr.destination(distance: distance, bearing: rightAB)
                let p2 = curr.destination(distance: distance, bearing: rightBC)
                let opp1 = curr.destination(distance: distance, bearing: leftAB)
                let opp2 = curr.destination(distance: distance, bearing: leftBC)
                let inner = Coordinate3D(
                    x: (opp1.x + opp2.x) / 2.0,
                    y: (opp1.y + opp2.y) / 2.0,
                    projection: proj)
                return Polygon([[p1, inner, p2, p1]])
            }
        }
        else {
            let dx1 = curr.x - prev.x
            let dy1 = curr.y - prev.y
            let dx2 = next.x - curr.x
            let dy2 = next.y - curr.y
            let len1 = sqrt(dx1 * dx1 + dy1 * dy1)
            let len2 = sqrt(dx2 * dx2 + dy2 * dy2)
            guard len1 > GISTool.intersectionEpsilon,
                  len2 > GISTool.intersectionEpsilon
            else { return nil }

            let cross = dx1 * dy2 - dy1 * dx2
            if abs(cross) < GISTool.determinantEpsilon * len1 * len2 {
                return nil
            }

            let e1x = dx1 / len1
            let e1y = dy1 / len1
            let e2x = dx2 / len2
            let e2y = dy2 / len2

            if cross > 0 {
                // Left turn: gap on right side, overlap on left
                let p1 = Coordinate3D(
                    x: curr.x + distance * e1y,
                    y: curr.y - distance * e1x,
                    projection: proj)
                let p2 = Coordinate3D(
                    x: curr.x + distance * e2y,
                    y: curr.y - distance * e2x,
                    projection: proj)
                let opp1 = Coordinate3D(
                    x: curr.x - distance * e1y,
                    y: curr.y + distance * e1x,
                    projection: proj)
                let opp2 = Coordinate3D(
                    x: curr.x - distance * e2y,
                    y: curr.y + distance * e2x,
                    projection: proj)
                let inner = Coordinate3D(
                    x: (opp1.x + opp2.x) / 2.0,
                    y: (opp1.y + opp2.y) / 2.0,
                    projection: proj)
                return Polygon([[p1, inner, p2, p1]])
            }
            else {
                // Right turn: gap on left side, overlap on right
                let p1 = Coordinate3D(
                    x: curr.x - distance * e1y,
                    y: curr.y + distance * e1x,
                    projection: proj)
                let p2 = Coordinate3D(
                    x: curr.x - distance * e2y,
                    y: curr.y + distance * e2x,
                    projection: proj)
                let opp1 = Coordinate3D(
                    x: curr.x + distance * e1y,
                    y: curr.y - distance * e1x,
                    projection: proj)
                let opp2 = Coordinate3D(
                    x: curr.x + distance * e2y,
                    y: curr.y - distance * e2x,
                    projection: proj)
                let inner = Coordinate3D(
                    x: (opp1.x + opp2.x) / 2.0,
                    y: (opp1.y + opp2.y) / 2.0,
                    projection: proj)
                return Polygon([[p1, inner, p2, p1]])
            }
        }
    }

    /// Intersection point of two lines (in CRS units).
    /// Lines are defined by point pairs (a1, a2) and (b1, b2).
    private static func lineIntersect(
        _ a1: Coordinate3D,
        _ a2: Coordinate3D,
        _ b1: Coordinate3D,
        _ b2: Coordinate3D
    ) -> Coordinate3D? {
        let x1 = a1.x, y1 = a1.y, x2 = a2.x, y2 = a2.y
        let x3 = b1.x, y3 = b1.y, x4 = b2.x, y4 = b2.y
        let denom = (x1 - x2) * (y3 - y4) - (y1 - y2) * (x3 - x4)
        guard abs(denom) > GISTool.intersectionEpsilon else { return nil }
        let t = ((x1 - x3) * (y3 - y4) - (y1 - y3) * (x3 - x4)) / denom
        return Coordinate3D(x: x1 + t * (x2 - x1), y: y1 + t * (y2 - y1))
    }

    /// Creates a miter polygon at a vertex, extending the offset edges
    /// to their intersection point (the miter point).  Falls back to a
    /// bevel if the miter length exceeds `limit × distance`.
    private static func miterFill(
        from prev: Coordinate3D,
        over curr: Coordinate3D,
        to next: Coordinate3D,
        distance: Double,
        limit: Double
    ) -> Polygon? {
        let proj = curr.projection

        // Project to 3857 for Euclidean offset‑edge intersection
        let p = prev.projected(to: .epsg3857)
        let c = curr.projected(to: .epsg3857)
        let n = next.projected(to: .epsg3857)

        let dx1 = c.x - p.x; let dy1 = c.y - p.y
        let dx2 = n.x - c.x; let dy2 = n.y - c.y
        let len1 = sqrt(dx1 * dx1 + dy1 * dy1)
        let len2 = sqrt(dx2 * dx2 + dy2 * dy2)
        guard len1 > GISTool.intersectionEpsilon,
              len2 > GISTool.intersectionEpsilon else { return nil }

        let e1x = dx1 / len1; let e1y = dy1 / len1
        let e2x = dx2 / len2; let e2y = dy2 / len2

        let cross = dx1 * dy2 - dy1 * dx2
        guard abs(cross) > GISTool.determinantEpsilon * len1 * len2
        else { return nil }

        let d = distance

        // Outer side normals and opposite (inner) normals
        let onx1: Double, ony1: Double, onx2: Double, ony2: Double
        let inx1: Double, iny1: Double, inx2: Double, iny2: Double

        if cross > 0 {
            onx1 = e1y;  ony1 = -e1x
            onx2 = e2y;  ony2 = -e2x
            inx1 = -e1y; iny1 = e1x
            inx2 = -e2y; iny2 = e2x
        }
        else {
            onx1 = -e1y; ony1 = e1x
            onx2 = -e2y; ony2 = e2x
            inx1 = e1y;  iny1 = -e1x
            inx2 = e2y;  iny2 = -e2x
        }

        // Miter point = intersection of the two offset‑edge lines
        let oa1 = Coordinate3D(
            x: p.x + d * onx1,
            y: p.y + d * ony1,
            projection: .epsg3857)
        let oa2 = Coordinate3D(
            x: c.x + d * onx1,
            y: c.y + d * ony1,
            projection: .epsg3857)
        let ob1 = Coordinate3D(
            x: c.x + d * onx2,
            y: c.y + d * ony2,
            projection: .epsg3857)
        let ob2 = Coordinate3D(
            x: n.x + d * onx2,
            y: n.y + d * ony2,
            projection: .epsg3857)

        guard let miter3857 = Self.lineIntersect(oa1, oa2, ob1, ob2)
        else {
            return Self.bevelTriangle(
                from: prev,
                over: curr,
                to: next,
                distance: distance)
        }

        let mdx = miter3857.x - c.x
        let mdy = miter3857.y - c.y
        let miterLen = sqrt(mdx * mdx + mdy * mdy)

        if miterLen > limit * d {
            return Self.bevelTriangle(
                from: prev,
                over: curr,
                to: next,
                distance: distance)
        }

        let miterPt = miter3857.projected(to: proj)

        let p1 = Coordinate3D(
            x: c.x + d * onx1,
            y: c.y + d * ony1,
            projection: .epsg3857).projected(to: proj)
        let p2 = Coordinate3D(
            x: c.x + d * onx2,
            y: c.y + d * ony2,
            projection: .epsg3857).projected(to: proj)
        let inner = Coordinate3D(
            x: (c.x + d * inx1 + c.x + d * inx2) / 2.0,
            y: (c.y + d * iny1 + c.y + d * iny2) / 2.0,
            projection: .epsg3857).projected(to: proj)

        return Polygon([[p1, miterPt, p2, inner, p1]])
    }

    private static func cutAtAntimeridianIfNeeded(_ result: MultiPolygon?) -> MultiPolygon? {
        guard let mp = result else { return nil }
        guard mp.polygons.contains(where: { $0.crossesAntimeridian }) else { return mp }

        var cutPolygons: [Polygon] = []
        for polygon in mp.polygons {
            if polygon.crossesAntimeridian {
                let fc = polygon.cutAtAntimeridian()
                for feature in fc.features {
                    if let part = feature.geometry as? Polygon {
                        cutPolygons.append(part)
                    }
                }
            }
            else {
                cutPolygons.append(polygon)
            }
        }
        return MultiPolygon(unchecked: cutPolygons)
    }

}

extension LineSegment {

    /// Returns the line segment with a buffer applied.
    ///
    /// - Parameter distance: The buffer distance in meters.
    /// - Parameter endType: Line end style (default `.round`).
    /// - Parameter unionType: How to combine buffered parts (default `.individual`).
    /// - Parameter steps: Number of steps for circle approximation (default `64`).
    /// - Parameter gridSize: Snap coordinates to a grid before computing (default `nil`).
    /// - Returns: The buffered segment, or `nil` if it could not be computed.
    public func buffered(
        by distance: Double,
        endType: BufferEndType = .round,
        unionType: BufferUnionType = .individual,
        steps: Int = 64,
        gridSize: Double? = nil
    ) -> MultiPolygon? {
        guard distance > 0.0 else { return nil }

        let snappedSegment = gridSize.map { self.snappedToGrid(tolerance: $0) } ?? self

        let firstBearing = snappedSegment.bearing
        let leftBearing = (firstBearing - 90.0).truncatingRemainder(dividingBy: 360.0)
        let rightBearing = (firstBearing + 90.0).truncatingRemainder(dividingBy: 360.0)

        let corners = [
            snappedSegment.first.destination(distance: distance, bearing: leftBearing),
            snappedSegment.second.destination(distance: distance, bearing: leftBearing),
            snappedSegment.second.destination(distance: distance, bearing: rightBearing),
            snappedSegment.first.destination(distance: distance, bearing: rightBearing),
            snappedSegment.first.destination(distance: distance, bearing: leftBearing),
        ]

        guard let rectPolygon = Polygon([corners]) else { return nil }

        var polygons: [Polygon]
        if rectPolygon.crossesAntimeridian {
            polygons = rectPolygon.cutAtAntimeridian()
                .features
                .compactMap { $0.geometry as? Polygon }
        }
        else {
            polygons = [rectPolygon]
        }

        if case .round = endType,
           let firstCircle = snappedSegment.first.circle(radius: distance, steps: steps),
           let secondCircle = snappedSegment.second.circle(radius: distance, steps: steps)
        {
            polygons.append(firstCircle)
            polygons.append(secondCircle)
        }

        if unionType == .none { return MultiPolygon(polygons) }
        return Union.unionPolygons(polygons)
    }

}
