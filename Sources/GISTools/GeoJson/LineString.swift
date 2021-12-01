#if !os(Linux)
import CoreLocation
#endif
import Foundation

public struct LineString: LineStringGeometry, EmptyCreatable {

    public var type: GeoJsonType {
        return .lineString
    }

    public let coordinates: [Coordinate3D]

    public var boundingBox: BoundingBox?

    public var foreignMembers: [String: Any] = [:]

    public var lineStrings: [LineString] {
        return [self]
    }

    public init() {
        self.coordinates = []
    }

    public init?(_ coordinates: [Coordinate3D], calculateBoundingBox: Bool = false) {
        guard coordinates.count >= 2 else { return nil }

        self.init(unchecked: coordinates, calculateBoundingBox: calculateBoundingBox)
    }

    public init(unchecked coordinates: [Coordinate3D], calculateBoundingBox: Bool = false) {
        self.coordinates = coordinates

        if calculateBoundingBox {
            self.boundingBox = self.calculateBoundingBox()
        }
    }

    public init(_ lineSegment: LineSegment, calculateBoundingBox: Bool = false) {
        self.coordinates = lineSegment.coordinates

        if calculateBoundingBox {
            self.boundingBox = self.calculateBoundingBox()
        }
    }

    public init?(json: Any?) {
        self.init(json: json, calculateBoundingBox: false)
    }

    public init?(json: Any?, calculateBoundingBox: Bool = false) {
        guard let geoJson = json as? [String: Any],
              LineString.isValid(geoJson: geoJson),
              let coordinates: [Coordinate3D] = LineString.tryCreate(json: geoJson["coordinates"])
        else { return nil }

        self.coordinates = coordinates
        self.boundingBox = LineString.tryCreate(json: geoJson["bbox"])

        if calculateBoundingBox, self.boundingBox == nil {
            self.boundingBox = self.calculateBoundingBox()
        }

        if geoJson.count > 2 {
            var foreignMembers = geoJson
            foreignMembers.removeValue(forKey: "type")
            foreignMembers.removeValue(forKey: "coordinates")
            foreignMembers.removeValue(forKey: "bbox")
            self.foreignMembers = foreignMembers
        }
    }

    public func asJson() -> [String: Any] {
        var result: [String: Any] = [
            "type": GeoJsonType.lineString.rawValue,
            "coordinates": coordinates.map { $0.asJson() }
        ]
        if let boundingBox = boundingBox {
            result["bbox"] = boundingBox.asJson()
        }
        result.merge(foreignMembers) { (current, new) in
            return current
        }
        return result
    }

}

extension LineString {

    public var firstCoordinate: Coordinate3D? {
        return coordinates.first
    }

    public var lastCoordinate: Coordinate3D? {
        return coordinates.last
    }

}

// MARK: - CoreLocation compatibility

#if !os(Linux)
extension LineString {

    public init?(_ coordinates: [CLLocationCoordinate2D], calculateBoundingBox: Bool = false) {
        self.init(coordinates.map({ Coordinate3D($0) }), calculateBoundingBox: calculateBoundingBox)
    }

    public init?(_ coordinates: [CLLocation], calculateBoundingBox: Bool = false) {
        self.init(coordinates.map({ Coordinate3D($0) }), calculateBoundingBox: calculateBoundingBox)
    }

}
#endif

// MARK: - BoundingBox

extension LineString {

    public func calculateBoundingBox() -> BoundingBox? {
        return BoundingBox(coordinates: coordinates)
    }

    public func intersects(_ otherBoundingBox: BoundingBox) -> Bool {
        if let boundingBox = boundingBox,
           !boundingBox.intersects(otherBoundingBox)
        {
            return false
        }

        let boundingBoxSegments: [LineSegment] = otherBoundingBox.lineSegments()

        let minLongitude = otherBoundingBox.southWest.longitude
        let minLatitude = otherBoundingBox.southWest.latitude
        let maxLongitude = otherBoundingBox.northEast.longitude
        let maxLatitude = otherBoundingBox.northEast.latitude

        for index in 0 ..< coordinates.count - 1 {
            let segment = LineSegment(first: coordinates[index], second: coordinates[index + 1])

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

extension LineString {

    public var hasValidCoordinates: Bool {
        return coordinates.count >= 2
    }

    public static func isValid(geoJson: [String: Any]) -> Bool {
        return checkIsValid(geoJson: geoJson, ofType: .lineString)
    }

}

// MARK: - Equatable

extension LineString: Equatable {

    public static func ==(
        lhs: LineString,
        rhs: LineString)
        -> Bool
    {
        return lhs.coordinates == rhs.coordinates
    }

}
