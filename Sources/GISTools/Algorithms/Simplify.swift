#if canImport(CoreLocation)
import CoreLocation
#endif
import Foundation

// Ported from https://github.com/Turfjs/turf/blob/master/packages/turf-simplify
// and https://github.com/Turfjs/turf/blob/master/packages/turf-simplify/lib/simplify.js

// MARK: - simplified / simplify

extension GeoJson {

    /// Returns a simplified GeoJson.
    ///
    /// - Parameters:
    /// - Parameter tolerance: Affects the amount of simplification (in meters)
    /// - Parameter highQuality: Excludes distance-based preprocessing step which leads to highest quality simplification but runs ~10-20 times slower
    /// - Parameter gridSize: An optional grid size for snapping inputs
    ///
    /// - Returns: A new simplified GeoJson
    public func simplified(
        tolerance: CLLocationDistance = 1.0,
        highQuality: Bool = false,
        gridSize: Double? = nil
    ) -> Self {
        let snappedSelf = gridSize.map { self.snappedToGrid(tolerance: $0) } ?? self
        switch snappedSelf {
        case let lineString as LineString:
            var newLineString = LineString(Simplify.simplify(coordinates: lineString.coordinates, toleranceInMeters: tolerance, highQuality: highQuality)) ?? lineString
            newLineString.boundingBox = lineString.boundingBox
            newLineString.foreignMembers = lineString.foreignMembers
            return GeometryDispatch.checkedCast(newLineString, to: Self.self)

        case let multiLineString as MultiLineString:
            var newMultiLineString = MultiLineString(multiLineString.lineStrings.map({
                $0.simplified(tolerance: tolerance, highQuality: highQuality)
            })) ?? multiLineString
            newMultiLineString.boundingBox = multiLineString.boundingBox
            newMultiLineString.foreignMembers = multiLineString.foreignMembers
            return GeometryDispatch.checkedCast(newMultiLineString, to: Self.self)

        case let polygon as Polygon:
            var newPolygon = Polygon(polygon.rings.map({
                $0.simplified(tolerance: tolerance, highQuality: highQuality)
            })) ?? polygon
            newPolygon.boundingBox = polygon.boundingBox
            newPolygon.foreignMembers = polygon.foreignMembers
            return GeometryDispatch.checkedCast(newPolygon, to: Self.self)

        case let multiPolygon as MultiPolygon:
            var newMultiPolygon = MultiPolygon(multiPolygon.polygons.map({
                $0.simplified(tolerance: tolerance, highQuality: highQuality)
            })) ?? multiPolygon
            newMultiPolygon.boundingBox = multiPolygon.boundingBox
            newMultiPolygon.foreignMembers = multiPolygon.foreignMembers
            return GeometryDispatch.checkedCast(newMultiPolygon, to: Self.self)

        case let geometryCollection as GeometryCollection:
            var newGeometryCollection = GeometryCollection(geometryCollection.geometries.map({
                $0.simplified(tolerance: tolerance, highQuality: highQuality)
            }))
            newGeometryCollection.boundingBox = geometryCollection.boundingBox
            newGeometryCollection.foreignMembers = geometryCollection.foreignMembers
            return GeometryDispatch.checkedCast(newGeometryCollection, to: Self.self)

        case let feature as Feature:
            guard let geometry = feature.geometry else {
                var newFeature = Feature(
                    id: feature.id,
                    properties: feature.properties,
                    foreignMembers: feature.foreignMembers)
                newFeature.boundingBox = feature.boundingBox
                return GeometryDispatch.checkedCast(newFeature, to: Self.self)
            }

            var newFeature = Feature(
                geometry.simplified(tolerance: tolerance, highQuality: highQuality),
                id: feature.id,
                properties: feature.properties)
            newFeature.boundingBox = feature.boundingBox
            newFeature.foreignMembers = feature.foreignMembers
            return GeometryDispatch.checkedCast(newFeature, to: Self.self)

        case let featureCollection as FeatureCollection:
            var newFeatureCollection = FeatureCollection(featureCollection.features.map({
                $0.simplified(tolerance: tolerance, highQuality: highQuality)
            }))
            newFeatureCollection.boundingBox = featureCollection.boundingBox
            newFeatureCollection.foreignMembers = featureCollection.foreignMembers
            return GeometryDispatch.checkedCast(newFeatureCollection, to: Self.self)

        default:
            return snappedSelf
        }
    }

