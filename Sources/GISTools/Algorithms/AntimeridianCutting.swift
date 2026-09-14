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
    /// crosses the wraparound axis of a CRS whose horizontal axis wraps
    /// at ±`extent` (e.g. the anti-meridian at ±180° for EPSG:4326).
    static func segmentCrossesMeridian(
        _ p1: Coordinate3D,
        _ p2: Coordinate3D,
        extent: Double
    ) -> Bool {
        abs(p1.x - p2.x) > extent
    }

    /// Returns `true` when any consecutive coordinate pair crosses the
    /// wraparound axis of a CRS whose horizontal axis wraps at ±`extent`.
    static func coordinatesCrossMeridian(
        _ coordinates: [Coordinate3D],
        extent: Double
    ) -> Bool {
        guard coordinates.count >= 2 else { return false }

        for i in 1..<coordinates.count {
            if segmentCrossesMeridian(coordinates[i - 1], coordinates[i], extent: extent) {
                return true
            }
        }
        return false
    }

    // MARK: - Detection (EPSG:4326)

    /// Returns `true` when the shortest path between `p1` and `p2`
    /// crosses the anti-meridian.
    static func segmentCrossesMeridian(
        _ p1: Coordinate3D,
        _ p2: Coordinate3D
    ) -> Bool {
        segmentCrossesMeridian(p1, p2, extent: 180.0)
    }

    /// Returns `true` when any consecutive coordinate pair
    /// crosses the anti-meridian.
    static func coordinatesCrossMeridian(_ coordinates: [Coordinate3D]) -> Bool {
        coordinatesCrossMeridian(coordinates, extent: 180.0)
    }

    // MARK: - Intersection

    /// Computes the two intersection points at ±`extent` for a segment
    /// that crosses the wraparound axis of a CRS whose horizontal axis
    /// wraps at ±`extent`.
    ///
    /// The sign of each intersection point depends on whether `p1`
    /// lies on the positive-x side, so that the resulting
    /// split preserves the natural direction of the line.
    static func intersection(
        _ p1: Coordinate3D,
        _ p2: Coordinate3D,
        extent: Double
    ) -> (first: Coordinate3D, second: Coordinate3D)? {
        let dx = abs(p1.x - p2.x)
        guard dx > extent else { return nil }

        var unwrapped = p2.x
        if p2.x - p1.x > extent {
            unwrapped = p2.x - (2.0 * extent)
        }
        else if p1.x - p2.x > extent {
            unwrapped = p2.x + (2.0 * extent)
        }

        let target = p1.x >= 0.0 ? extent : -extent
        let fraction = (target - p1.x) / (unwrapped - p1.x)
        let intersectionY = p1.y + fraction * (p2.y - p1.y)

        let first: Coordinate3D
        let second: Coordinate3D
        if p1.x >= 0.0 {
            first = Coordinate3D(x: extent, y: intersectionY, projection: p1.projection)
            second = Coordinate3D(x: -extent, y: intersectionY, projection: p1.projection)
        }
        else {
            first = Coordinate3D(x: -extent, y: intersectionY, projection: p1.projection)
            second = Coordinate3D(x: extent, y: intersectionY, projection: p1.projection)
        }

        return (first, second)
    }

    // MARK: - Intersection (EPSG:4326)

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
        intersection(p1, p2, extent: 180.0)
    }

    // MARK: - Ring cutting

    /// Splits a ring's coordinate array at crossings of the wraparound
    /// axis of a CRS whose horizontal axis wraps at ±`extent`.
    static func cutRing(_ ring: Ring, extent: Double) -> RingCutResult {
        let coords = ring.coordinates
        var result = RingCutResult()
        guard coords.count >= 4 else { return result }

        var currentPart: [Coordinate3D] = []
        var currentSide: Side!

        for i in 1..<coords.count {
            let prev = coords[i - 1]
            let curr = coords[i]

            if currentSide == nil {
                currentSide = prev.x >= 0 ? .right : .left
                currentPart = [prev]
            }

            if let intersection = AntimeridianCutting.intersection(prev, curr, extent: extent) {
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

    // MARK: - Build polygons

    /// Builds one or more polygons from ring parts on one side of the
    /// wraparound axis at ±`extent`, closing them along it.
    static func buildPolygons(
        outerParts: [[Coordinate3D]],
        innerParts: [[Coordinate3D]],
        side: Side,
        extent: Double,
        projection: Projection
    ) -> [Polygon] {
        guard outerParts.isNotEmpty else { return [] }

        let wrapX = (side == .right) ? extent : -extent
        let outerRing = connectRingParts(outerParts, alongX: wrapX, projection: projection)

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

    /// Connects disjoint ring parts on one side of a wraparound axis,
    /// joining their endpoints along it.
    static func connectRingParts(
        _ parts: [[Coordinate3D]],
        alongX x: Double,
        projection: Projection
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
                if prevEnd.x != thisStart.x
                    || prevEnd.y != thisStart.y
                {
                    result.append(Coordinate3D(x: x, y: prevEnd.y, projection: projection))
                    result.append(Coordinate3D(x: x, y: thisStart.y, projection: projection))
                }
            }
            result.append(contentsOf: part)
        }

        if result.first != result.last {
            let first = result.first!
            let last = result.last!
            if last.x != first.x
                || last.y != first.y
            {
                result.append(Coordinate3D(x: x, y: last.y, projection: projection))
                result.append(Coordinate3D(x: x, y: first.y, projection: projection))
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
    ///
    /// For projections with a wraparound horizontal axis (e.g.
    /// ``Projection/epsg4326`` at ±180° or ``Projection/epsg3857`` at
    /// ±`originShift` meters), checks if any consecutive segment spans
    /// more than the wraparound extent. Returns `false` for projections
    /// without one (e.g. ``Projection/epsg4978`` and ``Projection/noSRID``).
    public var crossesAntimeridian: Bool {
        guard let extent = projection.wraparoundExtent else { return false }
        return AntimeridianCutting.coordinatesCrossMeridian(coordinates, extent: extent)
    }

    /// Cuts the line string at the anti-meridian.
    ///
    /// Returns a ``FeatureCollection`` with one feature per cut part.
    /// If the line does not cross the anti-meridian the collection
    /// contains a single feature.
    ///
    /// For projections with a wraparound horizontal axis (e.g.
    /// ``Projection/epsg4326`` or ``Projection/epsg3857``), operates
    /// natively on the receiver's coordinates and splits at the wraparound
    /// extent. For other projections, returns the original geometry unchanged.
    ///
    /// Per RFC 7946 §3.1.9, a line from 45°N,170°E to 45°N,170°W
    /// becomes two features with parts `[170,45]→[180,45]`
    /// and `[-180,45]→[-170,45]`.
    public func cutAtAntimeridian() -> FeatureCollection {
        guard let extent = projection.wraparoundExtent else {
            return FeatureCollection([Feature(self)])
        }
        return FeatureCollection(_cutParts(extent: extent).map { Feature($0) })
    }

    /// Internal: returns each cut part as a separate `LineString`.
    fileprivate func _cutParts(extent: Double) -> [LineString] {
        guard coordinates.count >= 2,
              AntimeridianCutting.coordinatesCrossMeridian(coordinates, extent: extent)
        else { return [self] }

        var resultParts: [[Coordinate3D]] = []
        var currentPart: [Coordinate3D] = [coordinates[0]]

        for i in 1..<coordinates.count {
            let prev = currentPart.last!
            let curr = coordinates[i]

            if let intersection = AntimeridianCutting.intersection(prev, curr, extent: extent) {
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
    ///
    /// For projections with a wraparound horizontal axis (e.g.
    /// ``Projection/epsg4326`` at ±180° or ``Projection/epsg3857`` at
    /// ±`originShift` meters), checks if any ring spans more than the
    /// wraparound extent. Returns `false` for projections without one
    /// (e.g. ``Projection/epsg4978`` and ``Projection/noSRID``).
    public var crossesAntimeridian: Bool {
        guard let extent = projection.wraparoundExtent else { return false }
        return rings.contains { AntimeridianCutting.coordinatesCrossMeridian($0.coordinates, extent: extent) }
    }

    /// Cuts the polygon at the anti-meridian.
    ///
    /// Returns a ``FeatureCollection`` with one feature per resulting
    /// polygon. If the polygon does not cross the anti-meridian the
    /// collection contains a single feature.
    ///
    /// For projections with a wraparound horizontal axis (e.g.
    /// ``Projection/epsg4326`` or ``Projection/epsg3857``), operates
    /// natively on the receiver's coordinates and splits at the wraparound
    /// extent. For other projections, returns the original geometry unchanged.
    public func cutAtAntimeridian() -> FeatureCollection {
        guard let extent = projection.wraparoundExtent else {
            return FeatureCollection([Feature(self)])
        }
        return FeatureCollection(_cutParts(extent: extent).map { Feature($0) })
    }

    /// Internal: returns each cut part as a separate `Polygon`.
    fileprivate func _cutParts(extent: Double) -> [Polygon] {
        guard crossesAntimeridian else { return [self] }

        let outerResult = AntimeridianCutting.cutRing(outerRing!, extent: extent)

        var rightInnerRings: [[Coordinate3D]] = []
        var leftInnerRings: [[Coordinate3D]] = []

        if let innerRings {
            for hole in innerRings {
                if AntimeridianCutting.coordinatesCrossMeridian(hole.coordinates, extent: extent) {
                    let holeResult = AntimeridianCutting.cutRing(hole, extent: extent)
                    if holeResult.right.isNotEmpty {
                        let connected = AntimeridianCutting.connectRingParts(
                            holeResult.right,
                            alongX: extent,
                            projection: projection)
                        rightInnerRings.append(connected)
                    }
                    if holeResult.left.isNotEmpty {
                        let connected = AntimeridianCutting.connectRingParts(
                            holeResult.left,
                            alongX: -extent,
                            projection: projection)
                        leftInnerRings.append(connected)
                    }
                }
                else {
                    if hole.coordinates.first?.x ?? 0 >= 0 {
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
            side: .right,
            extent: extent,
            projection: projection)
        polygons.append(contentsOf: rightPolygons)

        let leftPolygons = AntimeridianCutting.buildPolygons(
            outerParts: outerResult.left,
            innerParts: leftInnerRings,
            side: .left,
            extent: extent,
            projection: projection)
        polygons.append(contentsOf: leftPolygons)

        return polygons.isEmpty ? [self] : polygons
    }

}

// MARK: - MultiLineString cutting

extension MultiLineString {

    /// Whether any line string in the multi-line-string crosses the anti-meridian.
    public var crossesAntimeridian: Bool {
        lineStrings.contains { $0.crossesAntimeridian }
    }

    /// Cuts each line string at the anti-meridian and returns the combined result.
    ///
    /// For projections with a wraparound horizontal axis (e.g.
    /// ``Projection/epsg4326`` or ``Projection/epsg3857``), operates
    /// natively on the receiver's coordinates. For other projections,
    /// returns the original geometry unchanged.
    public func cutAtAntimeridian() -> FeatureCollection {
        guard let extent = projection.wraparoundExtent else {
            return FeatureCollection([Feature(self)])
        }

        var allFeatures: [Feature] = []
        for ls in lineStrings {
            for part in ls._cutParts(extent: extent) {
                allFeatures.append(Feature(part))
            }
        }
        return FeatureCollection(allFeatures)
    }

}

// MARK: - MultiPolygon cutting

extension MultiPolygon {

    /// Whether any polygon in the multi-polygon crosses the anti-meridian.
    public var crossesAntimeridian: Bool {
        polygons.contains { $0.crossesAntimeridian }
    }

    /// Cuts each polygon at the anti-meridian and returns the combined result.
    ///
    /// For projections with a wraparound horizontal axis (e.g.
    /// ``Projection/epsg4326`` or ``Projection/epsg3857``), operates
    /// natively on the receiver's coordinates. For other projections,
    /// returns the original geometry unchanged.
    public func cutAtAntimeridian() -> FeatureCollection {
        guard let extent = projection.wraparoundExtent else {
            return FeatureCollection([Feature(self)])
        }

        var allFeatures: [Feature] = []
        for polygon in polygons {
            for part in polygon._cutParts(extent: extent) {
                allFeatures.append(Feature(part))
            }
        }
        return FeatureCollection(allFeatures)
    }

}

// MARK: - Feature & FeatureCollection

extension Feature {

    /// Whether the feature's geometry crosses the anti-meridian.
    public var crossesAntimeridian: Bool {
        geometry.crossesAntimeridian
    }

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

    /// Whether any feature's geometry in the collection crosses the anti-meridian.
    public var crossesAntimeridian: Bool {
        features.contains { $0.crossesAntimeridian }
    }

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

    /// Whether any sub-geometry in the collection crosses the anti-meridian.
    public var crossesAntimeridian: Bool {
        geometries.contains { $0.crossesAntimeridian }
    }

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

    /// Whether the geometry crosses the anti-meridian.
    ///
    /// For ``Projection/epsg4326`` and ``Projection/epsg3857``, checks if any
    /// consecutive segment spans more than the antimeridian threshold.
    /// Returns `false` for ``Projection/epsg4978`` and ``Projection/noSRID``.
    public var crossesAntimeridian: Bool {
        switch self {
        case let ls as LineString:
            return ls.crossesAntimeridian
        case let mls as MultiLineString:
            return mls.crossesAntimeridian
        case let p as Polygon:
            return p.crossesAntimeridian
        case let mp as MultiPolygon:
            return mp.crossesAntimeridian
        case let gc as GeometryCollection:
            return gc.crossesAntimeridian
        default:
            return false
        }
    }

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
