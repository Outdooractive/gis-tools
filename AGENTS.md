# AGENTS.md

# GISTools — Swift geospatial library

A Swift package for GIS operations on GeoJSON geometries.
Supports EPSG:4326 (WGS84), EPSG:3857 (Web Mercator), EPSG:4978 (ECEF),
and "noSRID". All coordinates use `Coordinate3D` which stores
latitude/longitude directly and provides `x`/`y` aliases. Distances default to
Haversine (4326) or Euclidean (3857/4978/noSRID).

Key areas:
- **Boolean predicates**: contains, covers, intersects, crosses, touches, etc.
- **Overlay operations**: union, intersection, difference, symmetric difference
- **Simplification**: Douglas-Peucker, Visvalingam-Whyatt, topology-preserving
- **Grid generation**: hex, rectangle, triangle, square, point
- **Geodesic**: distance, bearing, destination, rhumb line, midpoint
- **Polygon ops**: buffer, convex/concave hull, Voronoi, tesselate, Minkowski
- **Cleanup**: clean, makeValid, kinks, unkink, truncate, snapToGrid
- **Coverage**: unaryUnion, coverageUnion, coverageIsValid, coverageSimplify
- **Antimeridian crossing**: cutAtAntimeridian, crossesAntimeridian on all types

## Swift instructions

- DO USE idomatic Swift 6, at least version 6.1
- DO write tests for everything you do, use Swift Testing (`import Testing`), not XCTest
- DO ASK if anything is unclear, or you need a decision
- DO add proper Swift DocC code documentation to your code
- DO NOT introduce third-party frameworks without asking first
- AVOID force unwraps and force `try` unless it is unrecoverable
- Assume strict Swift concurrency rules are being applied

## Code style conventions

### Spacing

- 4-space indentation, no tabs
- Semicolons: A line with a semicolon is probably a two-liner.
- Commas: Left-hugging, space follows. `x, y`
- Generic parameters: Add spacing after the comma. `Type<T, U>`
- Braces: Always with a space on the inside. `{ get set }`
- Binary operators: add single-space padding before and after for all binary operators. `a + (b * c), a + b * c, or a + b * c`
    - Extra note: Use parenthesis in mathematical expressions to ease understanding even if not necessary. `a + (b * c)`
- Return arrow tokens: Spaces on both sides. `f() -> T`
- Ranges: prefer spaces on both sides. `1 ... 3, 1 ..< 4`
- Unterminated Ranges: Omit spacing. `1...`
- Empty constructs: No internal spaces. `[], [:], {}, f()`
- Trailing closure: Add a space before the opening brace. `function() { ... }`
- Functional closure: Trim spaces before opening parenthesis. `compactMap({ $0 })`
- Comments: Add single-space padding between comment delimiters and text. `// comment`, `/* comment */`
- Trailing whitespace: Never. Ever.
- Last file line: End each file with a single new line.

### General

- Multiple `if` conditions should be separated by `,`, not `&&`. Example: `if a==1, b==2 {}`.
- Use `x.isNotEmpty` (defined in a local extension) instead of `!x.isEmpty`.

### Colon style

Use left-hugging colons, with a space after the colon:
- `let dict = ["a": 1, "b": 2]`
- `let x: [String: String] = ["key": "value"]`
- `let y = foo(param1: value1, param2: value2)`
- `func bar<T: Hashable>(a: T) -> Void {}`
- `case a, b:`
- `class DerivedClass: ParentClass ...`

Don't use left-hugging colons in ternary expressions or in other places where they confuse the compiler:
- `let result = booleanCondition ? value1 : value2`

Skip spaces for empty constructors (see above):
- `[]`, `[:]`

### Ternary expressions

- Keep where short ternary expressions on one line:
`let result = booleanCondition ? value1 : value2`

- Split longer ternary expressions into three lines:
```swift
let result = booleanCondition
    ? value1
    : value2
```

Note that `?` and `:` are aligned.

### Attributes

Always place attributes (like `@objc`, `@discardableResult`) on their own line before the function declaration:
```swift
@discardableResult
func insert(...)
```

### Number Literals

- Use three-place underscore chunking for decimal numbers. `1_000_000`
- Use two-place underscore chunking for hex numbers. `FF_AB_01`
- Always add the fraction for floating-point numbers. `1.0`, not `1`

### Brace style

Put `else` on an extra line.

```swift
if let value = key {
    // ...do something
}
else {
    // ...do something else
}
```

### Code organization

- `// MARK:` and `// MARK: -` to organize type extensions into logical groups
- `PascalCase` for types and type aliases, `camelCase` for everything else (properties, methods, enum cases, constants)
- `struct` by default, `class` only when needed (reference semantics)
- `Sendable` conformance on all model types
- `guard let` / `if let` with early returns for failable initializers and optional handling
- Extensions to group related functionality per type (one extension per concern, e.g., `Equatable`, `Projection`, `JsonConvertible`)
- One file per type/algorithm, named `TypeName.swift` or `FunctionName.swift`
- One test struct per algorithm/type (e.g., `struct DistanceTests`)
- Key path expressions (`\.property`) over closures where possible

### Argument wrapping

If a method has ≤3 parameters and no return value, or ≤2 parameters and a return value, put the entire signature on one line (exception: line exceeds 80 characters). Otherwise, split parameters one per line and put the opening brace `{` on its own line.

  ```swift
  // One line (≤2 params + return, ≤80 chars)
  public func intersects(_ other: GeoJson) -> Bool {
      !isDisjoint(with: other)
  }

  // Multi-line (>2 params + return → one per line, brace on own line)
  public func buffered(
      by distance: Double,
      lineEndStyle: BufferLineEndStyle = .round,
      unionType: BufferUnionType = .individual,
      steps: Int = 64
  ) -> MultiPolygon? {

  // 80-char exception: one-line form too long → multi-line
  public func contains(
      _ coordinate: Coordinate3D,
      ignoringBoundary: Bool = false
  ) -> Bool {
  ```

## General instructions

- DO NOT take any shortcuts while implementing an algorithm. Correctness is the highest priority
- DO NOT commit changes unless the user tells you to do so, ALWAYS let the user review your changes
- DO NOT create free functions (un-namespaced top-level functions). Always use a `private enum` namespace or extensions on existing types.
- Code MUST compile cleanly, with no warnings
- New algorithms and bug fixes MUST include tests for all projections (EPSG:4326, EPSG:3857, EPSG:4978, noSRID)
- Antimeridian-crossing geometries MUST be tested in all projections where the concept applies (EPSG:4326 natively, EPSG:3857 and EPSG:4978 via projected coordinates)
- The result of an algorithm MUST be in the same projection as the input, where it makes sense
- Use written-out decimal numbers (e.g., `0.0000000001`) instead of scientific notation (`1e-10`)
- Use ``GISTool`` constants (``equalityDelta``, ``intersectionEpsilon``, ``determinantEpsilon``) instead of hardcoded epsilon values
