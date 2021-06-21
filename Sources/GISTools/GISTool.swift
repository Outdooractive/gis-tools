#if !os(Linux)
import CoreLocation
#endif
import Foundation

public struct GISTool {

    /// WGS84 equatorial radius as specified by the International Union of Geodesy and Geophysics.
    static let equatorialRadius: CLLocationDistance = 6_378_137

    /// The radius of the earth, in meters.
    static let earthRadius: CLLocationDistance = 6_371_008.8

    /// The accuracy for testing what is equal
    static let equalityDelta: Double = 1e-10

}
