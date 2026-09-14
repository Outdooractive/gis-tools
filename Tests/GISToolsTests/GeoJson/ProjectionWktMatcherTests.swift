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

    // MARK: - UTM zone identification

    /// Realistic ESRI-style `.prj` content: the Transverse_Mercator mention
    /// must not fall through to the generic EPSG:3395 Mercator fragments,
    /// and the central meridian must agree with the zone.
    @Test
    func utmEsriPrj() async throws {
        let prj = #"PROJCS["WGS_1984_UTM_Zone_19N",GEOGCS["GCS_WGS_1984",DATUM["D_WGS_1984",SPHEROID["WGS_1984",6378137,298.257223563]],PRIMEM["Greenwich",0],UNIT["Degree",0.0174532925199433]],PROJECTION["Transverse_Mercator"],PARAMETER["latitude_of_origin",0],PARAMETER["central_meridian",-69],PARAMETER["scale_factor",0.9996],PARAMETER["false_easting",500000],PARAMETER["false_northing",0],UNIT["metre",1]]"#

        #expect(Projection(wkt: prj) == .epsg32619)

        let prjSouth = prj
            .replacingOccurrences(of: #"Zone_19N"#, with: #"Zone_20S"#)
            .replacingOccurrences(of: #"central_meridian",-69"#, with: #"central_meridian",-63"#)
        #expect(Projection(wkt: prjSouth) == .epsg32720)

        // A UTM token that is contradicted by its parameters rejects the
        // whole string instead of falling through to unrelated fragments.
        let contradicted = prjSouth
            .replacingOccurrences(of: #"central_meridian",-63"#, with: #"central_meridian",-70"#)
        #expect(Projection(wkt: contradicted) == nil)
    }

    // Validates zone/hemisphere extraction variants (spaces, underscores,
    // casing) and the date-line edge zones.
    @Test
    func utmZoneVariants() async throws {
        #expect(Projection(wkt: "UTM Zone 1N") == .epsg32601)
        #expect(Projection(wkt: "UTM Zone 60S") == .epsg32760)
        #expect(Projection(wkt: "WGS_1984_UTM_Zone_18S") == .epsg32718)
        #expect(Projection(wkt: "utm zone 5n (WGS84)") == .epsg32605)
        #expect(Projection(wkt: "Universal Transverse Mercator Zone 33 N") == .epsg32633)
    }

    // Validates the central meridian cross-validation: a central meridian
    // that does not belong to the named zone makes the match fail.
    @Test
    func utmCentralMeridianValidation() async throws {
        #expect(Projection(wkt: #"UTM Zone 19N,PARAMETER["Central_Meridian",-69]"#) == .epsg32619)
        #expect(Projection(wkt: #"UTM Zone 19N,PARAMETER["Central_Meridian",-70]"#) == nil)
        #expect(Projection(wkt: #"UTM Zone 7S,PARAMETER["Central_Meridian",-141]"#) == .epsg32707)
        #expect(Projection(wkt: #"UTM Zone 7S,PARAMETER["Central_Meridian",-140]"#) == nil)
    }

    // Validates that incomplete or invalid UTM tokens do not match.
    @Test
    func utmInvalid() async throws {
        // Hemisphere is required.
        #expect(Projection(wkt: #"PROJCS["UTM Zone 19","#) == nil)
        // Zones outside 1...60.
        #expect(Projection(wkt: "UTM Zone 0N") == nil)
        #expect(Projection(wkt: "UTM Zone 61N") == nil)
        #expect(Projection(wkt: "UTM Zone 100N") == nil)
        #expect(Projection(wkt: "UTM Zones") == nil)
    }

}
