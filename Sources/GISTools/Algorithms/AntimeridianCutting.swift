#if canImport(CoreLocation)
import CoreLocation
#endif
import Foundation

// Per RFC 7946 §3.1.9, geometries that cross the anti-meridian (±180°)
// SHOULD be cut into parts such that no individual part crosses it.
//
// https://tools.ietf.org/html/rfc7946#section-3.1.9

/// Namespace for anti-meridian cutting helpers.
enum AntimeridianCutting {

    /// Which side of the anti-meridian a ring part belongs to.
    enum Side {
        case right
        case left
    }

    /// Result of cutting a single ring at the anti-meridian.
    struct RingCutResult {
        var right: [[Coordinate3D]] = []
        var left: [[Coordinate3D]] = []
    }

    // MARK: - Detection

    /// Returns `true` when the shortest path between `p1` and `p2`
    /// crosses the anti-meridian.
    static func segmentCrossesMeridian(
        _ p1: Coordinate3D,
        _ p2: Coordinate3D
    ) -> Bool {
        abs(p1.longitude - p2.longitude) > 180.0
    }

    /// Returns `true` when any consecutive coordinate pair
    /// crosses the anti-meridian.
    static func coordinatesCrossMeridian(_ coordinates: [Coordinate3D]) -> Bool {
        guard coordinates.count >= 2 else { return false }

        for i in 1..<coordinates.count {
            if segmentCrossesMeridian(coordinates[i - 1], coordinates[i]) {
                return true
            }
        }
        return false
    }

    // MARK: - Intersection

    /// Computes the two intersection points at ±180° for a segment
    /// that crosses the anti-meridian.
    ///
    /// The sign of each intersection point depends on whether `p1`
    /// lies on the positive-latitude side, so that the resulting
    /// split preserves the natural direction of the line.
    static func intersection(
        _ p1: Coordinate3D,
        _ p2: Coordinate3D
    ) -> (first: Coordinate3D, second: Coordinate3D)? {
        let dl = abs(p1.longitude - p2.longitude)
        guard dl > 180.0 else { return nil }

        var unwrapped = p2.longitude
        if p2.longitude - p1.longitude > 180.0 {
            unwrapped = p2.longitude - 360.0
        }
        else if p1.longitude - p2.longitude > 180.0 {
            unwrapped = p2.longitude + 360.0
        }

        let target = p1.longitude >= 0.0 ? 180.0 : -180.0
        let fraction = (target - p1.longitude) / (unwrapped - p1.longitude)
        let intersectionLatitude = p1.latitude + fraction * (p2.latitude - p1.latitude)

        let first: Coordinate3D
        let second: Coordinate3D
        if p1.longitude >= 0.0 {
            first = Coordinate3D(latitude: intersectionLatitude, longitude: 180.0)
            second = Coordinate3D(latitude: intersectionLatitude, longitude: -180.0)
        }
        else {
            first = Coordinate3D(latitude: intersectionLatitude, longitude: -180.0)
            second = Coordinate3D(latitude: intersectionLatitude, longitude: 180.0)
        }

        return (first, second)
    }

    // MARK: - Ring cutting

    /// Splits a ring's coordinate array at anti-meridian crossings.
    static func cutRing(_ ring: Ring) -> RingCutResult {
        let coords = ring.coordinates
        var result = RingCutResult()
        guard coords.count >= 4 else { return result }

        var currentPart: [Coordinate3D] = []
        var currentSide: Side!

        for i in 1..<coords.count {
            let prev = coords[i - 1]
            let curr = coords[i]

            if currentSide == nil {
                currentSide = prev.longitude >= 0 ? .right : .left
                currentPart = [prev]
            }

            if let intersection = AntimeridianCutting.intersection(prev, curr) {
                currentPart.append(intersection.first)
                appendPart(&result, currentPart, side: currentSide)
                currentSide = (currentSide == .right) ? .left : .right
                currentPart = [intersection.second, curr]
            }
            else {
                currentPart.append(curr)
            }
        }

        if let side = currentSide, currentPart.isNotEmpty {
            appendPart(&result, currentPart, side: side)
        }

        return result
    }

    /// Builds one or more polygons from ring parts on one side of the anti-meridian,
    /// closing them along ±180°.
    static func buildPolygons(
        outerParts: [[Coordinate3D]],
        innerParts: [[Coordinate3D]],
        side: Side
    ) -> [Polygon] {
        guard outerParts.isNotEmpty else { return [] }

        let longitude = (side == .right) ? 180.0 : -180.0
        let outerRing = connectRingParts(outerParts, alongLongitude: longitude)

        var polygonInnerRings: [Ring] = []
        for innerCoords in innerParts {
            if let ring = Ring(innerCoords) {
                polygonInnerRings.append(ring)
            }
        }

        var rings: [Ring] = [Ring(unchecked: outerRing)]
        rings.append(contentsOf: polygonInnerRings)

        if let polygon = Polygon(rings) {
            return [polygon]
        }
        return []
    }

