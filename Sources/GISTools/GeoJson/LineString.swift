#if canImport(CoreLocation)
import CoreLocation
#endif
import Foundation

/// A GeoJSON `LineString` object.
public struct LineString:
    LineStringGeometry,
    EmptyCreatable
{

    /// The GeoJSON object type.
    public var type: GeoJsonType {
        .lineString
    }

    /// The receiver's projection.
    public var projection: Projection {
        coordinates.first?.projection ?? .noSRID
    }

    /// The LineString's coordinates.
    public let coordinates: [Coordinate3D]

    /// All coordinates contained in the receiver.
    public var allCoordinates: [Coordinate3D] {
        coordinates
    }

    /// The receiver's bounding box.
    public var boundingBox: BoundingBox?

    /// Foreign members not defined in the GeoJSON specification.
    public var foreignMembers: [String: Sendable] = [:]

    /// The receiver represented as an array of LineStrings (containing only itself).
    public var lineStrings: [LineString] {
        [self]
    }

    /// Initialize an empty LineString.
    public init() {
        self.coordinates = []
    }

    /// Try to initialize a LineString with some coordinates.
    ///
    /// - Parameters:
    ///    - coordinates: The coordinates of the line string
    ///    - calculateBoundingBox: When true, calculate the bounding box from the coordinates
    /// - Returns: A line string, or `nil` if there are fewer than 2 coordinates
    public init?(_ coordinates: [Coordinate3D], calculateBoundingBox: Bool = false) {
        guard coordinates.count >= 2 else { return nil }

        self.init(unchecked: coordinates, calculateBoundingBox: calculateBoundingBox)
    }

    /// Initialize a LineString with some coordinates, don't check the coordinates for validity.
    ///
    /// - Parameters:
    ///    - coordinates: The coordinates of the line string
    ///    - calculateBoundingBox: When true, calculate the bounding box from the coordinates
    public init(unchecked coordinates: [Coordinate3D], calculateBoundingBox: Bool = false) {
        self.coordinates = coordinates

        if calculateBoundingBox {
            self.updateBoundingBox()
        }
    }

    /// Initialize a LineString with a LineSegment.
    ///
    /// - Parameters:
    ///    - lineSegment: The line segment to convert
    ///    - calculateBoundingBox: When true, calculate the bounding box from the coordinates
    public init(_ lineSegment: LineSegment, calculateBoundingBox: Bool = false) {
        self.coordinates = lineSegment.coordinates

        if calculateBoundingBox {
            self.updateBoundingBox()
        }
    }

    /// Try to initialize a LineString with some LineSegments.
    ///
    /// - Parameters:
    ///    - lineSegments: The line segments to join
    ///    - calculateBoundingBox: When true, calculate the bounding box from the coordinates
    /// - Returns: A line string, or `nil` if the segments don't form a valid line
    public init?(_ lineSegments: [LineSegment], calculateBoundingBox: Bool = false) {
        guard !lineSegments.isEmpty else { return nil }

        var coordinates: [Coordinate3D] = []
        for (previous, current, _) in lineSegments.overlappingPairs() {
            if coordinates.isEmpty {
                coordinates.append(previous.first)
                if previous.second != previous.first {
                    coordinates.append(previous.second)
                }
            }

            if let current {
                if current.first != previous.second {
                    coordinates.append(current.first)
                }
                if current.second != current.first {
                    coordinates.append(current.second)
                }
            }
        }

        guard coordinates.count >= 2 else { return nil }

        self.init(unchecked: coordinates, calculateBoundingBox: calculateBoundingBox)
    }

    /// Try to initialize a LineString from any GeoJSON object.
    ///
    /// - important: The source is expected to be in EPSG:4326.
    /// - Parameters:
    ///    - json: A GeoJSON object
    /// - Returns: A line string, or `nil` if the input is invalid
    public init?(json: Any?) {
        self.init(json: json, calculateBoundingBox: false)
    }

    /// Try to initialize a LineString from any GeoJSON object.
    ///
    /// - Parameters:
    ///    - json: A GeoJSON object
    ///    - calculateBoundingBox: When true, calculate the bounding box from the coordinates
    /// - important: The source is expected to be in EPSG:4326.
    /// - Returns: A line string, or `nil` if the input is invalid
    public init?(json: Any?, calculateBoundingBox: Bool = false) {
        guard let geoJson = json as? [String: Sendable],
              LineString.isValid(geoJson: geoJson),
              let coordinates: [Coordinate3D] = LineString.tryCreate(json: geoJson["coordinates"])
        else { return nil }

        self.coordinates = coordinates
        self.boundingBox = LineString.tryCreate(json: geoJson["bbox"])

        if calculateBoundingBox {
            self.updateBoundingBox()
        }

        if geoJson.count > 2 {
            var foreignMembers = geoJson
            foreignMembers.removeValue(forKey: "type")
            foreignMembers.removeValue(forKey: "coordinates")
            foreignMembers.removeValue(forKey: "bbox")
            self.foreignMembers = foreignMembers
        }
    }

    /// The receiver represented as a JSON dictionary.
    ///
    /// - important: Always projected to EPSG:4326, unless the receiver has no SRID.
    /// - Returns: A GeoJSON dictionary
    public var asJson: [String: Sendable] {
        var result: [String: Sendable] = [
            "type": GeoJsonType.lineString.rawValue,
            "coordinates": coordinates.map { $0.asJson }
        ]
        if let boundingBox = boundingBox {
            result["bbox"] = boundingBox.asJson
        }
        result.merge(foreignMembers) { (current, new) in
            return current
        }
        return result
    }

}

