#if canImport(CoreLocation)
import CoreLocation
#endif
import Foundation
@testable import GISTools
import Testing

struct RTreeTests {

    // Verifies that an R-tree initialized with no nodes returns an empty search result.
    @Test
    func empty() async throws {
        let nodes: [Point] = []
        let rTree = RTree(nodes)
        let objects = rTree.search(inBoundingBox: BoundingBox.world)
        #expect(objects.isEmpty)
    }

    // MARK: -

    // Verifies R-tree bounding-box search with simple points in EPSG:4326 for Hilbert, latitude, and unsorted sort options.
    @Test
    func simplePoints4326() async throws {
        var nodes: [Point] = []
        5.times {
            nodes.append(Point(Coordinate3D(
                latitude: Double.random(in: -10.0 ... 10.0),
                longitude: Double.random(in: -10.0 ... 10.0))))
        }

        let rTreeHilbert = RTree(nodes, nodeSize: 4)
        #expect(rTreeHilbert.projection == .epsg4326)
        _testSimplePoints(rTreeHilbert)

        let rTreeRandom = RTree(nodes, nodeSize: 4, sortOption: .byLatitude)
        #expect(rTreeRandom.projection == .epsg4326)
        _testSimplePoints(rTreeRandom)

        let rTreeAsInput = RTree(nodes, nodeSize: 4, sortOption: .unsorted)
        #expect(rTreeAsInput.projection == .epsg4326)
        _testSimplePoints(rTreeAsInput)
    }

    // Verifies R-tree bounding-box search with simple points in EPSG:3857 for Hilbert, latitude, and unsorted sort options.
    @Test
    func simplePoints3857() async throws {
        var nodes: [Point] = []
        5.times {
            nodes.append(Point(Coordinate3D(
                x: Double.random(in: -10.0 ... 10.0),
                y: Double.random(in: -10.0 ... 10.0),
                projection: .epsg3857)))
        }

        let rTreeHilbert = RTree(nodes, nodeSize: 4)
        #expect(rTreeHilbert.projection == .epsg3857)
        _testSimplePoints(rTreeHilbert)

        let rTreeRandom = RTree(nodes, nodeSize: 4, sortOption: .byLatitude)
        #expect(rTreeRandom.projection == .epsg3857)
        _testSimplePoints(rTreeRandom)

        let rTreeAsInput = RTree(nodes, nodeSize: 4, sortOption: .unsorted)
        #expect(rTreeAsInput.projection == .epsg3857)
        _testSimplePoints(rTreeAsInput)
    }

    private func _testSimplePoints(_ rTree: RTree<Point>) {
        var minX = Double.random(in: -10.0 ... 10.0)
        var maxX = Double.random(in: -10.0 ... 10.0)
        var minY = Double.random(in: -10.0 ... 10.0)
        var maxY = Double.random(in: -10.0 ... 10.0)

        if minX > maxX {
            (minX, maxX) = (maxX, minX)
        }
        if minY > maxY {
            (minY, maxY) = (maxY, minY)
        }

        let boundingBox = BoundingBox(
            southWest: Coordinate3D(x: minX, y: minY, projection: rTree.projection),
            northEast: Coordinate3D(x: maxX, y: maxY, projection: rTree.projection))

        let objects1 = rTree.search(inBoundingBox: boundingBox)
        let objects2 = rTree.searchSerial(inBoundingBox: boundingBox)

        #expect(objects1.count == objects2.count)
        #expect(objects1.sorted { $0.coordinate.longitude < $1.coordinate.longitude } == objects2.sorted { $0.coordinate.longitude < $1.coordinate.longitude })
    }

    // MARK: -

    // Verifies R-tree construction and search in EPSG:4326 across randomized node sizes and point counts.
    @Test
    func rTree4326() async throws {
        100.times {
            var nodes: [Point] = []
            Int.random(in: 10 ... 1000).times {
                nodes.append(Point(Coordinate3D(
                    latitude: Double.random(in: -10.0 ... 10.0),
                    longitude: Double.random(in: -10.0 ... 10.0))))
            }

            // Also test some invalid node sizes
            let rTreeHilbert = RTree(nodes, nodeSize: Int.random(in: -4 ... 16))
            #expect(rTreeHilbert.projection == .epsg4326)
            _testRTree(rTreeHilbert)

            let rTreeRandom = RTree(nodes, nodeSize: Int.random(in: -4 ... 16), sortOption: .byLatitude)
            #expect(rTreeRandom.projection == .epsg4326)
            _testRTree(rTreeRandom)

            let rTreeAsInput = RTree(nodes, nodeSize: Int.random(in: -4 ... 16), sortOption: .unsorted)
            #expect(rTreeAsInput.projection == .epsg4326)
            _testRTree(rTreeAsInput)
        }
    }

