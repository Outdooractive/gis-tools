#if !os(Linux)
import CoreLocation
#endif
import Foundation

public struct Ring {

    public let coordinates: [Coordinate3D]

    public init?(_ coordinates: [Coordinate3D]) {
        // TODO: Close the ring, if necessary
        guard coordinates.count >= 4 else { return nil }

        self.coordinates = coordinates
    }

}

// MARK: - CoreLocation compatibility

#if !os(Linux)
extension Ring {

    public init?(_ coordinates: [CLLocationCoordinate2D]) {
        self.init(coordinates.map({ Coordinate3D($0) }))
    }

    public init?(_ coordinates: [CLLocation]) {
        self.init(coordinates.map({ Coordinate3D($0) }))
    }

}
#endif
