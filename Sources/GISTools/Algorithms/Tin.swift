#if canImport(CoreLocation)
import CoreLocation
#endif
import Foundation

// Ported from https://github.com/Turfjs/turf/tree/master/packages/turf-tin
// http://en.wikipedia.org/wiki/Delaunay_triangulation
// https://github.com/ironwallaby/delaunay

extension GeoJson {

    /// Computes a Triangulated Irregular Network (TIN) from the receiver's
    /// coordinates using Delaunay triangulation.
    ///
    /// The resulting triangles are returned as a `FeatureCollection` of
    /// `Polygon` features. The coordinate's altitude is used as the
    /// z-value for each vertex.
    ///
    /// - Returns: A `FeatureCollection` of triangle polygons, or `nil` if
    ///   there are fewer than 3 distinct points.
    public func tin() -> FeatureCollection? {
        let coords = allCoordinates
        let unique = Set(coords)
        guard unique.count >= 3 else { return nil }

        let hasZ = coords.allSatisfy { $0.altitude != nil }
        let points = unique.map { Pt(x: $0.longitude, y: $0.latitude, z: hasZ ? $0.altitude : nil) }
        let triangles = Triangulator.triangulate(points)

        let features: [Feature] = triangles.map { triangle in
            let a = Coordinate3D(
                latitude: triangle.a.y, longitude: triangle.a.x,
                altitude: hasZ ? (triangle.a.z ?? 0.0) : nil)
            let b = Coordinate3D(
                latitude: triangle.b.y, longitude: triangle.b.x,
                altitude: hasZ ? (triangle.b.z ?? 0.0) : nil)
            let c = Coordinate3D(
                latitude: triangle.c.y, longitude: triangle.c.x,
                altitude: hasZ ? (triangle.c.z ?? 0.0) : nil)

            let polygon = Polygon(unchecked: [[a, b, c, a]])
            return Feature(polygon)
        }

        return FeatureCollection(features)
    }

}

// MARK: - Internal types

struct Pt: Hashable, Sendable {

    let x: Double
    let y: Double
    let z: Double?
    var isSentinel: Bool

    init(x: Double, y: Double, z: Double? = nil) {
        self.x = x
        self.y = y
        self.z = z
        self.isSentinel = false
    }

    private init(x: Double, y: Double, sentinel: Bool) {
        self.x = x
        self.y = y
        self.z = nil
        self.isSentinel = sentinel
    }

    static func sentinel(x: Double, y: Double) -> Pt {
        Pt(x: x, y: y, sentinel: true)
    }

}

// MARK: - Constants

private enum TinConstants {

    /// Epsilon for collinearity detection in circumcircle calculation.
    static let collinearEpsilon = 1e-12

}

// MARK: - Triangle

final class Triangle: Sendable {

    let a: Pt
    let b: Pt
    let c: Pt
    let cx: Double
    let cy: Double
    let r: Double

    init(_ a: Pt, _ b: Pt, _ c: Pt) {
        self.a = a
        self.b = b
        self.c = c

        let A = b.x - a.x
        let B = b.y - a.y
        let C = c.x - a.x
        let D = c.y - a.y
        let E = A * (a.x + b.x) + B * (a.y + b.y)
        let F = C * (a.x + c.x) + D * (a.y + c.y)
        let G = 2.0 * (A * (c.y - b.y) - B * (c.x - b.x))

        if abs(G) < TinConstants.collinearEpsilon {
            // Collinear — use midpoint as circumcenter
            let minX = min(a.x, b.x, c.x)
            let maxX = max(a.x, b.x, c.x)
            let minY = min(a.y, b.y, c.y)
            let maxY = max(a.y, b.y, c.y)
            self.cx = (minX + maxX) * 0.5
            self.cy = (minY + maxY) * 0.5
        }
        else {
            self.cx = (D * E - B * F) / G
            self.cy = (A * F - C * E) / G
        }

        let dx = self.cx - a.x
        let dy = self.cy - a.y
        self.r = dx * dx + dy * dy
    }

}

// MARK: - Triangulator

enum Triangulator {

    static func triangulate(_ vertices: [Pt]) -> [Triangle] {
        guard vertices.count >= 3 else { return [] }

        let sorted = vertices.sorted { $0.x > $1.x }

        let xmin = sorted.last!.x
        let xmax = sorted.first!.x
        var ymin = sorted.last!.y
        var ymax = ymin

        for v in sorted {
            if v.y < ymin { ymin = v.y }
            if v.y > ymax { ymax = v.y }
        }

        let dx = xmax - xmin
        let dy = ymax - ymin
        let dmax = max(dx, dy)
        let xmid = (xmax + xmin) * 0.5
        let ymid = (ymax + ymin) * 0.5

        let superA = Pt.sentinel(x: xmid - 20.0 * dmax, y: ymid - dmax)
        let superB = Pt.sentinel(x: xmid, y: ymid + 20.0 * dmax)
        let superC = Pt.sentinel(x: xmid + 20.0 * dmax, y: ymid - dmax)

        var open: [Triangle] = [Triangle(superA, superB, superC)]
        var closed: [Triangle] = []

        for v in sorted {
            var edges: [Pt] = []

            var j = open.count
            while j > 0 {
                j -= 1
                let t = open[j]

                let dx = v.x - t.cx
                if dx > 0, dx * dx > t.r {
                    closed.append(t)
                    open.remove(at: j)
                    continue
                }

                let dy = v.y - t.cy
                if dx * dx + dy * dy > t.r {
                    continue
                }

                edges.append(t.a)
                edges.append(t.b)
                edges.append(t.b)
                edges.append(t.c)
                edges.append(t.c)
                edges.append(t.a)
                open.remove(at: j)
            }

            dedup(&edges)

            j = edges.count
            while j > 0 {
                j -= 1
                let b = edges[j]
                j -= 1
                let a = edges[j]
                let c = v

                let A = b.x - a.x
                let B = b.y - a.y
                let G = 2.0 * (A * (c.y - b.y) - B * (c.x - b.x))
                if abs(G) > TinConstants.collinearEpsilon {
                    open.append(Triangle(a, b, c))
                }
            }
        }

        closed.append(contentsOf: open)

        let result = closed.filter { t in
            !t.a.isSentinel && !t.b.isSentinel && !t.c.isSentinel
        }

        return result
    }

    private static func dedup(_ edges: inout [Pt]) {
        var j = edges.count
        while j > 0 {
            j -= 1
            let b = edges[j]
            j -= 1
            let a = edges[j]

            var i = j
            while i > 0 {
                i -= 1
                let n = edges[i]
                i -= 1
                let m = edges[i]

                if (a == m && b == n) || (a == n && b == m) {
                    edges.removeSubrange(j ... j + 1)
                    edges.removeSubrange(i ... i + 1)
                    j -= 2
                    break
                }
            }
        }
    }

}
