#if !os(Linux)
import CoreLocation
#endif
import Foundation

extension PolygonGeometry {

    /// Returns a MultiLineString for each polygon.
    public var lineStrings: [MultiLineString] {
        polygons.compactMap { polygon in
            let lineStrings = polygon.rings.map(\.lineString)
            return MultiLineString(lineStrings)
        }
    }

}
