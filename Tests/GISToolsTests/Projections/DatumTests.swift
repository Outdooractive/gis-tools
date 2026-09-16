#if canImport(CoreLocation)
import CoreLocation
#endif
import Foundation
@testable import GISTools
import Testing

/// Tests for the datum metadata model.
struct DatumTests {

    /// Validates the well-known ellipsoid reference values (EPSG registry).
    @Test
    func ellipsoidReferenceValues() async throws {
        #expect(Ellipsoid.wgs84.semiMajorAxis == 6_378_137.0)
        #expect(Ellipsoid.wgs84.inverseFlattening == 298.257223563)
        #expect(abs(Ellipsoid.wgs84.semiMinorAxis - 6_356_752.31424518) < 0.000001)

        #expect(Ellipsoid.grs80.semiMajorAxis == 6_378_137.0)
        #expect(Ellipsoid.grs80.inverseFlattening == 298.257222101)

        #expect(Ellipsoid.clarke1866.semiMajorAxis == 6_378_206.4)
        #expect(Ellipsoid.clarke1866.inverseFlattening == 294.978698213898)

        #expect(Ellipsoid.airy1830.semiMajorAxis == 6_377_563.396)
        #expect(Ellipsoid.airy1830.inverseFlattening == 299.3249646)
    }

    /// Validates the well-known datum constants.
    @Test
    func datumConstants() async throws {
        #expect(Datum.wgs84.ellipsoid == Ellipsoid.wgs84)
        #expect(Datum.etrs89.ellipsoid == Ellipsoid.grs80)
        #expect(Datum.nad27.ellipsoid == Ellipsoid.clarke1866)
        #expect(Datum.osgb1936.ellipsoid == Ellipsoid.airy1830)
    }

    /// Validates that the built-in projections report their datums.
    @Test
    func projectionDatums() async throws {
        #expect(Projection.epsg4326.datum == Datum.wgs84)
        #expect(Projection.epsg3857.datum == Datum.wgs84)
        #expect(Projection.epsg4978.datum == Datum.wgs84)
        #expect(Projection.epsg3395.datum == Datum.wgs84)
        #expect(Projection.epsg32662.datum == Datum.wgs84)

        #expect(Projection.epsg4258.datum == Datum.etrs89)
        #expect(Projection.epsg4267.datum == Datum.nad27)
        #expect(Projection.epsg4277.datum == Datum.osgb1936)
        #expect(Projection.epsg27700.datum == Datum.osgb1936)
    }

}
