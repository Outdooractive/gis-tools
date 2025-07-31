import Foundation
@testable import GISTools
import Testing

#if canImport(SwiftData)
import SwiftData

struct SwiftDataTests {

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
    @Test(.disabled(if: CIHelper.isRunningInCI, "This test will currently not run in CI"))
    func insert() async throws {
        let geoJsonTests: [Int: GeoJson] = [
            0: try #require(Point(jsonString: PointTests.pointJson)),
            1: try #require(MultiPoint(jsonString: MultiPointTests.multiPointJson)),
            2: try #require(Feature(jsonString: FeatureTests.featureJson)),
            3: try #require(FeatureCollection(jsonString: FeatureCollectionTests.featureCollectionJson)),
            4: try #require(GeometryCollection(jsonString: GeometryCollectionTests.geometryCollectionJson)),
            5: try #require(LineString(jsonString: LineStringTests.lineStringJson)),
            6: try #require(MultiLineString(jsonString: MultiLineStringTests.multiLineStringJson)),
            7: try #require(Polygon(jsonString: PolygonTests.polygonJsonNoHole)),
            8: try #require(MultiPolygon(jsonString: MultiPolygonTests.multiPolygonJson)),
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

            let result = try #require(container.mainContext.fetch(descriptor).first?.geoJson)
            #expect(result.isEqualTo(geoJson))
        }
    }

}
#endif
