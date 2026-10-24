@testable import GISTools
import Testing

struct GeometryDispatchTests {

    @Test
    func genericDispatchPreservesConcreteTypes() throws {
        let point = Point(Coordinate3D(latitude: 0.0, longitude: 0.0))
        let multiPoint = try #require(MultiPoint([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 1.0, longitude: 1.0),
        ]))
        let lineString = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 1.0, longitude: 1.0),
        ]))
        let multiLineString = try #require(MultiLineString([[
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 1.0, longitude: 1.0),
        ]]))
        let polygon = try #require(Polygon([[
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 1.0),
            Coordinate3D(latitude: 1.0, longitude: 1.0),
            Coordinate3D(latitude: 1.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]]))
        let multiPolygon = try #require(MultiPolygon([polygon]))
        let geometryCollection = GeometryCollection([
            point,
            multiPoint,
            lineString,
            multiLineString,
            polygon,
            multiPolygon,
        ])
        let feature = Feature(
            point,
            id: .string("point"),
            properties: ["name": "Point"],
            calculateBoundingBox: true)
        let unlocatedFeature = Feature(id: .string("unlocated"))
        let featureCollection = FeatureCollection([feature, unlocatedFeature])

        assertDispatch(point)
        assertDispatch(multiPoint)
        assertDispatch(lineString)
        assertDispatch(multiLineString)
        assertDispatch(polygon)
        assertDispatch(multiPolygon)
        assertDispatch(geometryCollection)
        assertDispatch(feature)
        assertDispatch(unlocatedFeature)
        assertDispatch(featureCollection)
    }

    @Test
    func coderSwitchesCoverEveryGeometryType() throws {
        let polygon = try #require(Polygon([[
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 1.0),
            Coordinate3D(latitude: 1.0, longitude: 1.0),
            Coordinate3D(latitude: 1.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]]))
        let collection = GeometryCollection([
            Point(Coordinate3D(latitude: 0.0, longitude: 0.0)),
            try #require(MultiPoint([Coordinate3D(latitude: 0.0, longitude: 0.0)])),
            try #require(LineString([
                Coordinate3D(latitude: 0.0, longitude: 0.0),
                Coordinate3D(latitude: 1.0, longitude: 1.0),
            ])),
            try #require(MultiLineString([[
                Coordinate3D(latitude: 0.0, longitude: 0.0),
                Coordinate3D(latitude: 1.0, longitude: 1.0),
            ]])),
            polygon,
            try #require(MultiPolygon([polygon])),
        ])

        let wkt = try #require(WKTCoder.encode(geometry: collection, targetProjection: nil))
        let decodedWKT = try #require(try WKTCoder.decode(
            wkt: wkt,
            sourceProjection: .epsg4326) as? GeometryCollection)
        #expect(decodedWKT.geometries.count == collection.geometries.count)

        let wkb = try #require(WKBCoder.encode(geometry: collection, targetProjection: nil))
        let decodedWKB = try #require(try WKBCoder.decode(
            wkb: wkb,
            sourceProjection: .epsg4326) as? GeometryCollection)
        #expect(decodedWKB.geometries.count == collection.geometries.count)
    }

    private func assertDispatch<T: GeoJson>(_ value: T) {
        let transformed = value.transformedCoordinates { $0 }
        #expect(transformed.projection == value.projection)

        let snapped = value.snappedToGrid(tolerance: 0.000001)
        #expect(snapped.projection == value.projection)

        let rewound = value.withWindingOrder(.clockwise)
        #expect(rewound.projection == value.projection)

        let projected = value.projected(to: value.projection)
        #expect(projected.projection == value.projection)
    }

}
