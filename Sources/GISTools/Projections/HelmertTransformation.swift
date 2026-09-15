#if canImport(CoreLocation)
import CoreLocation
#endif
import Foundation

/// A Helmert datum transformation (translation + rotation + scale).
///
/// Coordinates are transformed between a geodetic datum and WGS84. The
/// parameters follow the **position vector convention** and are listed in
/// the direction *datum → WGS84* (the direction the EPSG registry uses).
/// Both directions are supported:
/// ``transform(datumToWgs84:)`` and ``transform(wgs84ToDatum:)``.
///
/// The transformation operates on geocentric (ECEF) coordinates, so the
/// datum's ``Datum/ellipsoid`` must be correct: the geocentric legs use it.
///
/// - Note: Well-known transformations for NAD27 and OSGB 1936 are provided
///   (``nad27``/``osgb1936``), sourced from the EPSG registry. Sub-meter
///   datum accuracy requires grid shift files (NADCON/OSTN15), which the
///   library does not incorporate (see the grid shift support issue).
///
/// ## Example
///
/// ```swift
/// let helmert = HelmertTransformation.osgb1936
/// let coordinate = Coordinate3D(latitude: 51.4778, longitude: -0.0015, altitude: 46.0)
/// let osgb = helmert.transform(wgs84ToDatum: coordinate)  // OSGB36 lat/lon
/// ```
public struct HelmertTransformation:
    Sendable,
    CustomStringConvertible
{

    // MARK: - Well-known transformations

    /// **NAD27 to WGS 84 (4)** ("NAD27 to WGS 84 (4)" in the EPSG registry,
    /// stated accuracy approximately 10 m): a translation-only
    /// transformation.
    ///
    /// Sub-meter or centimeter-level accuracy for NAD27 requires NADCON
    /// grid shifts, which the library does not provide (see the grid shift
    /// support issue).
    public static let nad27 = HelmertTransformation(
        datum: .nad27,
        dx: -8.0,
        dy: 160.0,
        dz: 176.0)

    /// **OSGB 1936 to WGS 84 (6)** (EPSG:1314, the OS-documented
    /// approximate Helmert transformation, stated accuracy approximately
    /// 2 m; the OS-recommended route for sub-meter accuracy is the OSTN15
    /// grid, which the library does not incorporate: see the grid shift
    /// support issue).
    public static let osgb1936 = HelmertTransformation(
        datum: .osgb1936,
        dx: 446.448,
        dy: -125.157,
        dz: 542.06,
        rx: 0.15,
        ry: 0.247,
        rz: 0.842,
        scalePpm: -20.489)

    // MARK: - Parameters

    /// The datum frame the transformation maps *from* (its geodetic
    /// coordinates feed the geocentric leg).
    public let datum: Datum

    /// Translation along the x/y/z axes, in meters (datum → WGS84).
    public let dx: Double
    /// Translation along the y axis, in meters (datum → WGS84).
    public let dy: Double
    /// Translation along the z axis, in meters (datum → WGS84).
    public let dz: Double

    /// Rotation about the x axis, in arc seconds (datum → WGS84,
    /// position vector convention).
    public let rx: Double
    /// Rotation about the y axis, in arc seconds.
    public let ry: Double
    /// Rotation about the z axis, in arc seconds.
    public let rz: Double

    /// Scale difference, in parts per million (datum → WGS84).
    public let scalePpm: Double

    /// A textual description of the receiver.
    public var description: String {
        "HelmertTransformation <- \(datum.name) (dx: \(dx), dy: \(dy), dz: \(dz), rx: \(rx), ry: \(ry), rz: \(rz), s: \(scalePpm))"
    }

    // MARK: - Initialization

    /// Creates a Helmert transformation *from* a datum frame *towards*
    /// WGS84 (position vector convention).
    ///
    /// - Parameters:
    ///     - datum: The datum the transformation maps *from*
    ///     - dx: Translation along the x axis, in meters
    ///     - dy: Translation along the y axis, in meters
    ///     - dz: Translation along the z axis, in meters
    ///     - rx: Rotation about the x axis, in arc seconds
    ///     - ry: Rotation about the y axis, in arc seconds
    ///     - rz: Rotation about the z axis, in arc seconds
    ///     - scalePpm: Scale difference, in parts per million
    public init(
        datum: Datum,
        dx: Double,
        dy: Double,
        dz: Double,
        rx: Double = 0.0,
        ry: Double = 0.0,
        rz: Double = 0.0,
        scalePpm: Double = 0.0
    ) {
        self.dx = dx
        self.dy = dy
        self.dz = dz
        self.rx = rx
        self.ry = ry
        self.rz = rz
        self.scalePpm = scalePpm
        self.datum = datum
    }

    // MARK: - Transformation

    /// Transforms WGS84 coordinates into the datum's geographic coordinate
    /// system.
    ///
    /// - Parameters:
    ///     - coordinate: A coordinate in EPSG:4326
    ///     - projection: The projection label carried by the result.
    ///       Geographic CRSs of the datum pass their own SRID here to keep
    ///       the label correct (e.g. EPSG:4267). Defaults to EPSG:4326,
    ///       marking the values as "geodetic but without a datum-specific
    ///       SRID".
    /// - Returns: A coordinate in the datum's frame (`latitude`/
    ///   `longitude` in degrees)
    public func transform(
        wgs84ToDatum coordinate: Coordinate3D,
        projection: Projection? = nil
    ) -> Coordinate3D {
        Self.transform(
            coordinate,
            sourceEllipsoid: Datum.wgs84.ellipsoid,
            targetEllipsoid: datum.ellipsoid,
            rotationIsForward: false,
            helmert: self,
            targetProjection: projection ?? .epsg4326)
    }

    /// Transforms datum-frame coordinates into WGS84.
    ///
    /// - Parameter coordinate: A coordinate in the datum's frame
    /// - Returns: A coordinate in EPSG:4326
    public func transform(datumToWgs84 coordinate: Coordinate3D) -> Coordinate3D {
        Self.transform(
            coordinate,
            sourceEllipsoid: datum.ellipsoid,
            targetEllipsoid: Datum.wgs84.ellipsoid,
            rotationIsForward: true,
            helmert: self,
            targetProjection: .epsg4326)
    }

    // MARK: - Batch

    /// Batch entry point: applies an already-prepared step to a single
    /// coordinate (the matrix construction is hoisted by the caller).
    func transform(
        wgs84ToDatum coordinate: Coordinate3D,
        step: PreparedStep,
        targetProjection: Projection? = nil
    ) -> Coordinate3D {
        Self.transform(coordinate, step: step, targetProjection: targetProjection ?? .epsg4326)
    }

    /// Batch entry point for the datum → WGS84 direction.
    func transform(
        datumToWgs84 coordinate: Coordinate3D,
        step: PreparedStep,
        targetProjection: Projection? = nil
    ) -> Coordinate3D {
        Self.transform(coordinate, step: step, targetProjection: targetProjection ?? .epsg4326)
    }

    // MARK: - Shared implementation

    /// One hoisted Helmert application step: the full transformation
    /// decision tree (matrix entries, scale, direction, ellipsoids) is
    /// computed once for batch use.
    struct PreparedStep: Sendable {

        let dx: Double
        let dy: Double
        let dz: Double
        let scale: Double
        let transposed: Bool
        let rxx: Double
        let rxy: Double
        let rxz: Double
        let ryx: Double
        let ryy: Double
        let ryz: Double
        let rzx: Double
        let rzy: Double
        let rzz: Double
        let sourceEllipsoid: Ellipsoid
        let targetEllipsoid: Ellipsoid

    }

    /// Builds both prepared steps (one per direction) once.
    func prepared() -> (datumToWgs84: PreparedStep, wgs84ToDatum: PreparedStep) {
        let rx = rx.arcSecondsToRadians
        let ry = ry.arcSecondsToRadians
        let rz = rz.arcSecondsToRadians

        let forwardEntries = Self.rotationEntries(
            rotationAboutX: rx,
            rotationAboutY: ry,
            rotationAboutZ: rz,
            transposed: false)
        let inverseEntries = Self.rotationEntries(
            rotationAboutX: rx,
            rotationAboutY: ry,
            rotationAboutZ: rz,
            transposed: true)

        let toWgs84 = PreparedStep(
            dx: dx,
            dy: dy,
            dz: dz,
            scale: 1.0 + scalePpm / 1_000_000.0,
            transposed: false,
            rxx: forwardEntries.rxx,
            rxy: forwardEntries.rxy,
            rxz: forwardEntries.rxz,
            ryx: forwardEntries.ryx,
            ryy: forwardEntries.ryy,
            ryz: forwardEntries.ryz,
            rzx: forwardEntries.rzx,
            rzy: forwardEntries.rzy,
            rzz: forwardEntries.rzz,
            sourceEllipsoid: datum.ellipsoid,
            targetEllipsoid: Datum.wgs84.ellipsoid)

        let scaleInverse = 1.0 / (1.0 + scalePpm / 1_000_000.0)
        let toDatum = PreparedStep(
            dx: dx,
            dy: dy,
            dz: dz,
            scale: scaleInverse,
            transposed: true,
            rxx: inverseEntries.rxx,
            rxy: inverseEntries.rxy,
            rxz: inverseEntries.rxz,
            ryx: inverseEntries.ryx,
            ryy: inverseEntries.ryy,
            ryz: inverseEntries.ryz,
            rzx: inverseEntries.rzx,
            rzy: inverseEntries.rzy,
            rzz: inverseEntries.rzz,
            sourceEllipsoid: Datum.wgs84.ellipsoid,
            targetEllipsoid: datum.ellipsoid)

        return (datumToWgs84: toWgs84, wgs84ToDatum: toDatum)
    }

    // MARK: - Shared implementation

    /// Shared implementation: `coordinate` is in the frame of
    /// `step.sourceEllipsoid`; the prepared step carries the control flags
    /// (entries, transposition, scale).
    private static func transform(
        _ coordinate: Coordinate3D,
        step: PreparedStep,
        targetProjection: Projection
    ) -> Coordinate3D {
        let phi = coordinate.latitude.degreesToRadians
        let lambda = coordinate.longitude.degreesToRadians
        let h = coordinate.altitude ?? 0.0

        // Geodetic -> geocentric on the source ellipsoid.
        let (x1, y1, z1) = geodeticToEcef(
            latitude: phi,
            longitude: lambda,
            height: h,
            ellipsoid: step.sourceEllipsoid)

        // Position vector convention: E = d + s * R * X (datum → WGS84).
        // The WGS84 → datum direction applies R^T and inverted shift/scale.
        var ecef: (x: Double, y: Double, z: Double)
        if step.transposed {
            ecef.x = step.scale * (step.rxx * (x1 - step.dx) + step.rxy * (y1 - step.dy) + step.rxz * (z1 - step.dz))
            ecef.y = step.scale * (step.ryx * (x1 - step.dx) + step.ryy * (y1 - step.dy) + step.ryz * (z1 - step.dz))
            ecef.z = step.scale * (step.rzx * (x1 - step.dx) + step.rzy * (y1 - step.dy) + step.rzz * (z1 - step.dz))
        }
        else {
            ecef.x = step.dx + step.scale * (step.rxx * x1 + step.rxy * y1 + step.rxz * z1)
            ecef.y = step.dy + step.scale * (step.ryx * x1 + step.ryy * y1 + step.ryz * z1)
            ecef.z = step.dz + step.scale * (step.rzx * x1 + step.rzy * y1 + step.rzz * z1)
        }

        // Geocentric -> geodetic on the target ellipsoid.
        let (latitude, longitude, altitude) = ecefToGeodetic(
            x: ecef.x,
            y: ecef.y,
            z: ecef.z,
            ellipsoid: step.targetEllipsoid)

        return Coordinate3D(
            x: longitude,
            y: latitude,
            z: altitude,
            m: coordinate.m,
            projection: targetProjection)
    }

    /// Single-coordinate path: builds the prepared step on the fly (matrix
    /// entries per call, identical to the previous per-call behavior).
    private static func transform(
        _ coordinate: Coordinate3D,
        sourceEllipsoid: Ellipsoid,
        targetEllipsoid: Ellipsoid,
        rotationIsForward: Bool,
        helmert: HelmertTransformation,
        targetProjection: Projection
    ) -> Coordinate3D {
        let phi = coordinate.latitude.degreesToRadians
        let lambda = coordinate.longitude.degreesToRadians
        let h = coordinate.altitude ?? 0.0

        // Geodetic -> geocentric on the source ellipsoid.
        let (x1, y1, z1) = geodeticToEcef(
            latitude: phi,
            longitude: lambda,
            height: h,
            ellipsoid: sourceEllipsoid)

        // Position vector convention: E = d + s * R * X (datum → WGS84),
        // with R the rotation matrix built from (rx, ry, rz).
        // The WGS84 → datum direction applies R^T and inverted shift/scale.
        var ecef: (x: Double, y: Double, z: Double)
        if rotationIsForward {
            let scale = 1.0 + helmert.scalePpm / 1_000_000.0
            let (rxx, rxy, rxz, ryx, ryy, ryz, rzx, rzy, rzz) = rotationEntries(
                rotationAboutX: helmert.rx.arcSecondsToRadians,
                rotationAboutY: helmert.ry.arcSecondsToRadians,
                rotationAboutZ: helmert.rz.arcSecondsToRadians,
                transposed: false)
            ecef.x = helmert.dx + scale * (rxx * x1 + rxy * y1 + rxz * z1)
            ecef.y = helmert.dy + scale * (ryx * x1 + ryy * y1 + ryz * z1)
            ecef.z = helmert.dz + scale * (rzx * x1 + rzy * y1 + rzz * z1)
        }
        else {
            let scale = 1.0 / (1.0 + helmert.scalePpm / 1_000_000.0)
            let (rxx, rxy, rxz, ryx, ryy, ryz, rzx, rzy, rzz) = rotationEntries(
                rotationAboutX: helmert.rx.arcSecondsToRadians,
                rotationAboutY: helmert.ry.arcSecondsToRadians,
                rotationAboutZ: helmert.rz.arcSecondsToRadians,
                transposed: true)
            ecef.x = scale * (rxx * (x1 - helmert.dx) + rxy * (y1 - helmert.dy) + rxz * (z1 - helmert.dz))
            ecef.y = scale * (ryx * (x1 - helmert.dx) + ryy * (y1 - helmert.dy) + ryz * (z1 - helmert.dz))
            ecef.z = scale * (rzx * (x1 - helmert.dx) + rzy * (y1 - helmert.dy) + rzz * (z1 - helmert.dz))
        }

        // Geocentric -> geodetic on the target ellipsoid.
        let (latitude, longitude, altitude) = ecefToGeodetic(
            x: ecef.x,
            y: ecef.y,
            z: ecef.z,
            ellipsoid: targetEllipsoid)

        return Coordinate3D(
            x: longitude,
            y: latitude,
            z: altitude,
            m: coordinate.m,
            projection: targetProjection)
    }

    /// The position vector rotation matrix R = Rz * Ry * Rx, built from
    /// arc seconds; optionally transposed.
    static func rotationEntries(
        rotationAboutX rxRadians: Double,
        rotationAboutY ryRadians: Double,
        rotationAboutZ rzRadians: Double,
        transposed: Bool
    ) -> (rxx: Double, rxy: Double, rxz: Double, ryx: Double, ryy: Double, ryz: Double, rzx: Double, rzy: Double, rzz: Double) {
        let cx = cos(rxRadians)
        let sx = sin(rxRadians)
        let cy = cos(ryRadians)
        let sy = sin(ryRadians)
        let cz = cos(rzRadians)
        let sz = sin(rzRadians)

        let rxx = cz * cy
        let rxy = cz * sy * sx - sz * cx
        let rxz = cz * sy * cx + sz * sx
        let ryx = sz * cy
        let ryy = sz * sy * sx + cz * cx
        let ryz = sz * sy * cx - cz * sx
        let rzx = -sy
        let rzy = cy * sx
        let rzz = cy * cx

        if transposed {
            return (rxx, ryx, rzx, rxy, ryy, rzy, rxz, ryz, rzz)
        }
        return (rxx, rxy, rxz, ryx, ryy, ryz, rzx, rzy, rzz)
    }

    /// Geodetic to geocentric conversion on an arbitrary ellipsoid.
    private static func geodeticToEcef(
        latitude phi: Double,
        longitude lambda: Double,
        height: Double,
        ellipsoid: Ellipsoid
    ) -> (x: Double, y: Double, z: Double) {
        let e2 = ellipsoid.eccentricitySquared

        let sinPhi = sin(phi)
        let cosPhi = cos(phi)
        let radiusSquared = 1.0 - e2 * sinPhi * sinPhi
        let nRadius = ellipsoid.semiMajorAxis / sqrt(radiusSquared)

        let x = (nRadius + height) * cosPhi * cos(lambda)
        let y = (nRadius + height) * cosPhi * sin(lambda)
        let z = ((1.0 - e2) * nRadius + height) * sinPhi

        return (x, y, z)
    }

    /// Geocentric to geodetic conversion on an arbitrary ellipsoid
    /// (iterative Bowring method, as used for EPSG:4978).
    private static func ecefToGeodetic(
        x: Double,
        y: Double,
        z: Double,
        ellipsoid: Ellipsoid
    ) -> (latitude: CLLocationDegrees, longitude: CLLocationDegrees, altitude: CLLocationDistance) {
        let a = ellipsoid.semiMajorAxis
        let e2 = ellipsoid.eccentricitySquared

        let p = sqrt(x * x + y * y)

        guard p > GISTool.intersectionEpsilon else {
            let latitude = z >= 0.0 ? 90.0 : -90.0
            let altitude = abs(z) - a * (1.0 - e2)
            return (latitude, 0.0, altitude)
        }

        var phi = atan2(z, p * (1.0 - e2))
        var height: Double = 0.0
        for _ in 0 ..< 10 {
            let sinPhi = sin(phi)
            let cosPhi = cos(phi)
            let radius = a / sqrt(1.0 - e2 * sinPhi * sinPhi)
            height = p / cosPhi - radius
            phi = atan2(z * (radius + height), p * ((1.0 - e2) * radius + height))
        }

        let latitude = Swift.min(90.0, Swift.max(-90.0, phi * 180.0 / .pi))
        let longitude = atan2(y, x) * 180.0 / .pi

        return (latitude, longitude, height)
    }

}
