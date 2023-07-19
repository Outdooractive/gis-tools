#if !os(Linux)
import CoreLocation
#endif
import Foundation

// Ported from https://github.com/Turfjs/turf/blob/master/packages/turf-bearing

extension Coordinate3D {

    /// Finds the geographic bearing between the receiver and another coordinate, i.e. the angle measured in degrees from the north line (0 degrees).
    ///
    /// - Parameters:
    ///    - other: The end point
    ///    - final: Calculates the final bearing (optional, default *false*)
    ///
    /// - Returns: The bearing in decimal degrees, between -180 and 180 (positive clockwise).
    public func bearing(
        to other: Coordinate3D,
        final: Bool = false)
        -> CLLocationDegrees
    {
        switch projection {
        case .epsg4326:
            return _bearing(to: other.projected(to: .epsg4326), final: final)
        case .epsg3857:
            return projected(to: .epsg4326)._bearing(to: other.projected(to: .epsg4326), final: final)
        case .noSRID:
            // TODO
            return Double.infinity
        }
    }

    private func _bearing(
        to other: Coordinate3D,
        final: Bool = false)
        -> CLLocationDegrees
    {
        if final {
            return Coordinate3D.calculateFinalBearing(from: self, to: other)
        }

        let longitude1 = longitude.degreesToRadians
        let longitude2 = other.longitude.degreesToRadians

        let latitude1 = latitude.degreesToRadians
        let latitude2 = other.latitude.degreesToRadians

        let a = sin(longitude2 - longitude1) * cos(latitude2)
        let b = cos(latitude1) * sin(latitude2) - sin(latitude1) * cos(latitude2) * cos(longitude2 - longitude1)

        return atan2(a, b).radiansToDegrees
    }

    private static func calculateFinalBearing(
        from: Coordinate3D,
        to: Coordinate3D)
        -> CLLocationDegrees
    {
        let bearing = to._bearing(to: from)
        return (bearing + 180.0).truncatingRemainder(dividingBy: 360.0)
    }

    /// Takes three coordinates and returns the angle between them, i.e. from the triangle *first* - *middle* - *last*.
    ///
    /// - Parameters:
    ///    - first: The first point in the triangle
    ///    - middle: The middle point in the triangle
    ///    - last: The last point in the trianle
    ///
    /// - Returns: The angle between the points, between -180 and 180.
    public static func angleBetween(
        first: Coordinate3D,
        middle: Coordinate3D,
        last: Coordinate3D)
        -> CLLocationDegrees
    {
        angleBetween(
            firstAzimuth: first.bearing(to: middle).bearingToAzimuth,
            secondAzimuth: middle.bearing(to: last).bearingToAzimuth)
    }

    /// Takes two azimuth values in decimal degrees and returns the angle between them.
    ///
    /// - Parameters:
    ///    - firstBearing: The first angle
    ///    - secondBearing: The second angle
    ///
    /// - Returns: The angle, between -180 and 180.
    public static func angleBetween(
        firstAzimuth: CLLocationDegrees,
        secondAzimuth: CLLocationDegrees)
        -> CLLocationDegrees
    {
        var angle: CLLocationDegrees = secondAzimuth - firstAzimuth
        if angle > 180.0 {
            angle -= 360.0
        }
        else if angle < -180.0 {
            angle += 360.0
        }

        return angle
    }

}

extension Point {

    /// Finds the geographic bearing between the receiver and another Point, i.e. the angle measured in degrees from the north line (0 degrees).
    ///
    /// - Parameters:
    ///    - other: The end point
    ///    - final: Calculates the final bearing (optional, default *false*)
    ///
    /// - Returns: The bearing in decimal degrees, between -180 and 180 (positive clockwise).
    public func bearing(
        to other: Point,
        final: Bool = false)
        -> CLLocationDegrees
    {
        self.coordinate.bearing(to: other.coordinate, final: final)
    }

    /// Takes three *Point*s and returns the angle between them, i.e. from the triangle *first* - *middle* - *last*.
    ///
    /// - Parameters:
    ///    - first: The first point in the triangle
    ///    - middle: The middle point in the triangle
    ///    - last: The last point in the trianle
    ///
    /// - Returns: The angle between the points, between -180 and 180.
    public static func angleBetween(
        first: Point,
        middle: Point,
        last: Point)
        -> CLLocationDegrees
    {
        Coordinate3D.angleBetween(
            first: first.coordinate,
            middle: middle.coordinate,
            last: last.coordinate)
    }

}

extension LineSegment {

    /// The geographic bearing between the first and second coordinate.
    public var bearing: CLLocationDegrees {
        first.bearing(to: second)
    }

    /// Converts the bearing angle from the north line direction (positive clockwise)
    /// and returns an angle between 0-360 degrees (positive clockwise), 0 being the north line.
    public var azimuth: CLLocationDegrees {
        bearing.bearingToAzimuth
    }

}
