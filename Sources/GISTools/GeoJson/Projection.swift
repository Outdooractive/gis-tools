
/// Projections that this library can handle.
public enum Projection:
    Int,
    CustomStringConvertible,
    Codable,
    Sendable
{

    /// No SRID (invalid/unknown projection).
    case noSRID = 0
    /// EPSG:3857 - web mercator (https://epsg.io/3857).
    case epsg3857 = 3857
    /// EPSG:4326 - geodetic (https://epsg.io/4326).
    case epsg4326 = 4326
    /// EPSG:4978 - geocentric (ECEF) (https://epsg.io/4978).
    case epsg4978 = 4978
    /// EPSG:3395 - WGS 84 / World Mercator, ellipsoidal Mercator
    /// (https://epsg.io/3395).
    case epsg3395 = 3395
    /// EPSG:32662 - WGS 84 / Plate Carree, equirectangular
    /// (https://epsg.io/32662).
    case epsg32662 = 32662
    // UTM zones (northern EPSG:32601-32660, southern EPSG:32701-32760).
    /// EPSG:32601 - UTM zone 1N (https://epsg.io/32601).
    case epsg32601 = 32601
    /// EPSG:32602 - UTM zone 2N (https://epsg.io/32602).
    case epsg32602 = 32602
    /// EPSG:32603 - UTM zone 3N (https://epsg.io/32603).
    case epsg32603 = 32603
    /// EPSG:32604 - UTM zone 4N (https://epsg.io/32604).
    case epsg32604 = 32604
    /// EPSG:32605 - UTM zone 5N (https://epsg.io/32605).
    case epsg32605 = 32605
    /// EPSG:32606 - UTM zone 6N (https://epsg.io/32606).
    case epsg32606 = 32606
    /// EPSG:32607 - UTM zone 7N (https://epsg.io/32607).
    case epsg32607 = 32607
    /// EPSG:32608 - UTM zone 8N (https://epsg.io/32608).
    case epsg32608 = 32608
    /// EPSG:32609 - UTM zone 9N (https://epsg.io/32609).
    case epsg32609 = 32609
    /// EPSG:32610 - UTM zone 10N (https://epsg.io/32610).
    case epsg32610 = 32610
    /// EPSG:32611 - UTM zone 11N (https://epsg.io/32611).
    case epsg32611 = 32611
    /// EPSG:32612 - UTM zone 12N (https://epsg.io/32612).
    case epsg32612 = 32612
    /// EPSG:32613 - UTM zone 13N (https://epsg.io/32613).
    case epsg32613 = 32613
    /// EPSG:32614 - UTM zone 14N (https://epsg.io/32614).
    case epsg32614 = 32614
    /// EPSG:32615 - UTM zone 15N (https://epsg.io/32615).
    case epsg32615 = 32615
    /// EPSG:32616 - UTM zone 16N (https://epsg.io/32616).
    case epsg32616 = 32616
    /// EPSG:32617 - UTM zone 17N (https://epsg.io/32617).
    case epsg32617 = 32617
    /// EPSG:32618 - UTM zone 18N (https://epsg.io/32618).
    case epsg32618 = 32618
    /// EPSG:32619 - UTM zone 19N (https://epsg.io/32619).
    case epsg32619 = 32619
    /// EPSG:32620 - UTM zone 20N (https://epsg.io/32620).
    case epsg32620 = 32620
    /// EPSG:32621 - UTM zone 21N (https://epsg.io/32621).
    case epsg32621 = 32621
    /// EPSG:32622 - UTM zone 22N (https://epsg.io/32622).
    case epsg32622 = 32622
    /// EPSG:32623 - UTM zone 23N (https://epsg.io/32623).
    case epsg32623 = 32623
    /// EPSG:32624 - UTM zone 24N (https://epsg.io/32624).
    case epsg32624 = 32624
    /// EPSG:32625 - UTM zone 25N (https://epsg.io/32625).
    case epsg32625 = 32625
    /// EPSG:32626 - UTM zone 26N (https://epsg.io/32626).
    case epsg32626 = 32626
    /// EPSG:32627 - UTM zone 27N (https://epsg.io/32627).
    case epsg32627 = 32627
    /// EPSG:32628 - UTM zone 28N (https://epsg.io/32628).
    case epsg32628 = 32628
    /// EPSG:32629 - UTM zone 29N (https://epsg.io/32629).
    case epsg32629 = 32629
    /// EPSG:32630 - UTM zone 30N (https://epsg.io/32630).
    case epsg32630 = 32630
    /// EPSG:32631 - UTM zone 31N (https://epsg.io/32631).
    case epsg32631 = 32631
    /// EPSG:32632 - UTM zone 32N (https://epsg.io/32632).
    case epsg32632 = 32632
    /// EPSG:32633 - UTM zone 33N (https://epsg.io/32633).
    case epsg32633 = 32633
    /// EPSG:32634 - UTM zone 34N (https://epsg.io/32634).
    case epsg32634 = 32634
    /// EPSG:32635 - UTM zone 35N (https://epsg.io/32635).
    case epsg32635 = 32635
    /// EPSG:32636 - UTM zone 36N (https://epsg.io/32636).
    case epsg32636 = 32636
    /// EPSG:32637 - UTM zone 37N (https://epsg.io/32637).
    case epsg32637 = 32637
    /// EPSG:32638 - UTM zone 38N (https://epsg.io/32638).
    case epsg32638 = 32638
    /// EPSG:32639 - UTM zone 39N (https://epsg.io/32639).
    case epsg32639 = 32639
    /// EPSG:32640 - UTM zone 40N (https://epsg.io/32640).
    case epsg32640 = 32640
    /// EPSG:32641 - UTM zone 41N (https://epsg.io/32641).
    case epsg32641 = 32641
    /// EPSG:32642 - UTM zone 42N (https://epsg.io/32642).
    case epsg32642 = 32642
    /// EPSG:32643 - UTM zone 43N (https://epsg.io/32643).
    case epsg32643 = 32643
    /// EPSG:32644 - UTM zone 44N (https://epsg.io/32644).
    case epsg32644 = 32644
    /// EPSG:32645 - UTM zone 45N (https://epsg.io/32645).
    case epsg32645 = 32645
    /// EPSG:32646 - UTM zone 46N (https://epsg.io/32646).
    case epsg32646 = 32646
    /// EPSG:32647 - UTM zone 47N (https://epsg.io/32647).
    case epsg32647 = 32647
    /// EPSG:32648 - UTM zone 48N (https://epsg.io/32648).
    case epsg32648 = 32648
    /// EPSG:32649 - UTM zone 49N (https://epsg.io/32649).
    case epsg32649 = 32649
    /// EPSG:32650 - UTM zone 50N (https://epsg.io/32650).
    case epsg32650 = 32650
    /// EPSG:32651 - UTM zone 51N (https://epsg.io/32651).
    case epsg32651 = 32651
    /// EPSG:32652 - UTM zone 52N (https://epsg.io/32652).
    case epsg32652 = 32652
    /// EPSG:32653 - UTM zone 53N (https://epsg.io/32653).
    case epsg32653 = 32653
    /// EPSG:32654 - UTM zone 54N (https://epsg.io/32654).
    case epsg32654 = 32654
    /// EPSG:32655 - UTM zone 55N (https://epsg.io/32655).
    case epsg32655 = 32655
    /// EPSG:32656 - UTM zone 56N (https://epsg.io/32656).
    case epsg32656 = 32656
    /// EPSG:32657 - UTM zone 57N (https://epsg.io/32657).
    case epsg32657 = 32657
    /// EPSG:32658 - UTM zone 58N (https://epsg.io/32658).
    case epsg32658 = 32658
    /// EPSG:32659 - UTM zone 59N (https://epsg.io/32659).
    case epsg32659 = 32659
    /// EPSG:32660 - UTM zone 60N (https://epsg.io/32660).
    case epsg32660 = 32660
    /// EPSG:32701 - UTM zone 1S (https://epsg.io/32701).
    case epsg32701 = 32701
    /// EPSG:32702 - UTM zone 2S (https://epsg.io/32702).
    case epsg32702 = 32702
    /// EPSG:32703 - UTM zone 3S (https://epsg.io/32703).
    case epsg32703 = 32703
    /// EPSG:32704 - UTM zone 4S (https://epsg.io/32704).
    case epsg32704 = 32704
    /// EPSG:32705 - UTM zone 5S (https://epsg.io/32705).
    case epsg32705 = 32705
    /// EPSG:32706 - UTM zone 6S (https://epsg.io/32706).
    case epsg32706 = 32706
    /// EPSG:32707 - UTM zone 7S (https://epsg.io/32707).
    case epsg32707 = 32707
    /// EPSG:32708 - UTM zone 8S (https://epsg.io/32708).
    case epsg32708 = 32708
    /// EPSG:32709 - UTM zone 9S (https://epsg.io/32709).
    case epsg32709 = 32709
    /// EPSG:32710 - UTM zone 10S (https://epsg.io/32710).
    case epsg32710 = 32710
    /// EPSG:32711 - UTM zone 11S (https://epsg.io/32711).
    case epsg32711 = 32711
    /// EPSG:32712 - UTM zone 12S (https://epsg.io/32712).
    case epsg32712 = 32712
    /// EPSG:32713 - UTM zone 13S (https://epsg.io/32713).
    case epsg32713 = 32713
    /// EPSG:32714 - UTM zone 14S (https://epsg.io/32714).
    case epsg32714 = 32714
    /// EPSG:32715 - UTM zone 15S (https://epsg.io/32715).
    case epsg32715 = 32715
    /// EPSG:32716 - UTM zone 16S (https://epsg.io/32716).
    case epsg32716 = 32716
    /// EPSG:32717 - UTM zone 17S (https://epsg.io/32717).
    case epsg32717 = 32717
    /// EPSG:32718 - UTM zone 18S (https://epsg.io/32718).
    case epsg32718 = 32718
    /// EPSG:32719 - UTM zone 19S (https://epsg.io/32719).
    case epsg32719 = 32719
    /// EPSG:32720 - UTM zone 20S (https://epsg.io/32720).
    case epsg32720 = 32720
    /// EPSG:32721 - UTM zone 21S (https://epsg.io/32721).
    case epsg32721 = 32721
    /// EPSG:32722 - UTM zone 22S (https://epsg.io/32722).
    case epsg32722 = 32722
    /// EPSG:32723 - UTM zone 23S (https://epsg.io/32723).
    case epsg32723 = 32723
    /// EPSG:32724 - UTM zone 24S (https://epsg.io/32724).
    case epsg32724 = 32724
    /// EPSG:32725 - UTM zone 25S (https://epsg.io/32725).
    case epsg32725 = 32725
    /// EPSG:32726 - UTM zone 26S (https://epsg.io/32726).
    case epsg32726 = 32726
    /// EPSG:32727 - UTM zone 27S (https://epsg.io/32727).
    case epsg32727 = 32727
    /// EPSG:32728 - UTM zone 28S (https://epsg.io/32728).
    case epsg32728 = 32728
    /// EPSG:32729 - UTM zone 29S (https://epsg.io/32729).
    case epsg32729 = 32729
    /// EPSG:32730 - UTM zone 30S (https://epsg.io/32730).
    case epsg32730 = 32730
    /// EPSG:32731 - UTM zone 31S (https://epsg.io/32731).
    case epsg32731 = 32731
    /// EPSG:32732 - UTM zone 32S (https://epsg.io/32732).
    case epsg32732 = 32732
    /// EPSG:32733 - UTM zone 33S (https://epsg.io/32733).
    case epsg32733 = 32733
    /// EPSG:32734 - UTM zone 34S (https://epsg.io/32734).
    case epsg32734 = 32734
    /// EPSG:32735 - UTM zone 35S (https://epsg.io/32735).
    case epsg32735 = 32735
    /// EPSG:32736 - UTM zone 36S (https://epsg.io/32736).
    case epsg32736 = 32736
    /// EPSG:32737 - UTM zone 37S (https://epsg.io/32737).
    case epsg32737 = 32737
    /// EPSG:32738 - UTM zone 38S (https://epsg.io/32738).
    case epsg32738 = 32738
    /// EPSG:32739 - UTM zone 39S (https://epsg.io/32739).
    case epsg32739 = 32739
    /// EPSG:32740 - UTM zone 40S (https://epsg.io/32740).
    case epsg32740 = 32740
    /// EPSG:32741 - UTM zone 41S (https://epsg.io/32741).
    case epsg32741 = 32741
    /// EPSG:32742 - UTM zone 42S (https://epsg.io/32742).
    case epsg32742 = 32742
    /// EPSG:32743 - UTM zone 43S (https://epsg.io/32743).
    case epsg32743 = 32743
    /// EPSG:32744 - UTM zone 44S (https://epsg.io/32744).
    case epsg32744 = 32744
    /// EPSG:32745 - UTM zone 45S (https://epsg.io/32745).
    case epsg32745 = 32745
    /// EPSG:32746 - UTM zone 46S (https://epsg.io/32746).
    case epsg32746 = 32746
    /// EPSG:32747 - UTM zone 47S (https://epsg.io/32747).
    case epsg32747 = 32747
    /// EPSG:32748 - UTM zone 48S (https://epsg.io/32748).
    case epsg32748 = 32748
    /// EPSG:32749 - UTM zone 49S (https://epsg.io/32749).
    case epsg32749 = 32749
    /// EPSG:32750 - UTM zone 50S (https://epsg.io/32750).
    case epsg32750 = 32750
    /// EPSG:32751 - UTM zone 51S (https://epsg.io/32751).
    case epsg32751 = 32751
    /// EPSG:32752 - UTM zone 52S (https://epsg.io/32752).
    case epsg32752 = 32752
    /// EPSG:32753 - UTM zone 53S (https://epsg.io/32753).
    case epsg32753 = 32753
    /// EPSG:32754 - UTM zone 54S (https://epsg.io/32754).
    case epsg32754 = 32754
    /// EPSG:32755 - UTM zone 55S (https://epsg.io/32755).
    case epsg32755 = 32755
    /// EPSG:32756 - UTM zone 56S (https://epsg.io/32756).
    case epsg32756 = 32756
    /// EPSG:32757 - UTM zone 57S (https://epsg.io/32757).
    case epsg32757 = 32757
    /// EPSG:32758 - UTM zone 58S (https://epsg.io/32758).
    case epsg32758 = 32758
    /// EPSG:32759 - UTM zone 59S (https://epsg.io/32759).
    case epsg32759 = 32759
    /// EPSG:32760 - UTM zone 60S (https://epsg.io/32760).
    case epsg32760 = 32760

    /// Initialize a Projection with a SRID number.
    ///
    /// - Parameters:
    ///    - srid: The SRID number (e.g. 4326, 3857)
    /// - Returns: A `Projection`, or `nil` if the SRID is not supported
    public init?(srid: Int) {
        switch srid {
        // A placeholder for 'No SRID'
        case 0: self = .noSRID
        case 102_100, 102_113, 900_913, 3587, 3785, 3857, 41001, 54004: self = .epsg3857
        case 4326: self = .epsg4326
        case 4978: self = .epsg4978
        case 3395: self = .epsg3395
        case 32662: self = .epsg32662
        // UTM zones 1-60, northern and southern.
        case 32_601 ... 32_660, 32_701 ... 32_760:
            self = Projection(rawValue: srid) ?? .noSRID
        default: return nil
        }
    }

    /// Initialize a Projection from a WKT projection string (e.g. from a `.prj` file).
    ///
    /// The string is matched against the WKT patterns registered by the
    /// library's projections (in registry order, first match wins):
    /// - EPSG:3857 — `PROJCS["...Pseudo-Mercator..."...]`
    /// - EPSG:3395 — `PROJCS["...Mercator..."...]` (without "Pseudo")
    /// - EPSG:32662 — `PROJCS["...Plate Carree..."...]`
    /// - EPSG:4326 — `GEOGCS["...WGS 84..."...]` or `GEOGCS["...WGS_1984..."...]`
    /// - EPSG:4978 — `GEOCCS["...WGS 84..."...]` or `GEOCCS["...WGS_1984..."...]`
    ///
    /// - Parameter wkt: A WKT projection string
    /// - Returns: A `Projection`, or `nil` if the string is not recognised
    public init?(wkt: String) {
        guard let definition = ProjectionRegistry.definition(matchingWkt: wkt) else {
            return nil
        }
        self = definition.projection
    }

    /// The receiver's SRID number.
    public var srid: Int {
        self.rawValue
    }

    /// A human readable description of the receiver.
    public var description: String {
        switch self {
        case .noSRID: return "No SRID"
        default: return "EPSG:" + String(rawValue)
        }
    }

}

