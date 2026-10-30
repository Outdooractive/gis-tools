#if canImport(CoreLocation)
import CoreLocation
#endif
import Foundation

// Ported from https://github.com/Turfjs/turf/blob/master/packages/turf-bbox-clip

extension Point {

    /// Clips the *Point* to the bounding box.
    ///
    /// All projections are supported — the 2‑D Cohen–Sutherland clipping
    /// operates on ``Coordinate3D/x`` and ``Coordinate3D/y`` directly.
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
    /// All projections are supported — the 2‑D Cohen–Sutherland clipping
    /// operates on ``Coordinate3D/x`` and ``Coordinate3D/y`` directly.
    ///
    /// - Parameter boundingBox: The bounding box
    ///
    /// - Returns: A *MultiPoint* with all points inside the bounding box, *nil* if no point was inside the bounding box.
    public func clipped(to boundingBox: BoundingBox) -> MultiPoint? {
        let clipped = coordinates.filter({ boundingBox.contains($0) })
        guard clipped.isNotEmpty else { return nil }

        var multiPoint = MultiPoint(
            clipped,
            calculateBoundingBox: self.boundingBox != nil)
        multiPoint?.foreignMembers = foreignMembers
        return multiPoint
    }

}

extension LineString {

    /// Clips the *LineString* to the bounding box.
    ///
    /// All projections are supported — the 2‑D Cohen–Sutherland clipping
    /// operates on ``Coordinate3D/x`` and ``Coordinate3D/y`` directly.
    ///
    /// - Parameter boundingBox: The bounding box
    ///
    /// - Returns: The line clipped to the bounding box.
    public func clipped(to boundingBox: BoundingBox) -> MultiLineString? {
        if boundingBox.projection != projection,
           boundingBox.projection != .noSRID,
           projection != .noSRID
        {
            guard let clipped = projected(to: boundingBox.projection)
                .clipped(to: boundingBox)
            else { return nil }

            var result = clipped.projected(to: projection)
            result.foreignMembers = foreignMembers
            return result
        }

        let boundingBox = boundingBox.projected(to: projection)

        var lineString = MultiLineString(
            boundingBox.clipLineParts(coordinates: coordinates, projection: projection),
            calculateBoundingBox: self.boundingBox != nil)
        lineString?.foreignMembers = foreignMembers
        return lineString
    }

}

extension MultiLineString {

    /// Clips the *MultiLineString* to the bounding box.
    ///
    /// All projections are supported — the 2‑D Cohen–Sutherland clipping
    /// operates on ``Coordinate3D/x`` and ``Coordinate3D/y`` directly.
    ///
    /// - Parameter boundingBox: The bounding box
    ///
    /// - Returns: The lines clipped to the bounding box.
    public func clipped(to boundingBox: BoundingBox) -> MultiLineString? {
        if boundingBox.projection != projection,
           boundingBox.projection != .noSRID,
           projection != .noSRID
        {
            guard let clipped = projected(to: boundingBox.projection)
                .clipped(to: boundingBox)
            else { return nil }

            var result = clipped.projected(to: projection)
            result.foreignMembers = foreignMembers
            return result
        }

        let boundingBox = boundingBox.projected(to: projection)

        var lineString = MultiLineString(
            coordinates.flatMap {
                boundingBox.clipLineParts(coordinates: $0, projection: projection)
            },
            calculateBoundingBox: self.boundingBox != nil)
        lineString?.foreignMembers = foreignMembers
        return lineString
    }

}

extension Polygon {

