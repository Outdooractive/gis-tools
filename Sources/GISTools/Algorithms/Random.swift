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
            latitude: Double.random(in: southWest.latitude ... northEast.latitude),
            longitude: Double.random(in: southWest.longitude ... northEast.longitude))
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
    /// - Parameter count: Number of polygons to generate (default `1`).
    /// - Parameter numVertices: Number of vertices per polygon (default `10`).
    /// - Parameter maxRadialLength: Maximum radial distance from center in degrees (default `10.0`).
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
            southWest: Coordinate3D(
                latitude: southWest.latitude + radialLength,
                longitude: southWest.longitude + radialLength),
            northEast: Coordinate3D(
                latitude: northEast.latitude - radialLength,
                longitude: northEast.longitude - radialLength))

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
                return Coordinate3D(
                    latitude: center.latitude + dy,
                    longitude: center.longitude + dx)
            }
            let ring = vertices.reversed() + [vertices.reversed()[0]]
            return Feature(Polygon(unchecked: [ring]))
        })
    }

    /// Generates random line strings within this bounding box.
    ///
    /// - Parameter count: Number of line strings to generate (default `1`).
    /// - Parameter numVertices: Number of vertices per line string (default `10`).
    /// - Parameter maxLength: Maximum segment length in degrees (default `0.0001`).
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
                    latitude: previous.latitude + distance * sin(angle),
                    longitude: previous.longitude + distance * cos(angle)))
            }
            return Feature(LineString(unchecked: vertices))
        })
    }

}

extension BoundingBox {

    /// A random position within the world bounding box.
    ///
    /// - Returns: A random coordinate.
    public static func randomCoordinate() -> Coordinate3D {
        world.randomCoordinate()
    }

    /// Generates random points within the world bounding box.
    ///
    /// - Parameter count: Number of points to generate (default `1`).
    /// - Returns: A feature collection of point features.
    public static func randomPoints(count: Int = 1) -> FeatureCollection {
        world.randomPoints(count: count)
    }

    /// Generates random polygons within the world bounding box.
    ///
    /// - Parameter count: Number of polygons to generate (default `1`).
    /// - Parameter numVertices: Number of vertices per polygon (default `10`).
    /// - Parameter maxRadialLength: Maximum radial distance from center in degrees (default `10.0`).
    /// - Returns: A feature collection of polygon features.
    public static func randomPolygons(
        count: Int = 1,
        numVertices: Int = 10,
        maxRadialLength: CLLocationDegrees = 10.0
    ) -> FeatureCollection {
        world.randomPolygons(
            count: count,
            numVertices: numVertices,
            maxRadialLength: maxRadialLength)
    }

    /// Generates random line strings within the world bounding box.
    ///
    /// - Parameter count: Number of line strings to generate (default `1`).
    /// - Parameter numVertices: Number of vertices per line string (default `10`).
    /// - Parameter maxLength: Maximum segment length in degrees (default `0.0001`).
    /// - Parameter maxRotation: Maximum turn angle in radians (default `π / 8`).
    /// - Returns: A feature collection of line string features.
    public static func randomLineStrings(
        count: Int = 1,
        numVertices: Int = 10,
        maxLength: CLLocationDegrees = 0.0001,
        maxRotation: CLLocationDegrees = .pi / 8.0
    ) -> FeatureCollection {
        world.randomLineStrings(
            count: count,
            numVertices: numVertices,
            maxLength: maxLength,
            maxRotation: maxRotation)
    }

}
