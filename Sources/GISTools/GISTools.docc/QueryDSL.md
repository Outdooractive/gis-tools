# Query DSL

``QueryParser`` evaluates property and spatial expressions against ``Feature``
values. It accepts a natural infix syntax and returns a Boolean result for each
feature.

## Parse and evaluate

```swift
if let parser = QueryParser(string: ".highway == primary and .name =~ '^Main'") {
    let matches = parser.evaluate(on: feature)
}
```

`FeatureCollection.query(term:)` and `Array<Feature>.query(term:)` provide a
convenient filter API:

```swift
if let hospitals = featureCollection.query(term: ".class == 'hospital'") {
    print(hospitals.features.count)
}

let nearby = features.query(
    term: ".name =~ /hospital/i and near(48.85, 2.35, 1000)") ?? []
```

## Property access

Properties are prefixed with `.`:

| Query | Meaning |
|---|---|
| `.name` | Property `name` exists and is truthy |
| `.foo.bar` | Nested property `foo` → `bar` |
| `."foo.bar"` | Property whose key contains a dot |
| `.foo.[0]` | First element of an array property |
| `.some.0` | Shorthand array access |

## Comparisons

| Operator | Meaning | Example |
|---|---|---|
| `==` | Equal | `.value == 1` |
| `!=` | Not equal | `.value != 2` |
| `>` | Greater than | `.value > 0` |
| `>=` | Greater than or equal | `.value >= 1` |
| `<` | Less than | `.value < 2` |
| `<=` | Less than or equal | `.value <= 1` |
| `=~` | Regular expression | `.name =~ /^Main/i` |
| `=*` | Contains | `.name =* "ain"` |
| `=^` | Starts with | `.name =^ "Mai"` |
| `=$` | Ends with | `.name =$ "ain"` |

Numeric comparisons coerce compatible integer and floating-point values.

## Set membership

```text
.class in ["primary", "secondary"]
.value in [1, 3, 5]
```

## Boolean logic and grouping

| Operator | Meaning | Example |
|---|---|---|
| `and` | Logical AND | `.a == 1 and .b == 2` |
| `or` | Logical OR | `.a == 1 or .b == 1` |
| `not` | Logical NOT | `.a not` |
| `exists` | Truthy check | `.a exists` |

Parentheses override left-to-right evaluation and can be nested:

```text
(.name == "Berlin" or .name == "Paris") and .population > 100000
not (.bridge exists) or .oneway == true
```

## Spatial predicates

| Predicate | Syntax | Meaning |
|---|---|---|
| `near` | `near(latitude, longitude, tolerance)` | Centroid is within `tolerance` meters |
| `within` | `within(minLon, minLat, maxLon, maxLat)` | Bounding box is fully inside the rectangle |
| `intersects` | `intersects(minLon, minLat, maxLon, maxLat)` | Geometry intersects the rectangle |

Spatial predicates use the feature's projection and bounding box; calculate
the bounding box before querying when it is not part of the source data.

## Next steps

- <doc:GeoJSONAndCoders> for feature construction and parsing.
- <doc:PerformanceAndMemory> for index and prepared-geometry advice.
