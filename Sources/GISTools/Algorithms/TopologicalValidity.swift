#if canImport(CoreLocation)
import CoreLocation
#endif
import Foundation

private enum TopologicalValidity {

    static func coordinateReason(_ coordinate: Coordinate3D) -> String? {
        coordinate.isValid ? nil : "Coordinate is outside the projection's valid extent"
    }

    static func lineReason(_ lineString: LineString) -> String? {
        guard lineString.coordinates.count >= 2 else {
            return "LineString must contain at least two coordinates"
        }

        for coordinate in lineString.coordinates {
            if let reason = coordinateReason(coordinate) {
                return reason
            }
        }

        for index in 1 ..< lineString.coordinates.count
            where lineString.coordinates[index].isCoincident(
                to: lineString.coordinates[index - 1])
        {
            return "LineString contains a zero-length segment"
        }

        return nil
    }

    static func ringReason(
        _ coordinates: [Coordinate3D],
        label: String
    ) -> String? {
        guard coordinates.count >= 4 else {
            return "\(label) must contain at least four positions"
        }
        guard coordinates.first == coordinates.last else {
            return "\(label) is not closed"
        }
        guard Set(coordinates).count >= 3 else {
            return "\(label) has fewer than three distinct positions"
        }

        for coordinate in coordinates {
            if let reason = coordinateReason(coordinate) {
                return reason
            }
        }

        let ring = Ring(unchecked: coordinates)
        guard abs(ring.area) > GISTool.equalityDelta else {
            return "\(label) has zero area"
        }
        guard ring.lineString.kinks().points.isEmpty else {
            return "\(label) self-intersects"
        }

        return nil
    }

    static func polygonReason(_ polygon: Polygon) -> String? {
        let polygon = polygon.projection.isGeocentric
            ? polygon.projected(to: .epsg4326)
            : polygon

        guard let rawOuter = polygon.coordinates.first else {
            return "Polygon has no rings"
        }

        if let reason = ringReason(rawOuter, label: "Outer ring") {
            return reason
        }

        let outerRing = Ring(unchecked: rawOuter)
        let holes = polygon.coordinates.dropFirst().map { Ring(unchecked: $0) }
        for (index, hole) in holes.enumerated() {
            if let reason = ringReason(hole.coordinates, label: "Hole \(index + 1)") {
                return reason
            }

            guard let first = hole.coordinates.first else { continue }
            guard outerRing.locate(first) == .interior else {
                return "Hole \(index + 1) lies outside the outer ring"
            }

            if hasCrossing(outerRing.coordinates, hole.coordinates) {
                return "Hole \(index + 1) crosses the outer ring"
            }
        }

        for i in holes.indices {
            for j in holes.indices where j > i {
                let first = holes[i].coordinates.first!
                let second = holes[j].coordinates.first!

                if holes[i].locate(second) == .interior
                    || holes[j].locate(first) == .interior
                {
                    return "Holes overlap or are nested"
                }

                if hasCrossing(holes[i].coordinates, holes[j].coordinates) {
                    return "Hole boundaries cross"
                }
            }
        }

        return nil
    }

    static func multiPolygonReason(_ multiPolygon: MultiPolygon) -> String? {
        let multiPolygon = multiPolygon.projection.isGeocentric
            ? multiPolygon.projected(to: .epsg4326)
            : multiPolygon

        guard multiPolygon.polygons.isNotEmpty else {
            return "MultiPolygon has no polygons"
        }

        for (index, polygon) in multiPolygon.polygons.enumerated() {
            if let reason = polygonReason(polygon) {
                return "Polygon \(index + 1): \(reason)"
            }
        }

        for i in multiPolygon.polygons.indices {
            for j in multiPolygon.polygons.indices where j > i {
                if let intersection = Intersection.intersectPolygons(
                    multiPolygon.polygons[i].polygons + multiPolygon.polygons[j].polygons,
                    firstCount: multiPolygon.polygons[i].polygons.count),
                    hasAreaOrLength(intersection)
                {
                    return "MultiPolygon components overlap or share an edge"
                }

                if polygonsShareEdge(
                    multiPolygon.polygons[i],
                    multiPolygon.polygons[j])
                {
                    return "MultiPolygon components share an edge"
                }
            }
        }

        return nil
    }

