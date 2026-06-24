#if canImport(CoreLocation)
import CoreLocation
#endif
import Foundation
@testable import GISTools
import Testing

struct CLLocationDegreesExtensionsTests {

    // MARK: - bearingToAzimuth

    @Test
    func bearingToAzimuthPositive() async throws {
        let bearing: CLLocationDegrees = 45.0
        #expect(bearing.bearingToAzimuth == 45.0)
    }

    @Test
    func bearingToAzimuthZero() async throws {
        let bearing: CLLocationDegrees = 0.0
        #expect(bearing.bearingToAzimuth == 0.0)
    }

    @Test
    func bearingToAzimuthFullCircle() async throws {
        let bearing: CLLocationDegrees = 360.0
        #expect(bearing.bearingToAzimuth == 0.0)
    }

    @Test
    func bearingToAzimuthNegative() async throws {
        let bearing: CLLocationDegrees = -45.0
        #expect(bearing.bearingToAzimuth == 315.0)
    }

    @Test
    func bearingToAzimuthLargeNegative() async throws {
        let bearing: CLLocationDegrees = -450.0
        #expect(bearing.bearingToAzimuth == 270.0)
    }

    @Test
    func bearingToAzimuthLargePositive() async throws {
        let bearing: CLLocationDegrees = 450.0
        #expect(bearing.bearingToAzimuth == 90.0)
    }

    @Test
    func bearingToAzimuthExactly360() async throws {
        let bearing: CLLocationDegrees = -360.0
        #expect(bearing.bearingToAzimuth == 0.0)
    }

}
