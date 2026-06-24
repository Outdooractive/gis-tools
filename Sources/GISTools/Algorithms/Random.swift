#if canImport(CoreLocation)
import CoreLocation
#endif
import Foundation

// Ported from https://github.com/Turfjs/turf/tree/master/packages/turf-random

extension BoundingBox {

    /// A random coordinate within this bounding box.
    ///
    /// - Returns: A random coordinate.
    public func randomCoordinate() -> Coordinate3D {
        Coordinate3D(
            x: Double.random(in: southWest.longitude ... northEast.longitude),
            y: Double.random(in: southWest.latitude ... northEast.latitude),
            projection: projection)
    }

    /// Generates random points within this bounding box.
    ///
    /// - Parameter count: Number of points to generate (default `1`).
    /// - Returns: A feature collection of point features.
    public func randomPoints(count: Int = 1) -> FeatureCollection {
        FeatureCollection((0 ..< count).map { _ in
            Feature(Point(randomCoordinate()))
        })
    }

    /// Generates random polygons within this bounding box.
    ///
    /// The coordinate values (bbox extents, ``maxRadialLength``) are in degrees
    /// for EPSG:4326 and in projection units (meters for 3857/4978) for others.
    ///
    /// - Parameter count: Number of polygons to generate (default `1`).
    /// - Parameter numVertices: Number of vertices per polygon (default `10`).
    /// - Parameter maxRadialLength: Maximum radial distance from center (default `10.0`).
    /// - Returns: A feature collection of polygon features.
    public func randomPolygons(
        count: Int = 1,
        numVertices: Int = 10,
        maxRadialLength: CLLocationDegrees = 10.0
    ) -> FeatureCollection {
        let bboxWidth = abs(northEast.longitude - southWest.longitude)
        let bboxHeight = abs(northEast.latitude - southWest.latitude)
        let maxRadius = min(bboxWidth / 2.0, bboxHeight / 2.0)
        let radialLength = min(maxRadialLength, maxRadius)

        let paddedBbox = BoundingBox(
            southWest: Coordinate3D(x: southWest.longitude + radialLength,
                                    y: southWest.latitude + radialLength,
                                    projection: projection),
            northEast: Coordinate3D(x: northEast.longitude - radialLength,
                                    y: northEast.latitude - radialLength,
                                    projection: projection))

        return FeatureCollection((0 ..< count).map { _ in
            let center = paddedBbox.randomCoordinate()
            let offsets = (0 ... numVertices).map { _ in Double.random(in: 0 ... 1) }
            let total = offsets.reduce(0, +)
            let cumulative = offsets.reduce(into: [Double]()) { acc, val in
                acc.append((acc.last ?? 0.0) + val)
            }
            let vertices: [Coordinate3D] = cumulative.map { cur in
                let angle = cur * 2.0 * .pi / total
                let scale = Double.random(in: 0 ... 1)
                let dx = scale * radialLength * sin(angle)
                let dy = scale * radialLength * cos(angle)
                return Coordinate3D(x: center.longitude + dx,
                                    y: center.latitude + dy,
                                    projection: projection)
            }
            let ring = vertices.reversed() + [vertices.reversed()[0]]
            return Feature(Polygon(unchecked: [ring]))
        })
    }

    /// Generates random line strings within this bounding box.
    ///
    /// The coordinate values (bbox extents, ``maxLength``) are in degrees
    /// for EPSG:4326 and in projection units (meters for 3857/4978) for others.
    ///
    /// - Parameter count: Number of line strings to generate (default `1`).
    /// - Parameter numVertices: Number of vertices per line string (default `10`).
    /// - Parameter maxLength: Maximum segment length (default `0.0001`).
    /// - Parameter maxRotation: Maximum turn angle in radians (default `π / 8`).
    /// - Returns: A feature collection of line string features.
    public func randomLineStrings(
        count: Int = 1,
        numVertices: Int = 10,
        maxLength: CLLocationDegrees = 0.0001,
        maxRotation: CLLocationDegrees = .pi / 8.0
    ) -> FeatureCollection {
        FeatureCollection((0 ..< count).map { _ in
            let start = randomCoordinate()
            var vertices = [start]
            for index in 1 ..< numVertices {
                let previous = vertices[index - 1]
                let priorAngle = index == 1
                    ? Double.random(in: 0 ... 2.0 * .pi)
                    : atan2(
                        vertices[index - 1].latitude - vertices[index - 2].latitude,
                        vertices[index - 1].longitude - vertices[index - 2].longitude)
                let angle = priorAngle + Double.random(in: -maxRotation ... maxRotation)
                let distance = Double.random(in: 0 ... maxLength)
                vertices.append(Coordinate3D(
                    x: previous.longitude + distance * cos(angle),
                    y: previous.latitude + distance * sin(angle),
                    projection: projection))
            }
            return Feature(LineString(unchecked: vertices))
        })
    }

}

