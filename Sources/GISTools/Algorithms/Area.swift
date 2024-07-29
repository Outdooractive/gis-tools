#if !os(Linux)
    import CoreLocation
#endif
import Foundation

// Ported from https://github.com/Turfjs/turf/blob/master/packages/turf-area

extension Polygon {

    /// Returns the *Polygon*'s area.
    ///
    /// - Returns: The area of the outer ring minus the areas of the inner rings, in square meters.
    public var area: Double {
        guard let outerRing else { return 0.0 }

        var area: Double = abs(outerRing.area)

        if let innerRings {
            area -= innerRings.reduce(0.0, { $0 + abs($1.area) })
        }

        return area
    }

}

extension MultiPolygon {

    /// Returns the *MultiPolygon*'s area.
    ///
    /// - Returns: The sum of all *Polygon*s areas, in square meters.
    public var area: Double {
        polygons.reduce(0.0, { $0 + $1.area })
    }

}

// MARK: - Copied from turf-swift

extension Ring {

    /// Calculate the approximate area of the polygon were it projected onto the earth, in square meters.
    /// Note that this area will be positive if ring is oriented clockwise, otherwise it will be negative.
    ///
    /// Reference:
    /// Robert. G. Chamberlain and William H. Duquette, "Some Algorithms for Polygons on a Sphere", JPL Publication 07-03, Jet Propulsion
    /// Laboratory, Pasadena, CA, June 2007 https://trs.jpl.nasa.gov/handle/2014/41271
    public var area: Double {
        let coordinates = projection == .epsg4326
            ? coordinates
            : coordinates.map({ $0.projected(to: .epsg4326) })

        var area = 0.0
        let coordinatesCount = coordinates.count

        if coordinatesCount > 2 {
            for index in 0 ..< coordinatesCount {
                let controlPoints: (Coordinate3D, Coordinate3D, Coordinate3D) = if index == coordinatesCount - 2 {
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

                area += (controlPoints.2.longitude.degreesToRadians - controlPoints.0.longitude.degreesToRadians) * sin(controlPoints.1.latitude.degreesToRadians)
            }

            area *= GISTool.equatorialRadius * GISTool.equatorialRadius / 2.0
        }

        return area
    }

}
