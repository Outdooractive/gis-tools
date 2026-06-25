import Foundation
@testable import GISTools
import Testing

struct CenterTests {

    // MARK: - center

    // Validates that the center of a `Point` is the point itself.
    @Test
    func pointCenter() async throws {
        let point = Point(Coordinate3D(latitude: 10.0, longitude: 20.0))
        let center = try #require(point.center)
        #expect(center.coordinate.latitude == 10.0)
        #expect(center.coordinate.longitude == 20.0)
    }

    // Validates that the geodesic center of a `LineString` is computed correctly (with curvature shift).
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

    // Validates that the center of a `Polygon` is computed correctly.
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

    // Validates that the center of a `Feature` delegates to its underlying geometry.
    @Test
    func featureCenter() async throws {
        let point = Point(Coordinate3D(latitude: 10.0, longitude: 20.0))
        let feature = Feature(point)
        let center = try #require(feature.center)
        #expect(center.coordinate.latitude == 10.0)
        #expect(center.coordinate.longitude == 20.0)
    }

    // MARK: - centroid

    // Validates that the centroid of a `Point` is the point itself.
    @Test
    func pointCentroid() async throws {
        let point = Point(Coordinate3D(latitude: 10.0, longitude: 20.0))
        let centroid = try #require(point.centroid)
        #expect(centroid.coordinate.latitude == 10.0)
        #expect(centroid.coordinate.longitude == 20.0)
    }

    // Validates that the centroid of a `LineString` is the mean of its coordinates.
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

