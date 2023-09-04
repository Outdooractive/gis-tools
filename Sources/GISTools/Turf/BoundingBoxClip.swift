#if !os(Linux)
import CoreLocation
#endif
import Foundation

// Ported from https://github.com/Turfjs/turf/blob/master/packages/turf-bbox-clip

extension Point {

    /// Clips the *Point* to the bounding box.
    ///
    /// - Parameter boundingBox: The bounding box
    ///
    /// - Returns: The point if is inside the bounding box, *nil* otherwise.
    public func clipped(to boundingBox: BoundingBox) -> Point? {
        guard boundingBox.contains(coordinate) else { return nil }
        return self
    }

}

extension MultiPoint {

    /// Clips the *MultiPoint* to the bounding box.
    ///
    /// - Parameter boundingBox: The bounding box
    ///
    /// - Returns: A *MultiPoint* with all points inside the bounding box, *nil* if no point was inside the bounding box.
    public func clipped(to boundingBox: BoundingBox) -> MultiPoint? {
        let clipped = coordinates.filter({ boundingBox.contains($0) })
        guard clipped.isNotEmpty else { return nil }

        var multiPoint = MultiPoint(
            clipped,
            calculateBoundingBox: (self.boundingBox != nil))
        multiPoint?.foreignMembers = foreignMembers
        return multiPoint
    }

}

extension LineString {

    /// Clips the *LineString* to the bounding box.
    ///
    /// - Parameter boundingBox: The bounding box
    ///
    /// - Returns: The line clipped to the bounding box.
    public func clipped(to boundingBox: BoundingBox) -> MultiLineString? {
        let boundingBox = boundingBox.projected(to: projection)

        var lineString = MultiLineString(
            boundingBox.clipLine(coordinates: coordinates),
            calculateBoundingBox: (self.boundingBox != nil))
        lineString?.foreignMembers = foreignMembers
        return lineString
    }

}

extension MultiLineString {

    /// Clips the *MultiLineString* to the bounding box.
    ///
    /// - Parameter boundingBox: The bounding box
    ///
    /// - Returns: The lines clipped to the bounding box.
    public func clipped(to boundingBox: BoundingBox) -> MultiLineString? {
        let boundingBox = boundingBox.projected(to: projection)

        var lineString = MultiLineString(
            coordinates.flatMap({ boundingBox.clipLine(coordinates: $0) }),
            calculateBoundingBox: (self.boundingBox != nil))
        lineString?.foreignMembers = foreignMembers
        return lineString
    }

}

extension Polygon {

    /// Clips the *Polygon* to the bounding box. May result in degenerate edges.
    ///
    /// - Parameter boundingBox: The bounding box
    ///
    /// - Returns: The polygon clipped to the bounding box, or *nil* if the polygon would be empty.
    public func clipped(to boundingBox: BoundingBox) -> Polygon? {
        let boundingBox = boundingBox.projected(to: projection)

        var result: [Ring] = []

        for ring in rings {
            var clipped = boundingBox.clipPolygon(coordinates: ring.coordinates)
            guard !clipped.isEmpty else { continue }

            if clipped.first != clipped.last {
                clipped.append(clipped[0])
            }
            if let ring = Ring(clipped) {
                result.append(ring)
            }
        }

        guard result.isNotEmpty else { return nil }

        var polygon = Polygon(
            result,
            calculateBoundingBox: (self.boundingBox != nil))
        polygon?.foreignMembers = foreignMembers
        return polygon
    }

}

extension MultiPolygon {

    /// Clips the *MultiPolygon* to the bounding box. May result in degenerate edges.
    ///
    /// - Parameter boundingBox: The bounding box
    ///
    /// - Returns: The polygons clipped to the bounding box, or *nil* if the polygon would be empty.
    public func clipped(to boundingBox: BoundingBox) -> MultiPolygon? {
        let boundingBox = boundingBox.projected(to: projection)

        let clipped = polygons.compactMap({ $0.clipped(to: boundingBox) })
        guard clipped.isNotEmpty else { return nil }

        var polygon = MultiPolygon(
            clipped,
            calculateBoundingBox: (self.boundingBox != nil))
        polygon?.foreignMembers = foreignMembers
        return polygon
    }

}

