#if canImport(CoreLocation)
import CoreLocation
#endif
import Foundation

// MARK: Public

extension Array where Element == Coordinate3D {

#if canImport(CoreLocation)
    /// Maps the array of ``Coordinate3D`` values to an array of ``CLLocationCoordinate2D`` values.
    public var asCoordinates2D: [CLLocationCoordinate2D] {
        return map { $0.coordinate2D }
    }

    /// Maps the array of ``Coordinate3D`` values to an array of ``CLLocation`` values.
    public var asLocations: [CLLocation] {
        return map { $0.location }
    }
#endif

    /// Converts the array of ``Coordinate3D`` values to an array of ``Point`` geometries.
    public var asPoints: [Point] {
        map({ Point($0) })
    }

    /// Creates a ``MultiPoint`` geometry from the array of ``Coordinate3D`` values, or ``nil`` if the array is empty.
    public var asMultiPoint: MultiPoint? {
        MultiPoint(self)
    }

    /// Creates a ``MultiPoint`` geometry from the array of ``Coordinate3D`` values without checking for empty.
    public var asUncheckedMultiPoint: MultiPoint {
        MultiPoint(unchecked: self)
    }

    /// Creates a ``LineString`` geometry from the array of ``Coordinate3D`` values, or ``nil`` if the array is not valid.
    public var asLineString: LineString? {
        LineString(self)
    }

    /// Creates a ``LineString`` geometry from the array of ``Coordinate3D`` values without validation.
    public var asUncheckedLineString: LineString {
        LineString(unchecked: self)
    }

    /// Creates a ``Polygon`` geometry from the array of ``Coordinate3D`` values treated as a single ring, or ``nil`` if not valid.
    public var asPolygon: Polygon? {
        Polygon([self])
    }

    /// Creates a ``Polygon`` geometry from the array of ``Coordinate3D`` values treated as a single ring without validation.
    public var asUncheckedPolygon: Polygon {
        Polygon(unchecked: [self])
    }

    /// Creates a ``Ring`` from the array of ``Coordinate3D`` values, or ``nil`` if the ring is not valid.
    public var asRing: Ring? {
        Ring(self)
    }

    /// Creates a ``Ring`` from the array of ``Coordinate3D`` values without validation.
    public var asUncheckedRing: Ring {
        Ring(unchecked: self)
    }

}

extension Array where Element == GeoJsonGeometry {

    /// Creates a ``GeometryCollection`` from the array of ``GeoJsonGeometry`` values.
    public var asGeometryCollection: GeometryCollection {
        GeometryCollection(self)
    }

    /// Creates a ``FeatureCollection`` using each geometry as a separate feature.
    public var asFeatureCollection: FeatureCollection {
        FeatureCollection(self)
    }

    /// Encodes the array of ``GeoJsonGeometry`` values as Well-Known Binary data.
    public var asWKB: Data? {
        asGeometryCollection.asWKB
    }

    /// Encodes the array of ``GeoJsonGeometry`` values as a Well-Known Text string.
    public var asWKT: String? {
        asGeometryCollection.asWKT
    }

}

extension Array where Element == Feature {

    /// Extracts the geometries from the array of ``Feature`` values and creates a ``GeometryCollection``.
    public var asGeometryCollection: GeometryCollection {
        GeometryCollection(self.map(\.geometry))
    }

    /// Creates a ``FeatureCollection`` from the array of ``Feature`` values.
    public var asFeatureCollection: FeatureCollection {
        FeatureCollection(self)
    }

    /// Extracts geometries from the ``Feature`` array and encodes them as Well-Known Binary data.
    public var asWKB: Data? {
        asGeometryCollection.asWKB
    }

    /// Extracts geometries from the ``Feature`` array and encodes them as a Well-Known Text string.
    public var asWKT: String? {
        asGeometryCollection.asWKT
    }

}

extension Array where Element == FeatureCollection {

    /// Extracts all geometries from the array of ``FeatureCollection`` values and creates a single ``GeometryCollection``.
    public var asGeometryCollection: GeometryCollection {
        GeometryCollection(self.flatMap({ $0.features.map(\.geometry) }))
    }

    /// Merges all features from the array of ``FeatureCollection`` values into a single ``FeatureCollection``.
    public var asFeatureCollection: FeatureCollection {
        FeatureCollection(self.flatMap(\.features))
    }

    /// Extracts all geometries from the ``FeatureCollection`` array and encodes them as Well-Known Binary data.
    public var asWKB: Data? {
        asGeometryCollection.asWKB
    }

    /// Extracts all geometries from the ``FeatureCollection`` array and encodes them as a Well-Known Text string.
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