    /// Simplifies the GeoJson.
    ///
    /// **Important**: This method expects tolerance in meters. Use the *Simplify* struct directly if your GeoJSON is not in WGS84.
    ///
    /// - Parameters:
    /// - Parameter tolerance: Affects the amount of simplification (in meters)
    /// - Parameter highQuality: Excludes distance-based preprocessing step which leads to highest quality simplification but runs ~10-20 times slower
    /// - Parameter gridSize: An optional grid size for snapping inputs
    public mutating func simplify(
        tolerance: CLLocationDistance = 1.0,
        highQuality: Bool = false,
        gridSize: Double? = nil
    ) {
        self = simplified(
            tolerance: tolerance,
            highQuality: highQuality,
            gridSize: gridSize)
    }

}

// MARK: - topologyPreserveSimplify

extension GeoJson {

    /// Returns a simplified copy that guarantees topological correctness.
    ///
    /// Uses the Douglas-Peucker algorithm followed by a validity repair
    /// pass (``madeValid(gridSize:)``) to fix any self-intersections or
    /// degenerate rings that the simplification may have introduced.
    ///
    /// - Parameter tolerance: Simplification tolerance in meters (default `1.0`).
    /// - Parameter highQuality: Excludes distance-based preprocessing (slower but higher quality).
    /// - Parameter gridSize: Snap coordinates to a grid of the given size before simplifying.
    /// - Returns: A topologically valid simplified copy.
    public func topologyPreservedSimplified(
        tolerance: CLLocationDistance = 1.0,
        highQuality: Bool = false,
        gridSize: Double? = nil
    ) -> Self? {
        let snapped = gridSize.map { self.snappedToGrid(tolerance: $0) } ?? self
        let s = snapped.simplified(tolerance: tolerance, highQuality: highQuality)
        guard let valid = s.madeValid() else { return nil }

        return valid
    }

}

// MARK: - polygonHullSimplify (Visvalingam-Whyatt)

extension Polygon {

    /// Returns a simplified copy of the polygon using Visvalingam-Whyatt
    /// (area-based) simplification. The result stays within a given distance
    /// of the original boundary and preserves topological validity.
    ///
    /// Outer and inner rings are simplified independently and the holes are
    /// retained (with their winding) in the result.
    ///
    /// - Parameter tolerance: Simplification tolerance in meters (default `1.0`).
    /// - Parameter gridSize: Snap coordinates to a grid of the given size before simplifying.
    /// - Returns: A simplified topologically valid polygon, or `nil` if the polygon cannot be simplified.
    public func polygonHullSimplified(
        tolerance: CLLocationDistance = 1.0,
        gridSize: Double? = nil
    ) -> Polygon? {
        let snapped = gridSize.map { self.snappedToGrid(tolerance: $0) } ?? self
        guard let outerRing = snapped.outerRing else { return nil }

        var rings: [Ring] = []

        if let simplifiedOuter = Simplify.simplifiedRing(
            outerRing,
            toleranceInMeters: tolerance
        ) {
            rings.append(simplifiedOuter)
        }
        else {
            rings.append(outerRing)
        }

        if let innerRings = snapped.innerRings {
            for hole in innerRings {
                if let simplifiedHole = Simplify.simplifiedRing(
                    hole,
                    toleranceInMeters: tolerance
                ) {
                    rings.append(simplifiedHole)
                }
                else {
                    rings.append(hole)
                }
            }
        }

        guard let result = Polygon(rings) else { return nil }
        guard let valid = result.madeValid() else { return nil }
        return valid
    }

}

extension MultiPolygon {