    // Verifies R-tree construction and search in EPSG:3857 across randomized node sizes and point counts.
    @Test
    func rTree3857() async throws {
        100.times {
            var nodes: [Point] = []
            Int.random(in: 10 ... 1000).times {
                nodes.append(Point(Coordinate3D(
                    x: Double.random(in: -10.0 ... 10.0),
                    y: Double.random(in: -10.0 ... 10.0),
                    projection: .epsg3857)))
            }

            // Also test some invalid node sizes
            let rTreeHilbert = RTree(nodes, nodeSize: Int.random(in: -4 ... 16))
            #expect(rTreeHilbert.projection == .epsg3857)
            _testRTree(rTreeHilbert)

            let rTreeRandom = RTree(nodes, nodeSize: Int.random(in: -4 ... 16), sortOption: .byLatitude)
            #expect(rTreeRandom.projection == .epsg3857)
            _testRTree(rTreeRandom)

            let rTreeAsInput = RTree(nodes, nodeSize: Int.random(in: -4 ... 16), sortOption: .unsorted)
            #expect(rTreeAsInput.projection == .epsg3857)
            _testRTree(rTreeAsInput)
        }
    }

    private func _testRTree(_ rTree: RTree<Point>) {
        var minX = Double.random(in: -10.0 ... 10.0)
        var maxX = Double.random(in: -10.0 ... 10.0)
        var minY = Double.random(in: -10.0 ... 10.0)
        var maxY = Double.random(in: -10.0 ... 10.0)

        if minX > maxX {
            (minX, maxX) = (maxX, minX)
        }
        if minY > maxY {
            (minY, maxY) = (maxY, minY)
        }

        let boundingBox = BoundingBox(
            southWest: Coordinate3D(x: minX, y: minY, projection: rTree.projection),
            northEast: Coordinate3D(x: maxX, y: maxY, projection: rTree.projection))

        let objects1 = rTree.search(inBoundingBox: boundingBox)
        let objects2 = rTree.searchSerial(inBoundingBox: boundingBox)

        #expect(objects1.sorted { $0.coordinate.longitude < $1.coordinate.longitude } == objects2.sorted { $0.coordinate.longitude < $1.coordinate.longitude })
    }

    // MARK: -

    // Verifies around-coordinate search in EPSG:4326 matches serial search results.
    @Test
    func aroundSearch4326() async throws {
        100.times {
            var nodes: [Point] = []
            Int.random(in: 1000 ... 10000).times {
                nodes.append(Point(Coordinate3D(
                    latitude: Double.random(in: -10.0 ... 10.0),
                    longitude: Double.random(in: -10.0 ... 10.0))))
            }
            let rTree = RTree(nodes)
            #expect(rTree.projection == .epsg4326)
            _testAroundSearch(
                rTree,
                center: Coordinate3D(
                    latitude: Double.random(in: -10.0 ... 10.0),
                    longitude: Double.random(in: -10.0 ... 10.0)))
        }
    }

    // Verifies around-coordinate search in EPSG:3857 matches serial search results.
    @Test
    func aroundSearch3857() async throws {
        100.times {
            var nodes: [Point] = []
            Int.random(in: 1000 ... 10000).times {
                nodes.append(Point(Coordinate3D(
                    x: Double.random(in: -100_000.0 ... 100_000.0),
                    y: Double.random(in: -100_000.0 ... 100_000.0),
                    projection: .epsg3857)))
            }
            let rTree = RTree(nodes)
            #expect(rTree.projection == .epsg3857)
            _testAroundSearch(
                rTree,
                center: Coordinate3D(
                    x: Double.random(in: -100_000.0 ... 100_000.0),
                    y: Double.random(in: -100_000.0 ... 100_000.0)))
        }
    }

    private func _testAroundSearch(_ rTree: RTree<Point>, center: Coordinate3D) {
        let maximumDistance = Double.random(in: 10000.0 ... 100_000.0)

        let objects1 = rTree.search(aroundCoordinate: center, maximumDistance: maximumDistance)
        let objects2 = rTree.searchSerial(aroundCoordinate: center, maximumDistance: maximumDistance)

        assertCorrectDistance(result: objects1, from: center, maximumDistance: maximumDistance)
        assertCorrectDistance(result: objects2, from: center, maximumDistance: maximumDistance)

        #expect(objects1.map(\.object) == objects2.map(\.object))
    }

    private func assertCorrectDistance(
        result: [RTree<Point>.AroundSearchResult],
        from coordinate: Coordinate3D,
        maximumDistance: CLLocationDistance)
    {
        for (object, distance) in result {
            let objectDistance = object.coordinate.distance(from: coordinate)
            #expect(objectDistance == distance)
            #expect(objectDistance <= maximumDistance)
        }
    }

    // Verifies R-tree construction and search in EPSG:4978 matches serial search results.
    @Test
    func rTree4978() async throws {
        20.times {
            var nodes: [Point] = []
            Int.random(in: 50 ... 500).times {
                let coordinate = Coordinate3D(
                    latitude: Double.random(in: -10.0 ... 10.0),
                    longitude: Double.random(in: -10.0 ... 10.0))
                    .projected(to: .epsg4978)
                nodes.append(Point(coordinate))
            }
            let rTree = RTree(nodes)
            #expect(rTree.projection == .epsg4978)

            var minLat = Double.random(in: -10.0 ... 10.0)
            var maxLat = Double.random(in: -10.0 ... 10.0)
            var minLon = Double.random(in: -10.0 ... 10.0)
            var maxLon = Double.random(in: -10.0 ... 10.0)

            if minLat > maxLat {
                (minLat, maxLat) = (maxLat, minLat)
            }
            if minLon > maxLon {
                (minLon, maxLon) = (maxLon, minLon)
            }

            let geodeticBox = BoundingBox(
                southWest: Coordinate3D(latitude: minLat, longitude: minLon),
                northEast: Coordinate3D(latitude: maxLat, longitude: maxLon))
            let searchBox = geodeticBox.projected(to: .epsg4978)

            let objects1 = rTree.search(inBoundingBox: searchBox)
            let objects2 = rTree.searchSerial(inBoundingBox: searchBox)

            #expect(objects1.sorted { $0.coordinate.longitude < $1.coordinate.longitude } == objects2.sorted { $0.coordinate.longitude < $1.coordinate.longitude })
        }
    }

