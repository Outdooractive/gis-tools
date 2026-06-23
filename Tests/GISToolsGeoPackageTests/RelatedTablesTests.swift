import Testing
import Foundation
@testable import GISTools
@testable import GISToolsGeoPackage

struct GeoPackageRelatedTablesTests {

    private let tmpDir = URL(fileURLWithPath: "/tmp")

    private func testUrl(_ name: String = #function) -> URL {
        let cleanName = name.hasSuffix("()") ? String(name.dropLast(2)) : name
        return tmpDir.appendingPathComponent("gpkg_\(cleanName).gpkg")
    }

    @Test
    func attributeTableRoundTrip() async throws {
        let dbUrl = testUrl()
        try? FileManager.default.removeItem(at: dbUrl)

        try await FeatureCollection([
            Feature(Point(Coordinate3D(latitude: 10.0, longitude: 20.0)))
        ]).writeGeopackage(to: dbUrl)

        let attributes = AttributeTable(
            tableName: "station_info",
            columns: ["name", "elevation"],
            rows: [
                ["name": "Summit", "elevation": 1200],
                ["name": "Base", "elevation": 400],
            ],
            rowIds: [1, 2])

        try GeoPackage.writeAttributeTable(attributes, to: dbUrl)

        let db = try SQLiteDB(path: dbUrl.path)
        defer { db.close() }

        let sqlRows = try db.query("SELECT * FROM \"station_info\";")
        #expect(sqlRows.count == 2)
        guard sqlRows.count == 2 else { return }

        let read = try GeoPackage.readAttributeTable(from: dbUrl, table: "station_info")
        #expect(read.rows.count == 2)
        #expect(read.rowIds == [1, 2])

        let c2 = try db.query(
            "SELECT data_type FROM gpkg_contents WHERE table_name = 'station_info';")
        #expect(!c2.isEmpty)
        #expect(c2.first?["data_type"] as? String == "attributes")
    }

    @Test
    func mediaTableRoundTrip() async throws {
        let dbUrl = testUrl()
        try? FileManager.default.removeItem(at: dbUrl)

        try await FeatureCollection([
            Feature(Point(Coordinate3D(latitude: 10.0, longitude: 20.0)))
        ]).writeGeopackage(to: dbUrl)

        let imageData = Data([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00])
        let media = MediaTable(
            tableName: "photos",
            rowIds: [1],
            data: [imageData],
            contentTypes: ["image/png"],
            properties: [["caption": "Summit photo"]])

        try GeoPackage.writeMediaTable(media, to: dbUrl)
        let read = try GeoPackage.readMediaTable(from: dbUrl, table: "photos")

        #expect(read.count == 1)
        #expect(read.rowIds == [1])
        #expect(read.data[0] == imageData)
        #expect(read.contentTypes[0] == "image/png")
        #expect(read.properties[0]["caption"] as? String == "Summit photo")
    }

    @Test
    func relationshipsRoundTrip() async throws {
        let dbUrl = testUrl()
        try? FileManager.default.removeItem(at: dbUrl)

        try await FeatureCollection([
            Feature(Point(Coordinate3D(latitude: 10.0, longitude: 20.0)))
        ]).writeGeopackage(to: dbUrl)

        let attributes = AttributeTable(
            tableName: "info",
            columns: ["value"],
            rows: [["value": "test"]],
            rowIds: [1])
        try GeoPackage.writeAttributeTable(attributes, to: dbUrl)

        let db = try SQLiteDB(path: dbUrl.path)
        defer { db.close() }

        let relation = RelationRow(
            id: "rel1",
            tableName: "features",
            columnName: "geom",
            relatedTableName: "info",
            relatedColumnName: "id",
            relationName: .attributes)

        try GeoPackage.registerRelatedTablesExtension(in: db)
        try GeoPackage.writeRelation(relation, in: db)

        let relations = try GeoPackage.readRelations(in: db)
        #expect(relations.count == 1)
        #expect(relations[0].id == "rel1")
        #expect(relations[0].tableName == "features")
        #expect(relations[0].relatedTableName == "info")
        #expect(relations[0].relationName == .attributes)
        #expect(relations[0].mappingTableName == nil)
    }

    @Test
    func attributeTableValidation() async throws {
        let dbUrl = testUrl()
        try? FileManager.default.removeItem(at: dbUrl)

        try await FeatureCollection([
            Feature(Point(Coordinate3D(latitude: 0.0, longitude: 0.0)))
        ]).writeGeopackage(to: dbUrl)

        let attributes = AttributeTable(
            tableName: "data",
            columns: ["value"],
            rows: [["value": 42]],
            rowIds: [1])
        try GeoPackage.writeAttributeTable(attributes, to: dbUrl)

        let result = try GeoPackage.validate(url: dbUrl)
        #expect(result.isValid,
                "Expected valid: errors=\(result.errors.map(\.message))")
    }

    @Test
    func loadRelatedAttributesViaFeatureCollection() async throws {
        let dbUrl = testUrl()
        try? FileManager.default.removeItem(at: dbUrl)

        try await FeatureCollection([
            Feature(Point(Coordinate3D(latitude: 10.0, longitude: 20.0)))
        ]).writeGeopackage(to: dbUrl)

        let attributes = AttributeTable(
            tableName: "info",
            columns: ["value"],
            rows: [["value": "hello"]],
            rowIds: [1])
        try GeoPackage.writeAttributeTable(attributes, to: dbUrl)

        let gpkg = try GeoPackageConnection(url: dbUrl)
        try await gpkg.registerRelatedTablesExtension()
        try await gpkg.write(relation: RelationRow(
            id: "r1",
            tableName: "features",
            relatedTableName: "info",
            relationName: .attributes))

        let rels = try await gpkg.readRelations()
        let rel = try #require(rels.first)
        let attrs = try await gpkg.readAttributeTable(table: rel.relatedTableName)
        #expect(attrs.tableName == "info")
        #expect(attrs.rows.count == 1)
    }

    @Test
    func featureRelatedAttributes() async throws {
        let dbUrl = testUrl()
        try? FileManager.default.removeItem(at: dbUrl)

        try await FeatureCollection([
            Feature(Point(Coordinate3D(latitude: 10.0, longitude: 20.0)))
        ]).writeGeopackage(to: dbUrl)

        let attributes = AttributeTable(
            tableName: "info",
            columns: ["value"],
            rows: [["value": "row1"], ["value": "row2"]],
            rowIds: [1, 2])
        try GeoPackage.writeAttributeTable(attributes, to: dbUrl)

        let gpkg = try GeoPackageConnection(url: dbUrl)
        try await gpkg.registerRelatedTablesExtension()
        try await gpkg.write(relation: RelationRow(
            id: "r1",
            tableName: "features",
            relatedTableName: "info",
            relationName: .attributes))

        let fc = try await FeatureCollection(geopackage: dbUrl, table: "features")
        #expect(fc.features.count == 1)

        guard let feature = fc.features.first,
              case .int(let rowId) = feature.id
        else { return }

        #expect(rowId == 1)
        #expect(feature.gpkgTableName == "features")

        let related = try await feature.relatedAttributes(in: gpkg)
        #expect(related.count == 1)
        #expect(related[0]["value"] as? String == "row1")
    }

}