    /// Returns a simplified copy of each constituent polygon using
    /// Visvalingam-Whyatt (area-based) simplification.
    ///
    /// - Parameter tolerance: Simplification tolerance in meters (default `1.0`).
    /// - Parameter gridSize: Snap coordinates to a grid of the given size before simplifying.
    /// - Returns: A simplified topologically valid multi-polygon, or `nil` if empty.
    public func polygonHullSimplified(
        tolerance: CLLocationDistance = 1.0,
        gridSize: Double? = nil
    ) -> MultiPolygon? {
        let valid = polygons.compactMap {
            $0.polygonHullSimplified(tolerance: tolerance, gridSize: gridSize)
        }
        guard valid.isNotEmpty else { return nil }

        return MultiPolygon(unchecked: valid)
    }

}

// MARK: - Public API: coverageSimplify

extension MultiPolygon {

    /// Returns a simplified copy of a polygon coverage while keeping
    /// shared edges between adjacent polygons aligned.
    ///
    /// Each polygon is simplified individually. Edges that were originally
    /// shared between adjacent polygons are then restored from the original
    /// (pre-simplification) coordinates so that they remain identical
    /// after simplification.
    ///
    /// - Parameter tolerance: Simplification tolerance in meters (default `1.0`).
    /// - Parameter highQuality: Excludes distance-based preprocessing (slower but higher quality).
    /// - Parameter gridSize: Snap coordinates to a grid of the given size before simplifying.
    /// - Returns: A simplified coverage with aligned shared edges, or `nil` if empty.
    public func coverageSimplified(
        tolerance: CLLocationDistance = 1.0,
        highQuality: Bool = false,
        gridSize: Double? = nil
    ) -> MultiPolygon? {
        let polys: [Polygon]
        if let gridSize {
            polys = polygons.map { $0.snappedToGrid(tolerance: gridSize) }
        }
        else {
            polys = polygons
        }

        guard polys.count > 1 else {
            return polys.first.map {
                MultiPolygon(unchecked: [
                    $0.simplified(tolerance: tolerance, highQuality: highQuality),
                ])
            }
        }

        // Count every undirected original segment. Segments with a count
        // greater than one are shared with another polygon.
        var edgeCounts: [Simplify.CoverageSegmentKey: Int] = [:]
        for polygon in polys {
            for ring in polygon.rings {
                let coordinates = ring.coordinates
                for index in 0 ..< (coordinates.count - 1) {
                    let key = Simplify.CoverageSegmentKey(
                        first: coordinates[index],
                        second: coordinates[index + 1])
                    edgeCounts[key, default: 0] += 1
                }
            }
        }

        var sharedChains: [Simplify.CoverageChainKey: Simplify.CoverageChainValue] = [:]
        let result = polys.map { polygon -> Polygon in
            let rings = polygon.rings.map { ring -> [Coordinate3D] in
                Simplify.simplifyCoverageRing(
                    ring,
                    edgeCounts: edgeCounts,
                    toleranceInMeters: tolerance,
                    highQuality: highQuality,
                    sharedChains: &sharedChains)
            }
            return Polygon(unchecked: rings)
        }

        return MultiPolygon(unchecked: result)
    }

}

// MARK: - Implementation: Ring simplification

extension Ring {

    fileprivate func simplified(
        tolerance: CLLocationDistance = 1.0,
        highQuality: Bool = false
    ) -> Ring {
        guard coordinates.count > 3,
              tolerance > 0.0
        else { return self }

        var simplificationTolerance = tolerance
        var simplifiedCoordinates = Simplify.simplify(coordinates: coordinates, toleranceInMeters: simplificationTolerance, highQuality: highQuality)

        while !Ring.validCoordinates(simplifiedCoordinates) {
            guard simplificationTolerance >= (tolerance / 2.0) else { return self }

            simplificationTolerance *= 0.9
            simplifiedCoordinates = Simplify.simplify(coordinates: coordinates, toleranceInMeters: simplificationTolerance, highQuality: highQuality)
        }

        if let first = simplifiedCoordinates.first,
           let last = simplifiedCoordinates.last,
           first != last
        {
            simplifiedCoordinates.append(first)
        }

        return Ring(simplifiedCoordinates) ?? self
    }

