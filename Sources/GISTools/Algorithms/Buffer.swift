#if canImport(CoreLocation)
import CoreLocation
#endif
import Foundation

/// Controls how convex corners are joined during buffering.
/// The fidelity of rounded joins is controlled by the ``steps`` parameter.
public enum BufferJoinType: Sendable {

    /// Extend offset edges until they intersect, clamped by a miter limit.
    /// - Parameter limit: Maximum ratio of miter length to buffer distance (default `2.0`).
    case miter(limit: Double = 2.0)

    /// Cut off mitered corners with a straight line at the buffer distance.
    case bevel

    /// Extend corners by the buffer distance.
    case square

    /// Round corners (fidelity controlled by ``steps``).
    case round

}

/// Controls how the ends of open buffer paths are terminated.
/// Fidelity of round ends is controlled by the ``steps`` parameter.
public enum BufferEndType: Sendable {

    /// Closed polygon: the path forms a closed ring (no end caps).
    case polygon

    /// Extend both ends of an open path and join them together.
    case joined

    /// Flat end at the last vertex, perpendicular to the line direction.
    case butt

    /// Extended by half the buffer width beyond the last vertex.
    case square

    /// Rounded end cap (fidelity controlled by ``steps``).
    case round

}

/// Options for how buffered parts are combined into the result.
public enum BufferUnionType: Sendable {

    /// Return each buffered part as a separate polygon (no union).
    case none

