import Foundation

/// Element-wise JSON coercion helpers.
///
/// GeoJSON parsing historically relied on whole-dictionary conditional casts
/// such as `json as? [String: Sendable]` on values produced by
/// `Foundation.JSONSerialization`. On Darwin, that cast funnels into the
/// standard library's `_dictionaryUpCast`, which trips an internal assertion
/// (an uncatchable trap) for certain bridged layouts — inhomogeneous nested
/// values, `NSNumber`-backed numbers, booleans — *before* the `as?` can
/// return `nil`.
///
/// These helpers never whole-cast a dictionary. Bridged dictionaries are
/// iterated element by element; every value is checked individually so a bad
/// element degrades gracefully instead of trapping the process.
///
/// - note: Array elements are coerced **individually**, keeping each element's
///   runtime representation (numbers stay `NSNumber`). Rebuilding arrays as
///   opaque boxes would break downstream concrete typed casts (`as? [Double?]`,
///   `as? [Any]`, `as? [[Any]]`) used by ``Coordinate3D`` and the geometry
///   parsers — those casts succeed because they cast elements one by one.
enum JsonCoercion {

    /// Coerce a JSON object into `[String: Sendable]` without whole-dictionary casts.
    ///
    /// - Parameter value: A JSON object (`NSDictionary`, native dictionary, or `nil`)
    /// - Returns: A dictionary whose values are JSON-compatible, or `nil` if
    ///            the input is not a JSON object or contains a non-string key
    static func dictionary(_ value: Any?) -> [String: Sendable]? {
        guard let value else { return nil }

        // Bridged dictionaries (JSONSerialization output on Darwin): iterate
        // element-wise. A whole-dictionary upcast can trap inside the standard
        // library for inhomogeneous content.
        if let nsDictionary = value as? NSDictionary {
            return dictionary(from: nsDictionary)
        }

        // Native Swift dictionaries are coerced element-wise as well, so that
        // nested values get the same treatment on every platform.
        if let nativeDictionary = value as? [String: Any] {
            var result: [String: Sendable] = [:]
            result.reserveCapacity(nativeDictionary.count)

            for (key, element) in nativeDictionary {
                guard let coerced = sendable(element) else { return nil }
                result[key] = coerced
            }

            return result
        }

        return nil
    }

    /// Element-wise coercion of a bridged dictionary.
    private static func dictionary(from nsDictionary: NSDictionary) -> [String: Sendable]? {
        var result: [String: Sendable] = [:]
        result.reserveCapacity(nsDictionary.count)

        for (key, element) in nsDictionary {
            guard let key = key as? String else { return nil }
            guard let coerced = sendable(element) else { return nil }
            result[key] = coerced
        }

        return result
    }

    /// Coerce a JSON array into `[Any]` without whole-array casts that could
    /// trap on unexpected element layouts.
    ///
    /// - Parameter value: A JSON array (`NSArray`, native array, or `nil`)
    /// - Returns: The elements as `[Any]`, or `nil` if the input is not an array
    static func array(_ value: Any?) -> [Any]? {
        guard let value else { return nil }

        if let nsArray = value as? NSArray {
            return nsArray.map { $0 }
        }

        if let nativeArray = value as? [Any] {
            return nativeArray
        }

        return nil
    }

    /// Coerce a GeoJSON position array into `[Double?]`.
    ///
    /// Element-wise: a `null` (altitude/`m` placeholder) maps to `nil`, numbers
    /// (bridged `NSNumber` or native) map to `Double`, and anything else makes
    /// the whole array invalid — mirroring the semantics of the previous
    /// `as? [Double?]` cast without relying on bridging internals.
    ///
    /// - Parameter value: A JSON array of numbers (and `null` placeholders)
    /// - Returns: The coordinate values, or `nil` if the input is not an all-number array
    static func coordinateArray(_ value: Any?) -> [Double?]? {
        guard let elements = array(value) else { return nil }

        var result: [Double?] = []
        result.reserveCapacity(elements.count)

        for element in elements {
            if element is NSNull {
                result.append(nil)
            }
            else if let double = double(element) {
                result.append(double)
            }
            else {
                return nil
            }
        }

        return result
    }

