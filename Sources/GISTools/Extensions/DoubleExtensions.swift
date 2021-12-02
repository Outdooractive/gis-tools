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

}
