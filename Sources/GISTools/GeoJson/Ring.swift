#if !os(Linux)
import CoreLocation
#endif
import Foundation

public struct Ring {

    public let coordinates: [Coordinate3D]

    public init(_ coordinates: [Coordinate3D]) {
        // TODO: Close the ring, if necessary
        self.coordinates = coordinates
    }

}
