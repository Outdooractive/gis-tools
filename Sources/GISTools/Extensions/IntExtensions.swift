import Foundation

// MARK: Public

extension Int {

    /// Convert millimeters to meters.
    @available(*, deprecated, message: "Use GISTool.length(_:unit:) instead")
    public var millimeters: Double {
        Double(self) / 1000.0
    }

    /// Convert centimeters to meters.
    @available(*, deprecated, message: "Use GISTool.length(_:unit:) instead")
    public var centimeters: Double {
        Double(self) / 100.0
    }

    /// Convert meters to meters (i.e. returns self as Double).
    @available(*, deprecated, message: "Use GISTool.length(_:unit:) instead")
    public var meters: Double {
        Double(self)
    }

    /// Convert kilometers to meters.
    @available(*, deprecated, message: "Use GISTool.length(_:unit:) instead")
    public var kilometers: Double {
        Double(self) * 1000.0
    }

    /// Convert inches to meters.
    @available(*, deprecated, message: "Use GISTool.length(_:unit:) instead")
    public var inches: Double {
        Double(self) / 39.370
    }

    /// Convert feet to meters.
    @available(*, deprecated, message: "Use GISTool.length(_:unit:) instead")
    public var feet: Double {
        Double(self) / 3.28084
    }

    /// Convert yards to meters.
    @available(*, deprecated, message: "Use GISTool.length(_:unit:) instead")
    public var yards: Double {
        Double(self) / 1.0936
    }

    /// Convert miles to meters.
    @available(*, deprecated, message: "Use GISTool.length(_:unit:) instead")
    public var miles: Double {
        Double(self) * 1609.344
    }

    /// Convert nautical miles to meters.
    @available(*, deprecated, message: "Use GISTool.length(_:unit:) instead")
    public var nauticalMiles: Double {
        Double(self) * 1852.0
    }

}
