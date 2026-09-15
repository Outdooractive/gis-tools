/// A coordinate reference system.
///
/// Projections are value types identified by their ``srid``: equality,
/// hashing and `Codable` operate on the SRID number alone. Transform math
/// and metadata (``kind``, ``wraparoundExtent``, extents, ...) resolve
/// through the projection registry.
///
/// Every projection known to the library provides a constant (e.g.
/// ``Projection/epsg4326``, ``Projection/epsg32619``). Projections are
/// resolved through ``init(srid:)`` (with SRID aliases), ``init(wkt:)``
/// or ``init(utmZone:hemisphere:)``.
public struct Projection:
    Hashable,
    CustomStringConvertible,
    Codable,
    Sendable
{

    // MARK: - Built-in projections

    /// No SRID (invalid/unknown projection).
    public static let noSRID = Projection.builtin(srid: 0)
    /// EPSG:3857 - web mercator (https://epsg.io/3857).
    public static let epsg3857 = Projection.builtin(srid: 3857)
    /// EPSG:4326 - geodetic (https://epsg.io/4326).
    public static let epsg4326 = Projection.builtin(srid: 4326)
    /// EPSG:4978 - geocentric (ECEF) (https://epsg.io/4978).
    public static let epsg4978 = Projection.builtin(srid: 4978)
    /// EPSG:3395 - WGS 84 / World Mercator, ellipsoidal Mercator
    /// (https://epsg.io/3395).
    public static let epsg3395 = Projection.builtin(srid: 3395)
    /// EPSG:32662 - WGS 84 / Plate Carree, equirectangular
    /// (https://epsg.io/32662).
    public static let epsg32662 = Projection.builtin(srid: 32_662)
    /// EPSG:4258 - ETRS89 geodetic degrees (https://epsg.io/4258).
    /// Effectively coincides with WGS84 at meter accuracy.
    public static let epsg4258 = Projection.builtin(srid: 4258)
    /// EPSG:4267 - NAD27 geodetic degrees (https://epsg.io/4267).
    public static let epsg4267 = Projection.builtin(srid: 4267)
    /// EPSG:4277 - OSGB 1936 geodetic degrees (https://epsg.io/4277).
    public static let epsg4277 = Projection.builtin(srid: 4277)
    /// EPSG:27700 - OSGB 1936 / British National Grid (https://epsg.io/27700).
    public static let epsg27700 = Projection.builtin(srid: 27_700)
    // UTM zones (northern EPSG:32601-32660, southern EPSG:32701-32760).
    /// EPSG:32601 - UTM zone 1N (https://epsg.io/32601).
    public static let epsg32601 = Projection.builtin(srid: 32601)
    /// EPSG:32602 - UTM zone 2N (https://epsg.io/32602).
    public static let epsg32602 = Projection.builtin(srid: 32602)
    /// EPSG:32603 - UTM zone 3N (https://epsg.io/32603).
    public static let epsg32603 = Projection.builtin(srid: 32603)
    /// EPSG:32604 - UTM zone 4N (https://epsg.io/32604).
    public static let epsg32604 = Projection.builtin(srid: 32604)
    /// EPSG:32605 - UTM zone 5N (https://epsg.io/32605).
    public static let epsg32605 = Projection.builtin(srid: 32605)
    /// EPSG:32606 - UTM zone 6N (https://epsg.io/32606).
    public static let epsg32606 = Projection.builtin(srid: 32606)
    /// EPSG:32607 - UTM zone 7N (https://epsg.io/32607).
    public static let epsg32607 = Projection.builtin(srid: 32607)
    /// EPSG:32608 - UTM zone 8N (https://epsg.io/32608).
    public static let epsg32608 = Projection.builtin(srid: 32608)
    /// EPSG:32609 - UTM zone 9N (https://epsg.io/32609).
    public static let epsg32609 = Projection.builtin(srid: 32609)
    /// EPSG:32610 - UTM zone 10N (https://epsg.io/32610).
    public static let epsg32610 = Projection.builtin(srid: 32610)
    /// EPSG:32611 - UTM zone 11N (https://epsg.io/32611).
    public static let epsg32611 = Projection.builtin(srid: 32611)
    /// EPSG:32612 - UTM zone 12N (https://epsg.io/32612).
    public static let epsg32612 = Projection.builtin(srid: 32612)
    /// EPSG:32613 - UTM zone 13N (https://epsg.io/32613).
    public static let epsg32613 = Projection.builtin(srid: 32613)
    /// EPSG:32614 - UTM zone 14N (https://epsg.io/32614).
    public static let epsg32614 = Projection.builtin(srid: 32614)
    /// EPSG:32615 - UTM zone 15N (https://epsg.io/32615).
    public static let epsg32615 = Projection.builtin(srid: 32615)
    /// EPSG:32616 - UTM zone 16N (https://epsg.io/32616).
    public static let epsg32616 = Projection.builtin(srid: 32616)
    /// EPSG:32617 - UTM zone 17N (https://epsg.io/32617).
    public static let epsg32617 = Projection.builtin(srid: 32617)
    /// EPSG:32618 - UTM zone 18N (https://epsg.io/32618).
    public static let epsg32618 = Projection.builtin(srid: 32618)
    /// EPSG:32619 - UTM zone 19N (https://epsg.io/32619).
    public static let epsg32619 = Projection.builtin(srid: 32619)
    /// EPSG:32620 - UTM zone 20N (https://epsg.io/32620).
    public static let epsg32620 = Projection.builtin(srid: 32620)
    /// EPSG:32621 - UTM zone 21N (https://epsg.io/32621).
    public static let epsg32621 = Projection.builtin(srid: 32621)
    /// EPSG:32622 - UTM zone 22N (https://epsg.io/32622).
    public static let epsg32622 = Projection.builtin(srid: 32622)
    /// EPSG:32623 - UTM zone 23N (https://epsg.io/32623).
    public static let epsg32623 = Projection.builtin(srid: 32623)
    /// EPSG:32624 - UTM zone 24N (https://epsg.io/32624).
    public static let epsg32624 = Projection.builtin(srid: 32624)
    /// EPSG:32625 - UTM zone 25N (https://epsg.io/32625).
    public static let epsg32625 = Projection.builtin(srid: 32625)
    /// EPSG:32626 - UTM zone 26N (https://epsg.io/32626).
    public static let epsg32626 = Projection.builtin(srid: 32626)
    /// EPSG:32627 - UTM zone 27N (https://epsg.io/32627).
    public static let epsg32627 = Projection.builtin(srid: 32627)
    /// EPSG:32628 - UTM zone 28N (https://epsg.io/32628).
    public static let epsg32628 = Projection.builtin(srid: 32628)
    /// EPSG:32629 - UTM zone 29N (https://epsg.io/32629).
    public static let epsg32629 = Projection.builtin(srid: 32629)
    /// EPSG:32630 - UTM zone 30N (https://epsg.io/32630).
    public static let epsg32630 = Projection.builtin(srid: 32630)
    /// EPSG:32631 - UTM zone 31N (https://epsg.io/32631).
    public static let epsg32631 = Projection.builtin(srid: 32631)
    /// EPSG:32632 - UTM zone 32N (https://epsg.io/32632).
    public static let epsg32632 = Projection.builtin(srid: 32632)
    /// EPSG:32633 - UTM zone 33N (https://epsg.io/32633).
    public static let epsg32633 = Projection.builtin(srid: 32633)
    /// EPSG:32634 - UTM zone 34N (https://epsg.io/32634).
    public static let epsg32634 = Projection.builtin(srid: 32634)
    /// EPSG:32635 - UTM zone 35N (https://epsg.io/32635).
    public static let epsg32635 = Projection.builtin(srid: 32635)
    /// EPSG:32636 - UTM zone 36N (https://epsg.io/32636).
    public static let epsg32636 = Projection.builtin(srid: 32636)
    /// EPSG:32637 - UTM zone 37N (https://epsg.io/32637).
    public static let epsg32637 = Projection.builtin(srid: 32637)
    /// EPSG:32638 - UTM zone 38N (https://epsg.io/32638).
    public static let epsg32638 = Projection.builtin(srid: 32638)
    /// EPSG:32639 - UTM zone 39N (https://epsg.io/32639).
    public static let epsg32639 = Projection.builtin(srid: 32639)
    /// EPSG:32640 - UTM zone 40N (https://epsg.io/32640).
    public static let epsg32640 = Projection.builtin(srid: 32640)
    /// EPSG:32641 - UTM zone 41N (https://epsg.io/32641).
    public static let epsg32641 = Projection.builtin(srid: 32641)
    /// EPSG:32642 - UTM zone 42N (https://epsg.io/32642).
    public static let epsg32642 = Projection.builtin(srid: 32642)
    /// EPSG:32643 - UTM zone 43N (https://epsg.io/32643).
    public static let epsg32643 = Projection.builtin(srid: 32643)
    /// EPSG:32644 - UTM zone 44N (https://epsg.io/32644).
    public static let epsg32644 = Projection.builtin(srid: 32644)
    /// EPSG:32645 - UTM zone 45N (https://epsg.io/32645).
    public static let epsg32645 = Projection.builtin(srid: 32645)
    /// EPSG:32646 - UTM zone 46N (https://epsg.io/32646).
    public static let epsg32646 = Projection.builtin(srid: 32646)
    /// EPSG:32647 - UTM zone 47N (https://epsg.io/32647).
    public static let epsg32647 = Projection.builtin(srid: 32647)
    /// EPSG:32648 - UTM zone 48N (https://epsg.io/32648).
    public static let epsg32648 = Projection.builtin(srid: 32648)
    /// EPSG:32649 - UTM zone 49N (https://epsg.io/32649).
    public static let epsg32649 = Projection.builtin(srid: 32649)
    /// EPSG:32650 - UTM zone 50N (https://epsg.io/32650).
    public static let epsg32650 = Projection.builtin(srid: 32650)
    /// EPSG:32651 - UTM zone 51N (https://epsg.io/32651).
    public static let epsg32651 = Projection.builtin(srid: 32651)
    /// EPSG:32652 - UTM zone 52N (https://epsg.io/32652).
    public static let epsg32652 = Projection.builtin(srid: 32652)
    /// EPSG:32653 - UTM zone 53N (https://epsg.io/32653).
    public static let epsg32653 = Projection.builtin(srid: 32653)
    /// EPSG:32654 - UTM zone 54N (https://epsg.io/32654).
    public static let epsg32654 = Projection.builtin(srid: 32654)
    /// EPSG:32655 - UTM zone 55N (https://epsg.io/32655).
    public static let epsg32655 = Projection.builtin(srid: 32655)
    /// EPSG:32656 - UTM zone 56N (https://epsg.io/32656).
    public static let epsg32656 = Projection.builtin(srid: 32656)
    /// EPSG:32657 - UTM zone 57N (https://epsg.io/32657).
    public static let epsg32657 = Projection.builtin(srid: 32657)
    /// EPSG:32658 - UTM zone 58N (https://epsg.io/32658).
    public static let epsg32658 = Projection.builtin(srid: 32658)
    /// EPSG:32659 - UTM zone 59N (https://epsg.io/32659).
    public static let epsg32659 = Projection.builtin(srid: 32659)
    /// EPSG:32660 - UTM zone 60N (https://epsg.io/32660).
    public static let epsg32660 = Projection.builtin(srid: 32660)
    /// EPSG:32701 - UTM zone 1S (https://epsg.io/32701).
    public static let epsg32701 = Projection.builtin(srid: 32701)
    /// EPSG:32702 - UTM zone 2S (https://epsg.io/32702).
    public static let epsg32702 = Projection.builtin(srid: 32702)
    /// EPSG:32703 - UTM zone 3S (https://epsg.io/32703).
    public static let epsg32703 = Projection.builtin(srid: 32703)
    /// EPSG:32704 - UTM zone 4S (https://epsg.io/32704).
    public static let epsg32704 = Projection.builtin(srid: 32704)
    /// EPSG:32705 - UTM zone 5S (https://epsg.io/32705).
    public static let epsg32705 = Projection.builtin(srid: 32705)
    /// EPSG:32706 - UTM zone 6S (https://epsg.io/32706).
    public static let epsg32706 = Projection.builtin(srid: 32706)
    /// EPSG:32707 - UTM zone 7S (https://epsg.io/32707).
    public static let epsg32707 = Projection.builtin(srid: 32707)
    /// EPSG:32708 - UTM zone 8S (https://epsg.io/32708).
    public static let epsg32708 = Projection.builtin(srid: 32708)
    /// EPSG:32709 - UTM zone 9S (https://epsg.io/32709).
    public static let epsg32709 = Projection.builtin(srid: 32709)
    /// EPSG:32710 - UTM zone 10S (https://epsg.io/32710).
    public static let epsg32710 = Projection.builtin(srid: 32710)
    /// EPSG:32711 - UTM zone 11S (https://epsg.io/32711).
    public static let epsg32711 = Projection.builtin(srid: 32711)
    /// EPSG:32712 - UTM zone 12S (https://epsg.io/32712).
    public static let epsg32712 = Projection.builtin(srid: 32712)
    /// EPSG:32713 - UTM zone 13S (https://epsg.io/32713).
    public static let epsg32713 = Projection.builtin(srid: 32713)
    /// EPSG:32714 - UTM zone 14S (https://epsg.io/32714).
    public static let epsg32714 = Projection.builtin(srid: 32714)
    /// EPSG:32715 - UTM zone 15S (https://epsg.io/32715).
    public static let epsg32715 = Projection.builtin(srid: 32715)
    /// EPSG:32716 - UTM zone 16S (https://epsg.io/32716).
    public static let epsg32716 = Projection.builtin(srid: 32716)
    /// EPSG:32717 - UTM zone 17S (https://epsg.io/32717).
    public static let epsg32717 = Projection.builtin(srid: 32717)
    /// EPSG:32718 - UTM zone 18S (https://epsg.io/32718).
    public static let epsg32718 = Projection.builtin(srid: 32718)
    /// EPSG:32719 - UTM zone 19S (https://epsg.io/32719).
    public static let epsg32719 = Projection.builtin(srid: 32719)
    /// EPSG:32720 - UTM zone 20S (https://epsg.io/32720).
    public static let epsg32720 = Projection.builtin(srid: 32720)
    /// EPSG:32721 - UTM zone 21S (https://epsg.io/32721).
    public static let epsg32721 = Projection.builtin(srid: 32721)
    /// EPSG:32722 - UTM zone 22S (https://epsg.io/32722).
    public static let epsg32722 = Projection.builtin(srid: 32722)
    /// EPSG:32723 - UTM zone 23S (https://epsg.io/32723).
    public static let epsg32723 = Projection.builtin(srid: 32723)
    /// EPSG:32724 - UTM zone 24S (https://epsg.io/32724).
    public static let epsg32724 = Projection.builtin(srid: 32724)
    /// EPSG:32725 - UTM zone 25S (https://epsg.io/32725).
    public static let epsg32725 = Projection.builtin(srid: 32725)
    /// EPSG:32726 - UTM zone 26S (https://epsg.io/32726).
    public static let epsg32726 = Projection.builtin(srid: 32726)
    /// EPSG:32727 - UTM zone 27S (https://epsg.io/32727).
    public static let epsg32727 = Projection.builtin(srid: 32727)
    /// EPSG:32728 - UTM zone 28S (https://epsg.io/32728).
    public static let epsg32728 = Projection.builtin(srid: 32728)
    /// EPSG:32729 - UTM zone 29S (https://epsg.io/32729).
    public static let epsg32729 = Projection.builtin(srid: 32729)
    /// EPSG:32730 - UTM zone 30S (https://epsg.io/32730).
    public static let epsg32730 = Projection.builtin(srid: 32730)
    /// EPSG:32731 - UTM zone 31S (https://epsg.io/32731).
    public static let epsg32731 = Projection.builtin(srid: 32731)
    /// EPSG:32732 - UTM zone 32S (https://epsg.io/32732).
    public static let epsg32732 = Projection.builtin(srid: 32732)
    /// EPSG:32733 - UTM zone 33S (https://epsg.io/32733).
    public static let epsg32733 = Projection.builtin(srid: 32733)
    /// EPSG:32734 - UTM zone 34S (https://epsg.io/32734).
    public static let epsg32734 = Projection.builtin(srid: 32734)
    /// EPSG:32735 - UTM zone 35S (https://epsg.io/32735).
    public static let epsg32735 = Projection.builtin(srid: 32735)
    /// EPSG:32736 - UTM zone 36S (https://epsg.io/32736).
    public static let epsg32736 = Projection.builtin(srid: 32736)
    /// EPSG:32737 - UTM zone 37S (https://epsg.io/32737).
    public static let epsg32737 = Projection.builtin(srid: 32737)
    /// EPSG:32738 - UTM zone 38S (https://epsg.io/32738).
    public static let epsg32738 = Projection.builtin(srid: 32738)
    /// EPSG:32739 - UTM zone 39S (https://epsg.io/32739).
    public static let epsg32739 = Projection.builtin(srid: 32739)
    /// EPSG:32740 - UTM zone 40S (https://epsg.io/32740).
    public static let epsg32740 = Projection.builtin(srid: 32740)
    /// EPSG:32741 - UTM zone 41S (https://epsg.io/32741).
    public static let epsg32741 = Projection.builtin(srid: 32741)
    /// EPSG:32742 - UTM zone 42S (https://epsg.io/32742).
    public static let epsg32742 = Projection.builtin(srid: 32742)
    /// EPSG:32743 - UTM zone 43S (https://epsg.io/32743).
    public static let epsg32743 = Projection.builtin(srid: 32743)
    /// EPSG:32744 - UTM zone 44S (https://epsg.io/32744).
    public static let epsg32744 = Projection.builtin(srid: 32744)
    /// EPSG:32745 - UTM zone 45S (https://epsg.io/32745).
    public static let epsg32745 = Projection.builtin(srid: 32745)
    /// EPSG:32746 - UTM zone 46S (https://epsg.io/32746).
    public static let epsg32746 = Projection.builtin(srid: 32746)
    /// EPSG:32747 - UTM zone 47S (https://epsg.io/32747).
    public static let epsg32747 = Projection.builtin(srid: 32747)
    /// EPSG:32748 - UTM zone 48S (https://epsg.io/32748).
    public static let epsg32748 = Projection.builtin(srid: 32748)
    /// EPSG:32749 - UTM zone 49S (https://epsg.io/32749).
    public static let epsg32749 = Projection.builtin(srid: 32749)
    /// EPSG:32750 - UTM zone 50S (https://epsg.io/32750).
    public static let epsg32750 = Projection.builtin(srid: 32750)
    /// EPSG:32751 - UTM zone 51S (https://epsg.io/32751).
    public static let epsg32751 = Projection.builtin(srid: 32751)
    /// EPSG:32752 - UTM zone 52S (https://epsg.io/32752).
    public static let epsg32752 = Projection.builtin(srid: 32752)
    /// EPSG:32753 - UTM zone 53S (https://epsg.io/32753).
    public static let epsg32753 = Projection.builtin(srid: 32753)
    /// EPSG:32754 - UTM zone 54S (https://epsg.io/32754).
    public static let epsg32754 = Projection.builtin(srid: 32754)
    /// EPSG:32755 - UTM zone 55S (https://epsg.io/32755).
    public static let epsg32755 = Projection.builtin(srid: 32755)
    /// EPSG:32756 - UTM zone 56S (https://epsg.io/32756).
    public static let epsg32756 = Projection.builtin(srid: 32756)
    /// EPSG:32757 - UTM zone 57S (https://epsg.io/32757).
    public static let epsg32757 = Projection.builtin(srid: 32757)
    /// EPSG:32758 - UTM zone 58S (https://epsg.io/32758).
    public static let epsg32758 = Projection.builtin(srid: 32758)
    /// EPSG:32759 - UTM zone 59S (https://epsg.io/32759).
    public static let epsg32759 = Projection.builtin(srid: 32759)
    /// EPSG:32760 - UTM zone 60S (https://epsg.io/32760).
    public static let epsg32760 = Projection.builtin(srid: 32760)

    // MARK: - Initialization

    /// Creates a projection without registry validation.
    ///
    /// Only used with definitions from the registry; the SRID-info `init`
    /// and ``Projection/register(_:)`` validate before this is reached.
    /// Constructing arbitrary combinations is a programming error: the
    /// SRID and the definition must describe the same projection so that
    /// the registry's identity guarantees hold.
    internal init(uncheckedSrid srid: Int, definition: any ProjectionDefinition) {
        self.sridStorage = srid
        self.definition = definition
    }

    /// The definition carrying this projection's transform math and
    /// metadata - captured at construction so that hot paths resolve
    /// without registry lookups.
    internal let definition: any ProjectionDefinition

    /// Creates a built-in projection by canonical SRID.
    ///
    /// Internal factory for the built-in static constants; asserts that
    /// the SRID is registered.
    internal static func builtin(srid: Int) -> Projection {
        guard let definition = ProjectionRegistry.definition(forSrid: srid) else {
            preconditionFailure("Built-in projection \(srid) is not registered")
        }
        return Projection(uncheckedSrid: srid, definition: definition)
    }

    /// Initialize a Projection with a SRID number.
    ///
    /// - Parameters:
    ///    - srid: The SRID number (e.g. 4326, 3857)
    /// - Returns: A `Projection`, or `nil` if the SRID is not supported
    public init?(srid: Int) {
        guard let canonical = Self.registeredSrid(for: srid) else { return nil }
        self = Projection.builtin(srid: canonical)
    }

    /// Maps an SRID (or one of the known aliases) to the canonical SRID.
    internal static func registeredSrid(for srid: Int) -> Int? {
        let canonical = sridAliases[srid] ?? srid
        guard ProjectionRegistry.isRegisteredSrid(canonical) else { return nil }
        return canonical
    }

    /// Historical web-mercator aliases for EPSG:3857.
    private static let sridAliases: [Int: Int] = [
        102_100: 3857,
        102_113: 3857,
        900_913: 3857,
        3587: 3857,
        3785: 3857,
        41001: 3857,
        54004: 3857,
    ]

    /// Initialize a Projection from a WKT projection string (e.g. from a `.prj` file).
    ///
    /// UTM zones are identified through their zone token first (e.g.
    /// `PROJCS["WGS_1984_UTM_Zone_19N",...]`, central meridian parameter
    /// cross-validated when present), since such strings mention
    /// `Transverse_Mercator` - which would otherwise wrongly match the
    /// generic EPSG:3395 Mercator fragments.
    ///
    /// The string is then matched against the WKT patterns registered by the
    /// library's projections (in registry order, first match wins):
    /// - EPSG:3857 - `PROJCS["...Pseudo-Mercator..."...]`
    /// - EPSG:3395 - `PROJCS["...Mercator..."...]` (without "Pseudo")
    /// - EPSG:32662 - `PROJCS["...Plate Carree..."...]`
    /// - EPSG:4326 - `GEOGCS["...WGS 84..."...]` or `GEOGCS["...WGS_1984..."...]`
    /// - EPSG:4978 - `GEOCCS["...WGS 84..."...]` or `GEOCCS["...WGS_1984..."...]`
    ///
    /// - Parameter wkt: A WKT projection string
    /// - Returns: A `Projection`, or `nil` if the string is not recognised
    public init?(wkt: String) {
        if UtmWktIdentification.hasUtmZoneToken(in: wkt) {
            guard let utmProjection = UtmWktIdentification.projection(in: wkt) else {
                return nil
            }
            self = utmProjection
            return
        }

        guard let definition = ProjectionRegistry.definition(matchingWkt: wkt) else {
            return nil
        }
        self = definition.projection
    }

    /// Creates a UTM zone projection from its zone number and hemisphere.
    ///
    /// - Parameters:
    ///     - utmZone: The UTM zone number (`1 ... 60`)
    ///     - hemisphere: The hemisphere the zone covers
    /// - Returns: The zone projection, or `nil` for an invalid zone number
    public init?(utmZone: Int, hemisphere: UtmHemisphere) {
        guard utmZone >= 1, utmZone <= 60 else { return nil }

        let srid = hemisphere == .north ? 32_600 + utmZone : 32_700 + utmZone
        self.init(srid: srid)
    }

    // MARK: - Identity

    /// A human readable description of the receiver.
    public var description: String {
        srid == 0 ? "No SRID" : "EPSG:" + String(srid)
    }

    /// The SRID number of the projection (e.g. 4326, 3857).
    public var srid: Int {
        sridStorage
    }

    private let sridStorage: Int

    // MARK: - Equatable/Hashable

    /// Two projections are equal when their SRIDs are equal.
    public static func == (lhs: Projection, rhs: Projection) -> Bool {
        lhs.srid == rhs.srid
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(srid)
    }

    // MARK: - Codable

    /// Decodes the raw SRID number, which must be known to the registry.
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let srid = try container.decode(Int.self)

        guard let projection = Projection(srid: srid) else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "Unknown projection SRID \(srid)"))
        }
        self = projection
    }

    /// Encodes the raw SRID number.
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(srid)
    }

}