    // Verifies R-tree construction and search with noSRID points.
    @Test
    func rTreeNoSRID() async throws {
        20.times {
            var nodes: [Point] = []
            Int.random(in: 50 ... 500).times {
                nodes.append(Point(Coordinate3D(
                    x: Double.random(in: -10.0 ... 10.0),
                    y: Double.random(in: -10.0 ... 10.0),
                    projection: .noSRID)))
            }
            let rTree = RTree(nodes, nodeSize: 16, sortOption: .unsorted)
            #expect(rTree.projection == .noSRID)
            _testRTree(rTree)
        }
    }

    // Verifies bounding-box search across the antimeridian in EPSG:4326.
    @Test
    func antimeridian4326() async throws {
        20.times {
            var nodes: [Point] = []
            Int.random(in: 50 ... 250).times {
                let rawLongitude = Double.random(in: 170.0 ... 190.0)
                let longitude = rawLongitude > 180.0 ? rawLongitude - 360.0 : rawLongitude
                nodes.append(Point(Coordinate3D(
                    latitude: Double.random(in: -10.0 ... 10.0),
                    longitude: longitude)))
            }
            Int.random(in: 50 ... 250).times {
                let rawLongitude = Double.random(in: -190.0 ... -170.0)
                let longitude = rawLongitude < -180.0 ? rawLongitude + 360.0 : rawLongitude
                nodes.append(Point(Coordinate3D(
                    latitude: Double.random(in: -10.0 ... 10.0),
                    longitude: longitude)))
            }

            let rTree = RTree(nodes)
            #expect(rTree.projection == .epsg4326)

            let westLongitude = Double.random(in: 170.0 ... 180.0)
            let eastLongitude = Double.random(in: -180.0 ... -170.0)
            let searchBox = BoundingBox(
                southWest: Coordinate3D(latitude: -10.0, longitude: westLongitude),
                northEast: Coordinate3D(latitude: 10.0, longitude: eastLongitude))

            let objects1 = rTree.search(inBoundingBox: searchBox)
            let objects2 = rTree.searchSerial(inBoundingBox: searchBox)

            #expect(objects1.sorted { $0.coordinate.longitude < $1.coordinate.longitude } == objects2.sorted { $0.coordinate.longitude < $1.coordinate.longitude })
        }
    }

    // Verifies bounding-box search across the antimeridian in EPSG:3857.
    @Test
    func antimeridian3857() async throws {
        20.times {
            let margin = 1_000_000.0
            var nodes: [Point] = []
            Int.random(in: 50 ... 250).times {
                nodes.append(Point(Coordinate3D(
                    x: Double.random(in: GISTool.originShift - margin ... GISTool.originShift),
                    y: Double.random(in: -1_000_000.0 ... 1_000_000.0),
                    projection: .epsg3857)))
            }
            Int.random(in: 50 ... 250).times {
                nodes.append(Point(Coordinate3D(
                    x: Double.random(in: -GISTool.originShift ... -GISTool.originShift + margin),
                    y: Double.random(in: -1_000_000.0 ... 1_000_000.0),
                    projection: .epsg3857)))
            }

            let rTree = RTree(nodes)
            #expect(rTree.projection == .epsg3857)

            let westX = Double.random(in: GISTool.originShift - margin ... GISTool.originShift)
            let eastX = Double.random(in: -GISTool.originShift ... -GISTool.originShift + margin)
            let searchBox = BoundingBox(
                southWest: Coordinate3D(x: westX, y: -1_000_000.0),
                northEast: Coordinate3D(x: eastX, y: 1_000_000.0))

            let objects1 = rTree.search(inBoundingBox: searchBox)
            let objects2 = rTree.searchSerial(inBoundingBox: searchBox)

            #expect(objects1.sorted { $0.coordinate.longitude < $1.coordinate.longitude } == objects2.sorted { $0.coordinate.longitude < $1.coordinate.longitude })
        }
    }

    // Verifies that antimeridian-crossing queries are rejected consistently for noSRID.
    @Test
    func antimeridianNoSRIDReturnsEmpty() async throws {
        var nodes: [Point] = []
        100.times {
            nodes.append(Point(Coordinate3D(
                x: Double.random(in: -10.0 ... 10.0),
                y: Double.random(in: -10.0 ... 10.0),
                projection: .noSRID)))
        }

        let rTree = RTree(nodes)
        let crossingBox = BoundingBox(
            southWest: Coordinate3D(x: 5.0, y: -5.0, projection: .noSRID),
            northEast: Coordinate3D(x: -5.0, y: 5.0, projection: .noSRID))

        #expect(rTree.search(inBoundingBox: crossingBox).isEmpty)
        #expect(rTree.searchSerial(inBoundingBox: crossingBox).isEmpty)
    }

