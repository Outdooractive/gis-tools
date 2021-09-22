#if !os(Linux)
import CoreLocation
#endif
import Foundation

// This is a port from https://github.com/mourner/flatbush

/// An efficient implementation of the packed Hilbert R-tree algorithm.
public struct RTree<T: BoundingBoxRepresentable> {

    public let objects: [T]
    /// The number of elements in the RTree.
    public let count: Int
    /// Size of a tree node.
    public let nodeSize: Int

    private var position: Int = 0
    private var boundingBoxes: [BoundingBox] = []
    private var indices: [Int] = []
    private var levelBounds: [Int] = []

    private var minX = Double.infinity
    private var minY = Double.infinity
    private var maxX = -Double.infinity
    private var maxY = -Double.infinity

    public var boundingBox: BoundingBox {
        BoundingBox(
            southWest: Coordinate3D(latitude: minY, longitude: minX),
            northEast: Coordinate3D(latitude: maxY, longitude: maxX))
    }

    public init(_ objects: [T], nodeSize: Int = 16) {
        var objectsWithBoundingBox: [T] = []
        objectsWithBoundingBox.reserveCapacity(objects.count)

        // Set bounding boxes on all objects
        // Calculate the RTree bounding box
        for var object in objects {
            object.updateBoundingBox(onlyIfNecessary: true)

            guard let boundingBox = object.boundingBox else { continue }

            objectsWithBoundingBox.append(object)

            if boundingBox.southWest.longitude < minX {
                minX = boundingBox.southWest.longitude
            }
            if boundingBox.southWest.latitude < minY {
                minY = boundingBox.southWest.latitude
            }
            if boundingBox.northEast.longitude > maxX {
                maxX = boundingBox.northEast.longitude
            }
            if boundingBox.northEast.latitude > maxY {
                maxY = boundingBox.northEast.latitude
            }
        }
        self.objects = objectsWithBoundingBox
        self.count = objects.count
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
        } while n != 1

        boundingBoxes.reserveCapacity(numberOfNodes)
        indices = Array(repeating: 0, count: numberOfNodes)

        // Add objects to the tree
        for object in self.objects {
            guard let boundingBox = object.boundingBox else { return }

            indices[position] = position
            boundingBoxes.append(boundingBox)
            position = boundingBoxes.count
        }

        // Add the remaining tree nodes for faster search
        buildTree()
    }

    private mutating func buildTree() {
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
            let x = UInt32(floor(hilbertMax * ((boundingBox.southWest.longitude + boundingBox.northEast.longitude) / 2.0 - minX) / width))
            let y = UInt32(floor(hilbertMax * ((boundingBox.southWest.latitude + boundingBox.northEast.latitude) / 2.0 - minY) / height))
            hilbertValues[i] = RTree.hilbert(x: x, y: y);
        }

        // Sort items by their Hilbert value (for packing later)
        RTree.sort(
            hilbertValues: &hilbertValues,
            boundingBoxes: &boundingBoxes,
            indices: &indices,
            low: 0,
            high: count - 1,
            nodeSize: nodeSize)

        // Generate nodes at each tree level, bottom-up
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

                    nodeMinX = min(nodeMinX, boundingBox.southWest.longitude)
                    nodeMinY = min(nodeMinY, boundingBox.southWest.latitude)
                    nodeMaxX = max(nodeMaxX, boundingBox.northEast.longitude)
                    nodeMaxY = max(nodeMaxY, boundingBox.northEast.latitude)
                }

                // Add the new node to the tree data
                indices[position] = nodeIndex
                boundingBoxes.append(
                    BoundingBox(
                        southWest: Coordinate3D(latitude: nodeMinY, longitude: nodeMinX),
                        northEast: Coordinate3D(latitude: nodeMaxY, longitude: nodeMaxX)))
                position = boundingBoxes.count
            }
        }
    }

    public func search(inBoundingBox boundingBox: BoundingBox) -> [T] {
        guard count > nodeSize,
              position == boundingBoxes.count
        else { return searchSerial(inBoundingBox: boundingBox) }

        var result: [T] = []

        guard objects.count > 0,
              boundingBox.intersects(self.boundingBox)
        else { return result }

        var nodeIndex: Int? = boundingBoxes.count - 1
        var queue: [Int] = []

        let minX = boundingBox.southWest.longitude
        let minY = boundingBox.southWest.latitude
        let maxX = boundingBox.northEast.longitude
        let maxY = boundingBox.northEast.latitude

        while let lowerBound = nodeIndex {
            // Find the end index of the node
            let upperBound = min(lowerBound + nodeSize,
                                 RTree.upperBound(of: lowerBound, in: levelBounds))

            // Search through child nodes
            for localPosition in lowerBound ..< upperBound {
                let index = indices[localPosition]

                // Check if node bbox intersects with query bbox
                let nodeBoundingBox = boundingBoxes[localPosition]
                if maxX < nodeBoundingBox.southWest.longitude { continue } // maxX < nodeMinX
                if maxY < nodeBoundingBox.southWest.latitude { continue } // maxY < nodeMinY
                if minX > nodeBoundingBox.northEast.longitude { continue } // minX > nodeMaxX
                if minY > nodeBoundingBox.northEast.latitude { continue } // minY > nodeMaxY

                if lowerBound < count {
                    result.append(objects[index])
                }
                else {
                    queue.append(index)
                }
            }

            nodeIndex = (queue.isEmpty ? nil : queue.removeLast())
        }

        return result
    }

    public func searchSerial(inBoundingBox boundingBox: BoundingBox) -> [T] {
        var result: [T] = []

        guard objects.count > 0,
              boundingBox.intersects(self.boundingBox)
        else { return result }

        for object in objects
            where object.intersects(boundingBox)
        {
            result.append(object)
        }

        return result
    }

    public typealias AroundSearchResult = (
        object: T,
        distance: CLLocationDistance)

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

        guard objects.count > 0,
              boundingBox.intersects(self.boundingBox)
        else { return result }

        var nodeIndex: Int? = boundingBoxes.count - 1
        var queue: [Int] = []

        while let lowerBound = nodeIndex {
            // Find the end index of the node
            let upperBound = min(lowerBound + nodeSize,
                                 RTree.upperBound(of: lowerBound, in: levelBounds))

            // Search through child nodes
            for localPosition in lowerBound ..< upperBound {
                let index = indices[localPosition]

                if lowerBound < count {
                    let object = objects[index]
                    if let nearest = object.nearestCoordinateOnFeature(from: coordinate),
                       nearest.distance <= maximumDistance
                    {
                        result.append((object, nearest.distance))
                    }
                }
                else {
                    let nodeBoundingBox = boundingBoxes[localPosition]
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

        guard objects.count > 0,
              boundingBox.intersects(self.boundingBox)
        else { return result }

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

extension RTree {

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
        var (i,j) = (0, array.count - 1)

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

        i0 = (i0 | (i0 << 8)) & 0x00FF00FF
        i0 = (i0 | (i0 << 4)) & 0x0F0F0F0F
        i0 = (i0 | (i0 << 2)) & 0x33333333
        i0 = (i0 | (i0 << 1)) & 0x55555555

        i1 = (i1 | (i1 << 8)) & 0x00FF00FF
        i1 = (i1 | (i1 << 4)) & 0x0F0F0F0F
        i1 = (i1 | (i1 << 2)) & 0x33333333
        i1 = (i1 | (i1 << 1)) & 0x55555555

        return ((i1 << 1) | i0) >> 0
    }

}
