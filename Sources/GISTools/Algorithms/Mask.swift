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
    /// All projections are supported. The containment check delegates to
    /// ``PolygonGeometry/contains(_:gridSize:)`` which handles
    /// 4978→4326 projection. The antimeridian normalisation only applies
    /// to EPSG:4326.
    ///
    /// - Note: Because the result is a single `Polygon`, mask polygons with
    ///   holes and masks crossing the outer boundary are reduced to their outer
    ///   rings. Use ``PolygonGeometry/difference(with:gridSize:)`` when islands
    ///   or clipped multi-part results are required.
    ///
    /// - Parameter outerPolygon: The polygon to mask (defaults to the world bounding box).
    /// - Returns: A masked ``Polygon``, or `nil` if the geometry is empty.
    public func mask(outerPolygon: Polygon? = nil) -> Polygon? {
        let outer: Polygon
        if let outerPolygon {
            outer = outerPolygon
        }
        else if projection == .epsg4326 {
            outer = Polygon.world
        }
        else if projection == .noSRID,
                let box = calculateBoundingBox()
        {
            let dx = max((box.northEast.x - box.southWest.x) * 0.1, 1.0)
            let dy = max((box.northEast.y - box.southWest.y) * 0.1, 1.0)
            let minX = box.southWest.x - dx
            let minY = box.southWest.y - dy
            let maxX = box.northEast.x + dx
            let maxY = box.northEast.y + dy
            outer = Polygon(unchecked: [[
                Coordinate3D(x: minX, y: minY, projection: .noSRID),
                Coordinate3D(x: maxX, y: minY, projection: .noSRID),
                Coordinate3D(x: maxX, y: maxY, projection: .noSRID),
                Coordinate3D(x: minX, y: maxY, projection: .noSRID),
                Coordinate3D(x: minX, y: minY, projection: .noSRID),
            ]])
        }
        else if let world = projection.definition.worldBoundingBox,
                let polygon = world.boundingBoxGeometry.polygons.first
        {
            outer = polygon
        }
        else {
            outer = Polygon.world.projected(to: projection)
        }

        guard let outerRing = outer.outerRing else { return nil }

        let holes: [Ring] = polygons.compactMap { $0.outerRing }
        guard holes.isNotEmpty else { return outer }

        // Normalise antimeridian crossing so the Cartesian containment check works.
        // This only applies to EPSG:4326 where longitude is in degrees.
        // For other projections the values are in projection units (meters for 3857/4978).
        let outerCoords = outerRing.coordinates
        let needShift: Bool
        if projection.isGeographic {
            let minOuterLon = outerCoords.map(\.longitude).min() ?? 0
            let maxOuterLon = outerCoords.map(\.longitude).max() ?? 0
            let span = maxOuterLon - minOuterLon
            needShift = span > 180.0 && span < 360.0
        }
        else {
            needShift = false
        }

        let containedHoles: [Ring]
        if needShift {
            func shiftCoord(_ c: Coordinate3D) -> Coordinate3D {
                Coordinate3D(
                    latitude: c.latitude,
                    longitude: c.longitude < 0 ? c.longitude + 360.0 : c.longitude,
                    altitude: c.altitude,
                    m: c.m)
            }

            let shiftedOuter = Polygon(unchecked: [
                Ring(unchecked: outerCoords.map(shiftCoord)),
            ])

            containedHoles = holes.filter { hole in
                guard let pt = hole.coordinates.first else { return false }

                return shiftedOuter.contains(shiftCoord(pt))
            }
        }
        else {
            containedHoles = holes.filter { hole in
                guard let pt = hole.coordinates.first else { return false }

                return outer.contains(pt)
            }
        }

        guard containedHoles.isNotEmpty else { return outer }

        return Polygon(unchecked: [outerRing] + containedHoles)
    }

}
