#if canImport(CoreLocation)
import CoreLocation
#endif
import Foundation

// Ported from https://github.com/Turfjs/turf/blob/master/packages/turf-area

extension Polygon {

    /// Returns the *Polygon*'s area.
    ///
    /// For ``Projection/epsg3857`` and ``Projection/epsg4978`` the coordinates
    /// are projected to ``Projection/epsg4326`` first, then the geodesic area
    /// formula is applied. Altitude differences are ignored.
    ///
    /// - Returns: The area of the outer ring minus the area of the *union* of the inner rings, in square meters.
    public var area: Double {
        guard let outerRing else { return 0.0 }

        let outerArea = abs(outerRing.area)

        guard let innerRings,
              innerRings.isNotEmpty
        else { return outerArea }

        let holePolygons = innerRings.map { Polygon(unchecked: [$0.coordinates]) }
        if let union = Union.unionPolygons(holePolygons) {
            return outerArea - abs(union.area)
        }
        return outerArea
    }

    /// Returns the polygon's area converted to the requested unit.
    ///
    /// The receiver's existing ``area`` value is in square meters. Use
    /// ``GISTool/Unit/meters`` for square meters and
    /// ``GISTool/Unit/kilometers`` for square kilometers.
    ///
    /// - Parameter unit: The target area unit
    /// - Returns: The converted area, or `nil` if `unit` is not an area unit
    public func area(in unit: GISTool.Unit) -> Double? {
        guard projection != .noSRID else { return nil }

        return GISTool.convert(area: area, from: .meters, to: unit)
    }

}

extension MultiPolygon {

    /// Returns the *MultiPolygon*'s area.
    ///
    /// For ``Projection/epsg3857`` and ``Projection/epsg4978`` the coordinates
    /// are projected to ``Projection/epsg4326`` first. Altitude differences
    /// are ignored.
    ///
    /// - Returns: The sum of all *Polygon*s areas, in square meters.
    public var area: Double {
        polygons.reduce(0.0, { $0 + $1.area })
    }

    /// Returns the multi-polygon's area converted to the requested unit.
    ///
    /// - Parameter unit: The target area unit
    /// - Returns: The converted area, or `nil` if `unit` is not an area unit
    public func area(in unit: GISTool.Unit) -> Double? {
        guard projection != .noSRID else { return nil }

        return GISTool.convert(area: area, from: .meters, to: unit)
    }

}

// MARK: - Copied from turf-swift

extension Ring {

    /// Calculate the approximate area of the polygon were it projected onto the earth, in square meters.
    /// Note that this area will be positive if ring is oriented clockwise, otherwise it will be negative.
    ///
    /// For ``Projection/epsg3857`` and ``Projection/epsg4978`` the coordinates
    /// are projected to ``Projection/epsg4326`` first. Altitude differences
    /// are ignored.
    ///
    /// Reference:
    /// Robert. G. Chamberlain and William H. Duquette, "Some Algorithms for Polygons on a Sphere", JPL Publication 07-03, Jet Propulsion
    /// Laboratory, Pasadena, CA, June 2007 https://trs.jpl.nasa.gov/handle/2014/41271
    public var area: Double {
        if projection == .noSRID {
            return rawSignedArea
        }

        let projected = projection.isGeographic
            ? coordinates
            : coordinates.map({ $0.projected(to: .epsg4326) })

        // Normalize antimeridian crossing: detect large longitude jumps (> 180°)
        // in the ORIGINAL coordinate sequence and shift subsequent coordinates
        // by ±360° so the ring is contiguous.
        var coordinates = projected
        let n = coordinates.count
        if n > 1 {
            let origLons = projected.map(\.longitude)
            var shifts = Array(repeating: 0.0, count: n)
            for i in 1 ..< n {
                shifts[i] = shifts[i - 1]
                let origDelta = origLons[i] - origLons[i - 1]
                if origDelta > 180.0 {
                    shifts[i] -= 360.0
                }
                else if origDelta < -180.0 {
                    shifts[i] += 360.0
                }
            }
            for i in 0 ..< n where shifts[i] != 0.0 {
                coordinates[i] = Coordinate3D(
                    latitude: projected[i].latitude,
                    longitude: origLons[i] + shifts[i],
                    altitude: projected[i].altitude,
                    m: projected[i].m)
            }
        }
        var area = 0.0
        let coordinatesCount = coordinates.count

        if coordinatesCount > 2 {
            for index in 0 ..< coordinatesCount {
                let controlPoints: (Coordinate3D, Coordinate3D, Coordinate3D) =
                    if index == coordinatesCount - 2 {
                        (
                            coordinates[coordinatesCount - 2],
                            coordinates[coordinatesCount - 1],
                            coordinates[0]
                        )
                    }
                    else if index == coordinatesCount - 1 {
                        (
                            coordinates[coordinatesCount - 1],
                            coordinates[0],
                            coordinates[1]
                        )
                    }
                    else {
                        (
                            coordinates[index],
                            coordinates[index + 1],
                            coordinates[index + 2]
                        )
                    }

                let dLon = (controlPoints.2.longitude - controlPoints.0.longitude) * .pi / 180.0
                let sinLat = sin(controlPoints.1.latitude * .pi / 180.0)
                area += dLon * sinLat
            }

            area *= GISTool.equatorialRadius * GISTool.equatorialRadius / 2.0
        }

        return area
    }

    /// Returns the ring's signed area converted to the requested unit.
    ///
    /// The sign follows ``area``: positive for clockwise rings and negative
    /// for counter-clockwise rings. Returns `nil` for ``Projection/noSRID``.
    ///
    /// - Parameter unit: The target area unit
    /// - Returns: The converted area, or `nil` if `unit` is not an area unit
    public func area(in unit: GISTool.Unit) -> Double? {
        guard projection != .noSRID else { return nil }

        let signedArea = area
        guard let converted = GISTool.convert(
            area: abs(signedArea),
            from: .meters,
            to: unit)
        else { return nil }

        return signedArea < 0.0 ? -converted : converted
    }

    /// Planar shoelace area, with the same positive-clockwise sign convention as
    /// the geographic implementation.
    private var rawSignedArea: Double {
        guard coordinates.count >= 3 else { return 0.0 }

        var sum = 0.0
        for index in 0 ..< (coordinates.count - 1) {
            sum += (coordinates[index].longitude * coordinates[index + 1].latitude)
                - (coordinates[index + 1].longitude * coordinates[index].latitude)
        }

        if coordinates.first != coordinates.last,
           let first = coordinates.first,
           let last = coordinates.last
        {
            sum += (last.longitude * first.latitude) - (first.longitude * last.latitude)
        }

        return -sum / 2.0
    }

}
