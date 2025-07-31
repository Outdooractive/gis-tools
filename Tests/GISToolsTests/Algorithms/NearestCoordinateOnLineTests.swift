@testable import GISTools
import Testing

struct NearestCoordinateOnLineTests {

    @Test
    func firstPoint() async throws {
        let lineString = try  #require(LineString([
            Coordinate3D(latitude: 37.720033, longitude: -122.457175),
            Coordinate3D(latitude: 37.718242, longitude: -122.457175),
        ]))
        let coordinate = Coordinate3D(latitude: 37.720033, longitude: -122.457175)

        let nearestCoordinate = try #require(lineString.nearestCoordinateOnLine(from: coordinate)?.coordinate)
        #expect(nearestCoordinate == lineString.coordinates[0])
    }

    @Test
    func pointsBehindFirstPoint() async throws {
        let lineString = try #require(LineString([
            Coordinate3D(latitude: 37.720033, longitude: -122.457175),
            Coordinate3D(latitude: 37.718242, longitude: -122.457175),
        ]))
        let coordinates = [
            Coordinate3D(latitude: 37.720093, longitude: -122.457175),
            Coordinate3D(latitude: 37.820093, longitude: -122.457175),
            Coordinate3D(latitude: 37.720093, longitude: -122.457165),
            Coordinate3D(latitude: 37.720093, longitude: -122.455165),
        ]

        for coordinate in coordinates {
            let nearestCoordinate = try #require(lineString.nearestCoordinateOnLine(from: coordinate)?.coordinate)
            #expect(nearestCoordinate == lineString.coordinates[0])
        }
    }

    @Test
    func pointsInFrontOfLastPoint() async throws {
        let lineString = try #require(LineString([
            Coordinate3D(latitude: 37.721259, longitude: -122.456161),
            Coordinate3D(latitude: 37.720033, longitude: -122.457175),
            Coordinate3D(latitude: 37.718242, longitude: -122.457175),
        ]))
        let coordinates = [
            Coordinate3D(latitude: 37.718140, longitude: -122.456960),
            Coordinate3D(latitude: 37.718132, longitude: -122.457363),
            Coordinate3D(latitude: 37.717979, longitude: -122.457309),
            Coordinate3D(latitude: 37.717045, longitude: -122.457180),
        ]

        for coordinate in coordinates {
            let nearestCoordinate = try #require(lineString.nearestCoordinateOnLine(from: coordinate)?.coordinate)
            #expect(nearestCoordinate == lineString.coordinates[2])
        }
    }

    @Test
    func pointsOnJoints() async throws {
        let lines: [LineString] = [
            try #require(LineString([
                Coordinate3D(latitude: 37.721259, longitude: -122.456161),
                Coordinate3D(latitude: 37.720033, longitude: -122.457175),
                Coordinate3D(latitude: 37.718242, longitude: -122.457175),
            ])),
            try #require(LineString([
                Coordinate3D(latitude: 31.728167, longitude: 26.279296),
                Coordinate3D(latitude: 32.694865, longitude: 21.796875),
                Coordinate3D(latitude: 29.993002, longitude: 18.808593),
                Coordinate3D(latitude: 33.137551, longitude: 12.919921),
                Coordinate3D(latitude: 35.603718, longitude: 10.195312),
                Coordinate3D(latitude: 36.527294, longitude: 4.921875),
                Coordinate3D(latitude: 36.527294, longitude: -1.669921),
                Coordinate3D(latitude: 34.741612, longitude: -5.449218),
                Coordinate3D(latitude: 32.990235, longitude: -8.789062),
            ])),
            try #require(LineString([
                Coordinate3D(latitude: 51.522042, longitude: -0.109198),
                Coordinate3D(latitude: 51.521942, longitude: -0.109230),
                Coordinate3D(latitude: 51.521862, longitude: -0.109165),
                Coordinate3D(latitude: 51.521775, longitude: -0.109047),
                Coordinate3D(latitude: 51.521601, longitude: -0.108865),
                Coordinate3D(latitude: 51.521381, longitude: -0.108747),
                Coordinate3D(latitude: 51.520687, longitude: -0.108554),
                Coordinate3D(latitude: 51.520279, longitude: -0.108436),
                Coordinate3D(latitude: 51.519952, longitude: -0.108393),
                Coordinate3D(latitude: 51.519578, longitude: -0.108178),
                Coordinate3D(latitude: 51.519285, longitude: -0.108146),
                Coordinate3D(latitude: 51.518624, longitude: -0.107899),
                Coordinate3D(latitude: 51.517782, longitude: -0.107599),
            ])),
        ]

        for line in lines {
            for coordinate in line.coordinates {
                let nearestCoordinate = try #require(line.nearestCoordinateOnLine(from: coordinate)?.coordinate)
                #expect(nearestCoordinate == coordinate)
            }
        }
    }

    @Test
    func pointAlongLine() async throws {
        let lineString = try #require(LineString([
            Coordinate3D(latitude: 37.720033, longitude: -122.457175),
            Coordinate3D(latitude: 37.718242, longitude: -122.457175),
        ]))
        let coordinate = lineString.coordinateAlong(distance: 20.0)
        let nearestCoordinate = try #require(lineString.nearestCoordinateOnLine(from: coordinate)?.coordinate)
        #expect(coordinate == nearestCoordinate)
    }

    @Test
    func pointsOnSidesOfLines() async throws {
        let lineString = try #require(LineString([
            Coordinate3D(latitude: 37.721259, longitude: -122.456161),
            Coordinate3D(latitude: 37.718242, longitude: -122.457175),
        ]))
        let coordinates = [
            Coordinate3D(latitude: 37.718810, longitude: -122.457025),
            Coordinate3D(latitude: 37.719235, longitude: -122.457336),
            Coordinate3D(latitude: 37.720270, longitude: -122.456864),
            Coordinate3D(latitude: 37.720635, longitude: -122.456520),
        ]

        for coordinate in coordinates {
            let nearestCoordinate = try #require(lineString.nearestCoordinateOnLine(from: coordinate)?.coordinate)
            #expect(nearestCoordinate != lineString.coordinates[0])
            #expect(nearestCoordinate != lineString.coordinates[1])
        }
    }

    @Test
    func line() async throws {
        let lineString = try #require(LineString([
            Coordinate3D(latitude: 22.466878, longitude: -97.881317),
            Coordinate3D(latitude: 22.299261, longitude: -97.867584),
            Coordinate3D(latitude: 22.17596, longitude: -97.820892),
            Coordinate3D(latitude: 21.87042, longitude: -97.619019),
        ]))
        let coordinate = Coordinate3D(latitude: 22.26241, longitude: -97.879944)
        let result = Coordinate3D(latitude: 22.271125217965366, longitude: -97.8569294559593)
        let nearestCoordinate = try #require(lineString.nearestCoordinateOnLine(from: coordinate)?.coordinate)
        #expect(nearestCoordinate == result)
    }

}
