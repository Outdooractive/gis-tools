#if canImport(CoreLocation)
import CoreLocation
#endif
import Foundation

// Ported from https://github.com/Turfjs/turf/tree/master/packages/turf-polygon-smooth

extension GeoJson {

    /// Returns a copy of the receiver with additional interpolated vertices
    /// added along line segments longer than the given interval.
    ///
    /// When both endpoints of a segment have an ``altitude`` value, the
    /// interpolated vertices carry a linearly interpolated altitude.
    /// Otherwise the new vertices have no altitude.
    ///
    /// - Parameter maxSegmentLength: The maximum allowed segment length in meters.
    ///   For EPSG:4326, internally converted to degrees.
    ///   For EPSG:3857, EPSG:4978 and noSRID, used as-is.
    /// - Returns: A densified copy of the receiver.
    public func densified(maxSegmentLength: CLLocationDistance) -> Self {
        guard let geoJson = Densify.densify(geoJson: self, maxSegmentLength: maxSegmentLength) else {
            return self
        }
        return geoJson as! Self
    }

}

// MARK: - Implementation

private enum Densify {

    /// Converts meter tolerance to CRS units based on coordinate projection.
    static func crsTolerance(from meters: CLLocationDistance, projection: Projection) -> Double {
        switch projection {
        case .epsg4326:
            return meters / 111_325.0
        case .epsg3857, .epsg4978, .noSRID:
            return meters
        }
    }

    static func densify(geoJson: GeoJson, maxSegmentLength: CLLocationDistance) -> GeoJson? {
        switch geoJson.type {
        case .point, .multiPoint:
            return geoJson

        case .lineString:
            guard let ls = geoJson as? LineString else { return nil }
            return LineString(unchecked: densifyCoordinates(ls.coordinates, maxSegmentLength: maxSegmentLength))

        case .multiLineString:
            guard let mls = geoJson as? MultiLineString else { return nil }
            let densified: [LineString] = mls.lineStrings.map { ls in
                LineString(unchecked: densifyCoordinates(ls.coordinates, maxSegmentLength: maxSegmentLength))
            }
            return MultiLineString(unchecked: densified)

        case .polygon:
            guard let poly = geoJson as? Polygon else { return nil }
            let densifiedRings: [Ring] = poly.rings.map { ring in
                Ring(unchecked: densifyCoordinates(ring.coordinates, maxSegmentLength: maxSegmentLength))
            }
            return Polygon(unchecked: densifiedRings)

        case .multiPolygon:
            guard let mp = geoJson as? MultiPolygon else { return nil }
            let densified: [Polygon] = mp.polygons.map { poly in
                let rings: [Ring] = poly.rings.map { ring in
                    Ring(unchecked: densifyCoordinates(ring.coordinates, maxSegmentLength: maxSegmentLength))
                }
                return Polygon(unchecked: rings)
            }
            return MultiPolygon(unchecked: densified)

        case .geometryCollection:
            guard let gc = geoJson as? GeometryCollection else { return nil }
            let densified = gc.geometries.compactMap { g in
                densify(geoJson: g, maxSegmentLength: maxSegmentLength) as? GeoJsonGeometry
            }
            return GeometryCollection(densified)

        case .feature:
            guard let f = geoJson as? Feature else { return nil }
            let g = f.geometry
            guard let densifiedG = densify(geoJson: g, maxSegmentLength: maxSegmentLength) as? GeoJsonGeometry
            else { return f }
            return Feature(densifiedG, id: f.id, properties: f.properties)

        case .featureCollection:
            guard let fc = geoJson as? FeatureCollection else { return nil }
            let densified = fc.features.compactMap { f in
                densify(geoJson: f, maxSegmentLength: maxSegmentLength) as? Feature
            }
            return FeatureCollection(densified)

        case .invalid:
            return nil
        }
    }

    static func densifyCoordinates(
        _ coords: [Coordinate3D],
        maxSegmentLength: CLLocationDistance
    ) -> [Coordinate3D] {
        guard coords.count >= 2 else { return coords }
        guard maxSegmentLength > 0 else { return coords }

        // Convert meter tolerance to CRS units
        let projection = coords.first?.projection ?? .noSRID
        let segmentLength = crsTolerance(from: maxSegmentLength, projection: projection)

        var result: [Coordinate3D] = []
        for i in 0..<(coords.count - 1) {
            let start = coords[i]
            let end = coords[i + 1]
            let dx = end.x - start.x
            let dy = end.y - start.y
            let len = sqrt(dx * dx + dy * dy)

            if len <= segmentLength {
                result.append(start)
            }
            else {
                let steps = Int(ceil(len / segmentLength))
                for j in 0..<steps {
                    let t = Double(j) / Double(steps)
                    let x = start.x + t * dx
                    let y = start.y + t * dy
                    let z: Double?
                    if let startZ = start.altitude, let endZ = end.altitude {
                        z = startZ + t * (endZ - startZ)
                    }
                    else {
                        z = nil
                    }
                    result.append(Coordinate3D(
                        x: x, y: y, z: z,
                        projection: start.projection))
                }
            }
        }
        result.append(coords.last!)
        return result
    }

}
