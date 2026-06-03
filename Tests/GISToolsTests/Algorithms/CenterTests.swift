import Foundation
@testable import GISTools
import Testing

struct CenterTests {

    // MARK: - center

    @Test
    func pointCenter() async throws {
        let point = Point(Coordinate3D(latitude: 10.0, longitude: 20.0))
        let center = try #require(point.center)
        #expect(center.coordinate.latitude == 10.0)
        #expect(center.coordinate.longitude == 20.0)
    }

    @Test
    func lineStringCenter() async throws {
        let ls = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
        ]))
        let center = try #require(ls.center)
        // Geodesic center should be near (5, 5) but shifted due to curvature
        #expect(abs(center.coordinate.latitude - 5.0) < 0.2)
        #expect(abs(center.coordinate.longitude - 5.0) < 0.2)
    }

    @Test
    func polygonCenter() async throws {
        let polygon = try #require(Polygon([[
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 10.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
            Coordinate3D(latitude: 10.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]]))
        let center = try #require(polygon.center)
        #expect(abs(center.coordinate.latitude - 5.0) < 1.0)
        #expect(abs(center.coordinate.longitude - 5.0) < 1.0)
    }

    @Test
    func featureCenter() async throws {
        let point = Point(Coordinate3D(latitude: 10.0, longitude: 20.0))
        let feature = Feature(point)
        let center = try #require(feature.center)
        #expect(center.coordinate.latitude == 10.0)
        #expect(center.coordinate.longitude == 20.0)
    }

    // MARK: - centroid

    @Test
    func pointCentroid() async throws {
        let point = Point(Coordinate3D(latitude: 10.0, longitude: 20.0))
        let centroid = try #require(point.centroid)
        #expect(centroid.coordinate.latitude == 10.0)
        #expect(centroid.coordinate.longitude == 20.0)
    }

    @Test
    func lineStringCentroid() async throws {
        let ls = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
        ]))
        let centroid = try #require(ls.centroid)
        // Mean of (0,0) and (10,10) = (5,5)
        #expect(centroid.coordinate.latitude == 5.0)
        #expect(centroid.coordinate.longitude == 5.0)
    }

    @Test
    func polygonCentroid() async throws {
        let polygon = try #require(Polygon([[
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 10.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
            Coordinate3D(latitude: 10.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]]))
        let centroid = try #require(polygon.centroid)
        // Mean of all 5 coordinates (including the closing point)
        let expectedLat = (0.0 + 0.0 + 10.0 + 10.0 + 0.0) / 5.0
        let expectedLon = (0.0 + 10.0 + 10.0 + 0.0 + 0.0) / 5.0
        #expect(centroid.coordinate.latitude == expectedLat)
        #expect(centroid.coordinate.longitude == expectedLon)
    }

    @Test
    func multiPointCentroid() async throws {
        let mp = try #require(MultiPoint([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 10.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 10.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
        ]))
        let centroid = try #require(mp.centroid)
        #expect(centroid.coordinate.latitude == 5.0)
        #expect(centroid.coordinate.longitude == 5.0)
    }

    // MARK: - centroid (edge cases)

    @Test
    func emptyCentroid() async throws {
        let ls = LineString()
        #expect(ls.centroid == nil)
    }

    // MARK: - centerMean

    @Test
    func centerMeanUnweighted() async throws {
        let p1 = Point(Coordinate3D(latitude: 0.0, longitude: 0.0))
        let p2 = Point(Coordinate3D(latitude: 10.0, longitude: 10.0))
        let fc = FeatureCollection([Feature(p1), Feature(p2)])

        let mean = try #require(fc.centerMean())
        #expect(mean.coordinate.latitude == 5.0)
        #expect(mean.coordinate.longitude == 5.0)
    }

    @Test
    func centerMeanWeighted() async throws {
        let p1 = Point(Coordinate3D(latitude: 0.0, longitude: 0.0))
        let p2 = Point(Coordinate3D(latitude: 10.0, longitude: 10.0))
        var f1 = Feature(p1)
        f1.setProperty(2.0, for: "w")
        var f2 = Feature(p2)
        f2.setProperty(8.0, for: "w")

        let fc = FeatureCollection([f1, f2])
        let mean = try #require(fc.centerMean(weightAttribute: "w"))

        // Weighted: (0*2 + 10*8) / 10 = 8 for both lat and lon
        #expect(mean.coordinate.latitude == 8.0)
        #expect(mean.coordinate.longitude == 8.0)
    }

    @Test
    func centerMeanZeroWeightSkipped() async throws {
        let p1 = Point(Coordinate3D(latitude: 0.0, longitude: 0.0))
        let p2 = Point(Coordinate3D(latitude: 10.0, longitude: 10.0))
        var f1 = Feature(p1)
        f1.setProperty(0.0, for: "w")
        var f2 = Feature(p2)
        f2.setProperty(1.0, for: "w")

        let fc = FeatureCollection([f1, f2])
        let mean = try #require(fc.centerMean(weightAttribute: "w"))
        // f1 skipped (weight 0), only f2 counts
        #expect(mean.coordinate.latitude == 10.0)
        #expect(mean.coordinate.longitude == 10.0)
    }

    @Test
    func centerMeanEmpty() async throws {
        let fc = FeatureCollection()
        #expect(fc.centerMean() == nil)
    }

    // MARK: - centerMean with LineString coordinates

    @Test
    func centerMeanLineString() async throws {
        let ls = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 10.0, longitude: 0.0),
        ]))
        let fc = FeatureCollection([Feature(ls)])
        let mean = try #require(fc.centerMean())
        #expect(mean.coordinate.latitude == 5.0)
        #expect(mean.coordinate.longitude == 0.0)
    }

}