extension GeometryCollection {

    /// Clips the *GeometryCollection* to the bounding box.
    ///
    /// - Parameter boundingBox: The bounding box
    ///
    /// - Returns: The *GeometryCollection* clipped to the bounding box, or *nil* if it would be empty.
    public func clipped(to boundingBox: BoundingBox) -> GeometryCollection? {
        let boundingBox = boundingBox.projected(to: projection)

        let clipped = geometries.compactMap({ $0.clipped(to: boundingBox) })
        guard clipped.isNotEmpty else { return nil }

        var geometryCollection = GeometryCollection(
            clipped,
            calculateBoundingBox: (self.boundingBox != nil))
        geometryCollection.foreignMembers = foreignMembers
        return geometryCollection
    }

}

extension GeoJsonGeometry {

    /// Clips the receiver to the bounding box.
    ///
    /// - Parameter boundingBox: The bounding box
    ///
    /// - Returns: The geometry clipped to the bounding box, or *nil* if it would be empty.
    public func clipped(to boundingBox: BoundingBox) -> GeoJsonGeometry? {
        switch self {
        case let point as Point:
            return point.clipped(to: boundingBox)

        case let multiPoint as MultiPoint:
            return multiPoint.clipped(to: boundingBox)

        case let lineString as LineString:
            return lineString.clipped(to: boundingBox)

        case let multiLineString as MultiLineString:
            return multiLineString.clipped(to: boundingBox)

        case let polygon as Polygon:
            return polygon.clipped(to: boundingBox)

        case let multiPolygon as MultiPolygon:
            return multiPolygon.clipped(to: boundingBox)

        case let geometryCollection as GeometryCollection:
            let clipped = geometryCollection.geometries.compactMap({ $0.clipped(to: boundingBox) })
            guard clipped.isNotEmpty else { return nil }
            return GeometryCollection(clipped)

        default:
            return nil
        }
    }

}

extension Feature {

    /// Clips the *Feature* to the bounding box.
    ///
    /// - Parameter boundingBox: The bounding box
    ///
    /// - Returns: The *Feature* clipped to the bounding box, or *nil* if it would be empty.
    public func clipped(to boundingBox: BoundingBox) -> Feature? {
        let boundingBox = boundingBox.projected(to: projection)

        guard let clipped = geometry.clipped(to: boundingBox) else { return nil }

        var feature = Feature(
            clipped,
            id: id,
            properties: properties,
            calculateBoundingBox: (self.boundingBox != nil))
        feature.foreignMembers = foreignMembers
        return feature
    }

}

extension FeatureCollection {

    /// Clips the *FeatureCollection* to the bounding box.
    ///
    /// - Parameter boundingBox: The bounding box
    ///
    /// - Returns: The *Feature*s of the *FeatureCollection* clipped to the bounding box, or *nil* if it would be empty.
    public func clipped(to boundingBox: BoundingBox) -> FeatureCollection? {
        let boundingBox = boundingBox.projected(to: projection)

        let clipped = features.compactMap({ $0.clipped(to: boundingBox) })
        guard clipped.isNotEmpty else { return nil }

        var featureCollection = FeatureCollection(
            clipped,
            calculateBoundingBox: (self.boundingBox != nil))
        featureCollection.foreignMembers = foreignMembers
        return featureCollection
    }

}

extension BoundingBox {

    // TODO: This is ugly Swift code