extension BoundingBox {

    /// The world bounding box projected to the given CRS.
    private static func worldBox(projection: Projection) -> BoundingBox {
        switch projection {
        case .epsg4326:
            return BoundingBox.world
        case .epsg3857:
            let s = GISTool.originShift
            return BoundingBox(
                southWest: Coordinate3D(x: -s, y: -s, projection: .epsg3857),
                northEast: Coordinate3D(x: s, y: s, projection: .epsg3857))
        case .epsg4978:
            let r = GISTool.equatorialRadius
            return BoundingBox(
                southWest: Coordinate3D(x: -r, y: -r, z: -r, projection: .epsg4978),
                northEast: Coordinate3D(x: r, y: r, z: r, projection: .epsg4978))
        case .noSRID:
            return BoundingBox(
                southWest: Coordinate3D(x: -180.0, y: -90.0, projection: .noSRID),
                northEast: Coordinate3D(x: 180.0, y: 90.0, projection: .noSRID))
        }
    }

    /// A random position within the world bounding box.
    ///
    /// - Parameter projection: The target projection (default `.epsg4326`).
    /// - Returns: A random coordinate.
    public static func randomCoordinate(projection: Projection = .epsg4326) -> Coordinate3D {
        worldBox(projection: projection).randomCoordinate()
    }

    /// Generates random points within the world bounding box.
    ///
    /// - Parameter count: Number of points to generate (default `1`).
    /// - Parameter projection: The target projection (default `.epsg4326`).
    /// - Returns: A feature collection of point features.
    public static func randomPoints(
        count: Int = 1,
        projection: Projection = .epsg4326
    ) -> FeatureCollection {
        worldBox(projection: projection).randomPoints(count: count)
    }

    /// Generates random polygons within the world bounding box.
    ///
    /// The coordinate values (``maxRadialLength``) are in degrees for EPSG:4326
    /// and in projection units (meters for 3857/4978) for others.
    ///
    /// - Parameter count: Number of polygons to generate (default `1`).
    /// - Parameter numVertices: Number of vertices per polygon (default `10`).
    /// - Parameter maxRadialLength: Maximum radial distance from center (default `10.0`).
    /// - Parameter projection: The target projection (default `.epsg4326`).
    /// - Returns: A feature collection of polygon features.
    public static func randomPolygons(
        count: Int = 1,
        numVertices: Int = 10,
        maxRadialLength: CLLocationDegrees = 10.0,
        projection: Projection = .epsg4326
    ) -> FeatureCollection {
        worldBox(projection: projection).randomPolygons(
            count: count,
            numVertices: numVertices,
            maxRadialLength: maxRadialLength)
    }

    /// Generates random line strings within the world bounding box.
    ///
    /// The coordinate values (``maxLength``) are in degrees for EPSG:4326
    /// and in projection units (meters for 3857/4978) for others.
    ///
    /// - Parameter count: Number of line strings to generate (default `1`).
    /// - Parameter numVertices: Number of vertices per line string (default `10`).
    /// - Parameter maxLength: Maximum segment length (default `0.0001`).
    /// - Parameter maxRotation: Maximum turn angle in radians (default `π / 8`).
    /// - Parameter projection: The target projection (default `.epsg4326`).
    /// - Returns: A feature collection of line string features.
    public static func randomLineStrings(
        count: Int = 1,
        numVertices: Int = 10,
        maxLength: CLLocationDegrees = 0.0001,
        maxRotation: CLLocationDegrees = .pi / 8.0,
        projection: Projection = .epsg4326
    ) -> FeatureCollection {
        worldBox(projection: projection).randomLineStrings(
            count: count,
            numVertices: numVertices,
            maxLength: maxLength,
            maxRotation: maxRotation)
    }

}
