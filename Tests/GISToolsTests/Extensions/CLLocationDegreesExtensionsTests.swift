#if canImport(CoreLocation)
import CoreLocation
#endif
import Foundation
@testable import GISTools
import Testing

struct CLLocationDegreesExtensionsTests {

    // MARK: - bearingToAzimuth

    // Validates bearingToAzimuth returns the same value for positive bearing.
    @Test
    func bearingToAzimuthPositive() async throws {
        let bearing: CLLocationDegrees = 45.0
        #expect(bearing.bearingToAzimuth == 45.0)
    }

    // Verifies bearingToAzimuth returns 0 for zero bearing.
    @Test
    func bearingToAzimuthZero() async throws {
        let bearing: CLLocationDegrees = 0.0
        #expect(bearing.bearingToAzimuth == 0.0)
    }

    // Verifies bearingToAzimuth normalizes 360 to 0.
    @Test
    func bearingToAzimuthFullCircle() async throws {
        let bearing: CLLocationDegrees = 360.0
        #expect(bearing.bearingToAzimuth == 0.0)
    }

    // Verifies bearingToAzimuth wraps negative bearings into 0..<360.
    @Test
    func bearingToAzimuthNegative() async throws {
        let bearing: CLLocationDegrees = -45.0
        #expect(bearing.bearingToAzimuth == 315.0)
    }

    // Verifies bearingToAzimuth handles large negative values via normalization.
    @Test
    func bearingToAzimuthLargeNegative() async throws {
        let bearing: CLLocationDegrees = -450.0
        #expect(bearing.bearingToAzimuth == 270.0)
    }

    // Verifies bearingToAzimuth handles large positive values via normalization.
    @Test
    func bearingToAzimuthLargePositive() async throws {
        let bearing: CLLocationDegrees = 450.0
        #expect(bearing.bearingToAzimuth == 90.0)
    }

    // Verifies bearingToAzimuth normalizes -360 to 0.
    @Test
    func bearingToAzimuthExactly360() async throws {
        let bearing: CLLocationDegrees = -360.0
        #expect(bearing.bearingToAzimuth == 0.0)
    }

}
