#if !os(Linux)
import CoreLocation
#endif
import Foundation

// MARK: Public

extension CLLocationDegrees { // aka Double

    /// Converts any bearing angle from the north line direction (positive clockwise)
    /// and returns an angle between 0-360 degrees (positive clockwise), 0 being the north line.
    ///
    /// - Returns: The angle between 0 and 360 degrees.
    public var bearingToAzimuth: CLLocationDegrees {
        var angle: CLLocationDegrees = self.truncatingRemainder(dividingBy: 360.0)
        if angle < 0 {
            angle += 360.0
        }
        return angle
    }

}
