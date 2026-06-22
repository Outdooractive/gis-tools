@testable import GISTools
import Testing

struct CollectTests {

    /// Collects population values from points inside two separate polygon bins.
    @Test
    func collectPopulation() {
        let poly1 = Polygon(unchecked: [[
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 5.0, longitude: 0.0),
            Coordinate3D(latitude: 5.0, longitude: 5.0),
            Coordinate3D(latitude: 0.0, longitude: 5.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]])
        let poly2 = Polygon(unchecked: [[
            Coordinate3D(latitude: 10.0, longitude: 10.0),
            Coordinate3D(latitude: 15.0, longitude: 10.0),
            Coordinate3D(latitude: 15.0, longitude: 15.0),
            Coordinate3D(latitude: 10.0, longitude: 15.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
        ]])

        var point1 = Feature(Point(Coordinate3D(latitude: 2.5, longitude: 2.5)))
        point1.properties = ["pop": 100]
        var point2 = Feature(Point(Coordinate3D(latitude: 3.0, longitude: 3.0)))
        point2.properties = ["pop": 200]
        var point3 = Feature(Point(Coordinate3D(latitude: 12.5, longitude: 12.5)))
        point3.properties = ["pop": 300]

        let polys = FeatureCollection([Feature(poly1), Feature(poly2)])
        let points = FeatureCollection([point1, point2, point3])

        let result = polys.collect(from: points, inProperty: "pop", outProperty: "collected_pop")

        #expect(result.features.count == 2)

        let collected1 = result.features[0].properties["collected_pop"] as? [Int]
        #expect(collected1 != nil)
        if let collected1 {
            #expect(collected1.count == 2)
            #expect(collected1.contains(100))
            #expect(collected1.contains(200))
        }

        let collected2 = result.features[1].properties["collected_pop"] as? [Int]
        #expect(collected2 != nil)
        if let collected2 {
            #expect(collected2.count == 1)
            #expect(collected2[0] == 300)
        }
    }

    /// A polygon with no points inside gets an empty array.
    @Test
    func emptyCollection() {
        let poly = Polygon(unchecked: [[
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 5.0, longitude: 0.0),
            Coordinate3D(latitude: 5.0, longitude: 5.0),
            Coordinate3D(latitude: 0.0, longitude: 5.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]])
        var point = Feature(Point(Coordinate3D(latitude: 50.0, longitude: 50.0)))
        point.properties = ["val": 42]

        let polys = FeatureCollection([Feature(poly)])
        let result = polys.collect(from: FeatureCollection([point]), inProperty: "val", outProperty: "vals")

        let vals = result.features[0].properties["vals"] as? [Int]
        #expect(vals != nil)
        #expect(vals?.isEmpty == true)
    }

    /// Non-polygon features in the collection pass through unchanged.
    @Test
    func nonPolygonFeature() {
        let line = LineString(unchecked: [
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
        ])

        let polys = FeatureCollection([Feature(line)])
        let result = polys.collect(from: FeatureCollection(), inProperty: "x", outProperty: "y")

        #expect(result.features.count == 1)
        #expect(result.features[0].properties["y"] == nil)
    }

    /// Collects points in EPSG:3857 into a multi-point result.
    @Test
    func collect3857() {
        let poly = Polygon(unchecked: [[
            Coordinate3D(x: 0.0, y: 0.0),
            Coordinate3D(x: 200_000.0, y: 0.0),
            Coordinate3D(x: 200_000.0, y: 200_000.0),
            Coordinate3D(x: 0.0, y: 200_000.0),
            Coordinate3D(x: 0.0, y: 0.0),
        ]])
        var point1 = Feature(Point(Coordinate3D(x: 50_000.0, y: 50_000.0)))
        point1.properties = ["pop": 100]
        var point2 = Feature(Point(Coordinate3D(x: 150_000.0, y: 150_000.0)))
        point2.properties = ["pop": 200]

        let polys = FeatureCollection([Feature(poly)])
        let points = FeatureCollection([point1, point2])

        let result = polys.collect(from: points, inProperty: "pop", outProperty: "collected_pop")

        #expect(result.features.count == 1)

        let collected = result.features[0].properties["collected_pop"] as? [Int]
        #expect(collected != nil)
        if let collected {
            #expect(collected.count == 2)
        }
    }

}