    fileprivate static func validCoordinates(_ coordinates: [Coordinate3D]) -> Bool {
        guard coordinates.count >= 3 else { return false }

        if coordinates.count == 3,
           coordinates[0] == coordinates[2]
        {
            return false
        }

        return true
    }

}

// MARK: - Implementation: Simplify algorithm

/// Static methods for simplifiying geometries.
public enum Simplify {

    /// Returns an array of simplified coordinates.
    ///
    /// - Parameters:
    /// - Parameter coordinates: An array of Coordinate3D
    /// - Parameter tolerance: Affects the amount of simplification (in units of the coordinate's coordinate system)
    /// - Parameter highQuality: Skip the distance-based preprocessing step which leads to highest quality simplification but runs quite a bit times slower
    ///
    /// - Returns: Returns an array of simplified coordinates
    public static func simplify(
        coordinates: [Coordinate3D],
        tolerance: CLLocationDegrees,
        highQuality: Bool = false
    ) -> [Coordinate3D] {
        guard coordinates.count > 2 else { return coordinates }

        let sqTolerance: Double = tolerance * tolerance

        if highQuality {
            return simplifyDouglasPeucker(
                coordinates: coordinates,
                tolerance: sqTolerance)
        }
        else {
            return simplifyDouglasPeucker(
                coordinates: simplifyRadialDistance(coordinates: coordinates, tolerance: sqTolerance),
                tolerance: sqTolerance)
        }
    }

    fileprivate static func simplify(
        coordinates: [Coordinate3D],
        toleranceInMeters: CLLocationDistance = 1.0,
        highQuality: Bool = false
    ) -> [Coordinate3D] {
        guard coordinates.count > 2,
              let firstCoordinate = coordinates.first
        else { return coordinates }

        switch firstCoordinate.projection.kind {
        case .geographic:
            let toleranceInDegrees = firstCoordinate.degrees(
                fromMeters: toleranceInMeters)
                .longitudeDegrees

            return simplify(
                coordinates: coordinates,
                tolerance: toleranceInDegrees,
                highQuality: highQuality)

        case .geocentric, .planar, .undefined:
            return simplify(
                coordinates: coordinates,
                tolerance: toleranceInMeters,
                highQuality: highQuality)
        }
    }

    /// simplification using Ramer-Douglas-Peucker algorithm
    private static func simplifyDouglasPeucker(
        coordinates: [Coordinate3D],
        tolerance: Double
    ) -> [Coordinate3D] {
        guard coordinates.count > 2 else { return coordinates }

        let last: Int = coordinates.count - 1
        var simplified: [Coordinate3D] = [coordinates[0]]

        simplifyDPStep(
            coordinates: coordinates,
            first: 0,
            last: last,
            tolerance: tolerance,
            simplified: &simplified)

        simplified.append(coordinates[last])

        return simplified
    }

    private static func simplifyRadialDistance(
        coordinates: [Coordinate3D],
        tolerance: Double
    ) -> [Coordinate3D] {
        guard var previousCoordinate = coordinates.first else { return coordinates }

        var newCoordinates: [Coordinate3D] = [previousCoordinate]
        var coordinate: Coordinate3D = coordinates[0]

        for index in 1 ..< coordinates.count {
            coordinate = coordinates[index]

            let distance = getSqDist(p1: coordinate, p2: previousCoordinate)
            if distance > tolerance {
                newCoordinates.append(coordinate)
                previousCoordinate = coordinate
            }
        }

        if previousCoordinate != coordinate {
            newCoordinates.append(coordinate)
        }

        return newCoordinates
    }

