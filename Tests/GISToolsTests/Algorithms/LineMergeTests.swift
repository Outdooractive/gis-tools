import Testing
import Foundation
@testable import GISTools

struct LineMergeTests {

    // Validates that two connected LineStrings merge into one.
    @Test
    func twoConnectedLines() async throws {
        let a = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 5.0, longitude: 0.0),
        ]))
        let b = try #require(LineString([
            Coordinate3D(latitude: 5.0, longitude: 0.0),
            Coordinate3D(latitude: 10.0, longitude: 0.0),
        ]))
        let fc = FeatureCollection([Feature(a), Feature(b)])

        let result = fc.lineMerged()
        #expect(result.features.count == 1)
        let ls = result.features[0].geometry as! LineString
        #expect(ls.coordinates.count == 3)
    }

    // Validates that two disconnected LineStrings remain separate.
    @Test
    func twoDisconnectedLines() async throws {
        let a = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 5.0, longitude: 0.0),
        ]))
        let b = try #require(LineString([
            Coordinate3D(latitude: 10.0, longitude: 0.0),
            Coordinate3D(latitude: 15.0, longitude: 0.0),
        ]))
        let fc = FeatureCollection([Feature(a), Feature(b)])

        let result = fc.lineMerged()
        #expect(result.features.count == 2)
    }

    // Validates that three lines in a chain merge into one.
    @Test
    func threeLineChain() async throws {
        let a = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 5.0, longitude: 0.0),
        ]))
        let b = try #require(LineString([
            Coordinate3D(latitude: 5.0, longitude: 0.0),
            Coordinate3D(latitude: 10.0, longitude: 0.0),
        ]))
        let c = try #require(LineString([
            Coordinate3D(latitude: 10.0, longitude: 0.0),
            Coordinate3D(latitude: 15.0, longitude: 0.0),
        ]))
        let fc = FeatureCollection([Feature(a), Feature(b), Feature(c)])

        let result = fc.lineMerged()
        #expect(result.features.count == 1)
        let ls = result.features[0].geometry as! LineString
        #expect(ls.coordinates.count == 4)
    }

    // Validates that lines meeting at a junction (Y-shape) split into two separate merged lines.
    @Test
    func junction() async throws {
        // Two lines pointing to the same junction point
        let a = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 5.0, longitude: 0.0),
        ]))
        let b = try #require(LineString([
            Coordinate3D(latitude: 5.0, longitude: 0.0),
            Coordinate3D(latitude: 10.0, longitude: 0.0),
        ]))
        let c = try #require(LineString([
            Coordinate3D(latitude: 5.0, longitude: 0.0),
            Coordinate3D(latitude: 5.0, longitude: 5.0),
        ]))
        let fc = FeatureCollection([Feature(a), Feature(b), Feature(c)])

        let result = fc.lineMerged()
        // A and B form a straight line, C branches off — should produce 1 merged result
        // (A+B merge, C stays unmerged)
        #expect(result.features.count == 2)
    }

    // Validates that reversed lines (end-to-end) are handled correctly.
    @Test
    func reversedLine() async throws {
        let a = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 5.0, longitude: 0.0),
        ]))
        // b is reversed relative to a's continuation
        let b = try #require(LineString([
            Coordinate3D(latitude: 10.0, longitude: 0.0),
            Coordinate3D(latitude: 5.0, longitude: 0.0),
        ]))
        let fc = FeatureCollection([Feature(a), Feature(b)])

        let result = fc.lineMerged()
        #expect(result.features.count == 1)
        let coords = (result.features[0].geometry as! LineString).coordinates
        // Should be (0,0) → (5,0) → (10,0) — three points in order
        #expect(coords.count == 3)
        #expect(coords[0].latitude == 0.0)
        #expect(coords[2].latitude == 10.0)
    }

    // Validates that an empty FeatureCollection returns empty.
    @Test
    func emptyInput() async throws {
        let fc = FeatureCollection()
        let result = fc.lineMerged()
        #expect(result.features.isEmpty)
    }

    // Validates that a single LineString returns as-is.
    @Test
    func singleLine() async throws {
        let a = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 5.0, longitude: 0.0),
        ]))
        let fc = FeatureCollection([Feature(a)])

        let result = fc.lineMerged()
        #expect(result.features.count == 1)
        #expect(result.features[0].geometry is LineString)
    }

    // Validates that MultiLineString inputs are flattened and merged.
    @Test
    func multiLineStringInput() async throws {
        let mls = try #require(MultiLineString([
            [
                Coordinate3D(latitude: 0.0, longitude: 0.0),
                Coordinate3D(latitude: 5.0, longitude: 0.0),
            ],
            [
                Coordinate3D(latitude: 5.0, longitude: 0.0),
                Coordinate3D(latitude: 10.0, longitude: 0.0),
            ],
        ]))
        let fc = FeatureCollection([Feature(mls)])

        let result = fc.lineMerged()
        #expect(result.features.count == 1)
    }

    // MARK: - Projections

    // Tests line merge in EPSG:3857 projection.
    @Test
    func lineMerge3857() async throws {
        let a = try #require(LineString([
            Coordinate3D(x: 0.0, y: 0.0, projection: .epsg3857),
            Coordinate3D(x: 500_000.0, y: 0.0, projection: .epsg3857),
        ]))
        let b = try #require(LineString([
            Coordinate3D(x: 500_000.0, y: 0.0, projection: .epsg3857),
            Coordinate3D(x: 1_000_000.0, y: 0.0, projection: .epsg3857),
        ]))
        let fc = FeatureCollection([Feature(a), Feature(b)])

        let result = fc.lineMerged()
        #expect(result.features.count == 1)
        let ls = result.features[0].geometry as! LineString
        #expect(ls.coordinates.count == 3)
    }

    // Tests line merge in EPSG:4978 projection.
    @Test
    func lineMerge4978() async throws {
        let a = try #require(LineString([
            Coordinate3D(x: 0.0, y: 0.0, z: 0.0, projection: .epsg4978),
            Coordinate3D(x: 500_000.0, y: 0.0, z: 0.0, projection: .epsg4978),
        ]))
        let b = try #require(LineString([
            Coordinate3D(x: 500_000.0, y: 0.0, z: 0.0, projection: .epsg4978),
            Coordinate3D(x: 1_000_000.0, y: 0.0, z: 0.0, projection: .epsg4978),
        ]))
        let fc = FeatureCollection([Feature(a), Feature(b)])

        let result = fc.lineMerged()
        #expect(result.features.count == 1)
    }

    // Tests line merge in noSRID projection.
    @Test
    func lineMergeNoSRID() async throws {
        let a = try #require(LineString([
            Coordinate3D(x: 0.0, y: 0.0, projection: .noSRID),
            Coordinate3D(x: 10.0, y: 0.0, projection: .noSRID),
        ]))
        let b = try #require(LineString([
            Coordinate3D(x: 10.0, y: 0.0, projection: .noSRID),
            Coordinate3D(x: 20.0, y: 0.0, projection: .noSRID),
        ]))
        let fc = FeatureCollection([Feature(a), Feature(b)])

        let result = fc.lineMerged()
        #expect(result.features.count == 1)
    }

    // Validates merging two LineStrings that cross the antimeridian.
    @Test
    func antimeridianConnected() async throws {
        let a = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 170.0),
            Coordinate3D(latitude: 0.0, longitude: -170.0),
        ]))
        let b = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: -170.0),
            Coordinate3D(latitude: 5.0, longitude: -170.0),
        ]))
        let fc = FeatureCollection([Feature(a), Feature(b)])

        let result = fc.lineMerged()
        #expect(result.features.count == 1)
        let ls = result.features[0].geometry as! LineString
        #expect(ls.coordinates.count == 3)
    }

    // Validates merging lines on both sides of the antimeridian.
    @Test
    func antimeridianBothSides() async throws {
        let a = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 175.0),
            Coordinate3D(latitude: 0.0, longitude: 180.0),
        ]))
        let b = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 180.0),
            Coordinate3D(latitude: 0.0, longitude: -175.0),
        ]))
        let fc = FeatureCollection([Feature(a), Feature(b)])

        let result = fc.lineMerged()
        #expect(result.features.count == 1)
    }

    // Validates that lineMerged returns LineString features.
    @Test
    func mergedLineStringsBasic() async throws {
        let a = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 5.0, longitude: 0.0),
        ]))
        let b = try #require(LineString([
            Coordinate3D(latitude: 5.0, longitude: 0.0),
            Coordinate3D(latitude: 10.0, longitude: 0.0),
        ]))
        let fc = FeatureCollection([Feature(a), Feature(b)])

        let result = fc.lineMerged()
        #expect(result.features.count == 1)
        #expect(result.features[0].geometry is LineString)
        let ls = result.features[0].geometry as! LineString
        #expect(ls.coordinates.count == 3)
    }

    // Validates that lineMerged handles disconnected lines.
    @Test
    func mergedLineStringsDisconnected() async throws {
        let a = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 5.0, longitude: 0.0),
        ]))
        let b = try #require(LineString([
            Coordinate3D(latitude: 10.0, longitude: 0.0),
            Coordinate3D(latitude: 15.0, longitude: 0.0),
        ]))
        let fc = FeatureCollection([Feature(a), Feature(b)])

        let result = fc.lineMerged()
        #expect(result.features.count == 2)
        for feature in result.features {
            #expect(feature.geometry is LineString)
        }
    }

    // Validates that lineMerged handles junctions (each branch becomes a LineString).
    @Test
    func mergedLineStringsJunction() async throws {
        let a = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 5.0, longitude: 0.0),
        ]))
        let b = try #require(LineString([
            Coordinate3D(latitude: 5.0, longitude: 0.0),
            Coordinate3D(latitude: 10.0, longitude: 0.0),
        ]))
        let c = try #require(LineString([
            Coordinate3D(latitude: 5.0, longitude: 0.0),
            Coordinate3D(latitude: 5.0, longitude: 5.0),
        ]))
        let fc = FeatureCollection([Feature(a), Feature(b), Feature(c)])

        let result = fc.lineMerged()
        #expect(result.features.count == 2)
        for feature in result.features {
            #expect(feature.geometry is LineString)
        }
    }


    // MARK: - Audit regressions

    private func junctionFeatures(
        order: [Int],
        metadata: Bool = false
    ) throws -> FeatureCollection {
        let a = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 5.0, longitude: 0.0),
        ]))
        let b = try #require(LineString([
            Coordinate3D(latitude: 5.0, longitude: 0.0),
            Coordinate3D(latitude: 10.0, longitude: 0.0),
        ]))
        let c = try #require(LineString([
            Coordinate3D(latitude: 5.0, longitude: 0.0),
            Coordinate3D(latitude: 5.0, longitude: 5.0),
        ]))
        let features = [
            Feature(a, id: .string("a"), properties: ["name": "A"]),
            Feature(b, id: .string("b"), properties: ["name": "B"]),
            Feature(c, id: .string("c"), properties: ["name": "C"]),
        ]
        return FeatureCollection(order.map { features[$0] })
    }

    /// At a Y-junction the straight-through pair (a+b) must merge and the
    /// branch stays separate, in the exact coordinates, for every input order.
    @Test
    func junctionChoosesStraightThroughIndependentOfOrder() throws {
        let orders = [[0, 1, 2], [2, 1, 0], [1, 0, 2], [2, 0, 1], [1, 2, 0], [0, 2, 1]]
        var expected: [[Coordinate3D]]?

        for order in orders {
            let result = try junctionFeatures(order: order).lineMerged()
            #expect(result.features.count == 2)

            let lines = result.features.compactMap { $0.geometry as? LineString }
            #expect(lines.count == 2)

            let coordinates = lines.map(\.coordinates).sorted { lhs, rhs in
                (lhs.first?.longitude ?? 0.0) < (rhs.first?.longitude ?? 0.0)
            }

            if let expected {
                #expect(coordinates == expected, "order \(order) differs")
            }
            else {
                expected = coordinates
            }

            let through = try #require(lines.first(where: { $0.coordinates.count == 3 }))
            #expect(through.coordinates.map(\.longitude) == [0.0, 0.0, 0.0])
            #expect(through.coordinates.map(\.latitude) == [0.0, 5.0, 10.0])

            let branch = try #require(lines.first(where: { $0.coordinates.count == 2 }))
            #expect(branch.coordinates.map(\.longitude) == [0.0, 5.0])
            #expect(branch.coordinates.map(\.latitude) == [5.0, 5.0])
        }
    }

    /// A merged line takes the metadata of the earliest contributing input
    /// feature; a branch keeps its own metadata.
    @Test
    func metadataFollowsEarliestContributor() throws {
        let result = try junctionFeatures(order: [1, 0, 2], metadata: true).lineMerged()
        let through = try #require(result.features.first { ($0.geometry as? LineString)?.coordinates.count == 3 })
        #expect(through.id == .string("b"))
        let name: String? = through.property(for: "name")
        #expect(name == "B")

        let branch = try #require(result.features.first { ($0.geometry as? LineString)?.coordinates.count == 2 })
        #expect(branch.id == .string("c"))
    }

    /// A MultiLineString that produces several merged lines copies its
    /// metadata (id, properties and foreign members) to every result.
    @Test
    func multiLineStringMetadataCopiedToEveryLine() throws {
        let multiLineString = try #require(MultiLineString([
            [
                Coordinate3D(latitude: 0.0, longitude: 0.0),
                Coordinate3D(latitude: 0.0, longitude: 5.0),
            ],
            [
                Coordinate3D(latitude: 10.0, longitude: 10.0),
                Coordinate3D(latitude: 10.0, longitude: 15.0),
            ],
        ]))
        var feature = Feature(
            multiLineString,
            id: .string("multi"),
            properties: ["kind": "route"])
        feature.foreignMembers = ["source": "audit"]

        let result = FeatureCollection([feature]).lineMerged()
        #expect(result.features.count == 2)
        for output in result.features {
            #expect(output.id == .string("multi"))
            let kind: String? = output.property(for: "kind")
            #expect(kind == "route")
            let source: String? = output.foreignMember(for: "source")
            #expect(source == "audit")
        }
    }

    /// `+180` and `−180` are the same endpoint. The merged line keeps one
    /// shared coordinate and does not duplicate the seam point.
    @Test
    func antimeridianPlusMinus180AreCoincident() throws {
        let a = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 175.0),
            Coordinate3D(latitude: 0.0, longitude: 180.0),
        ]))
        let b = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: -180.0),
            Coordinate3D(latitude: 0.0, longitude: -175.0),
        ]))

        let result = FeatureCollection([Feature(a), Feature(b)]).lineMerged()
        #expect(result.features.count == 1)
        let line = try #require(result.features.first?.geometry as? LineString)
        #expect(line.coordinates.count == 3)
        // Orientation is normalized lexicographically, so the seam point may
        // be represented as +180 or −180; either is the same location.
        #expect(abs(line.coordinates[1].longitude) == 180.0)
        #expect(Set([line.coordinates[0].longitude, line.coordinates[2].longitude]) == [175.0, -175.0])
    }


}
