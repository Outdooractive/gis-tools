#if !os(Linux)
import CoreLocation
#endif
import Foundation

// This is a port from https://github.com/mourner/flatbush

/// Options for how to build the tree with different performance characteristics/tradeoffs.
public enum RTreeSortOption: Sendable {

    /// Sort input objects by their hilbert value.
    /// - Note: **Performance**: Slow tree build time, very fast search
    case hilbert

    /// Add input objects sorted by their latitude.
    /// - Note: **Performance**: Tree build time is slightly faster than for `hilbert`
    ///         but search will be ~3x slower
    case byLatitude

    /// Add input objects sorted by their longitude.
    /// - Note: **Performance**: Tree build time is slightly faster than for `hilbert`
    ///         but search will be ~3x slower
    case byLongitude

    /// Don't sort input objects.
    /// - Note: **Performance**: Very fast tree build time, but search will be
    ///         very slow (even slower than serial search) if the input is not
    ///         already spatially correlated
    case unsorted

}

// MARK: - RTree

/// An efficient implementation of the packed Hilbert R-tree algorithm.
public struct RTree<T: BoundingBoxRepresentable & Sendable>: Sendable {

    /// The R-Tree's `projection`.
    public let projection: Projection

    /// The indexed objects.
    public let objects: [T]
    /// The number of elements in the RTree.
    public let count: Int
    /// Size of a tree node.
    public let nodeSize: Int

    private var position = 0
    private var boundingBoxes: [BoundingBox] = []
    private var indices: [Int] = []
    private var levelBounds: [Int] = []

    private var minX = Double.infinity
    private var minY = Double.infinity
    private var maxX = -Double.infinity
    private var maxY = -Double.infinity

    /// The R-Tree's bounding box.
    public var boundingBox: BoundingBox {
        BoundingBox(
            southWest: Coordinate3D(x: minX, y: minY, projection: projection),
            northEast: Coordinate3D(x: maxX, y: maxY, projection: projection))
    }

    /// Create a new R-Tree from `objects`.
    public init(
        _ objects: [T],
        nodeSize: Int = 16,
        sortOption: RTreeSortOption = .hilbert)
    {
        var objectsWithBoundingBox: [T] = []
        objectsWithBoundingBox.reserveCapacity(objects.count)

        projection = objects.first?.projection ?? .noSRID

        // Set bounding boxes on all objects
        // Calculate the RTree bounding box
        for var object in objects {
            object.updateBoundingBox(onlyIfNecessary: true)

            guard let boundingBox = object.boundingBox?.projected(to: projection) else { continue }

            objectsWithBoundingBox.append(object)

            if boundingBox.southWest.x < minX {
                minX = boundingBox.southWest.x
            }
            if boundingBox.southWest.y < minY {
                minY = boundingBox.southWest.y
            }
            if boundingBox.northEast.x > maxX {
                maxX = boundingBox.northEast.x
            }
            if boundingBox.northEast.y > maxY {
                maxY = boundingBox.northEast.y
            }
        }

        // Sort input by latitude or longitude
        if sortOption == .byLatitude {
            objectsWithBoundingBox.sort(by: { a, b in
                guard let aLat = a.boundingBox?.southWest.latitude,
                      let bLat = b.boundingBox?.southWest.latitude
                else { return false }
                return aLat < bLat
            })
        }
        else if sortOption == .byLongitude {
            objectsWithBoundingBox.sort(by: { a, b in
                guard let aLong = a.boundingBox?.southWest.longitude,
                      let bLong = b.boundingBox?.southWest.longitude
                else { return false }
                return aLong < bLong
            })
        }

        self.objects = objectsWithBoundingBox
        self.count = objectsWithBoundingBox.count
        self.nodeSize = Int(min(max(nodeSize, 4), 65535))

        // Don't build a tree if serial search would be faster
        guard count > nodeSize else { return }

        // Calculate the number of tree nodes
        var n = count
        var numberOfNodes = n
        levelBounds = [n]

        repeat {
            n = Int(ceil(Double(n) / Double(self.nodeSize)))
            numberOfNodes += n
            levelBounds.append(numberOfNodes)
        }
        while n != 1

        boundingBoxes.reserveCapacity(numberOfNodes)
        indices = Array(repeating: 0, count: numberOfNodes)

        // Add objects to the tree
        for object in self.objects {
            guard let boundingBox = object.boundingBox?.projected(to: projection) else { return }

            indices[position] = position
            boundingBoxes.append(boundingBox)
            position = boundingBoxes.count
        }

        if sortOption == .hilbert {
            sortByHilbertValue()
        }

        // Add the remaining tree nodes for faster search
        buildTree()
    }

}

