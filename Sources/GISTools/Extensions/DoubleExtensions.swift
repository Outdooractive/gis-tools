import Foundation

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