// MARK: - ProjectionKind

extension Projection {

    /// The receiver's semantic category, resolved from the projection's
    /// captured definition.
    public var kind: ProjectionKind {
        definition.kind
    }

    /// `true` if the receiver uses angular (degree-based) coordinates.
    public var isGeographic: Bool {
        kind == .geographic
    }

    /// `true` if the receiver uses planar (meter-based, Euclidean) coordinates.
    public var isPlanar: Bool {
        kind == .planar
    }

    /// `true` if the receiver uses geocentric 3D cartesian coordinates.
    public var isGeocentric: Bool {
        kind == .geocentric
    }

    /// `false` for ``Projection/noSRID``, `true` otherwise.
    public var hasSRID: Bool {
        kind != .undefined
    }

    /// The geodetic datum of the receiver's coordinate frame, resolved from
    /// the projection's captured definition.
    public var datum: Datum {
        definition.datum
    }

    /// The absolute value beyond which the receiver's horizontal axis wraps
    /// around (±180° for EPSG:4326, ±`originShift` meters for EPSG:3857),
    /// or `nil` if the horizontal axis does not wrap.
    public var wraparoundExtent: Double? {
        definition.wraparoundExtent
    }

    /// Converts a length in meters to the receiver's native coordinate units.
    ///
    /// For geographic (degree-based) projections the value is divided by an
    /// approximate meters-per-degree factor; for all other projections
    /// coordinates are already in meters and the value is returned unchanged.
    ///
    /// - Parameter meters: The length in meters
    /// - Returns: The length in the receiver's coordinate units
    public func crsLength(fromMeters meters: Double) -> Double {
        isGeographic ? meters / 111_325.0 : meters
    }

}

