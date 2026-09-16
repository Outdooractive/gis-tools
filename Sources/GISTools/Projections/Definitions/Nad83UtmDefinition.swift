#if canImport(CoreLocation)
import CoreLocation
#endif
import Foundation

/// NAD83 UTM math: the EPSG:26901–26960 zone belt (the NAD83-flavoured
/// equivalent of EPSG:326xx), used across the United States and Canada.
///
/// Same transverse Mercator geometry as the WGS84 UTM zones on the GRS80
/// ellipsoid, with the NAD83 datum (effectively coincident with WGS84 at
/// meter accuracy; see ``Nad83Definition``). The northern belt covers
/// zones 1–60; NAD83 has no southern zone block (its area of use is North
/// America).
struct Nad83UtmDefinition: ProjectionDefinition {

    var projection: Projection {
        Projection(uncheckedSrid: 26900 + zone, definition: self)
    }

    let zone: Int

    init(zone: Int) {
        precondition(zone >= 1 && zone <= 60, "NAD83/UTM zones are 1 to 60")
        self.zone = zone
    }

    var kind: ProjectionKind {
        .planar
    }

    var datum: Datum {
        .nad83
    }

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

    var wraparoundExtent: Double? {
        nil
    }

    var wktMatchers: [[String]] {
        // Identified through the UTM zone token evaluation in
        // ``Projection/init(wkt:)`` (the WKT carries an NAD83 datum token
        // next to the zone token), so no matcher list is needed.
        []
    }

    /// The Karney transverse Mercator setup of the zone.
    var karneyTransverseMercator: KarneyTransverseMercatorMath {
        KarneyTransverseMercatorMath(
            ellipsoid: .grs80,
            longitudeOfOrigin: Double((zone - 1) * 6 - 180 + 3),
            scaleFactor: 0.9996,
            falseEasting: 500_000.0,
            falseNorthing: 0.0)
    }

    var prepared: BatchPreparedTransforms {
        let tm = karneyTransverseMercator
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
        let (easting, northing) = karneyTransverseMercator.forward(
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
        let (latitude, longitude) = karneyTransverseMercator.inverse(
            x: coordinate.longitude,
            y: coordinate.latitude)

        return Coordinate3D(
            latitude: latitude,
            longitude: longitude,
            altitude: coordinate.altitude,
            m: coordinate.m)
    }

    /// Returns the NAD83/UTM definition for a canonical SRID
    /// (EPSG:26901–26960).
    static func definition(forSrid srid: Int) -> Nad83UtmDefinition? {
        guard srid >= 26901, srid <= 26960 else { return nil }

        return Nad83UtmDefinition(zone: srid - 26900)
    }

}