// MARK: - Search

extension RTree {

    public typealias AroundSearchResult = (
        object: T,
        distance: CLLocationDistance)

    /// Search for objects inside a bounding box.
    public func search(inBoundingBox searchBoundingBox: BoundingBox) -> [T] {
        guard count > nodeSize,
              position == boundingBoxes.count
        else { return searchSerial(inBoundingBox: searchBoundingBox) }

        let searchBoundingBox = searchBoundingBox.projected(to: projection)

        var result: [T] = []

        guard objects.isNotEmpty,
              searchBoundingBox.intersects(boundingBox)
        else { return result }

        var nodeIndex: Int? = boundingBoxes.count - 1
        var queue: [Int] = []

        while let lowerBound = nodeIndex {
            // Find the end index of the node
            let upperBound = min(lowerBound + nodeSize,
                                 RTree.upperBound(of: lowerBound, in: levelBounds))

            // Search through child nodes
            for currentPosition in lowerBound ..< upperBound {
                let index = indices[currentPosition]

                if lowerBound < count {
                    // Check if the object intersects with the query bbox
                    let object = objects[index]
                    if object.intersects(searchBoundingBox) {
                        result.append(object)
                    }
                }
                else {
                    // Check if node bbox intersects with query bbox
                    let nodeBoundingBox = boundingBoxes[currentPosition]
                    if nodeBoundingBox.intersects(searchBoundingBox) {
                        queue.append(index)
                    }
                }
            }

            nodeIndex = (queue.isEmpty ? nil : queue.removeLast())
        }

        return result
    }

    public func searchSerial(inBoundingBox searchBoundingBox: BoundingBox) -> [T] {
        let searchBoundingBox = searchBoundingBox.projected(to: projection)

        var result: [T] = []

        guard objects.isNotEmpty,
              searchBoundingBox.intersects(boundingBox)
        else { return result }

        for object in objects
            where object.intersects(searchBoundingBox)
        {
            result.append(object)
        }

        return result
    }

    /// Search for objects around a coordinate.
    public func search(
        aroundCoordinate coordinate: Coordinate3D,
        maximumDistance: CLLocationDistance,
        sorted: Bool = true)
        -> [AroundSearchResult] where T: GeoJson
    {
        guard count > nodeSize,
              position == boundingBoxes.count
        else { return searchSerial(aroundCoordinate: coordinate, maximumDistance: maximumDistance, sorted: sorted) }

        var result: [AroundSearchResult] = []

        guard objects.isNotEmpty else { return result }

        let coordinate = coordinate.projected(to: projection)

        var nodeIndex: Int? = boundingBoxes.count - 1
        var queue: [Int] = []

        while let lowerBound = nodeIndex {
            // Find the end index of the node
            let upperBound = min(lowerBound + nodeSize,
                                 RTree.upperBound(of: lowerBound, in: levelBounds))

            // Search through child nodes
            for currentPosition in lowerBound ..< upperBound {
                let index = indices[currentPosition]

                if lowerBound < count {
                    let object = objects[index]
                    if let nearest = object.nearestCoordinateOnFeature(from: coordinate),
                       nearest.distance <= maximumDistance
                    {
                        result.append((object, nearest.distance))
                    }
                }
                else {
                    let nodeBoundingBox = boundingBoxes[currentPosition]
                    if let nearest = nodeBoundingBox.nearestCoordinateOnFeature(from: coordinate),
                       nearest.distance <= maximumDistance
                    {
                        queue.append(index)
                    }
                }
            }

            nodeIndex = (queue.isEmpty ? nil : queue.removeLast())
        }

        if sorted {
            result.sort(by: { $0.distance < $1.distance })
        }

        return result
    }