    /// Combine the buffered parts of each input geometry.
    case individual

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
        return Self.buffer(geometry, by: distance, endType: endType, unionType: unionType, steps: steps)
    }

    private static func buffer(
        _ geometry: GeoJson,
        by distance: Double,
        endType: BufferEndType,
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
            result = unionType == .overlapping ? Union.unionPolygons(bufferedPoints) : MultiPolygon(bufferedPoints)

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
                Self.addSquareEndCap(at: coords[0], bearing: startBearing, distance: distance, forward: false, to: &polygons)
                Self.addSquareEndCap(at: coords[coords.count - 1], bearing: endBearing, distance: distance, forward: true, to: &polygons)
            }
            else if case .joined = endType {
                bufferCoordinates.removeFirst()
                bufferCoordinates.removeLast()
                let coords = lineString.coordinates
                let startBearing = coords[0].bearing(to: coords[1])
                let endBearing = coords[coords.count - 2].bearing(to: coords[coords.count - 1])
                Self.addSquareEndCap(at: coords[0], bearing: startBearing, distance: distance * 2.0, forward: false, to: &polygons)
                Self.addSquareEndCap(at: coords[coords.count - 1], bearing: endBearing, distance: distance * 2.0, forward: true, to: &polygons)
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

            for coordinate in bufferCoordinates {
                guard let circle = coordinate.circle(radius: distance, steps: steps) else { continue }
                polygons.append(circle)
            }
            result = unionType.isIn([.individual, .overlapping]) ? Union.unionPolygons(polygons) : MultiPolygon(polygons)

        case let multiLineString as MultiLineString:
            let buffered = multiLineString.lineStrings.compactMap {
                $0.buffered(by: distance, endType: endType, unionType: unionType, steps: steps)
            }.flatMap(\.polygons)
            guard buffered.isNotEmpty else { return nil }
            result = unionType == .overlapping ? Union.unionPolygons(buffered) : MultiPolygon(buffered)

        case let polygon as Polygon:
            let bufferCoordinates = polygon.allCoordinates
            guard bufferCoordinates.count >= 2 else { return nil }
            var polygons = polygon.lineSegments.flatMap { segment in
                segment.buffered(by: distance, endType: .butt, unionType: .none)?.polygons ?? []
            }
            for coordinate in bufferCoordinates {
                guard let circle = coordinate.circle(radius: distance, steps: steps) else { continue }
                polygons.append(circle)
            }
            polygons.append(polygon)
            result = unionType.isIn([.individual, .overlapping]) ? Union.unionPolygons(polygons) : MultiPolygon(polygons)

        case let multiPolygon as MultiPolygon:
            let buffered = multiPolygon.polygons.compactMap {
                $0.buffered(by: distance, endType: endType, unionType: unionType, steps: steps)
            }.flatMap(\.polygons)
            guard buffered.isNotEmpty else { return nil }
            result = unionType == .overlapping ? Union.unionPolygons(buffered) : MultiPolygon(buffered)

        case let geometryCollection as GeometryCollection:
            let buffered = geometryCollection.geometries.compactMap {
                $0.buffered(by: distance, endType: endType, unionType: unionType, steps: steps)
            }.flatMap(\.polygons)
            guard buffered.isNotEmpty else { return nil }
            result = unionType == .overlapping ? Union.unionPolygons(buffered) : MultiPolygon(buffered)

        case let feature as Feature:
            return feature.geometry.buffered(by: distance, endType: endType, unionType: unionType, steps: steps)

        case let featureCollection as FeatureCollection:
            let buffered = featureCollection.features.compactMap {
                $0.geometry.buffered(by: distance, endType: endType, unionType: unionType, steps: steps)
            }.flatMap(\.polygons)
            guard buffered.isNotEmpty else { return nil }
            result = unionType == .overlapping ? Union.unionPolygons(buffered) : MultiPolygon(buffered)

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
            result = unionType == .overlapping ? Union.unionPolygons(buffered) : MultiPolygon(unchecked: buffered)

        case let geometryCollection as GeometryCollection:
            let buffered = geometryCollection.geometries.compactMap {
                $0.buffered(by: -distance, endType: endType, unionType: unionType, steps: steps)
            }.flatMap(\.polygons)
            guard buffered.isNotEmpty else { return nil }
            result = unionType == .overlapping ? Union.unionPolygons(buffered) : MultiPolygon(unchecked: buffered)

        default:
            return nil
        }

        return Self.cutAtAntimeridianIfNeeded(result)
    }

    private static func insetPolygon(_ polygon: Polygon, by distance: Double) -> Polygon? {
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
            let prev = outerCoords[(i + n - 1) % n], curr = outerCoords[i], next = outerCoords[(i + 1) % n]
            guard let n0 = inwardNormal(prev, curr), let n1 = inwardNormal(curr, next) else { return nil }
            let oa1 = Coordinate3D(x: prev.x + distance * n0.dx, y: prev.y + distance * n0.dy)
            let oa2 = Coordinate3D(x: curr.x + distance * n0.dx, y: curr.y + distance * n0.dy)
            let ob1 = Coordinate3D(x: curr.x + distance * n1.dx, y: curr.y + distance * n1.dy)
            let ob2 = Coordinate3D(x: next.x + distance * n1.dx, y: next.y + distance * n1.dy)
            guard let intersection = intersect(oa1, oa2, ob1, ob2) else { return nil }
            newOuter.append(intersection)
        }
        newOuter.append(newOuter[0])

        guard let insetRing = Ring(newOuter), insetRing.area != 0.0 else { return nil }
        guard abs(insetRing.area) < abs(outerRing.area) else { return nil }

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
                          let n1 = outwardNormal(curr, next, hole.isClockwise) else { return nil }
                    let oa1 = Coordinate3D(x: prev.x + distance * n0.dx, y: prev.y + distance * n0.dy)
                    let oa2 = Coordinate3D(x: curr.x + distance * n0.dx, y: curr.y + distance * n0.dy)
                    let ob1 = Coordinate3D(x: curr.x + distance * n1.dx, y: curr.y + distance * n1.dy)
                    let ob2 = Coordinate3D(x: next.x + distance * n1.dx, y: next.y + distance * n1.dy)
                    guard let intersection = intersect(oa1, oa2, ob1, ob2) else { return nil }
                    newHole.append(intersection)
                }
                newHole.append(newHole[0])
                if let holeRing = Ring(newHole), holeRing.area != 0.0 {
                    insetHoles.append(holeRing)
                }
            }
        }
        var insetRings = [insetRing]
        insetRings.append(contentsOf: insetHoles)
        let insetPolygon = Polygon(unchecked: insetRings)
        return insetPolygon.projected(to: polygon.projection)
    }

    /// Appends a square end‑cap rectangle extending `distance × 0.5` past the endpoint.
    /// - Parameter forward: `true` for the end of the line, `false` for the start.
    private static func addSquareEndCap(
        at coordinate: Coordinate3D,
        bearing: CLLocationDegrees,
        distance: Double,
        forward: Bool,
        to polygons: inout [Polygon]
    ) {
        let tip = coordinate.destination(distance: distance * 0.5, bearing: bearing)
        let p = forward ? coordinate : tip
        let q = forward ? tip : coordinate
        let left = (bearing - 90.0).truncatingRemainder(dividingBy: 360.0)
        let right = (bearing + 90.0).truncatingRemainder(dividingBy: 360.0)
        if let rect = Polygon([[
            q.destination(distance: distance, bearing: left),
            p.destination(distance: distance, bearing: left),
            p.destination(distance: distance, bearing: right),
            q.destination(distance: distance, bearing: right),
            q.destination(distance: distance, bearing: left),
        ]]) {
            polygons.append(rect)
        }
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
            polygons = rectPolygon.cutAtAntimeridian().features.compactMap { $0.geometry as? Polygon }
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