    /// Numeric value of a JSON number, tolerating both bridged `NSNumber` and
    /// native Swift numeric types (including `Float`).
    ///
    /// - Parameter value: A JSON value
    /// - Returns: The value as `Double`, or `nil` if the value is not a number
    static func double(_ value: Any?) -> Double? {
        guard let value else { return nil }

        if let number = value as? NSNumber {
            // Reject booleans: they are `NSNumber`-backed (`__NSCFBoolean` on
            // Darwin, and bridged native `Bool`). Note that `value is Bool`
            // is *not* usable as a discriminator on Linux corelibs, where
            // plain numbers like `1.0` also answer `true`; `objCType == "c"`
            // is the reliable boolean marker on both platforms. (An `Int8`
            // would also report `"c"`, but JSON has no `Int8` numbers.)
            if String(cString: number.objCType) == "c" {
                return nil
            }
            return number.doubleValue
        }
        if let double = value as? Double {
            return double
        }
        if let float = value as? Float {
            return Double(float)
        }
        return nil
    }

    /// Coerce a JSON array of numbers into `[Double]`.
    ///
    /// - Parameter value: A JSON array of numbers
    /// - Returns: The values as `[Double]`, or `nil` if any element is not a number
    static func doubleArray(_ value: Any?) -> [Double]? {
        guard let elements = array(value) else { return nil }

        var result: [Double] = []
        result.reserveCapacity(elements.count)

        for element in elements {
            guard let double = double(element) else { return nil }
            result.append(double)
        }

        return result
    }

    /// Coerce an array of JSON number arrays into `[[Double]]`.
    ///
    /// - Parameter value: An array of JSON number arrays
    /// - Returns: The values as `[[Double]]`, or `nil` if the input shape doesn't match
    static func coordinateArrayList(_ value: Any?) -> [[Double]]? {
        guard let elements = array(value) else { return nil }

        var result: [[Double]] = []
        result.reserveCapacity(elements.count)

        for element in elements {
            guard let inner = doubleArray(element) else { return nil }
            result.append(inner)
        }

        return result
    }

    /// Coerce a single JSON value into a `Sendable` box.
    ///
    /// - Parameter value: A JSON value
    /// - Returns: The value unchanged (numbers, booleans and strings keep their
    ///            original runtime representation), a recursively coerced
    ///            dictionary, or `nil` if the value is not JSON-compatible
    private static func sendable(_ value: Any) -> Sendable? {
        // Dictionaries: recurse element-wise. This is where the trapping
        // upcast lives, so nested dictionaries must never be whole-cast.
        if let nsDictionary = value as? NSDictionary {
            return dictionary(from: nsDictionary)
        }
        if let nativeDictionary = value as? [String: Any] {
            return dictionary(nativeDictionary)
        }

        // Strings (including toll-free bridged `NSString`).
        if let string = value as? String {
            return string
        }

        // Numbers and booleans produced by `JSONSerialization` on Darwin are
        // `NSNumber` (booleans are `__NSCFBoolean`, an `NSNumber` subclass).
        // They must stay `NSNumber`: converting them to native `Int`/`Double`
        // would break integer-valued coordinate arrays (`as? [Double?]`) and
        // change `as? Double`/`as? Int` read semantics downstream.
        if let number = value as? NSNumber {
            return number
        }

        // Native Swift scalars (values not bridged from ObjC).
        if let bool = value as? Bool {
            return bool
        }
        if let int = value as? Int {
            return int
        }
        if let uint = value as? UInt {
            return uint
        }
        if let int64 = value as? Int64 {
            return int64
        }
        if let uint64 = value as? UInt64 {
            return uint64
        }
        if let double = value as? Double {
            return double
        }
        if let float = value as? Float {
            return float
        }

        if value is NSNull {
            return NSNull()
        }

        // Arrays: coerce element-wise, preserving each element's runtime
        // representation (numbers stay `NSNumber`). The boxed `[Sendable]`
        // array still satisfies all downstream dynamic reads
        // (`as? [Double?]`, `as? [Any]`, `as? [[Any]]`, …) because those
        // perform element-wise casts. The raw `NSArray` cannot be stored
        // directly: its `Sendable` conformance is unavailable in Swift 6 mode
        // on Darwin.
        if let array = value as? [Any] {
            return sendableArray(from: array)
        }
        if let array = value as? NSArray {
            return sendableArray(from: array.map { $0 })
        }

        // Tolerate common non-JSON but hashable value types (e.g. `Data`) the
        // same way the previous whole-dictionary cast did: keep them, wrapped.
        if let data = value as? Data {
            return data
        }

        return nil
    }

    /// Element-wise coercion of an array's elements into a `[Sendable]` box.
    ///
    /// - Parameter elements: The array elements
    /// - Returns: The coerced array, or `nil` if any element is not JSON-compatible
    private static func sendableArray(from elements: [Any]) -> [Sendable]? {
        var result: [Sendable] = []
        result.reserveCapacity(elements.count)

        for element in elements {
            guard let coerced = sendable(element) else { return nil }
            result.append(coerced)
        }

        return result
    }

}