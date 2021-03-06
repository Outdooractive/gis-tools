[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FOutdooractive%2Fgis-tools%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/Outdooractive/gis-tools)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FOutdooractive%2Fgis-tools%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/Outdooractive/gis-tools)

# GISTools

GIS tools for Swift, including a GeoJSON implementation and many algorithms ported from https://github.com/Turfjs/turf/tree/master/packages (https://turfjs.org)

## Notes

This package makes some assumptions about what is equal, i.e. coordinates that are inside of `1e-10` degrees are regarded as equal. See `GISTool.equalityDelta`.

## Installation with Swift Package Manager

```swift
dependencies: [
    .package(url: "https://github.com/Outdooractive/gis-tools", from: "0.3.4"),
],
targets: [
    .target(name: "MyTarget", dependencies: [
        .product(name: "GISTools", package: "gis-tools"),
    ]),
]
```

## Features

- Supports the full GeoJSON standard, with some exceptions (see `TODO.md`)

## Usage

```swift
import GISTools

var feature = Feature(Point(Coordinate3D(latitude: 3.870163, longitude: 11.518585)))
feature.properties = [
    "test": 1,
    "test2": 5.567,
    "test3": [1, 2, 3],
    "test4": [
        "sub1": 1,
        "sub2": 2
    ]
]
```

See the tests for more examples.

## Contributing

Please create an issue or open a pull request with a fix

## License

MIT

## Author

Thomas Rasch, Outdooractive
