#if canImport(CoreLocation)
import CoreLocation
#endif
import Foundation

// Ported from https://github.com/Turfjs/turf/tree/master/packages/turf-mask

extension PolygonGeometry {

    /// Creates a mask by subtracting this geometry from a larger polygon.
    ///
    /// The result is `outerPolygon` minus the receiver. It is returned as a
    /// ``MultiPolygon`` because a mask can require holes, islands and multiple
    /// disconnected parts (e.g. a mask partially crossing the outer boundary
    /// or an antimeridian-crossing mask cut at the seam). If no outer polygon
    /// is provided, the projection's world extent is used.
    ///
    /// All projections are supported; overlay performs the difference in a
    /// consistent frame. This replaces the old single-`Polygon` API, which
    /// silently dropped holes and multi-part results.
    ///
    /// - Parameter outerPolygon: The polygon to mask (defaults to the world extent).
    /// - Returns: The masked area as a ``MultiPolygon``, or `nil` if nothing remains.
    public func mask(outerPolygon: Polygon? = nil) -> MultiPolygon? {
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

        // If the mask is fully inside the outer polygon, construct the
        // result directly. This preserves the mask's holes as unmasked
        // islands and avoids running the full overlay on a world-sized shell.
        if polygons.count == 1,
           polygons[0].rings.count == 1,
           polygons[0].outerRing?.coordinates == outer.outerRing?.coordinates
        {
            // Masking the outer polygon itself leaves it unchanged.
            return MultiPolygon(unchecked: [outer])
        }

        if outer.covers(self) {

            let maskPolygons = polygons
            let maskHoles: [Ring] = maskPolygons.compactMap(\.outerRing)
            var outerRings: [Ring] = []
            if let outerRing = outer.outerRing {
                outerRings.append(outerRing)
            }
            if let innerRings = outer.innerRings {
                outerRings.append(contentsOf: innerRings)
            }
            outerRings.append(contentsOf: maskHoles)

            guard let base = Polygon(outerRings)?.rewinded else { return nil }

            var islands: [Polygon] = []
            for polygon in maskPolygons {
                for hole in polygon.innerRings ?? [] {
                    if let island = Polygon([hole])?.rewinded {
                        islands.append(island)
                    }
                }
            }
            return Self.cutAtSeam(MultiPolygon(unchecked: [base] + islands), enabled: self.crossesAntimeridian)
        }

        // Partial overlap/crossing masks need true overlay difference.
        guard let difference = outer.difference(with: self) else { return nil }

        if let multiPolygon = difference as? MultiPolygon {
            return multiPolygon.polygons.isEmpty
                ? nil
                : Self.cutAtSeam(multiPolygon, enabled: self.crossesAntimeridian)
        }
        if let polygon = difference as? Polygon {
            return Self.cutAtSeam(MultiPolygon(unchecked: [polygon]), enabled: self.crossesAntimeridian)
        }
        return nil
    }

    /// Cuts a mask result at the wraparound axis so every emitted polygon is
    /// non-crossing.
    private static func cutAtSeam(
        _ multiPolygon: MultiPolygon,
        enabled: Bool
    ) -> MultiPolygon {
        guard enabled, multiPolygon.crossesAntimeridian else { return multiPolygon }

        let parts = multiPolygon.cutAtAntimeridian().features.compactMap {
            $0.geometry as? Polygon
        }
        return parts.isEmpty
            ? multiPolygon
            : MultiPolygon(unchecked: parts)
    }

}
