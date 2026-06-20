import Testing
import Foundation
@testable import GISTools

struct LineMergeTests {

    // Validates that two connected LineStrings merge into one.
    @Test
    func twoConnectedLines() async throws {
        let a = LineString([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 5.0, longitude: 0.0),
        ])!
        let b = LineString([
            Coordinate3D(latitude: 5.0, longitude: 0.0),
            Coordinate3D(latitude: 10.0, longitude: 0.0),
        ])!
        let fc = FeatureCollection([Feature(a), Feature(b)])

        let result = fc.lineMerged()
        #expect(result.features.count == 1)
        let ls = result.features[0].geometry as! LineString
        #expect(ls.coordinates.count == 3)
    }

    // Validates that two disconnected LineStrings remain separate.
    @Test
    func twoDisconnectedLines() async throws {
        let a = LineString([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 5.0, longitude: 0.0),
        ])!
        let b = LineString([
            Coordinate3D(latitude: 10.0, longitude: 0.0),
            Coordinate3D(latitude: 15.0, longitude: 0.0),
        ])!
        let fc = FeatureCollection([Feature(a), Feature(b)])

        let result = fc.lineMerged()
        #expect(result.features.count == 2)
    }

    // Validates that three lines in a chain merge into one.
    @Test
    func threeLineChain() async throws {
        let a = LineString([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 5.0, longitude: 0.0),
        ])!
        let b = LineString([
            Coordinate3D(latitude: 5.0, longitude: 0.0),
            Coordinate3D(latitude: 10.0, longitude: 0.0),
        ])!
        let c = LineString([
            Coordinate3D(latitude: 10.0, longitude: 0.0),
            Coordinate3D(latitude: 15.0, longitude: 0.0),
        ])!
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
        let a = LineString([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 5.0, longitude: 0.0),
        ])!
        let b = LineString([
            Coordinate3D(latitude: 5.0, longitude: 0.0),
            Coordinate3D(latitude: 10.0, longitude: 0.0),
        ])!
        let c = LineString([
            Coordinate3D(latitude: 5.0, longitude: 0.0),
            Coordinate3D(latitude: 5.0, longitude: 5.0),
        ])!
        let fc = FeatureCollection([Feature(a), Feature(b), Feature(c)])

        let result = fc.lineMerged()
        // A and B form a straight line, C branches off — should produce 1 merged result
        // (A+B merge, C stays unmerged)
        #expect(result.features.count == 2)
    }

    // Validates that reversed lines (end-to-end) are handled correctly.
    @Test
    func reversedLine() async throws {
        let a = LineString([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 5.0, longitude: 0.0),
        ])!
        // b is reversed relative to a's continuation
        let b = LineString([
            Coordinate3D(latitude: 10.0, longitude: 0.0),
            Coordinate3D(latitude: 5.0, longitude: 0.0),
        ])!
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
        let a = LineString([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 5.0, longitude: 0.0),
        ])!
        let fc = FeatureCollection([Feature(a)])

        let result = fc.lineMerged()
        #expect(result.features.count == 1)
        #expect(result.features[0].geometry is LineString)
    }

    // Validates that MultiLineString inputs are flattened and merged.
    @Test
    func multiLineStringInput() async throws {
        let mls = MultiLineString([
            [
                Coordinate3D(latitude: 0.0, longitude: 0.0),
                Coordinate3D(latitude: 5.0, longitude: 0.0),
            ],
            [
                Coordinate3D(latitude: 5.0, longitude: 0.0),
                Coordinate3D(latitude: 10.0, longitude: 0.0),
            ],
        ])!
        let fc = FeatureCollection([Feature(mls)])

        let result = fc.lineMerged()
        #expect(result.features.count == 1)
    }

    // Validates merging two LineStrings that cross the antimeridian.
    @Test
    func antimeridianConnected() async throws {
        let a = LineString([
            Coordinate3D(latitude: 0.0, longitude: 170.0),
            Coordinate3D(latitude: 0.0, longitude: -170.0),
        ])!
        let b = LineString([
            Coordinate3D(latitude: 0.0, longitude: -170.0),
            Coordinate3D(latitude: 5.0, longitude: -170.0),
        ])!
        let fc = FeatureCollection([Feature(a), Feature(b)])

        let result = fc.lineMerged()
        #expect(result.features.count == 1)
        let ls = result.features[0].geometry as! LineString
        #expect(ls.coordinates.count == 3)
    }

    // Validates merging lines on both sides of the antimeridian.
    @Test
    func antimeridianBothSides() async throws {
        let a = LineString([
            Coordinate3D(latitude: 0.0, longitude: 175.0),
            Coordinate3D(latitude: 0.0, longitude: 180.0),
        ])!
        let b = LineString([
            Coordinate3D(latitude: 0.0, longitude: 180.0),
            Coordinate3D(latitude: 0.0, longitude: -175.0),
        ])!
        let fc = FeatureCollection([Feature(a), Feature(b)])

        let result = fc.lineMerged()
        #expect(result.features.count == 1)
    }

    // Validates that lineMerged returns LineString features.
    @Test
    func mergedLineStringsBasic() async throws {
        let a = LineString([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 5.0, longitude: 0.0),
        ])!
        let b = LineString([
            Coordinate3D(latitude: 5.0, longitude: 0.0),
            Coordinate3D(latitude: 10.0, longitude: 0.0),
        ])!
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
        let a = LineString([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 5.0, longitude: 0.0),
        ])!
        let b = LineString([
            Coordinate3D(latitude: 10.0, longitude: 0.0),
            Coordinate3D(latitude: 15.0, longitude: 0.0),
        ])!
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
        let a = LineString([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 5.0, longitude: 0.0),
        ])!
        let b = LineString([
            Coordinate3D(latitude: 5.0, longitude: 0.0),
            Coordinate3D(latitude: 10.0, longitude: 0.0),
        ])!
        let c = LineString([
            Coordinate3D(latitude: 5.0, longitude: 0.0),
            Coordinate3D(latitude: 5.0, longitude: 5.0),
        ])!
        let fc = FeatureCollection([Feature(a), Feature(b), Feature(c)])

        let result = fc.lineMerged()
        #expect(result.features.count == 2)
        for feature in result.features {
            #expect(feature.geometry is LineString)
        }
    }

}
