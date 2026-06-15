#if canImport(CoreLocation)
import CoreLocation
#endif
import Foundation

/// Line end styles for GeoJSON buffer.
public enum BufferLineEndStyle: Sendable {

    /// Line ends will be flat.
    case flat

    /// Line ends will be rounded.
    case round

}

/// Options for how to form an union of polygons.
public enum BufferUnionType: Sendable {

    /// Don't form a union from all geometries that make a buffer.
    case none

    /// Combine the buffered parts for each input geometry into one Polygon.
    case individual

    /// Combine all overlapping buffered geometries.
    case overlapping

}

extension GeoJson {

    /// Returns the receiver with a buffer.
    ///
    /// - Parameter distance: The buffer distance, in meters. A positive value expands
    ///                       the geometry; a negative value shrinks it (only supported
    ///                       for polygons and multi-polygons).
    /// - Parameter lineEndStyle: Controls how line ends will be drawn (default round)
    /// - Parameter unionType: How to combine buffered geometries (default individual)
    /// - Parameter steps: The number of steps for the circles (default 64)
    /// - Parameter gridSize: Snap coordinates to a grid of the given size before buffering (default `nil`).
    ///
    /// - Returns: The buffered geometry as a `MultiPolygon`, or `nil` if the buffer could not be computed.
    public func buffered(
        by distance: Double,
        lineEndStyle: BufferLineEndStyle = .round,
        unionType: BufferUnionType = .individual,
        steps: Int = 64,
        gridSize: Double? = nil
    ) -> MultiPolygon? {
        let geometry = gridSize.map { self.snappedToGrid(tolerance: $0) } ?? self
        guard distance != 0.0 else { return nil }

        if distance < 0.0 {
            return Self.inset(
                geometry,
                by: -distance,
                lineEndStyle: lineEndStyle,
                unionType: unionType,
                steps: steps)
        }
        return Self.buffer(
            geometry,
            by: distance,
            lineEndStyle: lineEndStyle,
            unionType: unionType,
            steps: steps)
    }

    private static func buffer(
        _ geometry: GeoJson,
        by distance: Double,
        lineEndStyle: BufferLineEndStyle,
        unionType: BufferUnionType,
        steps: Int
    ) -> MultiPolygon? {
        let result: MultiPolygon?

        switch geometry {
        case let point as Point:
            guard let circle = point.circle(radius: distance, steps: steps) else { return nil }
            result = MultiPolygon([circle])

        case let multiPoint as MultiPoint:
            let bufferedPoints = multiPoint
                .points
                .compactMap({ $0.circle(radius: distance, steps: steps) })
            guard bufferedPoints.isNotEmpty else { return nil }

            result = unionType == .overlapping
                ? Union.unionPolygons(bufferedPoints)
                : MultiPolygon(bufferedPoints)

        case let lineString as LineString:
            var polygons = lineString
                .lineSegments
                .flatMap({ segment in
                    segment.buffered(
                        by: distance,
                        lineEndStyle: .flat,
                        unionType: .none)?
                        .polygons ?? []
                })

            var bufferCoordinates = lineString.coordinates
            guard bufferCoordinates.count >= 2 else {
                result = MultiPolygon(polygons)
                break
            }

            if lineEndStyle == .flat {
                bufferCoordinates.removeFirst()
                bufferCoordinates.removeLast()
            }

            for coordinate in bufferCoordinates {
                guard let circle = coordinate.circle(radius: distance, steps: steps) else { continue }
                polygons.append(circle)
            }

            result = unionType.isIn([.individual, .overlapping])
                ? Union.unionPolygons(polygons)
                : MultiPolygon(polygons)

        case let multiLineString as MultiLineString:
            let bufferedLineStrings = multiLineString
                .lineStrings
                .compactMap({
                    $0.buffered(
                        by: distance,
                        lineEndStyle: lineEndStyle,
                        unionType: unionType,
                        steps: steps)
                })
                .map(\.polygons)
                .flatMap({ $0 })
            guard bufferedLineStrings.isNotEmpty else { return nil }

            result = unionType == .overlapping
                ? Union.unionPolygons(bufferedLineStrings)
                : MultiPolygon(bufferedLineStrings)

        case let polygon as Polygon:
            let bufferCoordinates = polygon.allCoordinates
            guard bufferCoordinates.count >= 2 else { return nil }

            var polygons = polygon
                .lineSegments
                .flatMap({ segment in
                    segment.buffered(
                        by: distance,
                        lineEndStyle: .flat,
                        unionType: .none)?
                        .polygons ?? []
                })

            for coordinate in bufferCoordinates {
                guard let circle = coordinate.circle(radius: distance, steps: steps) else { continue }
                polygons.append(circle)
            }

            polygons.append(polygon)

            result = unionType.isIn([.individual, .overlapping])
                ? Union.unionPolygons(polygons)
                : MultiPolygon(polygons)

        case let multiPolygon as MultiPolygon:
            let bufferedPolygons = multiPolygon
                .polygons
                .compactMap({
                    $0.buffered(
                        by: distance,
                        lineEndStyle: lineEndStyle,
                        unionType: unionType,
                        steps: steps)
                })
                .map(\.polygons)
                .flatMap({ $0 })
            guard bufferedPolygons.isNotEmpty else { return nil }

            result = unionType == .overlapping
                ? Union.unionPolygons(bufferedPolygons)
                : MultiPolygon(bufferedPolygons)

        case let geometryCollection as GeometryCollection:
            let bufferedPolygons = geometryCollection
                .geometries
                .compactMap({
                    $0.buffered(
                        by: distance,
                        lineEndStyle: lineEndStyle,
                        unionType: unionType,
                        steps: steps)?
                        .polygons
                })
                .flatMap({ $0 })
            guard bufferedPolygons.isNotEmpty else { return nil }

            result = unionType == .overlapping
                ? Union.unionPolygons(bufferedPolygons)
                : MultiPolygon(bufferedPolygons)

        case let feature as Feature:
            return feature.geometry.buffered(
                by: distance,
                lineEndStyle: lineEndStyle,
                unionType: unionType,
                steps: steps)

        case let featureCollection as FeatureCollection:
            let bufferedPolygons = featureCollection
                .features
                .compactMap({
                    $0.geometry.buffered(
                        by: distance,
                        lineEndStyle: lineEndStyle,
                        unionType: unionType,
                        steps: steps)?
                        .polygons
                })
                .flatMap({ $0 })
            guard bufferedPolygons.isNotEmpty else { return nil }

            result = unionType == .overlapping
                ? Union.unionPolygons(bufferedPolygons)
                : MultiPolygon(bufferedPolygons)

        // Can't happen
        default:
            return nil
        }

        return Self.cutAtAntimeridianIfNeeded(result)
    }

