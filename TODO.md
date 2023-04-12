# TODO

- Fix some TODOs in the code
- Port more packages
- Add more tests

## TODOs from the GeoJSON spec: https://tools.ietf.org/html/rfc7946

### 3.1.9.  Antimeridian Cutting

```
In representing Features that cross the antimeridian,
interoperability is improved by modifying their geometry.  Any
geometry that crosses the antimeridian SHOULD be represented by
cutting it in two such that neither part's representation crosses the
antimeridian.

For example, a line extending from 45 degrees N, 170 degrees E across
the antimeridian to 45 degrees N, 170 degrees W should be cut in two
and represented as a MultiLineString.

{
    "type": "MultiLineString",
    "coordinates": [
    [
    [170.0, 45.0], [180.0, 45.0]
    ], [
    [-180.0, 45.0], [-170.0, 45.0]
    ]
    ]
}

A rectangle extending from 40 degrees N, 170 degrees E across the
antimeridian to 50 degrees N, 170 degrees W should be cut in two and
represented as a MultiPolygon.

{
    "type": "MultiPolygon",
    "coordinates": [
    [
    [
    [180.0, 40.0], [180.0, 50.0], [170.0, 50.0],
    [170.0, 40.0], [180.0, 40.0]
    ]
    ],
    [
    [
    [-170.0, 40.0], [-170.0, 50.0], [-180.0, 50.0],
    [-180.0, 40.0], [-170.0, 40.0]
    ]
    ]
    ]
}
````

### 5.  Bounding Box

```
Example of a 3D bbox member with a depth of 100 meters:

{
    "type": "FeatureCollection",
    "bbox": [100.0, 0.0, -100.0, 105.0, 1.0, 0.0],
    "features": [
    //...
    ]
}

A rectangle extending from 40 degrees N, 170 degrees E across the
antimeridian to 50 degrees N, 170 degrees W should be cut in two and
represented as a MultiPolygon.

{
    "type": "MultiPolygon",
    "coordinates": [
    [
    [
    [180.0, 40.0], [180.0, 50.0], [170.0, 50.0],
    [170.0, 40.0], [180.0, 40.0]
    ]
    ],
    [
    [
    [-170.0, 40.0], [-170.0, 50.0], [-180.0, 50.0],
    [-180.0, 40.0], [-170.0, 40.0]
    ]
    ]
    ]
}
```

### 5.3.  The Poles

```
A bounding box that contains the North Pole extends from a southwest
corner of "minlat" degrees N, 180 degrees W to a northeast corner of
90 degrees N, 180 degrees E.  Viewed on a globe, this bounding box
approximates a spherical cap bounded by the "minlat" circle of
latitude.

"bbox": [-180.0, minlat, 180.0, 90.0]

A bounding box that contains the South Pole extends from a southwest
corner of 90 degrees S, 180 degrees W to a northeast corner of
"maxlat" degrees S, 180 degrees E.

"bbox": [-180.0, -90.0, 180.0, maxlat]

A bounding box that just touches the North Pole and forms a slice of
an approximate spherical cap when viewed on a globe extends from a
southwest corner of "minlat" degrees N and "westlon" degrees E to a
northeast corner of 90 degrees N and "eastlon" degrees E.

"bbox": [westlon, minlat, eastlon, 90.0]

Similarly, a bounding box that just touches the South Pole and forms
a slice of an approximate spherical cap when viewed on a globe has
the following representation in GeoJSON.

"bbox": [westlon, -90.0, eastlon, maxlat]

Implementers MUST NOT use latitude values greater than 90 or less
than -90 to imply an extent that is not a spherical cap.
```