    // Validates that the centroid of a `Polygon` is the mean of all its unique vertices.
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
        // Mean of 4 unique vertices (closing duplicate excluded)
        #expect(abs(centroid.coordinate.latitude - 5.0) < 0.0001)
        #expect(abs(centroid.coordinate.longitude - 5.0) < 0.0001)
    }

    // Validates that the centroid of a `MultiPoint` is the mean of all its points.
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

    // Validates that the centroid is nil for empty geometries.
    @Test
    func emptyCentroid() async throws {
        let ls = LineString()
        #expect(ls.centroid == nil)
    }

    // MARK: - centerMean

    // Validates that the unweighted center mean of a feature collection is correctly computed.
    @Test
    func centerMeanUnweighted() async throws {
        let p1 = Point(Coordinate3D(latitude: 0.0, longitude: 0.0))
        let p2 = Point(Coordinate3D(latitude: 10.0, longitude: 10.0))
        let fc = FeatureCollection([Feature(p1), Feature(p2)])

        let mean = try #require(fc.centerMean())
        #expect(mean.coordinate.latitude == 5.0)
        #expect(mean.coordinate.longitude == 5.0)
    }

    // Validates that the weighted center mean correctly applies per-feature weights.
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

    // Validates that features with zero weight are skipped when computing the weighted center mean.
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

    // Validates that center mean returns nil for an empty feature collection.
    @Test
    func centerMeanEmpty() async throws {
        let fc = FeatureCollection()
        #expect(fc.centerMean() == nil)
    }

    // MARK: - centerMean with LineString coordinates

    // Validates that center mean works correctly with `LineString` coordinates.
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

    // MARK: - centerOfMass

    // Validates that the center of mass of a `Point` is the point itself.
    @Test
    func pointCenterOfMass() async throws {
        let point = Point(Coordinate3D(latitude: 45.75764678012361, longitude: 4.831961989402771))
        let com = try #require(point.centerOfMass)
        #expect(com.coordinate.latitude == 45.75764678012361)
        #expect(com.coordinate.longitude == 4.831961989402771)
    }

    // Validates that the center of mass of a `Polygon` is computed correctly using the signed area method.
    @Test
    func polygonCenterOfMass() async throws {
        let polygon = try #require(Polygon([[
            Coordinate3D(latitude: 45.79398056386735, longitude: 4.8250579833984375),
            Coordinate3D(latitude: 45.79254427435898, longitude: 4.882392883300781),
            Coordinate3D(latitude: 45.76081677972451, longitude: 4.910373687744141),
            Coordinate3D(latitude: 45.7271539426975, longitude: 4.894924163818359),
            Coordinate3D(latitude: 45.71337148333104, longitude: 4.824199676513671),
            Coordinate3D(latitude: 45.74021417890731, longitude: 4.773387908935547),
            Coordinate3D(latitude: 45.778418789239055, longitude: 4.778022766113281),
            Coordinate3D(latitude: 45.79398056386735, longitude: 4.8250579833984375),
        ]]))
        let com = try #require(polygon.centerOfMass)
        #expect(abs(com.coordinate.latitude - 45.75581209996416) < 0.0001)
        #expect(abs(com.coordinate.longitude - 4.840728965137111) < 0.0001)
    }

    // Validates that the center of mass of a `Feature` wrapping a `Polygon` delegates correctly.
    @Test
    func featurePolygonCenterOfMass() async throws {
        let polygon = try #require(Polygon([[
            Coordinate3D(latitude: 45.79398056386735, longitude: 4.8250579833984375),
            Coordinate3D(latitude: 45.79254427435898, longitude: 4.882392883300781),
            Coordinate3D(latitude: 45.76081677972451, longitude: 4.910373687744141),
            Coordinate3D(latitude: 45.7271539426975, longitude: 4.894924163818359),
            Coordinate3D(latitude: 45.71337148333104, longitude: 4.824199676513671),
            Coordinate3D(latitude: 45.74021417890731, longitude: 4.773387908935547),
            Coordinate3D(latitude: 45.778418789239055, longitude: 4.778022766113281),
            Coordinate3D(latitude: 45.79398056386735, longitude: 4.8250579833984375),
        ]]))
        let feature = Feature(polygon)
        let com = try #require(feature.centerOfMass)
        #expect(abs(com.coordinate.latitude - 45.75581209996416) < 0.0001)
        #expect(abs(com.coordinate.longitude - 4.840728965137111) < 0.0001)
    }

    // Validates that the center of mass of a `Feature` wrapping a `Point` delegates correctly.
    @Test
    func featurePointCenterOfMass() async throws {
        let point = Point(Coordinate3D(latitude: 10.0, longitude: 20.0))
        let feature = Feature(point)
        let com = try #require(feature.centerOfMass)
        #expect(com.coordinate.latitude == 10.0)
        #expect(com.coordinate.longitude == 20.0)
    }

    // Validates that the center of mass falls back to the convex hull for non-polygon geometries (e.g., MultiPoint).
    @Test
    func multiPointCenterOfMass() async throws {
        let mp = try #require(MultiPoint([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 10.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 10.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
        ]))
        // The convex hull of these 4 points is a square. Center of mass ≈ (5, 5).
        let com = try #require(mp.centerOfMass)
        #expect(abs(com.coordinate.latitude - 5.0) < 0.0001)
        #expect(abs(com.coordinate.longitude - 5.0) < 0.0001)
    }

    // Validates that the center of mass falls back to the convex hull for a LineString.
    @Test
    func lineStringCenterOfMass() async throws {
        let ls = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
        ]))
        // 2 points -> convex hull returns nil (need >= 3 unique) -> fallback to centroid
        let com = ls.centerOfMass
        #expect(com != nil)
        #expect(abs(com!.coordinate.latitude - 5.0) < 0.0001)
        #expect(abs(com!.coordinate.longitude - 5.0) < 0.0001)
    }

    // Validates that center of mass is nil for empty geometries.
    @Test
    func emptyCenterOfMass() async throws {
        let ls = LineString()
        #expect(ls.centerOfMass == nil)
    }

    // Validates that center of mass works with a MultiPolygon (falls through to convex hull).
    @Test
    func multiPolygonCenterOfMass() async throws {
        let p1 = try #require(Polygon([[
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 10.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
            Coordinate3D(latitude: 10.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]]))
        let p2 = try #require(Polygon([[
            Coordinate3D(latitude: 20.0, longitude: 0.0),
            Coordinate3D(latitude: 20.0, longitude: 10.0),
            Coordinate3D(latitude: 30.0, longitude: 10.0),
            Coordinate3D(latitude: 30.0, longitude: 0.0),
            Coordinate3D(latitude: 20.0, longitude: 0.0),
        ]]))
        let mp = try #require(MultiPolygon([p1, p2]))
        let com = try #require(mp.centerOfMass)
        // Convex hull is a rectangle spanning lat 0-30, lon 0-10, center of mass ≈ (15, 5)
        #expect(abs(com.coordinate.latitude - 15.0) < 0.001)
        #expect(abs(com.coordinate.longitude - 5.0) < 0.001)
    }

    // MARK: - Projections

    // Verifies centroid of a polygon in EPSG:3857.
    @Test
    func polygonCentroid3857() throws {
        let polygon = try #require(Polygon([[
            Coordinate3D(x: 0.0, y: 0.0),
            Coordinate3D(x: 1_000.0, y: 0.0),
            Coordinate3D(x: 1_000.0, y: 1_000.0),
            Coordinate3D(x: 0.0, y: 1_000.0),
            Coordinate3D(x: 0.0, y: 0.0),
        ]]))
        let centroid = polygon.centroid
        #expect(centroid != nil)
        #expect(abs(centroid!.coordinate.x - 500.0) < 1.0)
        #expect(abs(centroid!.coordinate.y - 500.0) < 1.0)
        #expect(centroid!.coordinate.projection == .epsg3857)
    }

    // Verifies center of mass of a polygon in EPSG:3857.
    @Test
    func polygonCenterOfMass3857() throws {
        let polygon = try #require(Polygon([[
            Coordinate3D(x: 0.0, y: 0.0),
            Coordinate3D(x: 1_000.0, y: 0.0),
            Coordinate3D(x: 1_000.0, y: 1_000.0),
            Coordinate3D(x: 0.0, y: 1_000.0),
            Coordinate3D(x: 0.0, y: 0.0),
        ]]))
        let com = try #require(polygon.centerOfMass)
        #expect(abs(com.coordinate.x - 500.0) < 1.0)
        #expect(abs(com.coordinate.y - 500.0) < 1.0)
    }

    // MARK: - Antimeridian

    // Validates centroid of a polygon crossing the antimeridian.
    @Test
    func antimeridian() async throws {
        let polygon = try #require(Polygon([[
            Coordinate3D(latitude: 0.0, longitude: 170.0),
            Coordinate3D(latitude: 10.0, longitude: 170.0),
            Coordinate3D(latitude: 10.0, longitude: -170.0),
            Coordinate3D(latitude: 0.0, longitude: -170.0),
            Coordinate3D(latitude: 0.0, longitude: 170.0),
        ]]))
        let center = try #require(polygon.centroid)

        // After the fix, the centroid should be near the polygon's true center
        #expect(center.coordinate.latitude >= 0.0)
        #expect(center.coordinate.latitude <= 10.0)
        #expect(abs(center.coordinate.longitude) > 90.0)
    }

    // MARK: - centerMedian

    // Validates that centerMedian handles points that cross the antimeridian.
    @Test
    func centerMedianAntimeridian() async throws {
        let p1 = Point(Coordinate3D(latitude: 0.0, longitude: 170.0))
        let p2 = Point(Coordinate3D(latitude: 0.0, longitude: -170.0))
        let fc = FeatureCollection([Feature(p1), Feature(p2)])
        let median = try #require(fc.centerMedian())

        // Median should be near the antimeridian (lon ≈ ±180)
        #expect(abs(median.coordinate.latitude) < 0.01)
        #expect(abs(median.coordinate.longitude) > 170.0)
    }

    // Validates that centerMedian handles weighted points crossing the antimeridian.
    @Test
    func centerMedianAntimeridianWeighted() async throws {
        let p1 = Point(Coordinate3D(latitude: 0.0, longitude: 170.0))
        let p2 = Point(Coordinate3D(latitude: 0.0, longitude: -160.0))
        let p3 = Point(Coordinate3D(latitude: 0.0, longitude: -175.0))
        var f1 = Feature(p1)
        f1.setProperty(10.0, for: "w")
        let f2 = Feature(p2)
        let f3 = Feature(p3)
        let fc = FeatureCollection([f1, f2, f3])
        let median = try #require(fc.centerMedian(weightAttribute: "w"))

        // p1 at lon=170 with weight 10 should pull median toward the east side
        #expect(abs(median.coordinate.latitude) < 0.01)
        #expect(median.coordinate.longitude > 170.0 || median.coordinate.longitude < -170.0)
    }

    // Validates that the algorithm converges to a valid Point for symmetric data.
    @Test
    func centerMedianUnweighted() async throws {
        let p1 = Point(Coordinate3D(latitude: 0.0, longitude: 0.0))
        let p2 = Point(Coordinate3D(latitude: 10.0, longitude: 10.0))
        let fc = FeatureCollection([Feature(p1), Feature(p2)])

        let median = try #require(fc.centerMedian())
        // Should converge to a point between the two inputs
        #expect(median.coordinate.latitude > 0.0)
        #expect(median.coordinate.latitude < 10.0)
        #expect(median.coordinate.longitude > 0.0)
        #expect(median.coordinate.longitude < 10.0)
    }

    // Validates that weighted median center shifts toward higher-weighted points.
    @Test
    func centerMedianWeighted() async throws {
        let p1 = Point(Coordinate3D(latitude: 0.0, longitude: 0.0))
        let p2 = Point(Coordinate3D(latitude: 10.0, longitude: 10.0))
        var f1 = Feature(p1)
        f1.setProperty(1.0, for: "w")
        var f2 = Feature(p2)
        f2.setProperty(9.0, for: "w")

        let fc = FeatureCollection([f1, f2])
        let median = try #require(fc.centerMedian(weightAttribute: "w"))

        // Heavily weighted toward (10, 10)
        #expect(abs(median.coordinate.latitude - 10.0) < 0.5)
        #expect(abs(median.coordinate.longitude - 10.0) < 0.5)
    }

    // Validates that the median center is less sensitive to outliers than the mean center.
    @Test
    func centerMedianLessSensitiveToOutliers() async throws {
        let points = [
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 1.0),
            Coordinate3D(latitude: 1.0, longitude: 0.0),
            Coordinate3D(latitude: 8.0, longitude: 5.0),
        ]
        let fc = FeatureCollection(points.map { Feature(Point($0)) })
        let median = try #require(fc.centerMedian())
        let mean = try #require(fc.centerMean())

        // Median should be closer to the cluster than the mean
        let clusterCenter = Coordinate3D(latitude: 1.0 / 3.0, longitude: 1.0 / 3.0)
        let medianToCluster = median.coordinate.distance(from: clusterCenter)
        let meanToCluster = mean.coordinate.distance(from: clusterCenter)
        #expect(medianToCluster < meanToCluster)
    }

    // Validates that the median center of a single point is the point itself.
    @Test
    func centerMedianSinglePoint() async throws {
        let p = Point(Coordinate3D(latitude: 45.0, longitude: 8.0))
        let fc = FeatureCollection([Feature(p)])
        let median = try #require(fc.centerMedian())
        #expect(median.coordinate.latitude == 45.0)
        #expect(median.coordinate.longitude == 8.0)
    }

    // Validates that centerMedian returns nil for an empty feature collection.
    @Test
    func centerMedianEmpty() async throws {
        let fc = FeatureCollection()
        #expect(fc.centerMedian() == nil)
    }

    // Validates that centerMedian works correctly with LineString features.
    @Test
    func centerMedianLineString() async throws {
        let ls = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 10.0, longitude: 0.0),
        ]))
        let fc = FeatureCollection([Feature(ls)])
        let median = try #require(fc.centerMedian())
        // Centroid of this LineString is (5, 0)
        #expect(abs(median.coordinate.latitude - 5.0) < 0.001)
        #expect(abs(median.coordinate.longitude - 0.0) < 0.001)
    }

    // MARK: - Altitude preservation

    // Validates that centroid preserves altitude values.
    @Test
    func centroidPreservesAltitude() async throws {
        let coords = [
            Coordinate3D(latitude: 0.0, longitude: 0.0, altitude: 100.0),
            Coordinate3D(latitude: 10.0, longitude: 0.0, altitude: 200.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0, altitude: 300.0),
            Coordinate3D(latitude: 0.0, longitude: 10.0, altitude: 400.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0, altitude: 100.0),
        ]
        let polygon = try #require(Polygon([coords]))
        let centroid = try #require(polygon.centroid)
        #expect(centroid.coordinate.altitude != nil)
        #expect(abs(centroid.coordinate.altitude! - 250.0) < 0.001) // (100+200+300+400)/4
    }

    // Validates that center of mass preserves altitude values.
    @Test
    func centerOfMassPreservesAltitude() async throws {
        let coords = [
            Coordinate3D(latitude: 0.0, longitude: 0.0, altitude: 100.0),
            Coordinate3D(latitude: 10.0, longitude: 0.0, altitude: 200.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0, altitude: 300.0),
            Coordinate3D(latitude: 0.0, longitude: 10.0, altitude: 400.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0, altitude: 100.0),
        ]
        let polygon = try #require(Polygon([coords]))
        let com = try #require(polygon.centerOfMass)
        #expect(com.coordinate.altitude != nil)
    }

    // Validates that center mean preserves altitude values.
    @Test
    func centerMeanWeightedAltitude() async throws {
        let coords = [
            Coordinate3D(latitude: 0.0, longitude: 0.0, altitude: 100.0),
            Coordinate3D(latitude: 10.0, longitude: 0.0, altitude: 200.0),
        ]
        let ls = try #require(LineString(coords))
        let fc = FeatureCollection([Feature(ls)])
        let mean = try #require(fc.centerMean())
        #expect(mean.coordinate.altitude != nil)
        #expect(abs(mean.coordinate.altitude! - 150.0) < 0.001)
    }

    // Validates centroid omits altitude when not all vertices have it.
    @Test
    func centroidOmitsAltitudeWhenMixed() async throws {
        let coords = [
            Coordinate3D(latitude: 0.0, longitude: 0.0, altitude: 100.0),
            Coordinate3D(latitude: 10.0, longitude: 0.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0, altitude: 300.0),
            Coordinate3D(latitude: 0.0, longitude: 10.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0, altitude: 100.0),
        ]
        let polygon = try #require(Polygon([coords]))
        let centroid = try #require(polygon.centroid)
        #expect(centroid.coordinate.altitude == nil)
    }

    // MARK: - Projections

    // Verifies centroid in EPSG:3857 projection.
    @Test
    func centroidEPSG3857() async throws {
        let polygon = try #require(Polygon([[
            Coordinate3D(x: 0.0, y: 0.0),
            Coordinate3D(x: 1_000.0, y: 0.0),
            Coordinate3D(x: 1_000.0, y: 1_000.0),
            Coordinate3D(x: 0.0, y: 1_000.0),
            Coordinate3D(x: 0.0, y: 0.0),
        ]]))
        let c = try #require(polygon.centroid)
        #expect(c.coordinate.projection == .epsg3857)
        #expect(abs(c.coordinate.x - 500.0) < 0.001)
        #expect(abs(c.coordinate.y - 500.0) < 0.001)
    }

    // Verifies centroid in EPSG:4978 projection.
    @Test
    func centroidEPSG4978() async throws {
        let polygon = try #require(Polygon([[
            Coordinate3D(x: 0.0, y: 0.0, z: 0.0, projection: .epsg4978),
            Coordinate3D(x: 1_000.0, y: 0.0, z: 0.0, projection: .epsg4978),
            Coordinate3D(x: 1_000.0, y: 1_000.0, z: 0.0, projection: .epsg4978),
            Coordinate3D(x: 0.0, y: 1_000.0, z: 0.0, projection: .epsg4978),
            Coordinate3D(x: 0.0, y: 0.0, z: 0.0, projection: .epsg4978),
        ]]))
        let c = try #require(polygon.centroid)
        #expect(c.coordinate.projection == .epsg4978)
        #expect(c.coordinate.altitude != nil) // all coords have z: 0.0
        #expect(abs(c.coordinate.altitude!) < 0.001)
    }

    // Verifies centroid in noSRID projection.
    @Test
    func centroidNoSRID() async throws {
        let polygon = try #require(Polygon([[
            Coordinate3D(x: 0.0, y: 0.0, projection: .noSRID),
            Coordinate3D(x: 10.0, y: 0.0, projection: .noSRID),
            Coordinate3D(x: 10.0, y: 10.0, projection: .noSRID),
            Coordinate3D(x: 0.0, y: 10.0, projection: .noSRID),
            Coordinate3D(x: 0.0, y: 0.0, projection: .noSRID),
        ]]))
        let c = try #require(polygon.centroid)
        #expect(c.coordinate.projection == .noSRID)
        #expect(abs(c.coordinate.x - 5.0) < 0.001)
        #expect(abs(c.coordinate.y - 5.0) < 0.001)
    }

    // Validates that center preserves altitude values.
    @Test
    func centerPreservesAltitude() async throws {
        let coords = [
            Coordinate3D(latitude: 0.0, longitude: 0.0, altitude: 100.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0, altitude: 200.0),
            Coordinate3D(latitude: 0.0, longitude: 10.0, altitude: 300.0),
            Coordinate3D(latitude: 10.0, longitude: 0.0, altitude: 400.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0, altitude: 100.0),
        ]
        let polygon = try #require(Polygon([coords]))
        let center = try #require(polygon.center)
        // center delegates to boundingBox.center → midpoint, preserving altitude
        #expect(center.coordinate.altitude != nil)
    }

    // Validates that centerMedian preserves altitude values.
    @Test
    func centerMedianPreservesAltitude() async throws {
        let fc = FeatureCollection([
            Feature(Point(Coordinate3D(latitude: 0.0, longitude: 0.0, altitude: 100.0))),
            Feature(Point(Coordinate3D(latitude: 10.0, longitude: 10.0, altitude: 200.0))),
        ])
        let median = try #require(fc.centerMedian())
        #expect(median.coordinate.altitude != nil)
        #expect(abs(median.coordinate.altitude! - 150.0) < 5.0)
    }

}
