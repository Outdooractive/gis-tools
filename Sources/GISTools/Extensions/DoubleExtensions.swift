import Foundation

// MARK: Public

extension Double {

    /// Converts an angle in degrees to radians.
    ///
    /// - Returns: The angle in radians.
    public var degreesToRadians: Self {
        self.remainder(dividingBy: 360.0) * .pi / 180.0
    }

    /// Converts an angle in radians to degrees.
    ///
    /// - Returns: The radians in degrees, between 0 and 360 degrees.
    public var radiansToDegrees: Self {
        self.remainder(dividingBy: 2.0 * .pi) * 180.0 / .pi
    }

}

extension Double {

    /// Convert a distance measurement (assuming a spherical Earth) from a real-world unit into radians.
    /// Valid units: miles, nauticalmiles, inches, yards, meters, metres, kilometers, centimeters, feet.
    ///
    /// - Parameter unit: Can be degrees, radians, miles, or kilometers inches, yards, metres, meters, kilometres, kilometers (default *meters*)
    ///
    /// - Returns: The distance in radians.
    public func lengthToRadians(unit: GISTool.Unit = .meters) -> Double? {
        guard let factor = GISTool.factor(for: unit) else { return nil }
        return self / factor
    }

    /// Convert a distance measurement (assuming a spherical Earth) from radians
    /// to a more friendly unit.
    /// Valid units: miles, nauticalmiles, inches, yards, meters, metres, kilometers, centimeters, feet.
    ///
    /// - Parameter unit: Can be degrees, radians, miles, or kilometers inches, yards, metres, meters, kilometres, kilometers (default *meters*)
    ///
    /// - Returns: The distance.
    public func radiansToLength(unit: GISTool.Unit = .meters) -> Double? {
        guard let factor = GISTool.factor(for: unit) else { return nil }
        return self * factor
    }

    /// Convert a distance measurement (assuming a spherical Earth) from a real-world unit into degrees.
    /// Valid units: miles, nauticalmiles, inches, yards, meters, metres, centimeters, kilometres, feet.
    ///
    /// - Parameter unit: Can be degrees, radians, miles, or kilometers inches, yards, metres, meters, kilometres, kilometers (default *meters*)
    ///
    /// - Returns: The distance in degrees.
    public func lengthToDegrees(unit: GISTool.Unit = .meters) -> Double? {
        lengthToRadians(unit: unit)?.radiansToDegrees
    }

}

#if EnableMeasurementConversionExtensions

extension Double {

    /// The value as a measurement in millimeters.
    public var millimeters: Measurement<UnitLength> {
        Measurement(value: self, unit: .millimeters)
    }

    /// The value as a measurement in centimeters.
    public var centimeters: Measurement<UnitLength> {
        Measurement(value: self, unit: .centimeters)
    }

    /// The value as a measurement in meters.
    public var meters: Measurement<UnitLength> {
        Measurement(value: self, unit: .meters)
    }

    /// The value as a measurement in kilometers.
    public var kilometers: Measurement<UnitLength> {
        Measurement(value: self, unit: .kilometers)
    }

    /// The value as a measurement in inches.
    public var inches: Measurement<UnitLength> {
        Measurement(value: self, unit: .inches)
    }

    /// The value as a measurement in feet.
    public var feet: Measurement<UnitLength> {
        Measurement(value: self, unit: .feet)
    }

    /// The value as a measurement in yards.
    public var yards: Measurement<UnitLength> {
        Measurement(value: self, unit: .yards)
    }

    /// The value as a measurement in miles.
    public var miles: Measurement<UnitLength> {
        Measurement(value: self, unit: .miles)
    }

    /// The value as a measurement in nautical miles.
    public var nauticalMiles: Measurement<UnitLength> {
        Measurement(value: self, unit: .nauticalMiles)
    }

    /// The value as a measurement in megameters.
    public var megameters: Measurement<UnitLength> {
        Measurement(value: self, unit: .megameters)
    }

    /// The value as a measurement in hectometers.
    public var hectometers: Measurement<UnitLength> {
        Measurement(value: self, unit: .hectometers)
    }

    /// The value as a measurement in decameters.
    public var decameters: Measurement<UnitLength> {
        Measurement(value: self, unit: .decameters)
    }

    /// The value as a measurement in decimeters.
    public var decimeters: Measurement<UnitLength> {
        Measurement(value: self, unit: .decimeters)
    }

    /// The value as a measurement in scandinavian miles.
    public var scandinavianMiles: Measurement<UnitLength> {
        Measurement(value: self, unit: .scandinavianMiles)
    }

}

#endif

#if EnableMeterConversionExtensions

extension Double {

    /// Convert millimeters to meters.
    public var millimeters: Double {
        self / 1000.0
    }

    /// Convert centimeters to meters.
    public var centimeters: Double {
        self / 100.0
    }

    /// Convert meters to meters (i.e. returns self).
    public var meters: Double {
        self
    }

    /// Convert kilometers to meters.
    public var kilometers: Double {
        self * 1000.0
    }

    /// Convert inches to meters.
    public var inches: Double {
        self / 39.370
    }

    /// Convert feet to meters.
    public var feet: Double {
        self / 3.28084
    }

    /// Convert yards to meters.
    public var yards: Double {
        self / 1.0936
    }

    /// Convert miles to meters.
    public var miles: Double {
        self * 1609.344
    }

    /// Convert nautical miles to meters.
    public var nauticalMiles: Double {
        self * 1852.0
    }

    /// Convert megameters to meters.
    public var megameters: Double {
        self * 1_000_000.0
    }

    /// Convert hectometers to meters.
    public var hectometers: Double {
        self * 100.0
    }

    /// Convert decameters to meters.
    public var decameters: Double {
        self * 10.0
    }

    /// Convert decimeters to meters.
    public var decimeters: Double {
        self / 10.0
    }

    /// Convert scandinavian miles to meters.
    public var scandinavianMiles: Double {
        self * 10_000.0
    }

}

#endif

// MARK: - Private

extension Double {

    /// Rounds a number to a precision
    func rounded(precision: Int) -> Double {
        guard precision >= 0 else { return self }

        let multiplier: Double = pow(Double(10), Double(precision))
        return (self * multiplier).rounded() / multiplier
    }

    /// Rounds a number to a precision
    mutating func round(precision: Int) {
        self = rounded(precision: precision)
    }

    /// Converts the value to an ``Int``, truncating any fractional part.
    var toInt: Int {
        Int(self)
    }

}