    private static func simplifyDPStep(
        coordinates: [Coordinate3D],
        first: Int,
        last: Int,
        tolerance: Double,
        simplified: inout [Coordinate3D]
    ) {
        guard last - first > 1 else { return }

        var maxSqDistance: Double = tolerance
        var index = 0

        for i in (first + 1) ..< last {
            let sqDist = getSQSegDist(
                p: coordinates[i],
                p1: coordinates[first],
                p2: coordinates[last])

            if sqDist > maxSqDistance {
                index = i
                maxSqDistance = sqDist
            }
        }

        if maxSqDistance > tolerance {
            if index - first > 1 {
                simplifyDPStep(
                    coordinates: coordinates,
                    first: first,
                    last: index,
                    tolerance: tolerance,
                    simplified: &simplified)
            }

            simplified.append(coordinates[index])

            if last - index > 1 {
                simplifyDPStep(
                    coordinates: coordinates,
                    first: index,
                    last: last,
                    tolerance: tolerance,
                    simplified: &simplified)
            }
        }
    }

    /// square distance from a point to a segment
    private static func getSQSegDist(
        p: Coordinate3D,
        p1: Coordinate3D,
        p2: Coordinate3D
    ) -> Double {
        var longitude: CLLocationDegrees = p1.longitude
        var latitude: CLLocationDegrees = p1.latitude
        var dLongitude: CLLocationDegrees = p2.longitude - longitude
        var dLatitude: CLLocationDegrees = p2.latitude - latitude

        if dLongitude != 0.0 || dLatitude != 0.0 {
            let t = ((p.longitude - longitude) * dLongitude + (p.latitude - latitude) * dLatitude) / ((dLongitude * dLongitude) + (dLatitude * dLatitude))
            if t > 1 {
                longitude = p2.longitude
                latitude = p2.latitude
            }
            else if t > 0 {
                longitude += dLongitude * t
                latitude += dLatitude * t
            }
        }

        dLongitude = p.longitude - longitude
        dLatitude = p.latitude - latitude

        return (dLongitude * dLongitude) + (dLatitude * dLatitude)
    }

    /// square distance between 2 points
    private static func getSqDist(
        p1: Coordinate3D,
        p2: Coordinate3D
    ) -> Double {
        let dx = p1.longitude - p2.longitude
        let dy = p1.latitude - p2.latitude
        return (dx * dx) + (dy * dy)
    }

    /// Visvalingam-Whyatt simplification (area-based).
    /// Removes vertices whose triangular effective area is below the
    /// threshold derived from `toleranceInMeters`. Better at preserving
    /// overall polygon shape than Douglas-Peucker.
    fileprivate static func simplifyVisvalingamWhyatt(
        coordinates: [Coordinate3D],
        toleranceInMeters: CLLocationDistance
    ) -> [Coordinate3D] {
        guard coordinates.count > 3 else { return coordinates }
        guard let first = coordinates.first else { return coordinates }

        let crsTolerance: Double = first.projection.crsLength(fromMeters: toleranceInMeters)

        let closeIfNeeded = coordinates.count >= 2 && coordinates.first == coordinates.last
        let coords = closeIfNeeded ? Array(coordinates.dropLast()) : coordinates
        guard coords.count >= 3 else { return coordinates }

        let n = coords.count
        var prev = Array(repeating: 0, count: n)
        var next = Array(repeating: 0, count: n)
        var area = Array(repeating: 0.0, count: n)
        var threshold = Array(repeating: 0.0, count: n)
        var removed = Array(repeating: false, count: n)

        for i in 0 ..< n {
            prev[i] = (i + n - 1) % n
            next[i] = (i + 1) % n
        }

        // Area = 0.5 * base * height. A vertex is removed when its
        // perpendicular distance (height) to the neighbour chord is below the
        // tolerance, so the area threshold depends on the chord length.
        func update(_ index: Int) {
            let base = distance(coords[prev[index]], coords[next[index]])
            threshold[index] = 0.5 * base * abs(crsTolerance)
            area[index] = triangleArea(coords[prev[index]], coords[index], coords[next[index]])
        }

        for i in 0 ..< n {
            update(i)
        }

        var remaining = n
        while remaining > 3 {
            var minIdx = -1
            var minArea = Double.infinity
            for i in 0 ..< n where !removed[i] {
                if area[i] >= 0, area[i] < minArea {
                    minArea = area[i]
                    minIdx = i
                }
            }
            if minIdx < 0 {
                break
            }

            if minArea > threshold[minIdx] {
                break
            }

            removed[minIdx] = true
            let p = prev[minIdx]
            let nxt = next[minIdx]
            next[p] = nxt
            prev[nxt] = p

            if !removed[prev[p]] {
                update(p)
            }
            if !removed[next[nxt]] {
                update(nxt)
            }
            area[minIdx] = -1.0

            remaining -= 1
        }

        var result: [Coordinate3D] = []
        for i in 0 ..< n where !removed[i] {
            result.append(coords[i])
        }
        return result
    }

