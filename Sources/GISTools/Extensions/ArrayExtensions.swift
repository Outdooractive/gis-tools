import Foundation

// MARK: Public

extension Array where Element == Coordinate3D {

    public func toMultiPoint() -> MultiPoint {
        MultiPoint(self)
    }

    public func toLineString() -> LineString {
        LineString(self)
    }

    public func toPolygon() -> Polygon? {
        Polygon([self])
    }

    public func toRing() -> Ring {
        Ring(self)
    }

}

// MARK: - Internal

extension Array {

    /// Returns the array's elements pairwise, with every element only once in the result.
    /// For arrays with uneven length, the last element will be skipped.
    /// let a = [1, 2, 3, 4, 5]
    /// a.distinctPairs() -> [(1, 2), (3, 4)]
    func distinctPairs() -> [(first: Element, second: Element)] {
        guard !isEmpty else { return [] }

        return (0 ..< (self.count / 2)).map { (index) in
            let i = index * 2
            return (first: self[i], second: self[i+1])
        }
    }

    /// Returns the array's elements pairwise, where each pair overlaps the previous pair.
    /// let a = [1, 2, 3, 4, 5]
    /// a.overlappingPairs() -> [(1, 2), (2, 3), (3, 4), (4, 5)]
    func overlappingPairs() -> [(first: Element, second: Element)] {
        guard !isEmpty else { return [] }

        return (0 ..< (self.count - 1)).map { (index) in
            return (first: self[index], second: self[index + 1])
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
    func nilIfEmpty() -> [Element]? {
        guard !isEmpty else { return nil }
        return self
    }

}
