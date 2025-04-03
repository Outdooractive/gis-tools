import Foundation

// MARK: Public

extension Int {

    /// Convert millimeters to meters.
    public var millimeters: Double {
        Double(self) / 1000.0
    }

    /// Convert centimeters to meters.
    public var centimeters: Double {
        Double(self) / 100.0
    }

    /// Convert meters to meters (i.e. returns self as Double).
    public var meters: Double {
        Double(self)
    }

    /// Convert kilometers to meters.
    public var kilometers: Double {
        Double(self) * 1000.0
    }

    /// Convert inches to meters.
    public var inches: Double {
        Double(self) / 39.370
    }

    /// Convert feet to meters.
    public var feet: Double {
        Double(self) / 3.28084
    }

    /// Convert yards to meters.
    public var yards: Double {
        Double(self) / 1.0936
    }

    /// Convert miles to meters.
    public var miles: Double {
        Double(self) * 1609.344
    }

    /// Convert nautical miles to meters.
    public var nauticalMiles: Double {
        Double(self) * 1852.0
    }

}