    public func searchSerial(
        aroundCoordinate coordinate: Coordinate3D,
        maximumDistance: CLLocationDistance,
        sorted: Bool = true)
        -> [AroundSearchResult] where T: GeoJson
    {
        var result: [AroundSearchResult] = []

        guard objects.isNotEmpty else { return result }

        let coordinate = coordinate.projected(to: projection)

        for object in objects {
            if let nearest = object.nearestCoordinateOnFeature(from: coordinate),
               nearest.distance <= maximumDistance
            {
                result.append((object, nearest.distance))
            }
        }

        if sorted {
            result.sort(by: { $0.distance < $1.distance })
        }

        return result
    }

}

// MARK: - Private

extension RTree {

    // Generate nodes at each tree level, bottom-up
    private mutating func buildTree() {
        var lowerBound = 0
        for i in 0 ..< levelBounds.count - 1 {
            let upperBound = levelBounds[i]

            // Generate a parent node for each block of consecutive <nodeSize> nodes
            while lowerBound < upperBound {
                let nodeIndex = lowerBound

                // calculate bbox for the new node
                var nodeMinX = Double.infinity
                var nodeMinY = Double.infinity
                var nodeMaxX = -Double.infinity
                var nodeMaxY = -Double.infinity

                for _ in 0 ..< nodeSize {
                    guard lowerBound < upperBound else { break }

                    let boundingBox = boundingBoxes[lowerBound]
                    lowerBound += 1

                    nodeMinX = min(nodeMinX, boundingBox.southWest.x)
                    nodeMinY = min(nodeMinY, boundingBox.southWest.y)
                    nodeMaxX = max(nodeMaxX, boundingBox.northEast.x)
                    nodeMaxY = max(nodeMaxY, boundingBox.northEast.y)
                }

                // Add the new node to the tree data
                indices[position] = nodeIndex
                boundingBoxes.append(
                    BoundingBox(
                        southWest: Coordinate3D(x: nodeMinX, y: nodeMinY, projection: projection),
                        northEast: Coordinate3D(x: nodeMaxX, y: nodeMaxY, projection: projection)))
                position = boundingBoxes.count
            }
        }
    }

    private mutating func sortByHilbertValue() {
        assert(count > nodeSize, "Bug: We don't build trees if serial search would be faster")

        var width = maxX - minX
        var height = maxY - minY
        if width == 0.0 { width = 1.0 }
        if height == 0.0 { height = 1.0 }

        var hilbertValues: [UInt32] = Array(repeating: 0, count: count)
        let hilbertMax = Double((1 << 16) - 1)

        // Map bounding box centers into Hilbert coordinate space and calculate Hilbert values
        for i in 0 ..< count {
            let boundingBox = boundingBoxes[i]
            let x = UInt32(floor(hilbertMax * ((boundingBox.southWest.x + boundingBox.northEast.x) / 2.0 - minX) / width))
            let y = UInt32(floor(hilbertMax * ((boundingBox.southWest.y + boundingBox.northEast.y) / 2.0 - minY) / height))
            hilbertValues[i] = RTree.hilbert(x: x, y: y)
        }

        // Sort items by their Hilbert value (for packing later)
        RTree.sort(
            hilbertValues: &hilbertValues,
            boundingBoxes: &boundingBoxes,
            indices: &indices,
            low: 0,
            high: count - 1,
            nodeSize: nodeSize)
    }