    // MARK: - Coverage simplification

    struct CoverageCoordinateKey: Hashable {
        let x: Int64
        let y: Int64

        init(_ coordinate: Coordinate3D) {
            x = Int64((coordinate.x / GISTool.equalityDelta).rounded())
            y = Int64((coordinate.y / GISTool.equalityDelta).rounded())
        }
    }

    struct CoverageSegmentKey: Hashable {
        let first: CoverageCoordinateKey
        let second: CoverageCoordinateKey

        init(first: Coordinate3D, second: Coordinate3D) {
            let a = CoverageCoordinateKey(first)
            let b = CoverageCoordinateKey(second)
            if (a.x, a.y) <= (b.x, b.y) {
                self.first = a
                self.second = b
            }
            else {
                self.first = b
                self.second = a
            }
        }
    }

    struct CoverageChainKey: Hashable {
        let coordinates: [CoverageCoordinateKey]

        init(_ coordinates: [Coordinate3D]) {
            let forward = coordinates.map(CoverageCoordinateKey.init)
            let reversed = Array(forward.reversed())
            self.coordinates = forward.lexicographicallyPrecedes(reversed) {
                ($0.x, $0.y) < ($1.x, $1.y)
            }
                ? forward
                : reversed
        }
    }

    struct CoverageChainValue {
        let first: CoverageCoordinateKey
        let simplified: [Coordinate3D]
    }

    /// Simplifies one coverage ring while replacing every maximal shared
    /// chain with a chain simplified exactly once. Nonshared runs between
    /// shared chains are simplified independently, so adjacent polygons keep
    /// identical shared vertices (no T-junctions) even when the shared edge
    /// has intermediate original vertices.
    static func simplifyCoverageRing(
        _ ring: Ring,
        edgeCounts: [CoverageSegmentKey: Int],
        toleranceInMeters: CLLocationDistance,
        highQuality: Bool,
        sharedChains: inout [CoverageChainKey: CoverageChainValue]
    ) -> [Coordinate3D] {
        let coordinates = ring.coordinates
        guard coordinates.count >= 4 else { return coordinates }

        let segmentCount = coordinates.count - 1
        let shared = (0 ..< segmentCount).map { index in
            (edgeCounts[CoverageSegmentKey(
                first: coordinates[index],
                second: coordinates[index + 1])] ?? 0) > 1
        }

        if !shared.contains(true) {
            return close(
                simplify(
                    coordinates: coordinates,
                    toleranceInMeters: toleranceInMeters,
                    highQuality: highQuality))
        }

        if shared.allSatisfy({ $0 }) {
            let chain = Array(coordinates.dropLast())
            let simplified = simplifiedSharedChain(
                chain,
                toleranceInMeters: toleranceInMeters,
                highQuality: highQuality,
                sharedChains: &sharedChains)
            return close(Array(simplified))
        }

        // Rotate so the ring starts on a nonshared segment; every run then
        // lies between two shared/nonshared boundaries with no wrap-around.
        var start = 0
        while shared[start] {
            start += 1
        }

        var runs: [(shared: Bool, coordinates: [Coordinate3D])] = []
        var offset = 0
        while offset < segmentCount {
            let isShared = shared[(start + offset) % segmentCount]
            var end = offset
            while end + 1 < segmentCount,
                  shared[(start + end + 1) % segmentCount] == isShared
            {
                end += 1
            }

            var runCoordinates: [Coordinate3D] = []
            for index in offset ... end {
                runCoordinates.append(coordinates[(start + index) % segmentCount])
            }
            runCoordinates.append(coordinates[(start + end + 1) % segmentCount])
            runs.append((isShared, runCoordinates))
            offset = end + 1
        }

        var result: [Coordinate3D] = []
        for run in runs {
            let simplified: [Coordinate3D]
            if run.shared {
                simplified = simplifiedSharedChain(
                    run.coordinates,
                    toleranceInMeters: toleranceInMeters,
                    highQuality: highQuality,
                    sharedChains: &sharedChains)
            }
            else {
                simplified = simplify(
                    coordinates: run.coordinates,
                    toleranceInMeters: toleranceInMeters,
                    highQuality: highQuality)
            }

            if result.isEmpty {
                result = simplified
            }
            else {
                result.append(contentsOf: simplified.dropFirst())
            }
        }

        return close(result)
    }