    // Verifies that inverted EPSG:4978 bounding boxes are normalized to min/max
    // axis-aligned boxes and produce the same results as their non-inverted form.
    @Test
    func invertedBoundingBox4978() async throws {
        var nodes: [Point] = []
        100.times {
            let coordinate = Coordinate3D(
                latitude: Double.random(in: -10.0 ... 10.0),
                longitude: Double.random(in: -10.0 ... 10.0))
                .projected(to: .epsg4978)
            nodes.append(Point(coordinate))
        }

        let rTree = RTree(nodes)

        var minX = Double.infinity
        var maxX = -Double.infinity
        var minY = Double.infinity
        var maxY = -Double.infinity
        for point in nodes {
            minX = min(minX, point.coordinate.longitude)
            maxX = max(maxX, point.coordinate.longitude)
            minY = min(minY, point.coordinate.latitude)
            maxY = max(maxY, point.coordinate.latitude)
        }

        let normalBox = BoundingBox(
            southWest: Coordinate3D(x: minX, y: minY, projection: .epsg4978),
            northEast: Coordinate3D(x: maxX, y: maxY, projection: .epsg4978))
        let invertedBox = BoundingBox(
            southWest: Coordinate3D(x: maxX, y: maxY, projection: .epsg4978),
            northEast: Coordinate3D(x: minX, y: minY, projection: .epsg4978))

        let normalTree = rTree.search(inBoundingBox: normalBox)
        let normalSerial = rTree.searchSerial(inBoundingBox: normalBox)
        let invertedTree = rTree.search(inBoundingBox: invertedBox)
        let invertedSerial = rTree.searchSerial(inBoundingBox: invertedBox)

        #expect(normalTree.count == normalSerial.count)
        #expect(invertedTree.count == invertedSerial.count)
        #expect(normalTree.count == invertedTree.count)
    }

    // MARK: -

    // MARK: - Edge cases

    // Verifies that small collections, including counts around the tree-build threshold, return correct results.
    @Test
    func smallCollections() async throws {
        for sortOption in [RTreeSortOption.hilbert, .byLatitude, .byLongitude, .unsorted] {
            for objectCount in [1, 2, 15, 16, 17, 31, 32, 33, 100] {
                var nodes: [Point] = []
                for i in 0 ..< objectCount {
                    nodes.append(Point(Coordinate3D(
                        latitude: Double(i) * 0.1,
                        longitude: Double(i) * 0.2)))
                }

                let rTree = RTree(nodes, nodeSize: 16, sortOption: sortOption)
                _testRTree(rTree)
            }
        }
    }

    // Verifies that all objects sharing the same coordinate are found correctly.
    @Test
    func identicalCoordinates() async throws {
        let coordinate = Coordinate3D(latitude: 1.0, longitude: 2.0)
        var nodes: [Point] = []
        50.times { nodes.append(Point(coordinate)) }

        for sortOption in [RTreeSortOption.hilbert, .byLatitude, .byLongitude, .unsorted] {
            let rTree = RTree(nodes, nodeSize: 16, sortOption: sortOption)

            let containingBox = BoundingBox(
                southWest: Coordinate3D(latitude: 0.0, longitude: 1.0),
                northEast: Coordinate3D(latitude: 2.0, longitude: 3.0))
            #expect(rTree.search(inBoundingBox: containingBox).count == 50)
            #expect(rTree.searchSerial(inBoundingBox: containingBox).count == 50)

            let outsideBox = BoundingBox(
                southWest: Coordinate3D(latitude: 10.0, longitude: 10.0),
                northEast: Coordinate3D(latitude: 11.0, longitude: 11.0))
            #expect(rTree.search(inBoundingBox: outsideBox).isEmpty)
            #expect(rTree.searchSerial(inBoundingBox: outsideBox).isEmpty)

            let zeroDistance = rTree.search(aroundCoordinate: coordinate, maximumDistance: 0.0)
            #expect(zeroDistance.count == 50)

            let unsortedZero = rTree.search(aroundCoordinate: coordinate, maximumDistance: 0.0, sorted: false)
            #expect(unsortedZero.count == 50)
        }
    }

    // Verifies that a query bounding box completely outside the tree returns no results.
    @Test
    func outsideBoundingBox() async throws {
        var nodes: [Point] = []
        100.times {
            nodes.append(Point(Coordinate3D(
                latitude: Double.random(in: -10.0 ... 10.0),
                longitude: Double.random(in: -10.0 ... 10.0))))
        }
        let rTree = RTree(nodes)

        let outsideBox = BoundingBox(
            southWest: Coordinate3D(latitude: 20.0, longitude: 20.0),
            northEast: Coordinate3D(latitude: 30.0, longitude: 30.0))
        #expect(rTree.search(inBoundingBox: outsideBox).isEmpty)
        #expect(rTree.searchSerial(inBoundingBox: outsideBox).isEmpty)
    }

    // Verifies that a point lying exactly on a query-bbox edge is included in the result.
    @Test
    func boundaryTouches() async throws {
        let point = Point(Coordinate3D(latitude: 5.0, longitude: 5.0))
        let rTree = RTree([point], nodeSize: 16)

        let touchingBox = BoundingBox(
            southWest: Coordinate3D(latitude: 5.0, longitude: 5.0),
            northEast: Coordinate3D(latitude: 10.0, longitude: 10.0))
        #expect(rTree.search(inBoundingBox: touchingBox).count == 1)
        #expect(rTree.searchSerial(inBoundingBox: touchingBox).count == 1)
    }

