import Foundation
@testable import GISTools
import Testing

struct ProjectionWktMatcherTests {

    // Validates that the more specific EPSG:3857 Pseudo-Mercator pattern
    // wins over the generic EPSG:3395 Mercator pattern.
    @Test
    func pseudoMercatorBeforeMercator() async throws {
        #expect(Projection(wkt: #"PROJCS["WGS 84 / Pseudo-Mercator",..Mercator..]"#) == .epsg3857)
        #expect(Projection(wkt: #"PROJCS["WGS 84 / World Mercator",..]"#) == .epsg3395)
        #expect(Projection(wkt: #"PROJCS["WGS 1984 / World Mercator",..]"#) == .epsg3395)
    }

    // Validates the alternative-fragment matching for the geographic
    // projections: "WGS 84" and "WGS_1984" are matched independently.
    @Test
    func geographicAlternatives() async throws {
        #expect(Projection(wkt: #"GEOGCS["GCS_WGS_1984",DATUM["D_WGS_1984"]]"#) == .epsg4326)
        #expect(Projection(wkt: #"GEOGCS["WGS 84",DATUM["WGS_1984"]]"#) == .epsg4326)
        #expect(Projection(wkt: #"GEOCCS["WGS 84 (geocentric)",DATUM["WGS_1984"]]"#) == .epsg4978)
        #expect(Projection(wkt: ##"GEOCCS["WGS_1984 (geocentric)",DATUM["WGS_1984"]]"##) == .epsg4978)
    }

    // Validates unrecognized WKT strings.
    @Test
    func unrecognized() async throws {
        #expect(Projection(wkt: "PROJCS[\"Something Else\"]") == nil)
        #expect(Projection(wkt: "GEOGCS[\"ETRS89\"]") == nil)
        #expect(Projection(wkt: "") == nil)
    }

}