    /// Clips the *Polygon* to the bounding box.
    ///
    /// The result is a ``MultiPolygon`` because a clipped polygon can split
    /// into multiple disconnected components, and an antimeridian-crossing
    /// clip box produces two parts. Holes that reach the clip edge become
    /// notches instead of invalid touching holes.
    ///
    /// All projections are supported. The clip box is built as a polygon
    /// geometry and projected into the receiver's CRS, so cross-projection
    /// clipping (e.g. a 4326 box against EPSG:4978 geometry) is not limited to
    /// corner projection.
    ///
    /// - Parameter boundingBox: The bounding box
    /// - Returns: The clipped parts, or `nil` if nothing remains.
    public func clipped(to boundingBox: BoundingBox) -> MultiPolygon? {
        let sourceBoxes = boundingBox.clipBoxes(projection: boundingBox.projection)
        let clipPolygons = sourceBoxes.flatMap { box in
            box.boundingBoxGeometry.projected(to: projection).polygons
        }

        // A crossing clip box is already split into non-crossing parts; clip
        // against each part independently so the overlay never merges them
        // into a seam-spanning result.
        var parts: [Polygon] = []
        for clipPolygon in clipPolygons {
            guard let result = MultiPolygon(unchecked: [clipPolygon])
                .intersection(with: self)
            else { continue }

            parts.append(contentsOf: result.polygons)
        }

        guard parts.isNotEmpty else { return nil }

        var output = MultiPolygon(
            parts,
            calculateBoundingBox: self.boundingBox != nil)
        output?.foreignMembers = foreignMembers
        return output
    }

}

extension MultiPolygon {

    /// Clips the *MultiPolygon* to the bounding box. May result in degenerate edges.
    ///
    /// All projections are supported — the 2‑D Sutherland–Hodgeman clipping
    /// operates on ``Coordinate3D/x`` and ``Coordinate3D/y`` directly.
    ///
    /// - Parameter boundingBox: The bounding box
    ///
    /// - Returns: The polygons clipped to the bounding box, or *nil* if the polygon would be empty.
    public func clipped(to boundingBox: BoundingBox) -> MultiPolygon? {
        let boundingBox = boundingBox.projected(to: projection)

        let clipped = polygons.flatMap { polygon in
            polygon.clipped(to: boundingBox)?.polygons ?? []
        }
        guard clipped.isNotEmpty else { return nil }

        var polygon = MultiPolygon(
            clipped,
            calculateBoundingBox: self.boundingBox != nil)
        polygon?.foreignMembers = foreignMembers
        return polygon
    }

}

extension GeometryCollection {

    /// Clips the *GeometryCollection* to the bounding box.
    ///
    /// All projections are supported — delegates to each geometry's
    /// ``clipped(to:)``.
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
            calculateBoundingBox: self.boundingBox != nil)
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

        guard let geometry,
              let clipped = geometry.clipped(to: boundingBox)
        else { return nil }

        var feature = Feature(
            clipped,
            id: id,
            properties: properties,
            calculateBoundingBox: self.boundingBox != nil)
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
            calculateBoundingBox: self.boundingBox != nil)
        featureCollection.foreignMembers = foreignMembers
        return featureCollection
    }

}

extension BoundingBox {

    /// Splits a crossing bounding box into its non-crossing world windows.
    /// Uses the projection's wraparound extent (180° for EPSG:4326,
    /// `originShift` for EPSG:3857), unlike `boundingBoxGeometry` which is
    /// degree-specific.
    fileprivate func clipBoxes(projection: Projection) -> [BoundingBox] {
        guard let extent = projection.wraparoundExtent,
              southWest.x > northEast.x
        else { return [self] }

        let south = southWest.y
        let north = northEast.y

        func window(west: Double, east: Double) -> BoundingBox {
            BoundingBox(
                southWest: Coordinate3D(x: west, y: south, projection: projection),
                northEast: Coordinate3D(x: east, y: north, projection: projection))
        }

        return [
            window(west: southWest.x, east: extent),
            window(west: -extent, east: northEast.x),
        ]
    }