    // Verifies the byLongitude sort option produces the same results as serial search.
    @Test
    func byLongitudeSortOption() async throws {
        20.times {
            var nodes: [Point] = []
            Int.random(in: 50 ... 500).times {
                nodes.append(Point(Coordinate3D(
                    latitude: Double.random(in: -10.0 ... 10.0),
                    longitude: Double.random(in: -10.0 ... 10.0))))
            }
            let rTree = RTree(nodes, nodeSize: 16, sortOption: .byLongitude)
            _testRTree(rTree)
        }
    }

    // Verifies around-coordinate search with sorted=false returns the same objects as the sorted variant.
    @Test
    func aroundSearchUnsorted() async throws {
        var nodes: [Point] = []
        500.times {
            nodes.append(Point(Coordinate3D(
                latitude: Double.random(in: -10.0 ... 10.0),
                longitude: Double.random(in: -10.0 ... 10.0))))
        }
        let rTree = RTree(nodes)

        let center = Coordinate3D(latitude: 0.0, longitude: 0.0)
        let unsorted = rTree.search(aroundCoordinate: center, maximumDistance: 100_000.0, sorted: false)
        let sorted = rTree.search(aroundCoordinate: center, maximumDistance: 100_000.0, sorted: true)

        #expect(unsorted.count == sorted.count)

        let unsortedObjects = unsorted.map(\.object).sorted { $0.coordinate.longitude < $1.coordinate.longitude }
        let sortedObjects = sorted.map(\.object).sorted { $0.coordinate.longitude < $1.coordinate.longitude }
        #expect(unsortedObjects == sortedObjects)
    }

    // Verifies extreme and invalid node sizes are clamped and still produce correct results.
    @Test
    func extremeNodeSizes() async throws {
        var nodes: [Point] = []
        100.times {
            nodes.append(Point(Coordinate3D(
                latitude: Double.random(in: -10.0 ... 10.0),
                longitude: Double.random(in: -10.0 ... 10.0))))
        }

        let tiny = RTree(nodes, nodeSize: -100, sortOption: .hilbert)
        #expect(tiny.nodeSize == 4)
        _testRTree(tiny)

        let huge = RTree(nodes, nodeSize: 1_000_000, sortOption: .hilbert)
        #expect(huge.nodeSize == 65_535)
        _testRTree(huge)

        let largerThanCount = RTree(nodes, nodeSize: 1_000, sortOption: .hilbert)
        #expect(largerThanCount.nodeSize == 1_000)
        _testRTree(largerThanCount)
    }

    // Verifies that a world-spanning query bounding box returns every indexed object.
    @Test
    func worldBoundingBoxSearch() async throws {
        var nodes: [Point] = []
        100.times {
            nodes.append(Point(Coordinate3D(
                latitude: Double.random(in: -80.0 ... 80.0),
                longitude: Double.random(in: -170.0 ... 170.0))))
        }
        let rTree = RTree(nodes)

        #expect(rTree.search(inBoundingBox: .world).count == 100)
        #expect(rTree.searchSerial(inBoundingBox: .world).count == 100)
    }

    // Verifies bounding-box search works for non-point geometries (LineString).
    @Test
    func lineStringBoundingBoxSearch() async throws {
        var nodes: [LineString] = []
        for i in 0 ..< 100 {
            let start = Coordinate3D(
                latitude: Double(i) * 0.1 - 5.0,
                longitude: Double(i) * 0.2 - 10.0)
            let end = Coordinate3D(
                latitude: Double(i) * 0.15 - 5.0,
                longitude: Double(i) * 0.25 - 10.0)
            let lineString = try #require(LineString([start, end]))
            nodes.append(lineString)
        }

        let rTree = RTree(nodes)
        let boundingBox = BoundingBox(
            southWest: Coordinate3D(latitude: -2.0, longitude: -2.0),
            northEast: Coordinate3D(latitude: 2.0, longitude: 2.0))

        let treeResults = rTree.search(inBoundingBox: boundingBox)
        let serialResults = rTree.searchSerial(inBoundingBox: boundingBox)

        let sortedTree = treeResults.sorted { $0.coordinates[0].longitude < $1.coordinates[0].longitude }
        let sortedSerial = serialResults.sorted { $0.coordinates[0].longitude < $1.coordinates[0].longitude }
        #expect(sortedTree == sortedSerial)
    }

    // Verifies bounding-box search works for non-point geometries (Polygon).
    @Test
    func polygonBoundingBoxSearch() async throws {
        var nodes: [Polygon] = []
        for i in 0 ..< 100 {
            let x = Double(i) * 0.2 - 10.0
            let y = Double(i) * 0.1 - 5.0
            let ring = [
                Coordinate3D(latitude: y, longitude: x),
                Coordinate3D(latitude: y, longitude: x + 0.5),
                Coordinate3D(latitude: y + 0.5, longitude: x + 0.5),
                Coordinate3D(latitude: y + 0.5, longitude: x),
                Coordinate3D(latitude: y, longitude: x),
            ]
            let polygon = try #require(Polygon([ring]))
            nodes.append(polygon)
        }

        let rTree = RTree(nodes)
        let boundingBox = BoundingBox(
            southWest: Coordinate3D(latitude: -2.0, longitude: -2.0),
            northEast: Coordinate3D(latitude: 2.0, longitude: 2.0))

        let treeResults = rTree.search(inBoundingBox: boundingBox)
        let serialResults = rTree.searchSerial(inBoundingBox: boundingBox)

        let sortedTree = treeResults.sorted { $0.coordinates[0][0].longitude < $1.coordinates[0][0].longitude }
        let sortedSerial = serialResults.sorted { $0.coordinates[0][0].longitude < $1.coordinates[0][0].longitude }
        #expect(sortedTree == sortedSerial)
    }

