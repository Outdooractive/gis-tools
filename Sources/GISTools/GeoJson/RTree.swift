#if !os(Linux)
import CoreLocation
#endif
import Foundation

// One big TODO :-)

public struct RTree<T: BoundingBoxRepresentable> {

    private let objects: [T]

    public init(_ objects: [T]) {
        self.objects = objects.map({ object in
            var object = object
            object.updateBoundingBox(onlyIfNecessary: true)
            return object
        })
    }

    public func search(inBoundingBox boundingBox: BoundingBox) -> [T] {
        var result: [T] = []

        for object in objects {
            if object.intersects(boundingBox) {
                result.append(object)
            }
        }

        return result
    }

}