// MARK: - ProjectionKind

extension Projection {

    /// The receiver's semantic category.
    public var kind: ProjectionKind {
        switch self {
        case .noSRID: .undefined
        case .epsg3857, .epsg3395, .epsg32662: .planar
        case .epsg4326: .geographic
        case .epsg4978: .geocentric
        case .epsg32601, .epsg32602, .epsg32603, .epsg32604, .epsg32605, .epsg32606, .epsg32607, .epsg32608, .epsg32609, .epsg32610, .epsg32611, .epsg32612,
            .epsg32613, .epsg32614, .epsg32615, .epsg32616, .epsg32617, .epsg32618, .epsg32619, .epsg32620, .epsg32621, .epsg32622, .epsg32623, .epsg32624,
            .epsg32625, .epsg32626, .epsg32627, .epsg32628, .epsg32629, .epsg32630, .epsg32631, .epsg32632, .epsg32633, .epsg32634, .epsg32635, .epsg32636,
            .epsg32637, .epsg32638, .epsg32639, .epsg32640, .epsg32641, .epsg32642, .epsg32643, .epsg32644, .epsg32645, .epsg32646, .epsg32647, .epsg32648,
            .epsg32649, .epsg32650, .epsg32651, .epsg32652, .epsg32653, .epsg32654, .epsg32655, .epsg32656, .epsg32657, .epsg32658, .epsg32659, .epsg32660,
            .epsg32701, .epsg32702, .epsg32703, .epsg32704, .epsg32705, .epsg32706, .epsg32707, .epsg32708, .epsg32709, .epsg32710, .epsg32711, .epsg32712,
            .epsg32713, .epsg32714, .epsg32715, .epsg32716, .epsg32717, .epsg32718, .epsg32719, .epsg32720, .epsg32721, .epsg32722, .epsg32723, .epsg32724,
            .epsg32725, .epsg32726, .epsg32727, .epsg32728, .epsg32729, .epsg32730, .epsg32731, .epsg32732, .epsg32733, .epsg32734, .epsg32735, .epsg32736,
            .epsg32737, .epsg32738, .epsg32739, .epsg32740, .epsg32741, .epsg32742, .epsg32743, .epsg32744, .epsg32745, .epsg32746, .epsg32747, .epsg32748,
            .epsg32749, .epsg32750, .epsg32751, .epsg32752, .epsg32753, .epsg32754, .epsg32755, .epsg32756, .epsg32757, .epsg32758, .epsg32759, .epsg32760:
            .planar
        }
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

    /// The absolute value beyond which the receiver's horizontal axis wraps
    /// around (±180° for EPSG:4326, ±`originShift` meters for EPSG:3857),
    /// or `nil` if the horizontal axis does not wrap.
    public var wraparoundExtent: Double? {
        switch self {
        case .noSRID, .epsg4978:
            nil
        case .epsg3857, .epsg3395:
            GISTool.originShift
        case .epsg4326, .epsg32662:
            180.0
        case .epsg32601, .epsg32602, .epsg32603, .epsg32604, .epsg32605, .epsg32606, .epsg32607, .epsg32608, .epsg32609, .epsg32610, .epsg32611, .epsg32612,
            .epsg32613, .epsg32614, .epsg32615, .epsg32616, .epsg32617, .epsg32618, .epsg32619, .epsg32620, .epsg32621, .epsg32622, .epsg32623, .epsg32624,
            .epsg32625, .epsg32626, .epsg32627, .epsg32628, .epsg32629, .epsg32630, .epsg32631, .epsg32632, .epsg32633, .epsg32634, .epsg32635, .epsg32636,
            .epsg32637, .epsg32638, .epsg32639, .epsg32640, .epsg32641, .epsg32642, .epsg32643, .epsg32644, .epsg32645, .epsg32646, .epsg32647, .epsg32648,
            .epsg32649, .epsg32650, .epsg32651, .epsg32652, .epsg32653, .epsg32654, .epsg32655, .epsg32656, .epsg32657, .epsg32658, .epsg32659, .epsg32660,
            .epsg32701, .epsg32702, .epsg32703, .epsg32704, .epsg32705, .epsg32706, .epsg32707, .epsg32708, .epsg32709, .epsg32710, .epsg32711, .epsg32712,
            .epsg32713, .epsg32714, .epsg32715, .epsg32716, .epsg32717, .epsg32718, .epsg32719, .epsg32720, .epsg32721, .epsg32722, .epsg32723, .epsg32724,
            .epsg32725, .epsg32726, .epsg32727, .epsg32728, .epsg32729, .epsg32730, .epsg32731, .epsg32732, .epsg32733, .epsg32734, .epsg32735, .epsg32736,
            .epsg32737, .epsg32738, .epsg32739, .epsg32740, .epsg32741, .epsg32742, .epsg32743, .epsg32744, .epsg32745, .epsg32746, .epsg32747, .epsg32748,
            .epsg32749, .epsg32750, .epsg32751, .epsg32752, .epsg32753, .epsg32754, .epsg32755, .epsg32756, .epsg32757, .epsg32758, .epsg32759, .epsg32760:
            nil
        }
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