    // Verifies that the R-tree falls back to serial search for small inputs.
    @Test
    func serialFallback() async throws {
        var nodes: [Point] = []
        8.times {
            nodes.append(Point(Coordinate3D(
                latitude: Double.random(in: -10.0 ... 10.0),
                longitude: Double.random(in: -10.0 ... 10.0))))
        }

        // nodeSize 16 means 8 objects stay below the tree-build threshold.
        let rTree = RTree(nodes, nodeSize: 16)
        _testRTree(rTree)
    }

    // Verifies that an R-tree initialized with objects that have no bounding box initially still indexes them.
    @Test
    func lazyBoundingBoxes() async throws {
        var nodes: [Point] = []
        100.times {
            nodes.append(Point(Coordinate3D(
                latitude: Double.random(in: -10.0 ... 10.0),
                longitude: Double.random(in: -10.0 ... 10.0))))
        }

        // Points are created without calculateBoundingBox, so updateBoundingBox is exercised by RTree.
        let rTree = RTree(nodes)
        #expect(rTree.count == 100)
        _testRTree(rTree)
    }

    // Verifies bounding-box and around-coordinate search work for MultiPoint geometries.
    @Test
    func multiPointBoundingBoxSearch() throws {
        var nodes: [MultiPoint] = []
        for i in 0 ..< 50 {
            let x = Double(i) * 0.5 - 12.5
            let y = Double(i) * 0.3 - 7.5
            let points = [
                Coordinate3D(latitude: y, longitude: x),
                Coordinate3D(latitude: y + 0.3, longitude: x + 0.4),
                Coordinate3D(latitude: y + 0.6, longitude: x + 0.2),
            ]
            nodes.append(try #require(MultiPoint(points)))
        }

        let rTree = RTree(nodes)
        let boundingBox = BoundingBox(
            southWest: Coordinate3D(latitude: -2.0, longitude: -2.0),
            northEast: Coordinate3D(latitude: 2.0, longitude: 2.0))

        let treeResults = rTree.search(inBoundingBox: boundingBox)
        let serialResults = rTree.searchSerial(inBoundingBox: boundingBox)
        #expect(treeResults.count == serialResults.count)

        let aroundResults = rTree.search(
            aroundCoordinate: Coordinate3D(latitude: 0.0, longitude: 0.0),
            maximumDistance: 500_000.0)
        let aroundSerial = rTree.searchSerial(
            aroundCoordinate: Coordinate3D(latitude: 0.0, longitude: 0.0),
            maximumDistance: 500_000.0)
        #expect(aroundResults.map(\.object) == aroundSerial.map(\.object))
    }

    // Verifies that around-coordinate search returns an empty result when
    // all objects are outside the maximum distance.
    @Test
    func aroundSearchEmptyResult() async throws {
        var nodes: [Point] = []
        50.times {
            nodes.append(Point(Coordinate3D(
                latitude: Double.random(in: 40.0 ... 50.0),
                longitude: Double.random(in: 40.0 ... 50.0))))
        }

        let rTree = RTree(nodes)
        let center = Coordinate3D(latitude: 0.0, longitude: 0.0)

        let treeResults = rTree.search(aroundCoordinate: center, maximumDistance: 1_000.0)
        let serialResults = rTree.searchSerial(aroundCoordinate: center, maximumDistance: 1_000.0)
        #expect(treeResults.isEmpty)
        #expect(serialResults.isEmpty)

        // Also test with sorted: false
        let unsortedTree = rTree.search(aroundCoordinate: center, maximumDistance: 1_000.0, sorted: false)
        let unsortedSerial = rTree.searchSerial(aroundCoordinate: center, maximumDistance: 1_000.0, sorted: false)
        #expect(unsortedTree.isEmpty)
        #expect(unsortedSerial.isEmpty)
    }

    // Verifies that around-coordinate search with sorted: false produces the same
    // objects as the sorted variant even when falling back to serial search.
    @Test
    func aroundSearchSerialUnsorted() async throws {
        var nodes: [Point] = []
        8.times {
            nodes.append(Point(Coordinate3D(
                latitude: Double.random(in: -10.0 ... 10.0),
                longitude: Double.random(in: -10.0 ... 10.0))))
        }

        let rTree = RTree(nodes, nodeSize: 16)
        let center = Coordinate3D(latitude: 0.0, longitude: 0.0)

        let unsorted = rTree.search(aroundCoordinate: center, maximumDistance: 500_000.0, sorted: false)
        let sorted = rTree.search(aroundCoordinate: center, maximumDistance: 500_000.0, sorted: true)

        #expect(unsorted.count == sorted.count)
        let unsortedObjects = unsorted.map(\.object).sorted { $0.coordinate.longitude < $1.coordinate.longitude }
        let sortedObjects = sorted.map(\.object).sorted { $0.coordinate.longitude < $1.coordinate.longitude }
        #expect(unsortedObjects == sortedObjects)
    }

    // Verifies that for various node sizes, the R-tree search eventually outperforms serial
    // search as the number of objects grows. Scans increasing object counts until tree
    // search is faster, then moves to the next node size.
    @Test(.disabled(if: CIHelper.isRunningInCI, "Skipping intensive test in CI"))
    func nodeSizes() async throws {
        let boundingBox = BoundingBox(
            southWest: Coordinate3D(latitude: 0.0, longitude: 0.0),
            northEast: Coordinate3D(latitude: 5.0, longitude: 5.0))

        for nodeSize in stride(from: 4, through: 256, by: 4) {
            for objectCount in stride(from: nodeSize * 2, to: 5000, by: 20) {
                var nodes: [Point] = []
                objectCount.times {
                    nodes.append(Point(Coordinate3D(
                        latitude: Double.random(in: -30.0 ... 30.0),
                        longitude: Double.random(in: -30.0 ... 30.0))))
                }
                let rTree = RTree(nodes, nodeSize: nodeSize)

                let startTime1 = Date().timeIntervalSinceReferenceDate
                let objects1 = rTree.search(inBoundingBox: boundingBox)
                let timeElapsed1 = Date().timeIntervalSinceReferenceDate - startTime1

                let startTime2 = Date().timeIntervalSinceReferenceDate
                let objects2 = rTree.searchSerial(inBoundingBox: boundingBox)
                let timeElapsed2 = Date().timeIntervalSinceReferenceDate - startTime2

                #expect(objects1.sorted { $0.coordinate.longitude < $1.coordinate.longitude } == objects2.sorted { $0.coordinate.longitude < $1.coordinate.longitude })

                if timeElapsed1 < timeElapsed2 {
                    print("nodeSize=\(nodeSize) crossover at count=\(objectCount)")
                    break
                }
            }
        }
    }

}

// MARK: - Deterministic RNG

/// A simple linear-congruential generator so the benchmarks use reproducible data.
private struct SeededRandomNumberGenerator: RandomNumberGenerator {

