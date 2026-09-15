#if canImport(CoreLocation)
import CoreLocation
#endif
import Foundation

/// ETRS89/UTM math: the EPSG:25831–25837 zone belt (the ETRS89-flavoured
/// equivalent of EPSG:32631–32637), used across continental Europe.
///
/// Same transverse Mercator geometry as the WGS84 UTM zones on the GRS80
/// ellipsoid (identical semi-major axis, flattening differing in the 8th
/// decimal), with the ETRS89 datum (an identity transformation at this
/// library's accuracy; see ``Etrs89Definition``). The geometry differs
/// from the WGS84 blocks by decimeters at the zone edges through the
/// flattening, so the values are computed with ``Ellipsoid/grs80`` rather
/// than reusing the EPSG:326xx math directly.
struct Etrs89UtmDefinition: ProjectionDefinition {

    var projection: Projection {
        Projection(uncheckedSrid: 25_800 + zone, definition: self)
    }

    let zone: Int

    init(zone: Int) {
        precondition(zone >= 31 && zone <= 37, "ETRS89/UTM zones are 31 to 37")
        self.zone = zone
    }

    var kind: ProjectionKind { .planar }

    var datum: Datum { .etrs89 }

    var validExtent: ProjectionExtent? {
        ProjectionExtent(
            minX: 100_000.0,
            minY: 0.0,
            maxX: 900_000.0,
            maxY: 10_000_000.0)
    }

    var worldBoundingBox: BoundingBox? {
        guard let extent = validExtent else { return nil }
        return BoundingBox(
            southWest: Coordinate3D(x: extent.minX, y: extent.minY, projection: projection),
            northEast: Coordinate3D(x: extent.maxX, y: extent.maxY, projection: projection))
    }

    var wraparoundExtent: Double? { nil }

    var wktMatchers: [[String]] {
        // Identified through the UTM zone token evaluation in
        // ``Projection/init(wkt:)`` (the WKT carries an ETRS89 datum token
        // next to the zone token), so no matcher list is needed.
        []
    }

    var transverseMercator: TransverseMercatorMath {
        TransverseMercatorMath(
            ellipsoid: .grs80,
            latitudeOfOrigin: 0.0,
            longitudeOfOrigin: Double((zone - 1) * 6 - 180 + 3),
            scaleFactor: 0.9996,
            falseEasting: 500_000.0,
            falseNorthing: 0.0)
    }

    var prepared: BatchPreparedTransforms {
        let tm = transverseMercator
        let projection = self.projection

        return BatchPreparedTransforms(
            forward: { coordinate in
                let (easting, northing) = tm.forward(
                    latitude: coordinate.latitude,
                    longitude: coordinate.longitude)
                return Coordinate3D(
                    x: easting,
                    y: northing,
                    z: coordinate.altitude,
                    m: coordinate.m,
                    projection: projection)
            },
            inverse: { coordinate in
                let (latitude, longitude) = tm.inverse(
                    x: coordinate.longitude,
                    y: coordinate.latitude)
                return Coordinate3D(
                    latitude: latitude,
                    longitude: longitude,
                    altitude: coordinate.altitude,
                    m: coordinate.m)
            })
    }

    func forward(_ coordinate: Coordinate3D) -> Coordinate3D {
        let (easting, northing) = transverseMercator.forward(
            latitude: coordinate.latitude,
            longitude: coordinate.longitude)

        return Coordinate3D(
            x: easting,
            y: northing,
            z: coordinate.altitude,
            m: coordinate.m,
            projection: projection)
    }

    func inverse(_ coordinate: Coordinate3D) -> Coordinate3D {
        let (latitude, longitude) = transverseMercator.inverse(
            x: coordinate.longitude,
            y: coordinate.latitude)

        return Coordinate3D(
            latitude: latitude,
            longitude: longitude,
            altitude: coordinate.altitude,
            m: coordinate.m)
    }

    /// Returns the ETRS89/UTM definition for a canonical SRID.
    static func definition(forSrid srid: Int) -> Etrs89UtmDefinition? {
        guard srid >= 25_831, srid <= 25_837 else { return nil }
        return Etrs89UtmDefinition(zone: srid - 25_800)
    }

}
