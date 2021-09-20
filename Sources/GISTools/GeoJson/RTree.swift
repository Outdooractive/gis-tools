#if !os(Linux)
import CoreLocation
#endif
import Foundation

// This is a port from https://github.com/mourner/flatbush

public struct RTree<T: BoundingBoxRepresentable> {

    let objects: [T]
    let numberOfItems: Int
    let nodeSize: Int

    private var position: Int = 0
    private var boundingBoxEdges: [Double]
    private var indices: [Int]
    private var levelBounds: [Int]

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
        self.numberOfItems = objects.count
        self.nodeSize = Int(min(max(nodeSize, 2), 65535))

        // calculate the total number of nodes in the R-tree to allocate space for
        // and the index of each tree level (used in search later)
        var n = numberOfItems
        var numberOfNodes = n
        levelBounds = [n * 4]

        repeat {
            n = Int(ceil(Double(n) / Double(self.nodeSize)))
            numberOfNodes += n
            levelBounds.append(numberOfNodes * 4)
        } while n != 1

        boundingBoxEdges = Array(repeating: 0.0, count: numberOfNodes * 4)
        indices = Array(repeating: 0, count: numberOfNodes)

        for object in self.objects {
            guard let boundingBox = object.boundingBox else { return }
            add(boundingBox: boundingBox)
        }