    private var state: UInt64

    init(seed: UInt64) {
        state = seed
    }

    mutating func next() -> UInt64 {
        state = 6_364_136_223_846_793_005 &* state &+ 1_442_695_040_888_963_407
        return state
    }

}

// MARK: - Benchmarks

@Suite
struct RTreeBenchmarks {

    private static let iterations: Int = 10

    private static let performanceInput: [Point] = {
        let count = 100_000
        var nodes: [Point] = []
        nodes.reserveCapacity(count)
        var rng = SeededRandomNumberGenerator(seed: 12_345)
        count.times {
            nodes.append(Point(Coordinate3D(
                latitude: Double.random(in: -10.0 ... 10.0, using: &rng),
                longitude: Double.random(in: -10.0 ... 10.0, using: &rng))))
        }
        return nodes
    }()

    private static let performanceSearchBoundingBox: BoundingBox = {
        var rng = SeededRandomNumberGenerator(seed: 67_890)
        var minX = Double.random(in: -10.0 ... 10.0, using: &rng)
        var maxX = Double.random(in: -10.0 ... 10.0, using: &rng)
        var minY = Double.random(in: -10.0 ... 10.0, using: &rng)
        var maxY = Double.random(in: -10.0 ... 10.0, using: &rng)

        if minX > maxX {
            (minX, maxX) = (maxX, minX)
        }
        if minY > maxY {
            (minY, maxY) = (maxY, minY)
        }

        return BoundingBox(
            southWest: Coordinate3D(latitude: minY, longitude: minX),
            northEast: Coordinate3D(latitude: maxY, longitude: maxX))
    }()

    private static let performanceAroundSearchCenter: Coordinate3D = {
        var rng = SeededRandomNumberGenerator(seed: 111_213)
        return Coordinate3D(
            latitude: Double.random(in: -10.0 ... 10.0, using: &rng),
            longitude: Double.random(in: -10.0 ... 10.0, using: &rng))
    }()

    private static func measure(_ name: String, _ block: () -> Void) {
        let clock = ContinuousClock()

        // Warmup
        block()

        var durations: [Duration] = []
        durations.reserveCapacity(iterations)
        for _ in 0 ..< iterations {
            let start = clock.now
            block()
            durations.append(clock.now - start)
        }

        let sorted = durations.sorted()
        let minMs = _milliseconds(sorted.first ?? .zero)
        let medianMs = _milliseconds(sorted[sorted.count / 2])
        let averageMs = durations.reduce(0.0) { $0 + _milliseconds($1) } / Double(iterations)

        print("[RTreeBenchmark] \(name): min=\(_format(minMs))ms median=\(_format(medianMs))ms avg=\(_format(averageMs))ms")
    }

    private static func _milliseconds(_ duration: Duration) -> Double {
        let components = duration.components
        return Double(components.seconds) * 1_000.0 + Double(components.attoseconds) / 1e15
    }

    private static func _format(_ value: Double) -> String {
        String(format: "%.3f", value)
    }

