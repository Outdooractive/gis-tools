import Foundation
@testable import GISTools
import Testing

/// Tests for the UTM zone SRIDs and their definitions.
struct UtmDefinitionTests {

    /// Validates that all 120 UTM SRIDs map to their zone projection and
    /// resolve to a registered definition with the expected metadata.
    @Test
    func sridMapping() async throws {
        for zone in 1 ... 60 {
            let northern = try #require(Projection(srid: 32_600 + zone))
            #expect(northern.srid == 32_600 + zone)
            let northernDefinition = UtmDefinition.definition(for: northern)
            #expect(northernDefinition?.zone == zone)
            #expect(northernDefinition?.hemisphere == .north)
            #expect(northernDefinition?.projection == northern)

            let southern = try #require(Projection(srid: 32_700 + zone))
            let southernDefinition = UtmDefinition.definition(for: southern)
            #expect(southernDefinition?.zone == zone)
            #expect(southernDefinition?.hemisphere == .south)
            #expect(southernDefinition?.projection == southern)
        }

        // Non-UTM SRIDs have no UTM definition.
        #expect(UtmDefinition.definition(for: .epsg4326) == nil)
        #expect(UtmDefinition.definition(for: .epsg3857) == nil)
        #expect(UtmDefinition.definition(for: .noSRID) == nil)
    }

    /// Validates that every projection case resolves to a registered
    /// definition (registry coverage).
    @Test
    func registryCoverage() async throws {
        for srid in [0, 3857, 4326, 4978, 3395, 32662] {
            let projection = try #require(Projection(srid: srid))
            #expect(projection.definition.projection == projection)
        }
        for srid in 32_601 ... 32_660 {
            let projection = try #require(Projection(srid: srid))
            #expect(projection.definition.projection == projection)
        }
        for srid in 32_701 ... 32_760 {
            let projection = try #require(Projection(srid: srid))
            #expect(projection.definition.projection == projection)
        }
    }

    /// Validates zone metadata.
    @Test
    func zoneMetadata() async throws {
        for zone in 1 ... 60 {
            let projection = try #require(Projection(srid: 32_600 + zone))
            let definition = try #require(UtmDefinition.definition(for: projection))

            // Central meridian: zone 1 is at -177 degrees, zones step by 6 degrees.
            let expectedCentralLongitude = Double((zone - 1) * 6 - 180 + 3)
            #expect(abs(definition.centralMeridian * 180.0 / .pi - expectedCentralLongitude) < 0.0000000001)
        }

        // Sector extent per hemisphere convention (false northing caps y).
        let northern = try #require(UtmDefinition.definition(for: .epsg32619))
        #expect(northern.hemisphere.falseNorthing == 0.0)
        #expect(northern.validExtent?.minY == 0.0)
        #expect(northern.validExtent?.maxY == 10_000_000.0)
        #expect(northern.validExtent?.minX == 100_000.0)
        #expect(northern.validExtent?.maxX == 900_000.0)

        // The world bounding box covers the zone sector; UTM zones do not wrap.
        let worldBox = try #require(northern.worldBoundingBox)
        #expect(worldBox.projection == .epsg32619)
        #expect(worldBox.southWest.x == 100_000.0)
        #expect(worldBox.northEast.x == 900_000.0)

        // Description strings.
        #expect(Projection.epsg32619.description == "EPSG:32619")
        #expect(Projection.epsg32719.description == "EPSG:32719")
    }

    /// Validates the UTM convenience API.
    @Test
    func utmConvenienceApi() async throws {
        for zone in [1, 19, 33, 60] {
            let northern = try #require(Projection(utmZone: zone, hemisphere: .north))
            #expect(northern.srid == 32_600 + zone)
            #expect(northern.utmZone == zone)
            #expect(northern.utmHemisphere == .north)

            let southern = try #require(Projection(utmZone: zone, hemisphere: .south))
            #expect(southern.srid == 32_700 + zone)
            #expect(southern.utmZone == zone)
            #expect(southern.utmHemisphere == .south)
        }

        // Invalid zone numbers.
        #expect(Projection(utmZone: 0, hemisphere: .north) == nil)
        #expect(Projection(utmZone: 61, hemisphere: .south) == nil)

        // Non-UTM projections.
        #expect(Projection.epsg4326.utmZone == nil)
        #expect(Projection.epsg4326.utmHemisphere == nil)
        #expect(Projection.epsg3857.utmZone == nil)
        #expect(Projection.epsg3395.utmHemisphere == nil)
        #expect(Projection.noSRID.utmZone == nil)
    }

}
