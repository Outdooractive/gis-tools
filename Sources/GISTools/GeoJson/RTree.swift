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
    /// Size of a tree node (16 by default)
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
        self.objects = objects.compactMap({ object in
            var object = object
            object.updateBoundingBox(onlyIfNecessary: true)
            return (object.boundingBox != nil ? object : nil)
        })
        self.count = objects.count
        self.nodeSize = Int(min(max(nodeSize, 2), 65535))

        guard count > 0 else { return }

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

        for object in self.objects {
            guard let boundingBox = object.boundingBox else { return }
            add(boundingBox: boundingBox)
        }

        finish()
    }

    private mutating func add(boundingBox: BoundingBox) {
        indices[position] = position
        boundingBoxes.append(boundingBox)
        position = boundingBoxes.count

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

    private mutating func finish() {
        if count <= nodeSize {
            // only one node, skip sorting and just fill the root box
            boundingBoxes.append(
                BoundingBox(
                    southWest: Coordinate3D(latitude: minY, longitude: minX),
                    northEast: Coordinate3D(latitude: maxY, longitude: maxX)))
            position = boundingBoxes.count
            return
        }

        var width = maxX - minX
        var height = maxY - minY
        if width == 0.0 { width = 1.0 }
        if height == 0.0 { height = 1.0 }

        var hilbertValues: [UInt32] = Array(repeating: 0, count: count)
        let hilbertMax = Double((1 << 16) - 1)

        // map item centers into Hilbert coordinate space and calculate Hilbert values
        for i in 0 ..< count {
            let boundingBox = boundingBoxes[i]
            let minX = boundingBox.southWest.longitude
            let minY = boundingBox.southWest.latitude
            let maxX = boundingBox.northEast.longitude
            let maxY = boundingBox.northEast.latitude
            let x = UInt32(floor(hilbertMax * ((minX + maxX) / 2.0 - self.minX) / width))
            let y = UInt32(floor(hilbertMax * ((minY + maxY) / 2.0 - self.minY) / height))
            hilbertValues[i] = RTree.hilbert(x: x, y: y);
        }

        RTree.sort(
            hilbertValues: &hilbertValues,
            boundingBoxes: &boundingBoxes,
            indices: &indices,
            low: 0,
            high: count - 1,
            nodeSize: nodeSize)

        // generate nodes at each tree level, bottom-up
        var localPosition = 0
        for i in 0 ..< levelBounds.count - 1 {
            let end = levelBounds[i]

            // generate a parent node for each block of consecutive <nodeSize> nodes
            while localPosition < end {
                let nodeIndex = localPosition

                // calculate bbox for the new node
                var nodeMinX = Double.infinity
                var nodeMinY = Double.infinity
                var nodeMaxX = -Double.infinity
                var nodeMaxY = -Double.infinity

                for _ in 0 ..< nodeSize {
                    guard localPosition < end else { break }

                    let boundingBox = boundingBoxes[localPosition]
                    localPosition += 1

                    nodeMinX = min(nodeMinX, boundingBox.southWest.longitude)
                    nodeMinY = min(nodeMinY, boundingBox.southWest.latitude)
                    nodeMaxX = max(nodeMaxX, boundingBox.northEast.longitude)
                    nodeMaxY = max(nodeMaxY, boundingBox.northEast.latitude)
                }

                // add the new node to the tree data
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
        assert(position == boundingBoxes.count, "Data not yet indexed")

        var result: [T] = []

        guard objects.count > 0 else { return result }

        var nodeIndex: Int? = boundingBoxes.count - 1
        var queue: [Int] = []

        let minX = boundingBox.southWest.longitude
        let minY = boundingBox.southWest.latitude
        let maxX = boundingBox.northEast.longitude
        let maxY = boundingBox.northEast.latitude

        while let localNodeIndex = nodeIndex {
            // find the end index of the node
            let end = min(localNodeIndex + nodeSize,
                          RTree.upperBound(of: localNodeIndex, in: levelBounds))

            // search through child nodes
            for localPosition in localNodeIndex ..< end {
                let index = indices[localPosition]

                // check if node bbox intersects with query bbox
                let nodeBoundingBox = boundingBoxes[localPosition]
                if maxX < nodeBoundingBox.southWest.longitude { continue } // maxX < nodeMinX
                if maxY < nodeBoundingBox.southWest.latitude { continue } // maxY < nodeMinY
                if minX > nodeBoundingBox.northEast.longitude { continue } // minX > nodeMaxX
                if minY > nodeBoundingBox.northEast.latitude { continue } // minY > nodeMaxY

                if localNodeIndex < count {
                    result.append(objects[index])
                }
                else {
                    queue.append(index) // node, add it to the search queue
                }
            }

            nodeIndex = (queue.isEmpty ? nil : queue.removeLast())
        }

        return result
    }

    public func searchSerial(inBoundingBox boundingBox: BoundingBox) -> [T] {
        var result: [T] = []

        guard objects.count > 0 else { return result }

        for object in objects {
            if object.intersects(boundingBox) {
                result.append(object)
            }
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
//        guard leftValue < rightValue else { return }
        guard floor(Double(low) / Double(nodeSize)) < floor(Double(high) / Double(nodeSize)) else { return }

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