    // Custom quicksort that partially sorts bbox data alongside the hilbert values
    private static func sort(
        hilbertValues: inout [UInt32],
        boundingBoxes: inout [BoundingBox],
        indices: inout [Int],
        low: Int,
        high: Int,
        nodeSize: Int)
    {
        guard low < high else { return }
//        guard floor(Double(low) / Double(nodeSize)) < floor(Double(high) / Double(nodeSize)) else { return }

        let pivot = hilbertValues[(low + high) >> 1]
        var i = low - 1
        var j = high + 1

        while true {
            repeat { i += 1 } while hilbertValues[i] < pivot
            repeat { j -= 1 } while hilbertValues[j] > pivot

            if i >= j { break }

            hilbertValues.swapAt(i, j)
            boundingBoxes.swapAt(i, j)
            indices.swapAt(i, j)
        }

        sort(hilbertValues: &hilbertValues,
             boundingBoxes: &boundingBoxes,
             indices: &indices,
             low: low,
             high: j,
             nodeSize: nodeSize)
        sort(hilbertValues: &hilbertValues,
             boundingBoxes: &boundingBoxes,
             indices: &indices,
             low: j + 1,
             high: high,
             nodeSize: nodeSize)
    }

    // Binary search for the first value in the array bigger than the given
    private static func upperBound(
        of value: Int,
        in array: [Int])
        -> Int
    {
        var (i, j) = (0, array.count - 1)

        while i < j {
            let m = (i + j) >> 1
            if array[m] > value {
                j = m
            }
            else {
                i = m + 1
            }
        }

        return array[i]
    }

    // Fast Hilbert curve algorithm by http://threadlocalmutex.com/
    // Ported from C++ https://github.com/rawrunprotected/hilbert_curves (public domain)
    private static func hilbert(x: UInt32, y: UInt32) -> UInt32 {
        var a = x ^ y
        var b = 0xFFFF ^ a
        var c = 0xFFFF ^ (x | y)
        var d = x & (y ^ 0xFFFF)

        var A = a | (b >> 1)
        var B = (a >> 1) ^ a
        var C = ((c >> 1) ^ (b & (d >> 1))) ^ c
        var D = ((a & (c >> 1)) ^ (d >> 1)) ^ d

        a = A
        b = B
        c = C
        d = D

        A = ((a & (a >> 2)) ^ (b & (b >> 2)))
        B = ((a & (b >> 2)) ^ (b & ((a ^ b) >> 2)))
        C ^= ((a & (c >> 2)) ^ (b & (d >> 2)))
        D ^= ((b & (c >> 2)) ^ ((a ^ b) & (d >> 2)))

        a = A
        b = B
        c = C
        d = D

        A = ((a & (a >> 4)) ^ (b & (b >> 4)))
        B = ((a & (b >> 4)) ^ (b & ((a ^ b) >> 4)))
        C ^= ((a & (c >> 4)) ^ (b & (d >> 4)))
        D ^= ((b & (c >> 4)) ^ ((a ^ b) & (d >> 4)))

        a = A
        b = B
        c = C
        d = D

        C ^= ((a & (c >> 8)) ^ (b & (d >> 8)))
        D ^= ((b & (c >> 8)) ^ ((a ^ b) & (d >> 8)))

        a = C ^ (C >> 1)
        b = D ^ (D >> 1)

        var i0 = x ^ y
        var i1 = b | (0xFFFF ^ (i0 | a))

        i0 = (i0 | (i0 << 8)) & 0x00FF_00FF
        i0 = (i0 | (i0 << 4)) & 0x0F0F_0F0F
        i0 = (i0 | (i0 << 2)) & 0x3333_3333
        i0 = (i0 | (i0 << 1)) & 0x5555_5555

        i1 = (i1 | (i1 << 8)) & 0x00FF_00FF
        i1 = (i1 | (i1 << 4)) & 0x0F0F_0F0F
        i1 = (i1 | (i1 << 2)) & 0x3333_3333
        i1 = (i1 | (i1 << 1)) & 0x5555_5555

        return ((i1 << 1) | i0) >> 0
    }

}
