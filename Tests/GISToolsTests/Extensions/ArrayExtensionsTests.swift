@testable import GISTools
import Testing

struct ArrayExtensionsTests {

    // Verifies that distinctPairs() returns non-overlapping pairs from even and uneven length arrays.
    @Test
    func distinctPairs() async throws {
        let even: [Int] = [1, 2, 3, 4, 5, 6]
        let uneven: [Int] = [1, 2, 3, 4, 5]

        let evenPairs = even.distinctPairs()
        let unevenPairs = uneven.distinctPairs()

        #expect(evenPairs.count == 3)
        #expect(unevenPairs.count == 2)

        #expect(evenPairs[0].first == 1)
        #expect(evenPairs[0].second == 2)
        #expect(evenPairs[1].first == 3)
        #expect(evenPairs[1].second == 4)
        #expect(evenPairs[2].first == 5)
        #expect(evenPairs[2].second == 6)

        #expect(unevenPairs[0].first == 1)
        #expect(unevenPairs[0].second == 2)
        #expect(unevenPairs[1].first == 3)
        #expect(unevenPairs[1].second == 4)
    }

    // Verifies that distinctPairs() handles empty and single-element arrays correctly.
    @Test
    func smallDistinctPairs() async throws {
        let empty: [Int] = []
        let small = [1]

        let emptyPairs = empty.distinctPairs()
        let smallPairs = small.distinctPairs()

        #expect(emptyPairs.count == 0)
        #expect(smallPairs.count == 1)
    }

    // Verifies that overlappingPairs() returns sliding window pairs from even and uneven length arrays.
    @Test
    func overlappingPairs() async throws {
        let even: [Int] = [1, 2, 3, 4, 5, 6]
        let uneven: [Int] = [1, 2, 3, 4, 5]

        let evenPairs = even.overlappingPairs()
        let unevenPairs = uneven.overlappingPairs()

        #expect(evenPairs.count == 5)
        #expect(unevenPairs.count == 4)

        #expect(evenPairs[0].first == 1)
        #expect(evenPairs[0].second == 2)
        #expect(evenPairs[1].first == 2)
        #expect(evenPairs[1].second == 3)
        #expect(evenPairs[2].first == 3)
        #expect(evenPairs[2].second == 4)
        #expect(evenPairs[3].first == 4)
        #expect(evenPairs[3].second == 5)
        #expect(evenPairs[4].first == 5)
        #expect(evenPairs[4].second == 6)

        #expect(unevenPairs[0].first == 1)
        #expect(unevenPairs[0].second == 2)
        #expect(unevenPairs[1].first == 2)
        #expect(unevenPairs[1].second == 3)
        #expect(evenPairs[2].first == 3)
        #expect(evenPairs[2].second == 4)
        #expect(evenPairs[3].first == 4)
        #expect(evenPairs[3].second == 5)
    }

    // Verifies that overlappingPairs() handles empty and single-element arrays correctly.
    @Test
    func smallOverlappingPairs() async throws {
        let empty: [Int] = []
        let small = [1]

        let emptyPairs = empty.overlappingPairs()
        let smallPairs = small.overlappingPairs()

        #expect(emptyPairs.count == 0)
        #expect(smallPairs.count == 1)
    }

    // Verifies safe array element access via get(at:) with positive, negative, and out-of-bounds indices.
    @Test
    func get() async throws {
        let array = [0, 1, 2, 3, 4, 5, 6]

        #expect(array.get(at: 0) == 0)
        #expect(array.get(at: 4) == 4)
        #expect(array.get(at: -1) == 6)
        #expect(array.get(at: -5) == 2)

        #expect(array.get(at: 7) == nil)
        #expect(array.get(at: -8) == nil)
    }

    // MARK: - chunked(into:)

    // Validates chunked splits an array into equal-sized chunks.
    @Test
    func chunked() async throws {
        let array = [1, 2, 3, 4, 5, 6, 7]
        let chunks = array.chunked(into: 3)
        #expect(chunks.count == 3)
        #expect(chunks[0] == [1, 2, 3])
        #expect(chunks[1] == [4, 5, 6])
        #expect(chunks[2] == [7])
    }

    // Verifies chunked(into:) returns empty array for empty input.
    @Test
    func chunkedEmpty() async throws {
        let array: [Int] = []
        #expect(array.chunked(into: 3).isEmpty)
    }

    // Verifies chunked(into:) produces a single chunk when size exceeds count.
    @Test
    func chunkedLargerThanCount() async throws {
        let array = [1, 2]
        let chunks = array.chunked(into: 10)
        #expect(chunks.count == 1)
        #expect(chunks[0] == [1, 2])
    }