    private static func inset(
        _ geometry: GeoJson,
        by distance: Double,
        lineEndStyle: BufferLineEndStyle,
        unionType: BufferUnionType,
        steps: Int
    ) -> MultiPolygon? {
        let result: MultiPolygon?

        switch geometry {
        case let polygon as Polygon:
            guard let inset = Self.insetPolygon(polygon, by: distance) else { return nil }
            result = MultiPolygon([inset])

        case let multiPolygon as MultiPolygon:
            let insets = multiPolygon.polygons.compactMap {
                Self.insetPolygon($0, by: distance)
            }
            guard insets.isNotEmpty else { return nil }
            result = MultiPolygon(unchecked: insets)

        case let feature as Feature:
            return feature.geometry.buffered(
                by: -distance,
                lineEndStyle: lineEndStyle,
                unionType: unionType,
                steps: steps)

        case let featureCollection as FeatureCollection:
            let bufferedPolygons = featureCollection
                .features
                .compactMap {
                    $0.geometry.buffered(
                        by: -distance,
                        lineEndStyle: lineEndStyle,
                        unionType: unionType,
                        steps: steps)?
                        .polygons
                }
                .flatMap { $0 }
            guard bufferedPolygons.isNotEmpty else { return nil }

            result = unionType == .overlapping
                ? Union.unionPolygons(bufferedPolygons)
                : MultiPolygon(unchecked: bufferedPolygons)

        case let geometryCollection as GeometryCollection:
            let bufferedPolygons = geometryCollection
                .geometries
                .compactMap {
                    $0.buffered(
                        by: -distance,
                        lineEndStyle: lineEndStyle,
                        unionType: unionType,
                        steps: steps)?
                        .polygons
                }
                .flatMap { $0 }
            guard bufferedPolygons.isNotEmpty else { return nil }

            result = unionType == .overlapping
                ? Union.unionPolygons(bufferedPolygons)
                : MultiPolygon(unchecked: bufferedPolygons)

        default:
            return nil
        }

        return Self.cutAtAntimeridianIfNeeded(result)
    }

