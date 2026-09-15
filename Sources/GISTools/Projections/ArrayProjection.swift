#if canImport(CoreLocation)
import CoreLocation
#endif
import Foundation

// MARK: - Batch prepared transforms

/// Per-batch hoisted conversion functions: conversion *setup* (rotation
/// matrices, origin constants, projection parameterization) is done once,
/// the closures are the per-coordinate inner loop. Math is identical to
/// the single-coordinate path. The closures use only captured immutable
/// values, hence the `@Sendable` annotations.
struct BatchPreparedTransforms: Sendable {

    let forward: @Sendable (Coordinate3D) -> Coordinate3D
    let inverse: @Sendable (Coordinate3D) -> Coordinate3D

}

extension ProjectionDefinition {

    /// Hoisted conversion functions for batch use.
    ///
    /// Default recomputes all setup per coordinate (identical math to
    /// ``forward(_:)``/``inverse(_:)``); definitions that benefit from
    /// constant hoisting override it.
    var prepared: BatchPreparedTransforms {
        BatchPreparedTransforms(forward: forward, inverse: inverse)
    }

}

// MARK: - Batch conversion

extension Array where Element == Coordinate3D {

    /// Converts every coordinate in the batch into `target`.
    ///
    /// The conversion setup (projection origin constants, rotation
    /// matrices, TM parameterization) is built once per batch instead of
    /// per coordinate, so large batches amortize the setup cost.
    ///
    /// All coordinates must share their projection (the library applies
    /// this invariant throughout); mixing projections in one batch is a
    /// programming error and asserts. Coordinates without an SRID are
    /// copied verbatim. Projections are value-copied: the receiver is
    /// unchanged.
    ///
    /// - Parameter target: The target projection
    /// - Returns: A new array of coordinates in the target projection
    public func projected(to target: Projection) -> [Coordinate3D] {
        guard let first else { return [] }
        if isNotEmpty {
            assert(
                allSatisfy { $0.projection == first.projection },
                "Batch projection: all coordinates must share the same projection")
        }

        let source = first.projection

        // Same projection: verbatim copy, no transformation ever runs.
        if source == target {
            return self
        }

        // Coordinates without an SRID are copied verbatim into any target
        // (see Coordinate3D.projected(to:) for the contract).
        if source == .noSRID || target == .noSRID {
            return map { Coordinate3D(
                x: $0.longitude,
                y: $0.latitude,
                z: $0.altitude,
                m: $0.m,
                projection: target) }
        }

        if source == .epsg4326 {
            let prepared = target.definition.prepared
            return map { prepared.forward($0) }
        }
        if target == .epsg4326 {
            let prepared = source.definition.prepared
            return map { prepared.inverse($0) }
        }

        // Any non-WGS84 projection pair routes through the EPSG:4326 pivot.
        let sourceSet = source.definition.prepared
        let targetSet = target.definition.prepared
        return map { targetSet.forward(sourceSet.inverse($0)) }
    }

    /// In-place variant of ``projected(to:)``: mutates the array's
    /// coordinates in place, keeping the value-semantics contract of
    /// `Coordinates` (mutating the variable, not the caller's array).
    ///
    /// - Parameter target: The target projection
    ///
    /// The conversion setup is pooled the same way as in ``projected(to:)``.
    public mutating func project(to target: Projection) {
        self = projected(to: target)
    }

}