    static func hasAreaOrLength(_ geometry: PolygonGeometry) -> Bool {
        switch geometry {
        case let polygon as Polygon:
            return polygon.area > GISTool.equalityDelta
        case let multiPolygon as MultiPolygon:
            return multiPolygon.area > GISTool.equalityDelta
        default:
            return false
        }
    }

    static func lineIsSimple(_ lineString: LineString) -> Bool {
        lineReason(lineString) == nil && lineString.kinks().points.isEmpty
    }

    static func multiLineIsSimple(_ multiLineString: MultiLineString) -> Bool {
        guard multiLineString.lineStrings.allSatisfy(lineIsSimple) else { return false }

        for i in multiLineString.lineStrings.indices {
            for j in multiLineString.lineStrings.indices where j > i {
                let first = multiLineString.lineStrings[i]
                let second = multiLineString.lineStrings[j]

                for segmentA in first.lineSegments {
                    for segmentB in second.lineSegments {
                        if let intersection = segmentA.intersection(
                            segmentB,
                            epsilon: GISTool.equalityDelta)
                        {
                            let allowed = isEndpoint(intersection, of: first)
                                && isEndpoint(intersection, of: second)
                            if !allowed {
                                return false
                            }
                        }
                        else if segmentA.compare(segmentB, tolerance: GISTool.equalityDelta) != .notEqual {
                            return false
                        }
                    }
                }
            }
        }

        return true
    }

    static func polygonIsSimple(_ polygon: Polygon) -> Bool {
        let polygon = polygon.projection.isGeocentric
            ? polygon.projected(to: .epsg4326)
            : polygon

        guard let rawOuter = polygon.coordinates.first else { return false }

        let outerRing = Ring(unchecked: rawOuter)
        guard rawOuter.first == rawOuter.last,
              outerRing.lineString.kinks().points.isEmpty
        else { return false }

        for rawHole in polygon.coordinates.dropFirst() {
            guard rawHole.first == rawHole.last else { return false }

            let hole = Ring(unchecked: rawHole)
            if !hole.lineString.kinks().points.isEmpty {
                return false
            }
            if hasCrossing(outerRing.coordinates, hole.coordinates) {
                return false
            }
        }

        return true
    }

    static func multiPolygonIsSimple(_ multiPolygon: MultiPolygon) -> Bool {
        let multiPolygon = multiPolygon.projection.isGeocentric
            ? multiPolygon.projected(to: .epsg4326)
            : multiPolygon

        guard multiPolygon.polygons.allSatisfy(polygonIsSimple) else { return false }

        for i in multiPolygon.polygons.indices {
            for j in multiPolygon.polygons.indices where j > i {
                if let intersection = Intersection.intersectPolygons(
                    multiPolygon.polygons[i].polygons + multiPolygon.polygons[j].polygons,
                    firstCount: multiPolygon.polygons[i].polygons.count),
                    hasAreaOrLength(intersection)
                {
                    return false
                }

                if polygonsShareEdge(
                    multiPolygon.polygons[i],
                    multiPolygon.polygons[j])
                {
                    return false
                }
            }
        }

        return true
    }

    /// Returns `true` when two rings cross, while allowing point touches at
    /// segment endpoints.
    static func hasCrossing(_ first: [Coordinate3D], _ second: [Coordinate3D]) -> Bool {
        guard first.count >= 2, second.count >= 2 else { return false }

        for i in 0 ..< (first.count - 1) {
            let segmentA = LineSegment(first: first[i], second: first[i + 1])

            for j in 0 ..< (second.count - 1) {
                let segmentB = LineSegment(first: second[j], second: second[j + 1])
                guard let intersection = segmentA.intersection(
                    segmentB,
                    epsilon: GISTool.equalityDelta)
                else { continue }

                let endpointA = intersection.isCoincident(to: segmentA.first)
                    || intersection.isCoincident(to: segmentA.second)
                let endpointB = intersection.isCoincident(to: segmentB.first)
                    || intersection.isCoincident(to: segmentB.second)

                if !endpointA, !endpointB {
                    return true
                }
            }
        }

        return false
    }

