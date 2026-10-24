#if canImport(CoreLocation)
import CoreLocation
#endif
import Foundation
@testable import GISTools
import Testing

/// Tests for the Helmert datum transformation helper.
///
/// The reference values were computed independently with pyproj/PROJ 9
/// (EPSG "NAD27 to WGS 84 (4)", accuracy ~10 m, and the OS-documented
/// "OSGB 1936 to WGS 84 (6)" transformation, EPSG:1314, accuracy ~2 m).
struct HelmertTransformationTests {

    /// Validates WGS84 → datum coordinates against the reference values.
    @Test
    func wgs84ToDatum() {
        // Reference: pyproj, Helmert inverse of "NAD27 to WGS 84 (4)".
        // (wgs84 lat/lon in, NAD27 lat/lon out)
        let helmertNad27 = HelmertTransformation.nad27
        let nad27 = helmertNad27.transform(wgs84ToDatum: Coordinate3D(latitude: 40.0, longitude: -100.0))
        #expect(abs(nad27.latitude - 39.999990516) < 0.00000001)
        #expect(abs(nad27.longitude - -99.999582393) < 0.00000001)

        // Reference: pyproj, Helmert inverse of "OSGB 1936 to WGS 84 (6)"
        // (zero height)
        let helmertOsgb = HelmertTransformation.osgb1936
        let osgb = helmertOsgb.transform(wgs84ToDatum: Coordinate3D(latitude: 52.0, longitude: -1.0))
        #expect(abs(osgb.latitude - 51.999560347) < 0.00000001)
        #expect(abs(osgb.longitude - -0.998473603) < 0.00000001)
    }

    /// Validates the datum → WGS84 direction against the reference values.
    @Test
    func datumToWgs84() {
        let helmertNad27 = HelmertTransformation.nad27
        let wgs84 = helmertNad27.transform(datumToWgs84: Coordinate3D(latitude: 39.999990516, longitude: -99.999582393))
        #expect(abs(wgs84.latitude - 40.0) < 0.00000001)
        #expect(abs(wgs84.longitude - -100.0) < 0.00000001)

        let helmertOsgb = HelmertTransformation.osgb1936
        let wgs84Uk = helmertOsgb.transform(datumToWgs84: Coordinate3D(latitude: 51.999560347, longitude: -0.998473603))
        #expect(abs(wgs84Uk.latitude - 52.0) < 0.00000001)
        #expect(abs(wgs84Uk.longitude - -1.0) < 0.0000001)
    }

    /// Validates the rotation-free and full 7-parameter matrix versions
    /// round trip through both directions.
    ///
    /// With the height passing through unchanged, the round trip is not
    /// exactly closed: the return leg rebuilds the ECEF position at the
    /// *input* height while the datum frame it came from encodes the
    /// datum-shifted height — the same ~1e-9..1e-8 degree looseness PROJ's
    /// own `+towgs84` pipeline exhibits (its round trips show the same
    /// order of magnitude). The tolerance reflects that reality (2e-8 deg
    /// ≈ 2 mm at the equator), far inside the transformations' stated
    /// 1–10 m accuracy.
    @Test
    func roundTrips() {
        // NAD27 has no rotations/scale; OSGB applies the full 7 parameters.
        for (helmert, testCoordinate) in [
            (HelmertTransformation.nad27, Coordinate3D(latitude: 40.0, longitude: -100.0, altitude: 300.0)),
            (HelmertTransformation.osgb1936, Coordinate3D(latitude: 52.5, longitude: -1.5, altitude: 250.0)),
        ] {
            let datumFrame = helmert.transform(wgs84ToDatum: testCoordinate)
            let back = helmert.transform(datumToWgs84: datumFrame)
            #expect(abs(back.latitude - testCoordinate.latitude) < 0.00000002)
            #expect(abs(back.longitude - testCoordinate.longitude) < 0.00000002)
            #expect(abs((back.altitude ?? 0.0) - (testCoordinate.altitude ?? 0.0)) < 0.00000001)
            #expect(back.m == testCoordinate.m)
        }
    }

    /// Zero parameters must be an exact identity in both directions.
    @Test
    func zeroParameterTransformationIsIdentity() {
        let identity = HelmertTransformation(datum: .wgs84, dx: 0.0, dy: 0.0, dz: 0.0)
        let coordinate = Coordinate3D(latitude: 12.34, longitude: 56.78, altitude: 123.0, m: 7.0)

        let toDatum = identity.transform(wgs84ToDatum: coordinate)
        let toWgs84 = identity.transform(datumToWgs84: coordinate)

        #expect(abs(toDatum.latitude - coordinate.latitude) < 0.000000001)
        #expect(abs(toDatum.longitude - coordinate.longitude) < 0.000000001)
        #expect(abs(toWgs84.latitude - coordinate.latitude) < 0.000000001)
        #expect(abs(toWgs84.longitude - coordinate.longitude) < 0.000000001)
        #expect(toDatum.altitude == coordinate.altitude)
        #expect(toDatum.m == coordinate.m)
    }

    /// The hoisted batch path must match the single-coordinate path exactly.
    @Test
    func preparedBatchMatchesSinglePath() {
        let coordinate = Coordinate3D(latitude: 47.5, longitude: 11.0, altitude: 600.0, m: 4.0)
        for helmert in [HelmertTransformation.nad27, .osgb1936] {
            let steps = helmert.prepared()
            let singleToWgs84 = helmert.transform(datumToWgs84: coordinate)
            let batchToWgs84 = helmert.transform(
                datumToWgs84: coordinate,
                step: steps.datumToWgs84)
            #expect(abs(singleToWgs84.latitude - batchToWgs84.latitude) < 0.0000000001)
            #expect(abs(singleToWgs84.longitude - batchToWgs84.longitude) < 0.0000000001)

            let singleToDatum = helmert.transform(wgs84ToDatum: coordinate)
            let batchToDatum = helmert.transform(
                wgs84ToDatum: coordinate,
                step: steps.wgs84ToDatum)
            #expect(abs(singleToDatum.latitude - batchToDatum.latitude) < 0.0000000001)
            #expect(abs(singleToDatum.longitude - batchToDatum.longitude) < 0.0000000001)
        }
    }

    /// The description exposes the datum and every Helmert parameter.
    @Test
    func descriptionIncludesParameters() {
        let description = HelmertTransformation.osgb1936.description
        #expect(description.contains("OSGB"))
        #expect(description.contains("446.448"))
        #expect(description.contains("-125.157"))
        #expect(description.contains("542.06"))
        #expect(description.contains("-20.489"))
    }

    /// The transformation remains finite at the equator and near the poles,
    /// and preserves the nominal height/metadata.
    @Test
    func poleAndEquatorCoordinatesStayFinite() {
        let helmert = HelmertTransformation.osgb1936
        let coordinates = [
            Coordinate3D(latitude: 0.0, longitude: 0.0, altitude: 10.0, m: 1.0),
            Coordinate3D(latitude: 89.999, longitude: 45.0, altitude: 20.0, m: 2.0),
            Coordinate3D(latitude: -89.999, longitude: -120.0, altitude: 30.0, m: 3.0),
        ]
        for coordinate in coordinates {
            let transformed = helmert.transform(datumToWgs84: coordinate)
            #expect(transformed.latitude.isFinite)
            #expect(transformed.longitude.isFinite)
            #expect(transformed.altitude == coordinate.altitude)
            #expect(transformed.m == coordinate.m)
        }
    }

}
