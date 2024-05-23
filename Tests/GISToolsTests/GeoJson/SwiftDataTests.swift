@testable import GISTools
import SwiftData
import XCTest

@available(macOS 14, *)
final class SwiftDataTests: XCTestCase {

    @Model
    class GeoJsonModel {
        @Attribute(.unique) var id: Int
        @Attribute(.transformable(by: GeoJsonTransformer.name.rawValue)) var geoJson: GeoJson?

        init(id: Int, geoJson: GeoJson) {
            self.id = id
            self.geoJson = geoJson
        }
    }

    let container = {
        GeoJsonTransformer.register()

        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try! ModelContainer(for: GeoJsonModel.self, configurations: config)
    }()

    @MainActor
    func testInsert() throws {
        let geoJsonTests: [Int: GeoJson] = [
            0: try XCTUnwrap(Point(jsonString: PointTests.pointJson)),
            1: try XCTUnwrap(MultiPoint(jsonString: MultiPointTests.multiPointJson)),
            2: try XCTUnwrap(Feature(jsonString: FeatureTests.featureJson)),
            3: try XCTUnwrap(FeatureCollection(jsonString: FeatureCollectionTests.featureCollectionJson)),
            4: try XCTUnwrap(GeometryCollection(jsonString: GeometryCollectionTests.geometryCollectionJson)),
            5: try XCTUnwrap(LineString(jsonString: LineStringTests.lineStringJson)),
            6: try XCTUnwrap(MultiLineString(jsonString: MultiLineStringTests.multiLineStringJson)),
            7: try XCTUnwrap(Polygon(jsonString: PolygonTests.polygonJsonNoHole)),
            8: try XCTUnwrap(MultiPolygon(jsonString: MultiPolygonTests.multiPolygonJson)),
        ]

        // Insert
        for (id, geoJson) in geoJsonTests {
            let model = GeoJsonModel(id: id, geoJson: geoJson)
            container.mainContext.insert(model)
        }

        // Check
        for (id, geoJson) in geoJsonTests {
            var descriptor = FetchDescriptor<GeoJsonModel>(
                predicate: #Predicate { $0.id == id },
                sortBy: [SortDescriptor(\.id)])
            descriptor.fetchLimit = 1

            let result = try XCTUnwrap(container.mainContext.fetch(descriptor).first?.geoJson)
            XCTAssertTrue(result.isEqualTo(geoJson))
        }
    }

}