    /// Connects disjoint ring parts on one side of the anti-meridian
    /// into a single closed ring by joining their endpoints along ±180°.
    static func connectRingParts(
        _ parts: [[Coordinate3D]],
        alongLongitude lon: Double
    ) -> [Coordinate3D] {
        guard parts.isNotEmpty else { return [] }
        guard parts.count > 1 else {
            var result = parts[0]
            if result.first != result.last {
                result.append(result[0])
            }
            return result
        }

        var result: [Coordinate3D] = []
        for part in parts {
            if result.isNotEmpty {
                let prevEnd = result.last!
                let thisStart = part.first!
                if prevEnd.longitude != thisStart.longitude
                    || prevEnd.latitude != thisStart.latitude
                {
                    result.append(Coordinate3D(latitude: prevEnd.latitude, longitude: lon))
                    result.append(Coordinate3D(latitude: thisStart.latitude, longitude: lon))
                }
            }
            result.append(contentsOf: part)
        }

        if result.first != result.last {
            let first = result.first!
            let last = result.last!
            if last.longitude != first.longitude
                || last.latitude != first.latitude
            {
                result.append(Coordinate3D(latitude: last.latitude, longitude: lon))
                result.append(Coordinate3D(latitude: first.latitude, longitude: lon))
            }
        }
        result.append(result.first!)

        return result
    }

    // MARK: - Private helpers

    private static func appendPart(
        _ result: inout RingCutResult,
        _ part: [Coordinate3D],
        side: Side
    ) {
        guard part.count >= 2 else { return }

        switch side {
        case .right: result.right.append(part)
        case .left: result.left.append(part)
        }
    }

}

// MARK: - LineString cutting

extension LineString {

    /// Whether the line string crosses the anti-meridian.
    public var crossesAntimeridian: Bool {
        AntimeridianCutting.coordinatesCrossMeridian(coordinates)
    }

    /// Cuts the line string at the anti-meridian.
    ///
    /// Returns a ``FeatureCollection`` with one feature per cut part.
    /// If the line does not cross the anti-meridian the collection
    /// contains a single feature.
    ///
    /// Per RFC 7946 §3.1.9, a line from 45°N,170°E to 45°N,170°W
    /// becomes two features with parts `[170,45]→[180,45]`
    /// and `[-180,45]→[-170,45]`.
    public func cutAtAntimeridian() -> FeatureCollection {
        FeatureCollection(_cutParts().map { Feature($0) })
    }

    /// Internal: returns each cut part as a separate `LineString`.
    fileprivate func _cutParts() -> [LineString] {
        guard coordinates.count >= 2 else { return [self] }
        guard crossesAntimeridian else { return [self] }

        var resultParts: [[Coordinate3D]] = []
        var currentPart: [Coordinate3D] = [coordinates[0]]

        for i in 1..<coordinates.count {
            let prev = currentPart.last!
            let curr = coordinates[i]

            if let intersection = AntimeridianCutting.intersection(prev, curr) {
                currentPart.append(intersection.first)
                resultParts.append(currentPart)
                currentPart = [intersection.second, curr]
            }
            else {
                currentPart.append(curr)
            }
        }

        if currentPart.isNotEmpty {
            resultParts.append(currentPart)
        }

        guard resultParts.count > 1 else { return [self] }
        return resultParts.map { LineString(unchecked: $0) }
    }

}

// MARK: - Polygon cutting

extension Polygon {

    /// Whether any ring of the polygon crosses the anti-meridian.
    public var crossesAntimeridian: Bool {
        rings.contains { AntimeridianCutting.coordinatesCrossMeridian($0.coordinates) }
    }

    /// Cuts the polygon at the anti-meridian.
    ///
    /// Returns a ``FeatureCollection`` with one feature per resulting
    /// polygon. If the polygon does not cross the anti-meridian the
    /// collection contains a single feature.
    public func cutAtAntimeridian() -> FeatureCollection {
        FeatureCollection(_cutParts().map { Feature($0) })
    }

