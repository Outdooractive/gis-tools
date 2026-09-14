#if canImport(CoreLocation)
import CoreLocation
#endif
import Foundation
@testable import GISTools
import Testing

/// Algorithm round trips and smoke tests in UTM zone projections.
struct UtmAlgorithmTests {

    // MARK: - Known reference values

    // Validates forward values against independently computed references:
    // the Snyder formulas were verified in Python against numerically
    // integrated meridian arcs before being ported.
    @Test
    func knownReferenceValues() async throws {
        // Zone 31N at 50N/3E (central meridian): x is exactly the false
        // easting, y is the scaled meridian arc to 50 degrees (verified
        // against numeric integration of the meridian radius).
        let zone31 = Coordinate3D(latitude: 50.0, longitude: 3.0).projected(to: .epsg32631)
        #expect(abs(zone31.longitude - 500_000.0) < 0.000001)
        #expect(abs(zone31.latitude - 5_538_630.703) < 0.001)

        // Zone edges at the equator are the known ±333_978.56 meter offsets
        // around the false easting (zones 1 and 60 both touch the date line).
        let zoneEdgeWest = Coordinate3D(latitude: 0.0, longitude: -180.0).projected(to: .epsg32601)
        #expect(abs(zoneEdgeWest.longitude - 166_021.443) < 0.001)
        #expect(abs(zoneEdgeWest.latitude) < 0.000001)

        let zoneEdgeEast = Coordinate3D(latitude: 0.0, longitude: 174.0).projected(to: .epsg32660)
        #expect(abs(zoneEdgeEast.longitude - 166_021.443) < 0.001)

        // Zone 19N at 41N/71W.
        let zone19 = Coordinate3D(latitude: 41.0, longitude: -71.0).projected(to: .epsg32619)
        #expect(abs(zone19.longitude - 331_792.115) < 0.001)
        #expect(abs(zone19.latitude - 4_540_683.529) < 0.001)

        // Zone 20S at 45.5S/63W: northing is below 10_000_000 (false northing).
        let zone20south = Coordinate3D(latitude: -45.5, longitude: -63.0).projected(to: .epsg32720)
        #expect(abs(zone20south.longitude - 500_000.0) < 0.000001)
        #expect(abs(zone20south.latitude - 4_961_503.495) < 0.001)
    }

    // Validates round trips between EPSG:4326 and both hemispheres of the
    // same zone: eastings are identical and northings differ by exactly the
    // 10_000_000 false-northing offset.
    @Test
    func hemisphereSymmetry() async throws {
        let equator = Coordinate3D(latitude: 0.0, longitude: -71.0)
        let north = equator.projected(to: .epsg32619)
        let south = equator.projected(to: .epsg32719)

        #expect(abs(north.longitude - south.longitude) < 0.0000000001)
        #expect(abs(south.latitude - (north.latitude + 10_000_000.0)) < 0.000001)

        #expect(abs(south.projected(to: .epsg4326).longitude - -71.0) < 0.0000000001)
        #expect(abs(south.projected(to: .epsg4326).latitude - 0.0) < 0.0000000001)
    }

    // MARK: - Round trips

    // Round-trips coordinates through each point's own zone across all
    // longitudes and near-polar latitudes.
    @Test
    func roundTrips() async throws {
        let latitudes: [Double] = [0.0, 41.0, -45.5, 80.0, -80.0, 89.0, -89.0]
        let longitudes: [Double] = [-180.0, -177.0, -150.0, -71.0, 0.0, 3.0, 45.0, 150.0, 174.0, 179.0]

        for longitude in longitudes {
            let zone = Int((longitude + 180.0).rounded(.down) / 6.0) + 1
            for latitude in latitudes {
                let srid: Int = latitude >= 0 ? 32_600 + zone : 32_700 + zone
                let projection: Projection = try #require(Projection(srid: srid))
                let original = Coordinate3D(latitude: latitude, longitude: longitude)

                let projected = original.projected(to: projection)
                #expect(abs(projected.longitude - 500_000.0) < 350_000.0) // inside the zone

                let back = projected.projected(to: .epsg4326)
                #expect(abs(back.latitude - latitude) < 0.00001)
                #expect(abs(back.longitude - longitude) < 0.00001)
            }
        }
    }

    // MARK: - Algorithm smoke tests

