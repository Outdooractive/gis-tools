import Foundation

// MARK: Public

extension String {

    public func asGeoJsonGeometry(srid: Int?) -> GeoJsonGeometry? {
        GeometryCollection.parse(wkt: self, srid: srid)
    }

    public func asGeoJsonGeometry(projection: Projection) -> GeoJsonGeometry? {
        GeometryCollection.parse(wkt: self, projection: projection)
    }

    public func asFeature(
        srid: Int?,
        properties: [String: Any] = [:])
        -> Feature?
    {
        Feature(wkt: self, srid: srid, properties: properties)
    }

    public func asFeature(
        projection: Projection,
        properties: [String: Any] = [:])
        -> Feature?
    {
        Feature(wkt: self, projection: projection, properties: properties)
    }

    public func asFeatureCollection(srid: Int?) -> FeatureCollection? {
        FeatureCollection(wkt: self, srid: srid)
    }

    public func asFeatureCollection(projection: Projection) -> FeatureCollection? {
        FeatureCollection(wkt: self, projection: projection)
    }

}

// MARK: Private

extension String {

    /// Tries to convert a String to an Int
    ///
    /// Allowes code like `optionalString?.toInt()`
    var toInt: Int? {
        return Int(self)
    }

    /// Tries to convert a String to a Double
    ///
    /// Allowes code like `optionalString?.toDouble()`
    var toDouble: Double? {
        return Double(self)
    }

    /// Trims white space and new line characters
    mutating func trim() {
        self = self.trimmed()
    }

    /// Trims white space and new line characters, returns a new string
    func trimmed() -> String {
        return self.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// The string, or nil if it is empty
    var nilIfEmpty: String? {
        guard !isEmpty else { return nil }
        return self
    }

}
