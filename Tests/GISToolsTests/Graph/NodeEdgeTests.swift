#if canImport(CoreLocation)
import CoreLocation
#endif
import Foundation
@testable import GISTools
import Testing

/// ``Node`` and ``Edge`` creation and identity tests.
struct NodeEdgeTests {

    @Test
    func nodeCreation() {
        let coord = Coordinate3D(latitude: 10.0, longitude: 20.0)
        let node = Node(index: 0, coordinate: coord)
        #expect(node.index == 0)
        #expect(node.coordinate == coord)
        #expect(node == Node(index: 0, coordinate: coord))
    }

    @Test
    func nodeHashable() {
        let a = Node(index: 0, coordinate: Coordinate3D(latitude: 10.0, longitude: 20.0))
        let b = Node(index: 0, coordinate: Coordinate3D(latitude: 10.0, longitude: 20.0))
        let c = Node(index: 1, coordinate: Coordinate3D(latitude: 10.0, longitude: 20.0))
        #expect(a == b)
        #expect(a != c)
        #expect(Set([a, b, c]).count == 2)
    }

    @Test
    func edgeCreation() {
        let from = Node(index: 0, coordinate: Coordinate3D(latitude: 10.0, longitude: 20.0))
        let to = Node(index: 1, coordinate: Coordinate3D(latitude: 10.1, longitude: 20.1))
        let edge = Edge(from: from, to: to)
        #expect(edge.from.index == 0)
        #expect(edge.to.index == 1)
        #expect(edge.feature == nil)
        #expect(edge.isDirected == false)
        #expect(edge.weight > 0)
    }

    @Test
    func edgeWithFeature() {
        let from = Node(index: 0, coordinate: Coordinate3D(latitude: 10.0, longitude: 20.0))
        let to = Node(index: 1, coordinate: Coordinate3D(latitude: 10.1, longitude: 20.1))
        let feature = Feature(LineString([from.coordinate, to.coordinate])!)
        let edge = Edge(from: from, to: to, feature: feature)
        #expect(edge.feature != nil)
    }

    @Test
    func edgeWeightIsDistance() {
        let from = Node(index: 0, coordinate: Coordinate3D(latitude: 10.0, longitude: 20.0))
        let to = Node(index: 1, coordinate: Coordinate3D(latitude: 10.0, longitude: 20.1))
        let edge = Edge(from: from, to: to)
        #expect(edge.weight > 0.0)
    }

    @Test
    func edgeHashable() {
        let a = Node(index: 0, coordinate: Coordinate3D(latitude: 10.0, longitude: 20.0))
        let b = Node(index: 1, coordinate: Coordinate3D(latitude: 10.1, longitude: 20.1))
        let e1 = Edge(from: a, to: b)
        let e2 = Edge(from: a, to: b)
        let e3 = Edge(from: b, to: a)
        #expect(e1 == e2)
        #expect(e1 != e3)
        #expect(Set([e1, e2, e3]).count == 2)
    }

    @Test
    func edgeDirectedEquality() {
        let a = Node(index: 0, coordinate: Coordinate3D(latitude: 10.0, longitude: 20.0))
        let b = Node(index: 1, coordinate: Coordinate3D(latitude: 10.1, longitude: 20.1))
        let undirected = Edge(from: a, to: b, isDirected: false)
        let directed = Edge(from: a, to: b, isDirected: true)
        #expect(undirected != directed)
    }

}