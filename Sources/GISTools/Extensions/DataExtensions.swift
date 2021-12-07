import Foundation

// MARK: Public

extension Data {

    public func asGeoJsonGeometry(srid: Int?) -> GeoJsonGeometry? {
        GeometryCollection.parse(wkb: self, srid: srid)
    }

    public func asGeoJsonGeometry(projection: Projection) -> GeoJsonGeometry? {
        GeometryCollection.parse(wkb: self, projection: projection)
    }

    public func asFeature(
        srid: Int?,
        properties: [String: Any] = [:])
        -> Feature?
    {
        Feature(wkb: self, srid: srid, properties: properties)
    }

    public func asFeature(
        projection: Projection,
        properties: [String: Any] = [:])
        -> Feature?
    {
        Feature(wkb: self, projection: projection, properties: properties)
    }

    public func asFeatureCollection(srid: Int?) -> FeatureCollection? {
        FeatureCollection(wkb: self, srid: srid)
    }

    public func asFeatureCollection(projection: Projection) -> FeatureCollection? {
        FeatureCollection(wkb: self, projection: projection)
    }

}

// MARK: Private

extension Data {

    /// Parses data from a hex string
    init?(hex: String) {
        guard hex.count > 0, hex.count.isMultiple(of: 2) else { return nil }

        let chars = hex.map { $0 }
        let bytes = stride(from: 0, to: chars.count, by: 2)
            .map { String(chars[$0]) + String(chars[$0 + 1]) }
            .compactMap { UInt8($0, radix: 16) }

        guard hex.count / bytes.count == 2 else { return nil }
        self.init(bytes)
    }

    /// The data, or nil if it is empty
    var nilIfEmpty: Data? {
        guard !isEmpty else { return nil }
        return self
    }

}