        finish()
    }

    private mutating func add(boundingBox: BoundingBox) {
        let index = self.position >> 2

        let minX = boundingBox.southWest.longitude
        let minY = boundingBox.southWest.latitude
        let maxX = boundingBox.northEast.longitude
        let maxY = boundingBox.northEast.latitude

        indices[index] = index
        boundingBoxEdges[position] = minX; position += 1
        boundingBoxEdges[position] = minY; position += 1
        boundingBoxEdges[position] = maxX; position += 1
        boundingBoxEdges[position] = maxY; position += 1

        if minX < self.minX { self.minX = minX }
        if minY < self.minY { self.minY = minY }
        if maxX > self.maxX { self.maxX = maxX }
        if maxY > self.maxY { self.maxY = maxY }
    }

    private mutating func finish() {
        if numberOfItems <= nodeSize {
            // only one node, skip sorting and just fill the root box
            boundingBoxEdges[position] = minX; position += 1
            boundingBoxEdges[position] = minY; position += 1
            boundingBoxEdges[position] = maxX; position += 1
            boundingBoxEdges[position] = maxY; position += 1
            return
        }

        let width = max(maxX - minX, 1)
        let height = max(maxY - minY, 1)
        var hilbertValues: [UInt32] = Array(repeating: 0, count: numberOfItems)
        let hilbertMax = Double((1 << 16) - 1)

        // map item centers into Hilbert coordinate space and calculate Hilbert values
        for i in 0 ..< numberOfItems {
            var localPosition = 4 * i
            let minX = boundingBoxEdges[localPosition]; localPosition += 1
            let minY = boundingBoxEdges[localPosition]; localPosition += 1
            let maxX = boundingBoxEdges[localPosition]; localPosition += 1
            let maxY = boundingBoxEdges[localPosition]; localPosition += 1
            let x = UInt32(floor(hilbertMax * ((minX + maxX) / 2 - self.minX) / width))
            let y = UInt32(floor(hilbertMax * ((minY + maxY) / 2 - self.minY) / height))
            hilbertValues[i] = RTree.hilbert(x: x, y: y);
        }

        RTree.sort(
            values: &hilbertValues,
            boundingBoxEdges: &boundingBoxEdges,
            indices: &indices,
            leftValue: 0,
            rightValue: numberOfItems - 1,
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
                    nodeMinX = min(nodeMinX, boundingBoxEdges[localPosition]); localPosition += 1
                    nodeMinY = min(nodeMinY, boundingBoxEdges[localPosition]); localPosition += 1
                    nodeMaxX = max(nodeMaxX, boundingBoxEdges[localPosition]); localPosition += 1
                    nodeMaxY = max(nodeMaxY, boundingBoxEdges[localPosition]); localPosition += 1
                }

                // add the new node to the tree data
                indices[self.position >> 2] = nodeIndex
                boundingBoxEdges[self.position] = nodeMinX; self.position += 1
                boundingBoxEdges[self.position] = nodeMinY; self.position += 1
                boundingBoxEdges[self.position] = nodeMaxX; self.position += 1
                boundingBoxEdges[self.position] = nodeMaxY; self.position += 1
            }
        }

    }

    public func search(inBoundingBox boundingBox: BoundingBox) -> [T] {
        assert(position == boundingBoxEdges.count, "Data not yet indexed")

        var result: [T] = []

        guard objects.count > 0 else { return result }

        var nodeIndex: Int? = boundingBoxEdges.count - 4
        var queue: [Int] = []

        let minX = boundingBox.southWest.longitude
        let minY = boundingBox.southWest.latitude
        let maxX = boundingBox.northEast.longitude
        let maxY = boundingBox.northEast.latitude

        while let localNodeIndex = nodeIndex {
            // find the end index of the node
            let end = min(localNodeIndex + nodeSize * 4,
                          RTree.upperBound(of: localNodeIndex, in: levelBounds))

            // search through child nodes
            for localPosition in stride(from: localNodeIndex, to: end, by: 4) {
                let index = indices[localPosition >> 2]

                // check if node bbox intersects with query bbox
                if maxX < boundingBoxEdges[localPosition] { continue } // maxX < nodeMinX
                if maxY < boundingBoxEdges[localPosition + 1] { continue } // maxY < nodeMinY
                if minX > boundingBoxEdges[localPosition + 2] { continue } // minX > nodeMaxX
                if minY > boundingBoxEdges[localPosition + 3] { continue } // minY > nodeMaxY

                if localNodeIndex < numberOfItems * 4 {
                    result.append(objects[index]) // leaf item
                }
                else {
                    queue.append(index) // node; add it to the search queue
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

    // custom quicksort that partially sorts bbox data alongside the hilbert values
    private static func sort(
        values: inout [UInt32],
        boundingBoxEdges: inout [Double],
        indices: inout [Int],
        leftValue: Int,
        rightValue: Int,
        nodeSize: Int)
    {
        if floor(Double(leftValue / nodeSize)) >= floor(Double(rightValue / nodeSize)) {
            return
        }

        let pivot = values[(leftValue + rightValue) >> 1]
        var i = leftValue - 1
        var j = rightValue + 1

        while true {
            repeat {
                i += 1
            } while values[i] < pivot

            repeat {
                j -= 1
            } while values[j] > pivot

            if i >= j { break }

            swap(values: &values,
                 boundingBoxEdges: &boundingBoxEdges,
                 indices: &indices,
                 i: i,
                 j: j)
        }

        sort(values: &values,
             boundingBoxEdges: &boundingBoxEdges,
             indices: &indices,
             leftValue: leftValue,
             rightValue: j,
             nodeSize: nodeSize)
        sort(values: &values,
             boundingBoxEdges: &boundingBoxEdges,
             indices: &indices,
             leftValue: j + 1,
             rightValue: rightValue,
             nodeSize: nodeSize)
    }

    // swap two values and two corresponding boxes
    private static func swap(
        values: inout [UInt32],
        boundingBoxEdges: inout [Double],
        indices: inout [Int],
        i: Int,
        j: Int)
    {
        let temp = values[i]
        values[i] = values[j]
        values[j] = temp

        let k = 4 * i
        let m = 4 * j

        let a = boundingBoxEdges[k]
        let b = boundingBoxEdges[k + 1]
        let c = boundingBoxEdges[k + 2]
        let d = boundingBoxEdges[k + 3]

        boundingBoxEdges[k] = boundingBoxEdges[m]
        boundingBoxEdges[k + 1] = boundingBoxEdges[m + 1]
        boundingBoxEdges[k + 2] = boundingBoxEdges[m + 2]
        boundingBoxEdges[k + 3] = boundingBoxEdges[m + 3]
        boundingBoxEdges[m] = a
        boundingBoxEdges[m + 1] = b
        boundingBoxEdges[m + 2] = c
        boundingBoxEdges[m + 3] = d

        let e = indices[i]
        indices[i] = indices[j]
        indices[j] = e
    }

    // binary search for the first value in the array bigger than the given
    private static func upperBound(
        of value: Int,
        in array: [Int])
        -> Int
    {
        var i = 0
        var j = array.count - 1

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
