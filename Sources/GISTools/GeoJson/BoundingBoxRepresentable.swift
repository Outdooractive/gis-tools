import Foundation

/// GeoJSON objects that may have a bounding box.
public protocol BoundingBoxRepresentable {

    /// The GeoJSON's projection.
    var projection: Projection { get }

    /// The receiver's bounding box.
    var boundingBox: BoundingBox? { get set }

    /// Calculates and returns the receiver's bounding box.
    func calculateBoundingBox() -> BoundingBox?

    /// Calculates the receiver's bounding box and updates the ``boundingBox`` property.
    ///
    /// - parameter ifNecessary: Only update the bounding box if the receiver doesn't already have one.
    @discardableResult
    mutating func updateBoundingBox(onlyIfNecessary ifNecessary: Bool) -> BoundingBox?

    /// Check if the receiver is inside or crosses  the other bounding box.
    ///
    /// - parameter otherBoundingBox: The bounding box to check.
    func intersects(_ otherBoundingBox: BoundingBox) -> Bool

}

// MARK: -

extension BoundingBoxRepresentable {

    @discardableResult
    public mutating func updateBoundingBox(onlyIfNecessary ifNecessary: Bool = true) -> BoundingBox? {
        if boundingBox != nil && ifNecessary { return boundingBox }
        boundingBox = calculateBoundingBox()
        return boundingBox
    }

}