    /// Returns a polygon inset (eroded) by a positive distance, or `nil` if the
    /// inset would degenerate. The outer ring is shrunk inward; inner rings
    /// (holes) are expanded.
    ///
    /// Computation is performed in EPSG:3857 (Mercator) for planar geometry.
    private static func insetPolygon(
        _ polygon: Polygon,
        by distance: Double
    ) -> Polygon? {
        guard distance > 0.0 else { return polygon }

        let projected = polygon.projected(to: .epsg3857)
        guard let outerRing = projected.outerRing else { return nil }

        let outerCoords = outerRing.coordinates
        guard outerCoords.count >= 4 else { return nil }

        func inwardNormal(
            _ a: Coordinate3D,
            _ b: Coordinate3D
        ) -> (dx: Double, dy: Double)? {
            let vx = b.x - a.x, vy = b.y - a.y
            let len = sqrt(vx * vx + vy * vy)
            guard len > 0 else { return nil }

            if outerRing.isClockwise {
                return (vy / len, -vx / len)
            }
            return (-vy / len, vx / len)
        }

        func outwardNormal(
            _ a: Coordinate3D,
            _ b: Coordinate3D,
            holeIsClockwise: Bool
        ) -> (dx: Double, dy: Double)? {
            let vx = b.x - a.x, vy = b.y - a.y
            let len = sqrt(vx * vx + vy * vy)
            guard len > 0 else { return nil }

            if holeIsClockwise {
                return (-vy / len, vx / len)
            }
            return (vy / len, -vx / len)
        }

        func intersect(
            _ a1: Coordinate3D, _ a2: Coordinate3D,
            _ b1: Coordinate3D, _ b2: Coordinate3D
        ) -> Coordinate3D? {
            let x1 = a1.x, y1 = a1.y, x2 = a2.x, y2 = a2.y
            let x3 = b1.x, y3 = b1.y, x4 = b2.x, y4 = b2.y
            let denom = (x1 - x2) * (y3 - y4) - (y1 - y2) * (x3 - x4)
            guard abs(denom) > 1e-12 else { return nil }

            let t = ((x1 - x3) * (y3 - y4) - (y1 - y3) * (x3 - x4)) / denom
            let x = x1 + t * (x2 - x1)
            let y = y1 + t * (y2 - y1)
            return Coordinate3D(x: x, y: y, projection: .epsg3857)
        }

        var newOuter: [Coordinate3D] = []
        let n = outerCoords.count - 1

        for i in 0..<n {
            let prev = outerCoords[(i + n - 1) % n]
            let curr = outerCoords[i]
            let next = outerCoords[(i + 1) % n]

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

        guard let insetRing = Ring(newOuter), insetRing.area != 0.0 else { return nil }
        guard abs(insetRing.area) < abs(outerRing.area) else { return nil }

        // Expand holes (inner rings): offset each hole outward (opposite direction)
        var insetHoles: [Ring] = []
        if let innerRings = projected.innerRings {
            for hole in innerRings {
                let holeCoords = hole.coordinates
                guard holeCoords.count >= 4 else { return nil }

                var newHole: [Coordinate3D] = []
                let m = holeCoords.count - 1

                for j in 0..<m {
                    let prev = holeCoords[(j + m - 1) % m]
                    let curr = holeCoords[j]
                    let next = holeCoords[(j + 1) % m]

                    guard let n0 = outwardNormal(prev, curr, holeIsClockwise: hole.isClockwise),
                          let n1 = outwardNormal(curr, next, holeIsClockwise: hole.isClockwise)
                    else { return nil }

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

    /// Returns self with any polygons that cross the antimeridian cut into
    /// valid pieces. All pieces are returned as a single ``MultiPolygon``.
    private static func cutAtAntimeridianIfNeeded(
        _ result: MultiPolygon?
    ) -> MultiPolygon? {
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

    /// Returns the line segment with a buffer.
    ///
    /// - Parameter distance: The buffer distance, in meters
    /// - Parameter lineEndStyle: Controls how line ends will be drawn (default round)
    /// - Parameter unionType: Whether to combine all overlapping buffers into one Polygon (default true)
    /// - Parameter steps: The number of steps for the circles (default 64)
    /// - Parameter gridSize: Snap coordinates to a grid of the given size before buffering (default `nil`).
    ///
    /// - Returns: The buffered line segment as a `MultiPolygon`, or `nil` if the buffer could not be computed.
    public func buffered(
        by distance: Double,
        lineEndStyle: BufferLineEndStyle = .round,
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

        if lineEndStyle == .round,
           let firstCircle = snappedSegment.first.circle(radius: distance, steps: steps),
           let secondCircle = snappedSegment.second.circle(radius: distance, steps: steps)
        {
            polygons.append(firstCircle)
            polygons.append(secondCircle)
        }

        if unionType == .none {
            return MultiPolygon(polygons)
        }

        return Union.unionPolygons(polygons)
    }

}
