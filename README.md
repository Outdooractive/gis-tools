# GISTools

GIS tools for Swift, including a GeoJSON implementation and many algorithms ported from https://github.com/Turfjs/turf/tree/master/packages (https://turfjs.org)

## Notes

This package makes some assumptions about what is equal, i.e. coordinates that are inside of `1e-10` degrees are regarded as equal. See `GISTool.equalityDelta`.

## Installation with Swift Package Manager

```swift
dependencies: [
    .package(url: "https://github.com/Outdooractive/gis-tools", from: "0.2.2"),
],
targets: [
    .target(name: "MyTarget", dependencies: [
        .product(name: "GISTools", package: "gis-tools"),
    ]),
]
```

## Features

TODO

## Usage

```swift
import GISTools
```

## Contributing

Please create an issue or open a pull request with a fix

## License

MIT

## Author

Thomas Rasch, OutdoorActive