    /// Clips a line against a possibly antimeridian-crossing box by splitting
    /// the box into its non-crossing parts and clipping against each one.
    ///
    /// The coordinates are unwrapped into a continuous frame first, so a
    /// segment that crosses the antimeridian becomes a segment that leaves the
    /// world on one side and re-enters on the other. A segment spanning more
    /// than half the world is therefore longer than one world period and can
    /// reach into more than one copy of the clip box. Every world copy that
    /// the unwrapped line touches is clipped and all resulting pieces are
    /// kept, so neither half of such a segment is lost.
    fileprivate func clipLineParts(
        coordinates: [Coordinate3D],
        projection: Projection,
    ) -> [[Coordinate3D]] {
        let boxes = clipBoxes(projection: projection)

        guard let extent = projection.wraparoundExtent,
              extent > 0.0
        else {
            return boxes.flatMap { $0.clipLine(coordinates: coordinates) }
        }

        let period = extent * 2.0
        let unwrapped = AntimeridianCutting.unwrapCoordinates(coordinates, extent: extent)

        guard let lineMinX = unwrapped.map(\.x).min(),
              let lineMaxX = unwrapped.map(\.x).max()
        else { return [] }

        var parts: [[Coordinate3D]] = []
        var seen: Set<[Coordinate3D]> = []

        for box in boxes {
            let boxMinX = box.southWest.x
            let boxMaxX = box.northEast.x

            // World copies of the box are the box shifted by whole periods.
            // Copy `k` covers `boxMinX + k * period ... boxMaxX + k * period`;
            // it overlaps the unwrapped line when
            // `k >= (lineMinX - boxMaxX) / period` and
            // `k <= (lineMaxX - boxMinX) / period`. Only whole copies count,
            // hence the `ceil`/`floor` bounds.
            let firstCopyValue = ((lineMinX - boxMaxX) / period).rounded(.up)
            let lastCopyValue = ((lineMaxX - boxMinX) / period).rounded(.down)

            guard firstCopyValue.isFinite,
                  lastCopyValue.isFinite,
                  firstCopyValue <= lastCopyValue,
                  firstCopyValue >= Double(Int.min),
                  lastCopyValue <= Double(Int.max)
            else { continue }

            let firstCopy = Int(firstCopyValue)
            let lastCopy = Int(lastCopyValue)

            for copyIndex in firstCopy ... lastCopy {
                // Clipping against the copy shifted by `shift` is equivalent to
                // shifting the line by the same amount in the opposite
                // direction, then clipping against the box itself.
                let shift = Double(copyIndex) * period
                let candidate = shift == 0.0
                    ? unwrapped
                    : unwrapped.map {
                        Coordinate3D(
                            x: $0.x - shift,
                            y: $0.y,
                            z: $0.altitude,
                            m: $0.m,
                            projection: $0.projection)
                    }

                for part in box.clipLine(coordinates: candidate) {
                    let normalized = part.map { $0.normalized() }
                    guard seen.insert(normalized).inserted else { continue }

                    parts.append(normalized)
                }
            }
        }

        return parts
    }

    /// Cohen-Sutherland line clipping algorithm, adapted to efficiently
    /// handle polylines rather than just segments.
    private func clipLine(coordinates: [Coordinate3D]) -> [[Coordinate3D]] {
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

                    if codeB != lastCode { // segment went outside
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

        if part.isNotEmpty {
            result.append(part)
        }

        return result
    }

    /// Sutherland-Hodgeman polygon clipping algorithm
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

    /// intersect a segment against one of the 4 lines that make up the bbox
    private func intersect(
        a: Coordinate3D,
        b: Coordinate3D,
        edge: UInt8,
    ) -> Coordinate3D? {
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

    /// bit code reflects the point position relative to the bbox:
    ///
    ///         left  mid  right
    ///    top  1001  1000  1010
    ///    mid  0001  0000  0010
    /// bottom  0101  0100  0110
    private func bitCode(for coordinate: Coordinate3D) -> UInt8 {
        var code: UInt8 = 0

        if coordinate.x < southWest.x {
            code |= 1 // left
        }
        else if coordinate.x > northEast.x {
            code |= 2 // right
        }

        if coordinate.y < southWest.y {
            code |= 4 // bottom
        }
        else if coordinate.y > northEast.y {
            code |= 8 // top
        }

        return code
    }

}
