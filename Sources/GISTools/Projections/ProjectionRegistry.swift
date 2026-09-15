import Foundation
import Synchronization

/// Registry providing ``ProjectionDefinition`` implementations for
/// registered projections.
///
/// The registry is **add-only**: the built-in projections are seeded once
/// and custom definitions can be added through ``Projection/register(_:)`` —
/// nothing can be removed or replaced afterwards. Lookups take a consistent
/// snapshot; the internal `Mutex` makes a completed registration visible to
/// all subsequent readers.
enum ProjectionRegistry {

    // MARK: - Definitions

    private static let noSridDefinition = NoSridDefinition()
    private static let epsg3857Definition = Epsg3857Definition()
    private static let epsg4326Definition = Epsg4326Definition()
    private static let epsg4978Definition = Epsg4978Definition()
    private static let epsg3395Definition = Epsg3395Definition()
    private static let epsg32662Definition = Epsg32662Definition()
    private static let nad27Definition = Nad27Definition()
    private static let etrs89Definition = Etrs89Definition()
    private static let osgb1936Definition = Osgb1936Definition()
    private static let osgb1936BngDefinition = Osgb1936BngDefinition()

    /// All built-in definitions: the 6 base definitions and all UTM zones,
    /// keyed by canonical SRID.
    ///
    /// `UtmTests` sweeps every UTM SRID and asserts that lookups resolve to
    /// definitions whose ``ProjectionDefinition/projection`` matches.
    private static let builtinDefinitions: [Int: any ProjectionDefinition] = {
        var map: [Int: any ProjectionDefinition] = [
            0: noSridDefinition,
            3857: epsg3857Definition,
            4326: epsg4326Definition,
            4978: epsg4978Definition,
            3395: epsg3395Definition,
            32_662: epsg32662Definition,
            4258: etrs89Definition,
            4267: nad27Definition,
            4277: osgb1936Definition,
            27700: osgb1936BngDefinition,
        ]

        for srid in 32_601 ... 32_660 {
            map[srid] = UtmDefinition.definition(forSrid: srid)
        }
        for srid in 32_701 ... 32_760 {
            map[srid] = UtmDefinition.definition(forSrid: srid)
        }

        return map
    }()

    /// The mutable registry state guarded by the mutex.
    private struct State {
        /// Definitions keyed by canonical SRID.
        var definitions: [Int: any ProjectionDefinition]

        /// WKT probes in match order: the ordered built-in list first
        /// (specific patterns before generic ones), custom registrations
        /// last.
        var wktDefinitions: [any ProjectionDefinition]
    }

    private static let builtinWktDefinitions: [any ProjectionDefinition] = [
        epsg3857Definition,
        osgb1936BngDefinition,
        epsg3395Definition,
        epsg32662Definition,
        etrs89Definition,
        nad27Definition,
        osgb1936Definition,
        epsg4978Definition,
        epsg4326Definition,
    ]

    private static let state = State(
        definitions: builtinDefinitions,
        wktDefinitions: builtinWktDefinitions)

    private static let stateMutex = Mutex<State>(state)

    // MARK: - Lookup

    /// The registered definition for a canonical SRID.
    ///
    /// - Parameter srid: A canonical SRID (aliases are resolved by ``Projection``)
    /// - Returns: The definition, or `nil` if the SRID is not registered
    static func definition(forSrid srid: Int) -> (any ProjectionDefinition)? {
        stateMutex.withLock { snapshot in
            snapshot.definitions[srid]
        }
    }

    /// Whether a canonical SRID has a registered definition.
    static func isRegisteredSrid(_ srid: Int) -> Bool {
        stateMutex.withLock { snapshot in
            snapshot.definitions[srid] != nil
        }
    }

    /// The first definition with a WKT alternative fully contained in the string.
    ///
    /// - Parameter wkt: A WKT projection string
    /// - Returns: The matching definition, or `nil` if the string is not recognised
    static func definition(matchingWkt wkt: String) -> (any ProjectionDefinition)? {
        stateMutex.withLock { snapshot in
            snapshot.wktDefinitions.first { definition in
                definition.wktMatchers.contains { alternative in
                    alternative.allSatisfy { wkt.contains($0) }
                }
            }
        }
    }

    // MARK: - Registration

    /// Registers a custom definition. Add-only: entries are never removed
    /// or replaced.
    ///
    /// Rejected when the SRID is `<= 0` or already registered; the state
    /// stays unchanged in that case.
    ///
    /// - Parameter definition: The custom projection to register
    /// - Returns: `true` when the registration succeeded
    static func register(_ definition: CustomProjection) -> Bool {
        guard definition.srid > 0 else { return false }

        return stateMutex.withLock { state in
            guard state.definitions[definition.srid] == nil else { return false }

            let registered = RegisteredCustomDefinition(custom: definition)
            var definitions = state.definitions
            definitions[definition.srid] = registered

            var wktDefinitions = state.wktDefinitions
            if definition.wktMatchers.isNotEmpty {
                wktDefinitions.append(registered)
            }

            state = State(definitions: definitions, wktDefinitions: wktDefinitions)
            return true
        }
    }

}
