#if canImport(CoreLocation)
import CoreLocation
#endif
import Foundation

// Ported from https://github.com/Turfjs/turf/tree/master/packages/turf-mask

extension PolygonGeometry {

    /// Creates a mask polygon by subtracting this geometry from a larger polygon.
    ///
    /// The result is ``outerPolygon`` with this geometry cut out as a hole (or holes).
    /// If no outer polygon is provided, the world bounding box `(-180, -90, 180, 90)` is used.
    ///
    /// - Parameter outerPolygon: The polygon to mask (defaults to the world bounding box).
    /// - Returns: A masked ``Polygon``, or `nil` if the geometry is empty.
    public func mask(outerPolygon: Polygon? = nil) -> Polygon? {
        let outer = outerPolygon ?? Polygon.world
        guard let outerRing = outer.outerRing else { return nil }

        let holes: [Ring] = polygons.compactMap { $0.outerRing }
        guard holes.isNotEmpty else { return outer }

        // Normalise antimeridian crossing so the Cartesian containment check works.
        // If the outer polygon spans >180° (but < 360°) of longitude, shift all
        // negative longitudes by +360° to make the coordinates contiguous.
        let outerCoords = outerRing.coordinates
        let minOuterLon = outerCoords.map(\.longitude).min() ?? 0
        let maxOuterLon = outerCoords.map(\.longitude).max() ?? 0
        let span = maxOuterLon - minOuterLon
        let needShift = span > 180.0 && span < 360.0

        let containedHoles: [Ring]
        if needShift {
            func shiftCoord(_ c: Coordinate3D) -> Coordinate3D {
                Coordinate3D(latitude: c.latitude,
                             longitude: c.longitude < 0 ? c.longitude + 360.0 : c.longitude,
                             altitude: c.altitude, m: c.m)
            }

            let shiftedOuter = Polygon(unchecked: [
                Ring(unchecked: outerCoords.map(shiftCoord))
            ])

            containedHoles = holes.filter { hole in
                guard let pt = hole.coordinates.first else { return false }
                return shiftedOuter.contains(shiftCoord(pt), ignoringBoundary: true)
            }
        }
        else {
            containedHoles = holes.filter { hole in
                guard let pt = hole.coordinates.first else { return false }
                return outer.contains(pt, ignoringBoundary: true)
            }
        }

        guard containedHoles.isNotEmpty else { return outer }

        return Polygon(unchecked: [outerRing] + containedHoles)
    }

}

extension Polygon {

    /// A polygon representing the world bounding box `(-180, -90, 180, 90)`.
    public static let world: Polygon = Polygon(unchecked: [[
        Coordinate3D(latitude: -90.0, longitude: -180.0),
        Coordinate3D(latitude: -90.0, longitude: 180.0),
        Coordinate3D(latitude: 90.0, longitude: 180.0),
        Coordinate3D(latitude: 90.0, longitude: -180.0),
        Coordinate3D(latitude: -90.0, longitude: -180.0),
    ]])

}