    private static func simplifiedSharedChain(
        _ coordinates: [Coordinate3D],
        toleranceInMeters: CLLocationDistance,
        highQuality: Bool,
        sharedChains: inout [CoverageChainKey: CoverageChainValue]
    ) -> [Coordinate3D] {
        guard coordinates.count >= 2 else { return coordinates }

        let key = CoverageChainKey(coordinates)
        let value: CoverageChainValue

        if let cached = sharedChains[key] {
            value = cached
        }
        else {
            let simplified = simplify(
                coordinates: coordinates,
                toleranceInMeters: toleranceInMeters,
                highQuality: highQuality)
            value = CoverageChainValue(
                first: CoverageCoordinateKey(coordinates[0]),
                simplified: simplified)
            sharedChains[key] = value
        }

        if CoverageCoordinateKey(coordinates[0]) == value.first {
            return value.simplified
        }
        return value.simplified.reversed()
    }

    private static func close(_ coordinates: [Coordinate3D]) -> [Coordinate3D] {
        guard let first = coordinates.first else { return coordinates }
        var result = coordinates
        if result.last != first {
            result.append(first)
        }
        return result
    }

    /// Planar distance between two coordinates in the CRS's native units.
    private static func distance(_ a: Coordinate3D, _ b: Coordinate3D) -> Double {
        let dx = a.x - b.x
        let dy = a.y - b.y
        return sqrt(dx * dx + dy * dy)
    }

    /// Simplifies a ring with Visvalingam-Whyatt and returns a closed ring.
    static func simplifiedRing(
        _ ring: Ring,
        toleranceInMeters: CLLocationDistance
    ) -> Ring? {
        let simplified = simplifyVisvalingamWhyatt(
            coordinates: ring.coordinates,
            toleranceInMeters: toleranceInMeters)
        guard simplified.count >= 3 else { return nil }

        var closed = simplified
        if closed.first != closed.last {
            closed.append(closed[0])
        }
        return Ring(closed)
    }

    /// Triangle area (2D cross product magnitude).
    private static func triangleArea(
        _ a: Coordinate3D,
        _ b: Coordinate3D,
        _ c: Coordinate3D
    ) -> Double {
        let ax = b.longitude - a.longitude
        let ay = b.latitude - a.latitude
        let bx = c.longitude - a.longitude
        let by = c.latitude - a.latitude
        return abs(ax * by - ay * bx) / 2.0
    }

}

// MARK: - Implementation: Edge key for shared edge detection

private struct EdgeKey: Hashable {

    let a: Double
    let b: Double

    init(_ p1: Coordinate3D, _ p2: Coordinate3D) {
        if p1.longitude < p2.longitude
            || (p1.longitude == p2.longitude && p1.latitude < p2.latitude)
        {
            self.a = p1.longitude * 1_000_000 + p1.latitude
            self.b = p2.longitude * 1_000_000 + p2.latitude
        }
        else {
            self.a = p2.longitude * 1_000_000 + p2.latitude
            self.b = p1.longitude * 1_000_000 + p1.latitude
        }
    }

}