    /// Internal: returns each cut part as a separate `Polygon`.
    fileprivate func _cutParts() -> [Polygon] {
        guard crossesAntimeridian else { return [self] }

        let outerResult = AntimeridianCutting.cutRing(outerRing!)

        var rightInnerRings: [[Coordinate3D]] = []
        var leftInnerRings: [[Coordinate3D]] = []

        if let innerRings {
            for hole in innerRings {
                if AntimeridianCutting.coordinatesCrossMeridian(hole.coordinates) {
                    let holeResult = AntimeridianCutting.cutRing(hole)
                    if holeResult.right.isNotEmpty {
                        let connected = AntimeridianCutting.connectRingParts(holeResult.right, alongLongitude: 180.0)
                        rightInnerRings.append(connected)
                    }
                    if holeResult.left.isNotEmpty {
                        let connected = AntimeridianCutting.connectRingParts(holeResult.left, alongLongitude: -180.0)
                        leftInnerRings.append(connected)
                    }
                }
                else {
                    if hole.coordinates.first?.longitude ?? 0 >= 0 {
                        rightInnerRings.append(hole.coordinates)
                    }
                    else {
                        leftInnerRings.append(hole.coordinates)
                    }
                }
            }
        }

        var polygons: [Polygon] = []

        let rightPolygons = AntimeridianCutting.buildPolygons(
            outerParts: outerResult.right,
            innerParts: rightInnerRings,
            side: .right)
        polygons.append(contentsOf: rightPolygons)

        let leftPolygons = AntimeridianCutting.buildPolygons(
            outerParts: outerResult.left,
            innerParts: leftInnerRings,
            side: .left)
        polygons.append(contentsOf: leftPolygons)

        return polygons.isEmpty ? [self] : polygons
    }

}

// MARK: - MultiLineString cutting

extension MultiLineString {

    /// Cuts each line string at the anti-meridian and returns the combined result.
    public func cutAtAntimeridian() -> FeatureCollection {
        var allFeatures: [Feature] = []
        for ls in lineStrings {
            for part in ls._cutParts() {
                allFeatures.append(Feature(part))
            }
        }
        return FeatureCollection(allFeatures)
    }

}

// MARK: - MultiPolygon cutting

extension MultiPolygon {

    /// Cuts each polygon at the anti-meridian and returns the combined result.
    public func cutAtAntimeridian() -> FeatureCollection {
        var allFeatures: [Feature] = []
        for polygon in polygons {
            for part in polygon._cutParts() {
                allFeatures.append(Feature(part))
            }
        }
        return FeatureCollection(allFeatures)
    }

}

// MARK: - Feature & FeatureCollection

extension Feature {

    /// Cuts the feature's geometry at the anti-meridian.
    ///
    /// The feature's properties are preserved on every resulting feature.
    /// The original feature's identifier is kept on the first result
    /// and cleared on subsequent parts.
    public func cutAtAntimeridian() -> FeatureCollection {
        let fc = geometry.cutAtAntimeridian()
        var features: [Feature] = []
        for (index, cutFeature) in fc.features.enumerated() {
            let featureId: Identifier? = (index == 0) ? id : nil
            features.append(Feature(cutFeature.geometry, id: featureId, properties: properties))
        }
        return FeatureCollection(features)
    }

}

extension FeatureCollection {

    /// Cuts each feature's geometry at the anti-meridian.
    ///
    /// - Returns: A new `FeatureCollection` with each feature cut at the anti-meridian.
    public func cutAtAntimeridian() -> FeatureCollection {
        var allFeatures: [Feature] = []
        for feature in features {
            let fc = feature.cutAtAntimeridian()
            allFeatures.append(contentsOf: fc.features)
        }
        var collection = FeatureCollection(allFeatures)
        if boundingBox != nil {
            collection.updateBoundingBox(onlyIfNecessary: false)
        }
        return collection
    }

}

// MARK: - GeometryCollection

extension GeometryCollection {

    /// Cuts each sub-geometry at the anti-meridian and returns the
    /// combined result as a ``FeatureCollection``.
    public func cutAtAntimeridian() -> FeatureCollection {
        var allFeatures: [Feature] = []
        for geometry in geometries {
            let fc = geometry.cutAtAntimeridian()
            allFeatures.append(contentsOf: fc.features)
        }
        return FeatureCollection(allFeatures)
    }

}

// MARK: - GeoJsonGeometry extension

extension GeoJsonGeometry {

    /// Cuts the geometry at the anti-meridian.
    ///
    /// Dispatches to the appropriate type-specific implementation.
    public func cutAtAntimeridian() -> FeatureCollection {
        switch self {
        case let ls as LineString:
            return ls.cutAtAntimeridian()
        case let mls as MultiLineString:
            return mls.cutAtAntimeridian()
        case let p as Polygon:
            return p.cutAtAntimeridian()
        case let mp as MultiPolygon:
            return mp.cutAtAntimeridian()
        case let gc as GeometryCollection:
            return gc.cutAtAntimeridian()
        default:
            return FeatureCollection([Feature(self)])
        }
    }

}
