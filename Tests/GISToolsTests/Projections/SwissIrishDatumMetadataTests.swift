#if canImport(CoreLocation)
import CoreLocation
#endif
import Foundation
@testable import GISTools
import Testing

/// Tests for the datum metadata of the Swiss/Irish CRS family.
struct SwissIrishDatumMetadataTests {

    /// Validates the datum/ellipsoid wiring of the new projections.
    @Test
    func projectionDatums() async throws {
        #expect(Projection.epsg2056.datum == Datum.ch1903plus)
        #expect(Projection.epsg21781.datum == Datum.ch1903)
        #expect(Projection.epsg29902.datum == Datum.tm65)
        #expect(Projection.epsg29903.datum == Datum.tm75)
        #expect(Projection.epsg2157.datum == Datum.irenet95)

        #expect(Ellipsoid.bessel1841.semiMajorAxis == 6_377_397.155)
        #expect(Ellipsoid.modifiedAiry.semiMajorAxis == 6_377_340.189)
        #expect(Datum.irenet95.ellipsoid == Ellipsoid.grs80)
    }

}
