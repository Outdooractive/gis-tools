#if !os(Linux)
import CoreLocation
#endif

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
        guard !clipped.isEmpty else { return nil }
        return MultiPoint(clipped, calculateBoundingBox: (self.boundingBox != nil))
    }

}

extension LineString {

    /// Clips the *LineString* to the bounding box.
    ///
    /// - Parameter boundingBox: The bounding box
    ///
    /// - Returns: The line clipped to the bounding box.
    public func clipped(to boundingBox: BoundingBox) -> MultiLineString? {
        MultiLineString(boundingBox.clipLine(coordinates: coordinates), calculateBoundingBox: (self.boundingBox != nil))
    }

}

extension MultiLineString {

    /// Clips the *MultiLineString* to the bounding box.
    ///
    /// - Parameter boundingBox: The bounding box
    ///
    /// - Returns: The lines clipped to the bounding box.
    public func clipped(to boundingBox: BoundingBox) -> MultiLineString? {
        MultiLineString(coordinates.flatMap({ boundingBox.clipLine(coordinates: $0) }), calculateBoundingBox: (self.boundingBox != nil))
    }

}

extension Polygon {

    /// Clips the *Polygon* to the bounding box. May result in degenerate edges.
    ///
    /// - Parameter boundingBox: The bounding box
    ///
    /// - Returns: The polygon clipped to the bounding box, or *nil* if the polygon would be empty.
    public func clipped(to boundingBox: BoundingBox) -> Polygon? {
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

        guard !result.isEmpty else { return nil }

        return Polygon(result, calculateBoundingBox: (self.boundingBox != nil))
    }

}

extension MultiPolygon {

    /// Clips the *MultiPolygon* to the bounding box. May result in degenerate edges.
    ///
    /// - Parameter boundingBox: The bounding box
    ///
    /// - Returns: The polygons clipped to the bounding box, or *nil* if the polygon would be empty.
    public func clipped(to boundingBox: BoundingBox) -> MultiPolygon? {
        let clipped = polygons.compactMap({ $0.clipped(to: boundingBox) })

        guard !clipped.isEmpty else { return nil }

        return MultiPolygon(clipped, calculateBoundingBox: (self.boundingBox != nil))
    }

}

extension GeometryCollection {

    /// Clips the *GeometryCollection* to the bounding box.
    ///
    /// - Parameter boundingBox: The bounding box
    ///
    /// - Returns: The *GeometryCollection* clipped to the bounding box, or *nil* if it would be empty.
    public func clipped(to boundingBox: BoundingBox) -> GeometryCollection? {
        let clipped = geometries.compactMap({ $0.clipped(to: boundingBox) })

        guard !clipped.isEmpty else { return nil }

        return GeometryCollection(clipped, calculateBoundingBox: (self.boundingBox != nil))
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
            guard !clipped.isEmpty else { return nil }
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
        guard let clipped = geometry.clipped(to: boundingBox) else { return nil }
        return Feature(clipped, properties: properties, calculateBoundingBox: (self.boundingBox != nil))
    }

}

extension FeatureCollection {

    /// Clips the *FeatureCollection* to the bounding box.
    ///
    /// - Parameter boundingBox: The bounding box
    ///
    /// - Returns: The *Feature*s of the *FeatureCollection* clipped to the bounding box, or *nil* if it would be empty.
    public func clipped(to boundingBox: BoundingBox) -> FeatureCollection? {
        let clipped = features.compactMap({ $0.clipped(to: boundingBox) })

        guard !clipped.isEmpty else { return nil }

        return FeatureCollection(clipped, calculateBoundingBox: (self.boundingBox != nil))
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
                latitude: northEast.latitude,
                longitude: a.longitude + (b.longitude - a.longitude) * (northEast.latitude - a.latitude) / (b.latitude - a.latitude))
        }
        else if edge & 4 != 0 { // bottom
            return Coordinate3D(
                latitude: southWest.latitude,
                longitude: a.longitude + (b.longitude - a.longitude) * (southWest.latitude - a.latitude) / (b.latitude - a.latitude))
        }
        else if edge & 2 != 0 { // right
            return Coordinate3D(
                latitude: a.latitude + (b.latitude - a.latitude) * (northEast.longitude - a.longitude) / (b.longitude - a.longitude),
                longitude: northEast.longitude)
        }
        else if edge & 1 != 0 { // left
            return Coordinate3D(
                latitude: a.latitude + (b.latitude - a.latitude) * (southWest.longitude - a.longitude) / (b.longitude - a.longitude),
                longitude: southWest.longitude)
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

        if coordinate.longitude < self.southWest.longitude {
            code |= 1 // left
        }
        else if coordinate.longitude > self.northEast.longitude {
            code |= 2 // right
        }

        if coordinate.latitude < self.southWest.latitude {
            code |= 4 // bottom
        }
        else if coordinate.latitude > self.northEast.latitude {
            code |= 8 // top
        }

        return code
    }

}
