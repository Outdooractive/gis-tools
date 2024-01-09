
/// Objects supporting ``Projection``s..
public protocol Projectable {

    /// The receiver's projection, which should typically be EPSG:4326.
    var projection: Projection { get }

    /// Reproject the receiver.
    func projected(to newProjection: Projection) -> Self

}

extension Projectable {

    /// Reproject this coordinate.
    public mutating func project(to newProjection: Projection) {
        guard newProjection != projection else { return }

        self = projected(to: newProjection)
    }

}
