#if !os(Linux)
import CoreLocation
#endif
import Foundation

// MARK: Public

extension Array where Element == Coordinate3D {

#if !os(Linux)
    public var asCoordinates2D: [CLLocationCoordinate2D] {
        return map { $0.coordinate2D }
    }

    public var asLocations: [CLLocation] {
        return map { $0.location }
    }
#endif

    public var asPoints: [Point] {
        map({ Point($0) })
    }

    public var asMultiPoint: MultiPoint? {
        MultiPoint(self)
    }

    public var asUncheckedMultiPoint: MultiPoint {
        MultiPoint(unchecked: self)
    }

    public var asLineString: LineString? {
        LineString(self)
    }

    public var asUncheckedLineString: LineString {
        LineString(unchecked: self)
    }

    public var asPolygon: Polygon? {
        Polygon([self])
    }

    public var asUncheckedPolygon: Polygon {
        Polygon(unchecked: [self])
    }

    public var asRing: Ring? {
        Ring(self)
    }

    public var asUncheckedRing: Ring {
        Ring(unchecked: self)
    }

}

extension Array where Element == GeoJsonGeometry {

    public var asGeometryCollection: GeometryCollection {
        GeometryCollection(self)
    }

    public var asFeatureCollection: FeatureCollection {
        FeatureCollection(self)
    }

    public var asWKB: Data? {
        asGeometryCollection.asWKB
    }

    public var asWKT: String? {
        asGeometryCollection.asWKT
    }

}

extension Array where Element == Feature {

    public var asGeometryCollection: GeometryCollection {
        GeometryCollection(self.map(\.geometry))
    }

    public var asFeatureCollection: FeatureCollection {
        FeatureCollection(self)
    }

    public var asWKB: Data? {
        asGeometryCollection.asWKB
    }

    public var asWKT: String? {
        asGeometryCollection.asWKT
    }

}

extension Array where Element == FeatureCollection {

    public var asGeometryCollection: GeometryCollection {
        GeometryCollection(self.flatMap({ $0.features.map(\.geometry) }))
    }

    public var asFeatureCollection: FeatureCollection {
        FeatureCollection(self.flatMap(\.features))
    }

    public var asWKB: Data? {
        asGeometryCollection.asWKB
    }

    public var asWKT: String? {
        asGeometryCollection.asWKT
    }

}

// MARK: - Private

extension Array {

    /// Returns the array's elements pairwise, with every element only once in the result.
    /// For arrays with uneven length, the last element will be skipped.
    ///
    /// ```
    /// let a = [1, 2, 3, 4, 5]
    /// a.distinctPairs() -> [(1, 2), (3, 4)]
    /// ```
    func distinctPairs() -> [(first: Element, second: Element?)] {
        guard !isEmpty else { return [] }

        if count == 1 {
            return [(first: self[0], second: nil)]
        }

        return (0 ..< (self.count / 2)).map { (index) in
            let i = index * 2
            return (first: self[i], second: self[i+1])
        }
    }

    /// Returns the array's elements pairwise, where each pair overlaps the previous pair.
    ///
    /// ```
    /// let a = [1, 2, 3, 4, 5]
    /// a.overlappingPairs() -> [(1, 2), (2, 3), (3, 4), (4, 5)]
    /// ```
    func overlappingPairs() -> [(first: Element, second: Element?, index: Int)] {
        guard !isEmpty else { return [] }

        if count == 1 {
            return [(first: self[0], second: nil, index: 0)]
        }

        return (0 ..< (self.count - 1)).map { (index) in
            return (first: self[index], second: self[index + 1], index: index)
        }
    }

    /// Split the array into equal sized chunks.
    func chunked(into chunkSize: Int) -> [[Element]] {
        stride(from: 0, to: count, by: chunkSize).map { chunk in
            Array(self[chunk ..< Swift.min(chunk + chunkSize, count)])
        }
    }

    /// Fetches an element from the array, or returns nil if the index is out of bounds.
    ///
    /// - parameter index: The index in the array. May be negative. In this case, -1 will be the last element, -2 the second-to-last, and so on.
    func get(at index: Int) -> Element? {
        guard index >= -count && index < count else { return nil }

        if index >= 0 {
            return self[index]
        }
        else {
            return self[count - abs(index)]
        }
    }

    /// Adds a new element at the end of the array, if it's not nil.
    mutating func append(ifNotNil newElement: Element?) {
        guard let element = newElement else { return }
        append(element)
    }

    /// The array, or nil if it is empty
    var nilIfEmpty: [Element]? {
        guard !isEmpty else { return nil }
        return self
    }

    /// A Boolean value indicating whether the collection is not empty.
    var isNotEmpty: Bool {
        !isEmpty
    }

}