    // Measures R-tree build performance using Hilbert sort.
    @Test(.disabled(if: CIHelper.isRunningInCI, "Skipping performance test in CI"))
    func performanceBuildTreeHilbert() {
        Self.measure("BuildTree/hilbert") {
            _ = RTree(Self.performanceInput, nodeSize: 16, sortOption: .hilbert)
        }
    }

    // Measures R-tree build performance using latitude sort.
    @Test(.disabled(if: CIHelper.isRunningInCI, "Skipping performance test in CI"))
    func performanceBuildTreeLatitude() {
        Self.measure("BuildTree/byLatitude") {
            _ = RTree(Self.performanceInput, nodeSize: 16, sortOption: .byLatitude)
        }
    }

    // Measures R-tree build performance using longitude sort.
    @Test(.disabled(if: CIHelper.isRunningInCI, "Skipping performance test in CI"))
    func performanceBuildTreeLongitude() {
        Self.measure("BuildTree/byLongitude") {
            _ = RTree(Self.performanceInput, nodeSize: 16, sortOption: .byLongitude)
        }
    }

    // Measures R-tree build performance with unsorted input.
    @Test(.disabled(if: CIHelper.isRunningInCI, "Skipping performance test in CI"))
    func performanceBuildTreeUnsorted() {
        Self.measure("BuildTree/unsorted") {
            _ = RTree(Self.performanceInput, nodeSize: 16, sortOption: .unsorted)
        }
    }

    // Measures serial bounding-box query performance on an unsorted R-tree.
    @Test(.disabled(if: CIHelper.isRunningInCI, "Skipping performance test in CI"))
    func performanceQuerySerial() {
        let rTree = RTree(Self.performanceInput, nodeSize: 16, sortOption: .unsorted)
        Self.measure("Query/serial") {
            _ = rTree.searchSerial(inBoundingBox: Self.performanceSearchBoundingBox)
        }
    }

    // Measures Hilbert-sorted R-tree bounding-box query performance.
    @Test(.disabled(if: CIHelper.isRunningInCI, "Skipping performance test in CI"))
    func performanceQueryHilbert() {
        let rTree = RTree(Self.performanceInput, nodeSize: 16, sortOption: .hilbert)
        Self.measure("Query/hilbert") {
            _ = rTree.search(inBoundingBox: Self.performanceSearchBoundingBox)
        }
    }

    // Measures latitude-sorted R-tree bounding-box query performance.
    @Test(.disabled(if: CIHelper.isRunningInCI, "Skipping performance test in CI"))
    func performanceQueryLatitude() {
        let rTree = RTree(Self.performanceInput, nodeSize: 16, sortOption: .byLatitude)
        Self.measure("Query/byLatitude") {
            _ = rTree.search(inBoundingBox: Self.performanceSearchBoundingBox)
        }
    }

    // Measures unsorted R-tree bounding-box query performance.
    @Test(.disabled(if: CIHelper.isRunningInCI, "Skipping performance test in CI"))
    func performanceQueryUnsorted() {
        let rTree = RTree(Self.performanceInput, nodeSize: 16, sortOption: .unsorted)
        Self.measure("Query/unsorted") {
            _ = rTree.search(inBoundingBox: Self.performanceSearchBoundingBox)
        }
    }

    // Measures serial around-coordinate query performance on an unsorted R-tree.
    @Test(.disabled(if: CIHelper.isRunningInCI, "Skipping performance test in CI"))
    func performanceAroundSearchSerial() {
        let maximumDistance = 100_000.0
        let rTree = RTree(Self.performanceInput, nodeSize: 16, sortOption: .unsorted)
        Self.measure("AroundSearch/serial") {
            _ = rTree.searchSerial(aroundCoordinate: Self.performanceAroundSearchCenter, maximumDistance: maximumDistance)
        }
    }

    // Measures Hilbert-sorted R-tree around-coordinate query performance.
    @Test(.disabled(if: CIHelper.isRunningInCI, "Skipping performance test in CI"))
    func performanceAroundSearchHilbert() {
        let maximumDistance = 100_000.0
        let rTree = RTree(Self.performanceInput, nodeSize: 16, sortOption: .hilbert)
        Self.measure("AroundSearch/hilbert") {
            _ = rTree.search(aroundCoordinate: Self.performanceAroundSearchCenter, maximumDistance: maximumDistance)
        }
    }

    // Measures latitude-sorted R-tree around-coordinate query performance.
    @Test(.disabled(if: CIHelper.isRunningInCI, "Skipping performance test in CI"))
    func performanceAroundSearchLatitude() {
        let maximumDistance = 100_000.0
        let rTree = RTree(Self.performanceInput, nodeSize: 16, sortOption: .byLatitude)
        Self.measure("AroundSearch/byLatitude") {
            _ = rTree.search(aroundCoordinate: Self.performanceAroundSearchCenter, maximumDistance: maximumDistance)
        }
    }

    // Measures unsorted R-tree around-coordinate query performance.
    @Test(.disabled(if: CIHelper.isRunningInCI, "Skipping performance test in CI"))
    func performanceAroundSearchUnsorted() {
        let maximumDistance = 100_000.0
        let rTree = RTree(Self.performanceInput, nodeSize: 16, sortOption: .unsorted)
        Self.measure("AroundSearch/unsorted") {
            _ = rTree.search(aroundCoordinate: Self.performanceAroundSearchCenter, maximumDistance: maximumDistance)
        }
    }

}