    // MARK: - append(ifNotNil:)

    // Validates append(ifNotNil:) appends non-nil values and ignores nil.
    @Test
    func appendIfNotNil() async throws {
        var array: [Int] = [1, 2]
        array.append(ifNotNil: 3)
        #expect(array == [1, 2, 3])
        array.append(ifNotNil: nil)
        #expect(array == [1, 2, 3])
    }

    // MARK: - nilIfEmpty / isNotEmpty

    // Validates nilIfEmpty returns nil for empty arrays and isNotEmpty.
    @Test
    func nilIfEmptyAndIsNotEmpty() async throws {
        let empty: [Int] = []
        let nonEmpty = [1]
        #expect(empty.nilIfEmpty == nil)
        #expect(nonEmpty.nilIfEmpty == [1])
        #expect(empty.isNotEmpty == false)
        #expect(nonEmpty.isNotEmpty == true)
    }

    // MARK: - Coordinate3D helpers

    // Validates Coordinate3D array conversion helpers.
    @Test
    func coordinateArrayHelpers() async throws {
        let coords: [Coordinate3D] = [
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 1.0, longitude: 1.0),
        ]
        #expect(coords.asPoints.count == 2)
        #expect(coords.asMultiPoint != nil)
        #expect(coords.asUncheckedMultiPoint.points.count == 2)
        #expect(coords.asLineString != nil)
        #expect(coords.asUncheckedLineString.coordinates == coords)
        #expect(coords.asPolygon == nil) // 2 points cannot form a polygon
        #expect(coords.asRing == nil) // Not closed
    }

    // Verifies that a closed ring of coordinates produces ring and polygon values.
    @Test
    func coordinateArrayRingClosed() async throws {
        let coords: [Coordinate3D] = [
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 1.0, longitude: 0.0),
            Coordinate3D(latitude: 1.0, longitude: 1.0),
            Coordinate3D(latitude: 0.0, longitude: 1.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]
        #expect(coords.asRing != nil)
        #expect(coords.asUncheckedRing.coordinates == coords)
        #expect(coords.asPolygon != nil)
        #expect(coords.asUncheckedPolygon.outerRing != nil)
    }

    // Verifies that an empty coordinate array yields nil for all geometry helpers.
    @Test
    func coordinateArrayEmpty() async throws {
        let coords: [Coordinate3D] = []
        #expect(coords.asMultiPoint == nil)
        #expect(coords.asLineString == nil)
        #expect(coords.asPolygon == nil)
        #expect(coords.asRing == nil)
    }

    // MARK: - GeoJsonGeometry helpers

    // Validates GeoJsonGeometry array conversion helpers.
    @Test
    func geometryArrayHelpers() async throws {
        let line = try #require(LineString([Coordinate3D(latitude: 0.0, longitude: 0.0), Coordinate3D(latitude: 1.0, longitude: 1.0)]))
        let point = Point(Coordinate3D(latitude: 2.0, longitude: 2.0))
        let geometries: [GeoJsonGeometry] = [line, point]
        #expect(geometries.asGeometryCollection.geometries.count == 2)
        #expect(geometries.asFeatureCollection.features.count == 2)
    }

    // MARK: - Feature helpers

    // Validates Feature array conversion helpers.
    @Test
    func featureArrayHelpers() async throws {
        let line = try #require(LineString([Coordinate3D(latitude: 0.0, longitude: 0.0), Coordinate3D(latitude: 1.0, longitude: 1.0)]))
        let point = Point(Coordinate3D(latitude: 2.0, longitude: 2.0))
        let features: [Feature] = [Feature(line), Feature(point)]
        #expect(features.asGeometryCollection.geometries.count == 2)
        #expect(features.asFeatureCollection.features.count == 2)
    }

    // MARK: - FeatureCollection helpers

    // Validates FeatureCollection array conversion helpers.
    @Test
    func featureCollectionArrayHelpers() async throws {
        let line = try #require(LineString([Coordinate3D(latitude: 0.0, longitude: 0.0), Coordinate3D(latitude: 1.0, longitude: 1.0)]))
        let fc1 = FeatureCollection([Feature(line)])
        let fc2 = FeatureCollection([Feature(Point(Coordinate3D(latitude: 2.0, longitude: 2.0)))])
        let fcs: [FeatureCollection] = [fc1, fc2]
        #expect(fcs.asGeometryCollection.geometries.count == 2)
        #expect(fcs.asFeatureCollection.features.count == 2)
    }

}