    // Validates bounding boxes and containment in a UTM zone.
    @Test
    func boundingBoxAndContains() async throws {
        let coordinates: [[Coordinate3D]] = [[
            Coordinate3D(x: 300_000.0, y: 4_000_000.0, projection: .epsg32619),
            Coordinate3D(x: 400_000.0, y: 4_000_000.0, projection: .epsg32619),
            Coordinate3D(x: 400_000.0, y: 4_100_000.0, projection: .epsg32619),
            Coordinate3D(x: 300_000.0, y: 4_100_000.0, projection: .epsg32619),
            Coordinate3D(x: 300_000.0, y: 4_000_000.0, projection: .epsg32619),
        ]]
        let polygon = try #require(Polygon(coordinates, calculateBoundingBox: true))
        #expect(polygon.projection == .epsg32619)

        let boundingBox = try #require(polygon.boundingBox)
        #expect(boundingBox.projection == .epsg32619)
        #expect(boundingBox.southWest.x == 300_000.0)
        #expect(boundingBox.northEast.x == 400_000.0)

        #expect(polygon.contains(Coordinate3D(x: 350_000.0, y: 4_050_000.0, projection: .epsg32619)))
        #expect(!polygon.contains(Coordinate3D(x: 450_000.0, y: 4_050_000.0, projection: .epsg32619)))
    }

    // Validates Euclidean distance (planar kind) in a UTM zone.
    @Test
    func distance() async throws {
        let origin = Coordinate3D(x: 500_000.0, y: 4_000_000.0, projection: .epsg32619)
        let point = Coordinate3D(x: 500_000.0, y: 4_300_000.0, projection: .epsg32619)

        #expect(abs(origin.distance(from: point) - 300_000.0) < 0.000001)
    }

    // Validates that the antimeridian machinery is a no-op for UTM zones:
    // coordinates in a zone never wrap, so nothing crosses or cuts.
    @Test
    func antimeridianIsNoop() async throws {
        #expect(Projection.epsg32660.wraparoundExtent == nil)

        // A geographic line across the date line, expressed in zone 60/1
        // coordinates: no wrap is possible within a zone.
        let lineCoordinates: [Coordinate3D] = [
            Coordinate3D(x: 700_000.0, y: 0.0, projection: .epsg32660),
            Coordinate3D(x: 100_000.0, y: 10_000.0, projection: .epsg32660),
        ]
        let line = try #require(LineString(lineCoordinates))

        #expect(!line.crossesAntimeridian)
        let cut = line.cutAtAntimeridian()
        #expect(cut.features.count == 1)
    }

    // Validates normalize/clamp in a zone sector.
    @Test
    func normalizeAndClamp() async throws {
        // Zone coordinates never wrap (no wraparound extent).
        let normalized = Coordinate3D(x: 950_000.0, y: 5_000_000.0, projection: .epsg32619).normalized()
        #expect(normalized.longitude == 950_000.0)

        let clamped = Coordinate3D(x: 50_000.0, y: 20_000_000.0, projection: .epsg32620).clamped()
        #expect(clamped.longitude == 100_000.0)
        #expect(clamped.latitude == 10_000_000.0)
    }

    // Validates geodesic operations via the EPSG:4326 pivot.
    @Test
    func destinationAndBearing() async throws {
        // 100_000 meters north of a zone point.
        // `destination()` uses a spherical earth model, so the grid northern
        // distance differs from the elipsoidal meridian arc by a few hundred
        // meters at mid latitudes; the tolerance accounts for that.
        let start = Coordinate3D(x: 500_000.0, y: 4_000_000.0, projection: .epsg32619)
        let destination = start.destination(distance: 100_000.0, bearing: 0.0)
        #expect(destination.projection == .epsg32619)
        #expect(abs(destination.longitude - 500_000.0) < 1.0)
        #expect(abs(destination.latitude - 4_100_000.0) < 500.0)
        #expect(destination.latitude > start.latitude)
    }

    // MARK: - Coders

    // Validates a WKB round trip with an embedded UTM zone SRID.
    @Test
    func wkbRoundTrip() async throws {
        let point = Point(Coordinate3D(x: 331_792.115, y: 4_540_683.529, projection: .epsg32619))

        let wkb = try #require(WKBCoder.encode(geometry: point, targetProjection: .epsg32619))
        let decoded = try #require(WKBCoder.decode(
            wkb: wkb,
            sourceSrid: nil,
            targetProjection: .epsg32619) as? Point)
        #expect(decoded.projection == .epsg32619)
        #expect(abs(decoded.coordinate.x - 331_792.115) < 0.000001)
        #expect(abs(decoded.coordinate.y - 4_540_683.529) < 0.000001)
    }

    // Validates random coordinate generation in a zone's world box.
    @Test
    func random() async throws {
        let coordinate = BoundingBox.randomCoordinate(projection: .epsg32619)
        #expect(coordinate.projection == .epsg32619)
        #expect(coordinate.longitude >= 100_000.0)
        #expect(coordinate.longitude <= 900_000.0)
        #expect(coordinate.latitude >= 0.0)
        #expect(coordinate.latitude <= 10_000_000.0)
    }

}