// MARK: - UTM WKT

/// Namespace for identifying UTM zones in WKT projection strings.
///
/// Both patterns allow spaces or underscores as word separators (the common
/// ESRI variant is `WGS_1984_UTM_Zone_19N`), and match case-insensitively.
private enum UtmWktIdentification {

    /// Returns the UTM zone projection identified in the string, or `nil`.
    ///
    /// The hemisphere token (`N`/`S`) is required: without it the zones are
    /// ambiguous and no result is returned rather than a guess. When the
    /// string also carries a `Central_Meridian` parameter, it must agree
    /// with the identified zone.
    static func projection(in wkt: String) -> Projection? {
        // A UTM zone token, e.g. `UTM Zone 19N` or `UTM_Zone_5s`.
        let zoneRegex = /(?i)(?:UTM|Universal[\s_]+Transverse[\s_]+Mercator)[\s_]*Zone[\s_]*(\d{1,2})[\s_]*([NS])/
        // A central meridian parameter, e.g. `"Central_Meridian",-69`.
        let centralMeridianRegex = /(?i)Central[\s_]*Meridian["]?\s*,\s*(-?\d+(?:\.\d+)?)/

        guard let zoneMatch = wkt.firstMatch(of: zoneRegex) else { return nil }

        guard let zone = Int(String(zoneMatch.1)), zone >= 1, zone <= 60 else { return nil }
        let isSouthern = zoneMatch.2.uppercased() == "S"
        let srid = isSouthern ? 32_700 + zone : 32_600 + zone

        if let meridianMatch = wkt.firstMatch(of: centralMeridianRegex) {
            let expected = Double((zone - 1) * 6 - 180 + 3)
            guard let centralMeridian = Double(String(meridianMatch.1)),
                  abs(centralMeridian - expected) < 0.001
            else { return nil }
        }

        return Projection(srid: srid)
    }

    /// `true` when the string carries a UTM zone token (regardless of
    /// whether the zone identification succeeds).
    static func hasUtmZoneToken(in wkt: String) -> Bool {
        let zoneRegex = /(?i)(?:UTM|Universal[\s_]+Transverse[\s_]+Mercator)[\s_]*Zone[\s_]*\d/
        return wkt.firstMatch(of: zoneRegex) != nil
    }

}