    // Cohen-Sutherland line clipping algorithm, adapted to efficiently
    // handle polylines rather than just segments.
    fileprivate func clipLine(coordinates: [Coordinate3D]) -> [[Coordinate3D]] {
        guard coordinates.count > 1 else { return [] }

        var result: [[Coordinate3D]] = []
        var part: [Coordinate3D] = []

        var codeA = bitCode(for: coordinates[0])

        for i in 1 ..< coordinates.count {
            var a = coordinates[i - 1]
            var b = coordinates[i]
            var codeB = bitCode(for: b)
            let lastCode = codeB

            while true {
                if (codeA | codeB) == 0 { // accept
                    part.append(a)

                    if (codeB != lastCode) { // segment went outside
                        part.append(b)

                        if i < coordinates.count - 1 { // start a new line
                            result.append(part)
                            part = []
                        }
                    }
                    else if i == coordinates.count - 1 {
                        part.append(b)
                    }

                    break
                }
                else if (codeA & codeB) != 0 { // trivial reject
                    break
                }
                else if codeA != 0 { // a outside, intersect with clip edge
                    guard let newA = intersect(a: a, b: b, edge: codeA) else {
                        break
                    }
                    a = newA
                    codeA = bitCode(for: a)
                }
                else { // b outside
                    guard let newB = intersect(a: a, b: b, edge: codeB) else {
                        break
                    }
                    b = newB
                    codeB = bitCode(for: b)
                }
            }

            codeA = lastCode
        }

        if !part.isEmpty {
            result.append(part)
        }

        return result
    }

    // Sutherland-Hodgeman polygon clipping algorithm
    fileprivate func clipPolygon(coordinates: [Coordinate3D]) -> [Coordinate3D] {
        guard coordinates.count > 1 else { return [] }

        var coordinates = coordinates

        var result: [Coordinate3D] = []
        let edges: [UInt8] = [1, 2, 4, 8]
        for edge in edges {
            result = []

            var previous = coordinates[coordinates.count - 1]
            var previousInside = (bitCode(for: previous) & edge) == 0

            for i in 0 ..< coordinates.count {
                let p = coordinates[i]
                let inside = (bitCode(for: p) & edge) == 0

                // if segment goes through the clip window, add an intersection
                if inside != previousInside {
                    result.append(ifNotNil: intersect(a: previous, b: p, edge: edge))
                }

                if inside {
                    result.append(p)
                }

                previous = p
                previousInside = inside
            }

            coordinates = result

            if coordinates.isEmpty {
                break
            }
        }

        return result
    }

    // intersect a segment against one of the 4 lines that make up the bbox
    private func intersect(
        a: Coordinate3D,
        b: Coordinate3D,
        edge: UInt8)
        -> Coordinate3D?
    {
        if edge & 8 != 0 { // top
            return Coordinate3D(
                x: a.x + (b.x - a.x) * (northEast.y - a.y) / (b.y - a.y),
                y: northEast.y,
                projection: a.projection)
        }
        else if edge & 4 != 0 { // bottom
            return Coordinate3D(
                x: a.x + (b.x - a.x) * (southWest.y - a.y) / (b.y - a.y),
                y: southWest.y,
                projection: a.projection)
        }
        else if edge & 2 != 0 { // right
            return Coordinate3D(
                x: northEast.x,
                y: a.y + (b.y - a.y) * (northEast.x - a.x) / (b.x - a.x),
                projection: a.projection)
        }
        else if edge & 1 != 0 { // left
            return Coordinate3D(
                x: southWest.x,
                y: a.y + (b.y - a.y) * (southWest.x - a.x) / (b.x - a.x),
                projection: a.projection)
        }

        return nil
    }

    // bit code reflects the point position relative to the bbox:
    //
    //         left  mid  right
    //    top  1001  1000  1010
    //    mid  0001  0000  0010
    // bottom  0101  0100  0110
    private func bitCode(for coordinate: Coordinate3D) -> UInt8 {
        var code: UInt8 = 0

        if coordinate.x < self.southWest.x {
            code |= 1 // left
        }
        else if coordinate.x > self.northEast.x {
            code |= 2 // right
        }

        if coordinate.y < self.southWest.y {
            code |= 4 // bottom
        }
        else if coordinate.y > self.northEast.y {
            code |= 8 // top
        }

        return code
    }

}