extension LineString {

    /// The receiver's first coordinate.
    ///
    /// - Returns: The first coordinate, or `nil` if the line string is empty
    public var firstCoordinate: Coordinate3D? {
        coordinates.first
    }

    /// The receiver's last coordinate.
    ///
    /// - Returns: The last coordinate, or `nil` if the line string is empty
    public var lastCoordinate: Coordinate3D? {
        coordinates.last
    }

    /// A Boolean value that indicates whether this line string forms a closed ring.
    ///
    /// A line string is closed when its first and last coordinates are equal
    /// (within ``GISTool/equalityDelta``).
    @inlinable
    public var isClosed: Bool {
        guard let first = coordinates.first,
              let last = coordinates.last,
              coordinates.count > 1
        else { return false }
        return first.isCoincident(to: last)
    }

}

// MARK: - Projection

extension LineString {

    /// Returns the receiver projected to a different projection.
    ///
    /// - Parameter newProjection: The target projection.
    /// - Returns: A new line string in the requested projection
    public func projected(to newProjection: Projection) -> LineString {
        guard newProjection != projection else { return self }

        var lineString = LineString(
            unchecked: coordinates.map({ $0.projected(to: newProjection) }),
            calculateBoundingBox: (boundingBox != nil))
        lineString.foreignMembers = foreignMembers
        return lineString
    }

}

// MARK: - CoreLocation compatibility

#if canImport(CoreLocation)
extension LineString {

    /// Try to initialize a LineString with some coordinates.
    ///
    /// - Parameters:
    ///    - coordinates: The coordinates of the line string
    ///    - calculateBoundingBox: When true, calculate the bounding box from the coordinates
    /// - Returns: A line string, or `nil` if there are fewer than 2 coordinates
    public init?(_ coordinates: [CLLocationCoordinate2D], calculateBoundingBox: Bool = false) {
        self.init(coordinates.map({ Coordinate3D($0) }), calculateBoundingBox: calculateBoundingBox)
    }

    /// Try to initialize a LineString with some locations.
    ///
    /// - Parameters:
    ///    - coordinates: The locations of the line string
    ///    - calculateBoundingBox: When true, calculate the bounding box from the coordinates
    /// - Returns: A line string, or `nil` if there are fewer than 2 locations
    public init?(_ coordinates: [CLLocation], calculateBoundingBox: Bool = false) {
        self.init(coordinates.map({ Coordinate3D($0) }), calculateBoundingBox: calculateBoundingBox)
    }

}
#endif

// MARK: - BoundingBox

extension LineString {

    /// Calculate and return the receiver's bounding box.
    ///
    /// - Returns: The calculated bounding box, or `nil` if there are no coordinates
    public func calculateBoundingBox() -> BoundingBox? {
        BoundingBox(coordinates: coordinates)
    }

    /// Check if the receiver intersects the other bounding box.
    ///
    /// - Parameter otherBoundingBox: The bounding box to check.
    /// - Returns: `true` if the bounding boxes intersect
    public func intersects(_ otherBoundingBox: BoundingBox) -> Bool {
        if let boundingBox = boundingBox ?? calculateBoundingBox(),
           !boundingBox.intersects(otherBoundingBox)
        {
            return false
        }

        let boundingBoxSegments: [LineSegment] = otherBoundingBox.lineSegments

        let minLongitude = otherBoundingBox.southWest.longitude
        let minLatitude = otherBoundingBox.southWest.latitude
        let maxLongitude = otherBoundingBox.northEast.longitude
        let maxLatitude = otherBoundingBox.northEast.latitude

        for index in 0 ..< coordinates.count - 1 {
            let segment = LineSegment(
                first: coordinates[index],
                second: coordinates[index + 1])

            // The bbox contains one of the end points
            if otherBoundingBox.contains(segment.first)
                || otherBoundingBox.contains(segment.second)
            {
                return true
            }

            // All points are outside of the bbox, on the same side
            if (segment.first.latitude > maxLatitude && segment.second.latitude > maxLatitude)
                || (segment.first.latitude < minLatitude && segment.second.latitude < minLatitude)
                || (segment.first.longitude > maxLongitude && segment.second.longitude > maxLongitude)
                || (segment.first.longitude < minLongitude && segment.second.longitude < minLongitude)
            {
                continue
            }

            for boundingBoxSegment in boundingBoxSegments {
                if boundingBoxSegment.intersects(segment) {
                    return true
                }
            }
        }

        return false
    }

}

// MARK: - Equatable

extension LineString: Equatable {

    /// Check if two LineStrings are equal.
    public static func ==(
        lhs: LineString,
        rhs: LineString
    ) -> Bool {
        return lhs.projection == rhs.projection
            && lhs.coordinates == rhs.coordinates
    }

}