    private static func polygonsShareEdge(
        _ first: Polygon,
        _ second: Polygon
    ) -> Bool {
        for segmentA in first.lineSegments {
            for segmentB in second.lineSegments {
                let comparison = segmentA.compare(
                    segmentB,
                    tolerance: GISTool.equalityDelta)
                if comparison == .equal
                    || comparison == .thisOnOther
                    || comparison == .otherOnThis
                {
                    return true
                }
            }
        }
        return false
    }

    private static func isEndpoint(
        _ coordinate: Coordinate3D,
        of lineString: LineString
    ) -> Bool {
        coordinate.isCoincident(to: lineString.firstCoordinate)
            || coordinate.isCoincident(to: lineString.lastCoordinate)
    }

}

// MARK: - Point / MultiPoint

extension Point {

    public var isValid: Bool {
        isValidReason == nil
    }

    public var isValidReason: String? {
        TopologicalValidity.coordinateReason(coordinate)
    }

    public var isSimple: Bool {
        isValid
    }

}

extension MultiPoint {

    public var isValid: Bool {
        isValidReason == nil
    }

    public var isValidReason: String? {
        guard isStructurallyValid else {
            return "MultiPoint must contain at least one coordinate"
        }

        for coordinate in coordinates {
            if let reason = TopologicalValidity.coordinateReason(coordinate) {
                return reason
            }
        }

        return nil
    }

    public var isSimple: Bool {
        guard isValid else { return false }

        return Set(coordinates).count == coordinates.count
    }

}

// MARK: - LineString / MultiLineString

extension LineString {

    public var isValid: Bool {
        isValidReason == nil
    }

    public var isValidReason: String? {
        TopologicalValidity.lineReason(self)
    }

    public var isSimple: Bool {
        TopologicalValidity.lineIsSimple(self)
    }

}

extension MultiLineString {

    public var isValid: Bool {
        isValidReason == nil
    }

    public var isValidReason: String? {
        guard isStructurallyValid else {
            return "MultiLineString must contain at least one line"
        }

        for (index, lineString) in lineStrings.enumerated() {
            if let reason = TopologicalValidity.lineReason(lineString) {
                return "LineString \(index + 1): \(reason)"
            }
        }

        return nil
    }

    public var isSimple: Bool {
        TopologicalValidity.multiLineIsSimple(self)
    }

}

// MARK: - Polygon / MultiPolygon

extension Polygon {

    public var isValid: Bool {
        isValidReason == nil
    }

    public var isValidReason: String? {
        TopologicalValidity.polygonReason(self)
    }

    public var isSimple: Bool {
        TopologicalValidity.polygonIsSimple(self)
    }

}

extension MultiPolygon {

    public var isValid: Bool {
        isValidReason == nil
    }

    public var isValidReason: String? {
        TopologicalValidity.multiPolygonReason(self)
    }

    public var isSimple: Bool {
        TopologicalValidity.multiPolygonIsSimple(self)
    }

}

// MARK: - Collections and wrappers

extension GeometryCollection {

    public var isValid: Bool {
        isValidReason == nil
    }

    public var isValidReason: String? {
        for (index, geometry) in geometries.enumerated() {
            if let reason = geometry.isValidReason {
                return "Geometry \(index + 1): \(reason)"
            }
        }

        return nil
    }

    public var isSimple: Bool {
        geometries.allSatisfy(\.isSimple)
    }

}

extension Feature {

    public var isValid: Bool {
        isValidReason == nil
    }

    public var isValidReason: String? {
        geometry?.isValidReason
    }

    public var isSimple: Bool {
        geometry?.isSimple ?? true
    }

}

extension FeatureCollection {

    public var isValid: Bool {
        isValidReason == nil
    }

    public var isValidReason: String? {
        for (index, feature) in features.enumerated() {
            if let reason = feature.isValidReason {
                return "Feature \(index + 1): \(reason)"
            }
        }

        return nil
    }

    public var isSimple: Bool {
        features.allSatisfy(\.isSimple)
    }

}
