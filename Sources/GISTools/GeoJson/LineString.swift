#if !os(Linux)
import CoreLocation
#endif
import Foundation

/// A GeoJSON `LineString` object.
public struct LineString:
    LineStringGeometry,
    EmptyCreatable
{

    public var type: GeoJsonType {
        .lineString
    }

    public var projection: Projection {
        coordinates.first?.projection ?? .noSRID
    }

    /// The LineString's coordinates.
    public let coordinates: [Coordinate3D]

    public var allCoordinates: [Coordinate3D] {
        coordinates
    }

    public var boundingBox: BoundingBox?

    public var foreignMembers: [String: Sendable] = [:]

    public var lineStrings: [LineString] {
        [self]
    }

    public init() {
        self.coordinates = []
    }

    /// Try to initialize a LineString with some coordinates.
    public init?(_ coordinates: [Coordinate3D], calculateBoundingBox: Bool = false) {
        guard coordinates.count >= 2 else { return nil }

        self.init(unchecked: coordinates, calculateBoundingBox: calculateBoundingBox)
    }

    /// Initialize a LineString with some coordinates, don't check the coordinates for validity.
    public init(unchecked coordinates: [Coordinate3D], calculateBoundingBox: Bool = false) {
        self.coordinates = coordinates

        if calculateBoundingBox {
            self.updateBoundingBox()
        }
    }

    /// Initialize a LineString with a LineSegment.
    public init(_ lineSegment: LineSegment, calculateBoundingBox: Bool = false) {
        self.coordinates = lineSegment.coordinates

        if calculateBoundingBox {
            self.updateBoundingBox()
        }
    }

    /// Try to initialize a LineString with some LineSegments.
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

    public init?(json: Any?) {
        self.init(json: json, calculateBoundingBox: false)
    }

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
    public var firstCoordinate: Coordinate3D? {
        coordinates.first
    }

    /// The receiver's last coordinate.
    public var lastCoordinate: Coordinate3D? {
        coordinates.last
    }

}

// MARK: - Projection

extension LineString {

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

#if !os(Linux)
extension LineString {

    /// Try to initialize a LineString with some coordinates.
    public init?(_ coordinates: [CLLocationCoordinate2D], calculateBoundingBox: Bool = false) {
        self.init(coordinates.map({ Coordinate3D($0) }), calculateBoundingBox: calculateBoundingBox)
    }

    /// Try to initialize a LineString with some locations.
    public init?(_ coordinates: [CLLocation], calculateBoundingBox: Bool = false) {
        self.init(coordinates.map({ Coordinate3D($0) }), calculateBoundingBox: calculateBoundingBox)
    }

}
#endif

// MARK: - BoundingBox

extension LineString {

    public func calculateBoundingBox() -> BoundingBox? {
        BoundingBox(coordinates: coordinates)
    }

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

    public static func ==(
        lhs: LineString,
        rhs: LineString)
        -> Bool
    {
        return lhs.projection == rhs.projection
            && lhs.coordinates == rhs.coordinates
    }

}
