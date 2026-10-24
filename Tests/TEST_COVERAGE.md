# Test coverage and fixture audit

Generated from `swift test --traits EnableGraphAPI --enable-code-coverage`
with SwiftPM's code-coverage JSON. The figures are line coverage for
`Sources/GISTools`; test sources are excluded from the per-file table.

## Summary

- Source files: **231**
- Weighted source line coverage: **88.27%**
- Status: **145 covered** (≥90%), **68 partial** (50–90%),
  **18 low** (1–50%), **0 untested** (0%).
- Every source file below has an explicit status and its direct (or indirect)
  test file.
- The remaining low-coverage algorithms are covered by the open follow-up
  issues listed in the `Gap` column; they are not silently ignored.
- The CI coverage floor is **87.5%** weighted line coverage.

## Per-file test status

| Source | Lines | Coverage | Status | Direct tests | Gap |
| --- | ---: | ---: | --- | --- | --- |
| `Sources/GISTools/Algorithms/Along.swift` | 100 | 94.00% | Covered | Algorithms/AlongTests.swift |  |
| `Sources/GISTools/Algorithms/AntimeridianCutting.swift` | 415 | 91.81% | Covered | Algorithms/AntimeridianCuttingTests.swift |  |
| `Sources/GISTools/Algorithms/Area.swift` | 135 | 97.78% | Covered | Algorithms/AreaTests.swift |  |
| `Sources/GISTools/Algorithms/Bearing.swift` | 61 | 95.08% | Covered | Algorithms/BearingTests.swift |  |
| `Sources/GISTools/Algorithms/BezierSpline.swift` | 174 | 90.80% | Covered | Algorithms/BezierSplineTests.swift | #336 |
| `Sources/GISTools/Algorithms/BooleanClockwise.swift` | 47 | 100.00% | Covered | Algorithms/BooleanClockwiseTests.swift |  |
| `Sources/GISTools/Algorithms/BooleanConcave.swift` | 57 | 100.00% | Covered | Algorithms/BooleanConcaveTests.swift |  |
| `Sources/GISTools/Algorithms/BooleanContains.swift` | 218 | 77.52% | Partial | Algorithms/BooleanContainsTests.swift | #339 |
| `Sources/GISTools/Algorithms/BooleanCovers.swift` | 435 | 85.75% | Partial | Algorithms/BooleanCoversTests.swift | #339 |
| `Sources/GISTools/Algorithms/BooleanCrosses.swift` | 193 | 98.96% | Covered | Algorithms/BooleanCrossesTests.swift |  |
| `Sources/GISTools/Algorithms/BooleanDisjoint.swift` | 235 | 87.23% | Partial | Algorithms/BooleanDisjointTests.swift | #339 |
| `Sources/GISTools/Algorithms/BooleanEquals.swift` | 89 | 92.13% | Covered | Algorithms/BooleanEqualsTests.swift |  |
| `Sources/GISTools/Algorithms/BooleanIntersects.swift` | 9 | 100.00% | Covered | Algorithms/BooleanIntersectsTests.swift |  |
| `Sources/GISTools/Algorithms/BooleanOverlap.swift` | 186 | 81.72% | Partial | Algorithms/BooleanOverlapTests.swift |  |
| `Sources/GISTools/Algorithms/BooleanParallel.swift` | 62 | 96.77% | Covered | Algorithms/BooleanParallelTests.swift |  |
| `Sources/GISTools/Algorithms/BooleanPointInPolygon.swift` | 474 | 90.30% | Covered | Algorithms/BooleanPointInPolygonTests.swift |  |
| `Sources/GISTools/Algorithms/BooleanPointOnLine.swift` | 44 | 100.00% | Covered | Algorithms/BooleanPointOnLineTests.swift | #338 |
| `Sources/GISTools/Algorithms/BooleanTouches.swift` | 544 | 64.52% | Partial | Algorithms/BooleanTouchesTests.swift |  |
| `Sources/GISTools/Algorithms/BooleanWithin.swift` | 20 | 95.00% | Covered | Algorithms/BooleanWithinTests.swift |  |
| `Sources/GISTools/Algorithms/Boundary.swift` | 151 | 86.09% | Partial | Algorithms/BoundaryTests.swift |  |
| `Sources/GISTools/Algorithms/BoundingBoxClip.swift` | 384 | 79.69% | Partial | Algorithms/BoundingBoxClipTests.swift | #340 / #341 |
| `Sources/GISTools/Algorithms/BoundingBoxPosition.swift` | 42 | 100.00% | Covered | Algorithms/BoundingBoxPositionTests.swift | #338 |
| `Sources/GISTools/Algorithms/Buffer.swift` | 847 | 84.89% | Partial | Algorithms/BufferTests.swift | #340 / #341 |
| `Sources/GISTools/Algorithms/Center.swift` | 460 | 93.91% | Covered | Algorithms/CenterTests.swift |  |
| `Sources/GISTools/Algorithms/Circle.swift` | 14 | 100.00% | Covered | Algorithms/CircleTests.swift |  |
| `Sources/GISTools/Algorithms/Clean.swift` | 168 | 86.90% | Partial | Algorithms/CleanTests.swift |  |
| `Sources/GISTools/Algorithms/ClosestPoint.swift` | 41 | 97.56% | Covered | Algorithms/ClosestPointTests.swift |  |
| `Sources/GISTools/Algorithms/Clusters.swift` | 373 | 96.51% | Covered | Algorithms/ClustersTests.swift |  |
| `Sources/GISTools/Algorithms/Collect.swift` | 34 | 100.00% | Covered | Algorithms/CollectTests.swift |  |
| `Sources/GISTools/Algorithms/ConcaveHull.swift` | 337 | 80.71% | Partial | Algorithms/ConcaveHullTests.swift | #336 |
| `Sources/GISTools/Algorithms/Conversions.swift` | 104 | 91.35% | Covered | — |  |
| `Sources/GISTools/Algorithms/ConvexHull.swift` | 115 | 98.26% | Covered | Algorithms/ConvexHullTests.swift |  |
| `Sources/GISTools/Algorithms/Densify.swift` | 130 | 81.54% | Partial | Algorithms/DensifyTests.swift |  |
| `Sources/GISTools/Algorithms/Destination.swift` | 57 | 77.19% | Partial | Algorithms/DestinationTests.swift |  |
| `Sources/GISTools/Algorithms/Difference.swift` | 61 | 83.61% | Partial | Algorithms/DifferenceTests.swift |  |
| `Sources/GISTools/Algorithms/Dissolve.swift` | 78 | 97.44% | Covered | Algorithms/DissolveTests.swift |  |
| `Sources/GISTools/Algorithms/Distance.swift` | 77 | 85.71% | Partial | Algorithms/DistanceTests.swift |  |
| `Sources/GISTools/Algorithms/Ellipse.swift` | 33 | 100.00% | Covered | Algorithms/EllipseTests.swift |  |
| `Sources/GISTools/Algorithms/EnumerateCoordinates.swift` | 24 | 100.00% | Covered | Algorithms/EnumerateCoordinatesTests.swift |  |
| `Sources/GISTools/Algorithms/EnumerateProperties.swift` | 27 | 92.59% | Covered | Algorithms/EnumeratePropertiesTests.swift |  |
| `Sources/GISTools/Algorithms/Flatten.swift` | 137 | 81.02% | Partial | Algorithms/FlattenTests.swift |  |
| `Sources/GISTools/Algorithms/Flip.swift` | 29 | 72.41% | Partial | Algorithms/FlipTests.swift |  |
| `Sources/GISTools/Algorithms/FrechetDistance.swift` | 58 | 94.83% | Covered | Algorithms/FrechetDistanceTests.swift |  |
| `Sources/GISTools/Algorithms/GreatCircle.swift` | 83 | 93.98% | Covered | Algorithms/GreatCircleTests.swift |  |
| `Sources/GISTools/Algorithms/HausdorffDistance.swift` | 62 | 96.77% | Covered | Algorithms/HausdorffDistanceTests.swift |  |
| `Sources/GISTools/Algorithms/HexGrid.swift` | 204 | 94.61% | Covered | Algorithms/HexGridTests.swift |  |
| `Sources/GISTools/Algorithms/Intersection.swift` | 62 | 90.32% | Covered | Algorithms/IntersectionTests.swift |  |
| `Sources/GISTools/Algorithms/IsoLines.swift` | 262 | 89.69% | Partial | Algorithms/IsoLinesTests.swift |  |
| `Sources/GISTools/Algorithms/Kinks.swift` | 593 | 93.42% | Covered | Algorithms/KinksTests.swift | #337 |
| `Sources/GISTools/Algorithms/Length.swift` | 19 | 100.00% | Covered | Algorithms/LengthTests.swift |  |
| `Sources/GISTools/Algorithms/LineArc.swift` | 42 | 100.00% | Covered | Algorithms/LineArcTests.swift |  |
| `Sources/GISTools/Algorithms/LineChunk.swift` | 89 | 88.76% | Partial | Algorithms/LineChunkTests.swift | #337 |
| `Sources/GISTools/Algorithms/LineIntersection.swift` | 184 | 97.28% | Covered | Algorithms/LineIntersectionTests.swift | #338 |
| `Sources/GISTools/Algorithms/LineMerge.swift` | 314 | 88.22% | Partial | Algorithms/LineMergeTests.swift | #332 |
| `Sources/GISTools/Algorithms/LineOffset.swift` | 154 | 99.35% | Covered | Algorithms/LineOffsetTests.swift | #337 |
| `Sources/GISTools/Algorithms/LineOverlap.swift` | 214 | 89.25% | Partial | Algorithms/LineOverlapTests.swift | #337 |
| `Sources/GISTools/Algorithms/LineSegments.swift` | 75 | 98.67% | Covered | Algorithms/LineSegmentsTests.swift | #337 |
| `Sources/GISTools/Algorithms/LineSlice.swift` | 85 | 97.65% | Covered | Algorithms/LineSliceTests.swift | #337 |
| `Sources/GISTools/Algorithms/LineSliceAlong.swift` | 107 | 90.65% | Covered | Algorithms/LineSliceAlongTests.swift | #337 |
| `Sources/GISTools/Algorithms/LineSplit.swift` | 67 | 98.51% | Covered | Algorithms/LineSplitTests.swift |  |
| `Sources/GISTools/Algorithms/MakeValid.swift` | 111 | 95.50% | Covered | Algorithms/MakeValidTests.swift | #337 |
| `Sources/GISTools/Algorithms/Mask.swift` | 99 | 94.95% | Covered | Algorithms/MaskTests.swift | #340 / #341 |
| `Sources/GISTools/Algorithms/MaximumInscribedCircle.swift` | 44 | 84.09% | Partial | Algorithms/MaximumInscribedCircleTests.swift |  |
| `Sources/GISTools/Algorithms/MidPoint.swift` | 30 | 90.00% | Covered | Algorithms/MidPointTests.swift |  |
| `Sources/GISTools/Algorithms/MinimumBoundingCircle.swift` | 159 | 84.28% | Partial | Algorithms/MinimumBoundingCircleTests.swift |  |
| `Sources/GISTools/Algorithms/MinkowskiSum.swift` | 173 | 95.95% | Covered | Algorithms/MinkowskiSumTests.swift | #331 |
| `Sources/GISTools/Algorithms/NearestPoint.swift` | 49 | 61.22% | Partial | Algorithms/NearestPointTests.swift |  |
| `Sources/GISTools/Algorithms/NearestPointOnFeature.swift` | 105 | 82.86% | Partial | Algorithms/NearestPointOnFeatureTests.swift |  |
| `Sources/GISTools/Algorithms/NearestPointOnLine.swift` | 133 | 78.95% | Partial | — | #338 |
| `Sources/GISTools/Algorithms/NearestPointToLine.swift` | 22 | 100.00% | Covered | Algorithms/NearestPointToLineTests.swift |  |
| `Sources/GISTools/Algorithms/OrientedEnvelope.swift` | 139 | 96.40% | Covered | Algorithms/OrientedEnvelopeTests.swift |  |
| `Sources/GISTools/Algorithms/Overlay.swift` | 930 | 93.23% | Covered | — |  |
| `Sources/GISTools/Algorithms/Planepoint.swift` | 118 | 93.22% | Covered | Algorithms/PlanepointTests.swift |  |
| `Sources/GISTools/Algorithms/PointGrid.swift` | 79 | 100.00% | Covered | Algorithms/PointGridTests.swift |  |
| `Sources/GISTools/Algorithms/PointOnFeature.swift` | 162 | 52.47% | Partial | Algorithms/PointOnFeatureTests.swift |  |
| `Sources/GISTools/Algorithms/PointToLineDistance.swift` | 55 | 83.64% | Partial | Algorithms/PointToLineDistanceTests.swift |  |
| `Sources/GISTools/Algorithms/PointsWithinPolygon.swift` | 18 | 83.33% | Partial | Algorithms/PointsWithinPolygonTests.swift |  |
| `Sources/GISTools/Algorithms/PoleOfInaccessibility.swift` | 257 | 94.94% | Covered | Algorithms/PoleOfInaccessibilityTests.swift |  |
| `Sources/GISTools/Algorithms/PolygonSmooth.swift` | 129 | 95.35% | Covered | Algorithms/PolygonSmoothTests.swift |  |
| `Sources/GISTools/Algorithms/PolygonTangents.swift` | 149 | 95.97% | Covered | Algorithms/PolygonTangentsTests.swift |  |
| `Sources/GISTools/Algorithms/PolygonToLine.swift` | 11 | 100.00% | Covered | Algorithms/PolygonToLineTests.swift | #337 |
| `Sources/GISTools/Algorithms/Polygonize.swift` | 676 | 94.82% | Covered | Algorithms/PolygonizeTests.swift | #333 |
| `Sources/GISTools/Algorithms/PreparedPolygon.swift` | 362 | 95.86% | Covered | Algorithms/PreparedPolygonTests.swift | #339 |
| `Sources/GISTools/Algorithms/Random.swift` | 148 | 98.65% | Covered | Algorithms/RandomTests.swift |  |
| `Sources/GISTools/Algorithms/RectangleGrid.swift` | 75 | 100.00% | Covered | Algorithms/RectangleGridTests.swift |  |
| `Sources/GISTools/Algorithms/Reverse.swift` | 74 | 68.92% | Partial | Algorithms/ReverseTests.swift |  |
| `Sources/GISTools/Algorithms/Rewind.swift` | 109 | 92.66% | Covered | Algorithms/RewindTests.swift |  |
| `Sources/GISTools/Algorithms/RhumbBearing.swift` | 44 | 84.09% | Partial | Algorithms/RhumbBearingTests.swift |  |
| `Sources/GISTools/Algorithms/RhumbDestination.swift` | 68 | 85.29% | Partial | Algorithms/RhumbDestinationTests.swift |  |
| `Sources/GISTools/Algorithms/RhumbDistance.swift` | 64 | 92.19% | Covered | Algorithms/RhumbDistanceTests.swift |  |
| `Sources/GISTools/Algorithms/Sample.swift` | 11 | 100.00% | Covered | Algorithms/SampleTests.swift |  |
| `Sources/GISTools/Algorithms/Sector.swift` | 20 | 100.00% | Covered | Algorithms/SectorTests.swift |  |
| `Sources/GISTools/Algorithms/SharedPaths.swift` | 63 | 100.00% | Covered | Algorithms/SharedPathsTests.swift |  |
| `Sources/GISTools/Algorithms/Simplify.swift` | 682 | 85.34% | Partial | Algorithms/SimplifyTests.swift | #334 |
| `Sources/GISTools/Algorithms/SnapToGrid.swift` | 204 | 98.04% | Covered | Algorithms/SnapToGridTests.swift | #337 |
| `Sources/GISTools/Algorithms/SquareGrid.swift` | 6 | 100.00% | Covered | Algorithms/SquareGridTests.swift |  |
| `Sources/GISTools/Algorithms/SymmetricDifference.swift` | 62 | 83.87% | Partial | Algorithms/SymmetricDifferenceTests.swift |  |
| `Sources/GISTools/Algorithms/Tesselate.swift` | 469 | 97.01% | Covered | Algorithms/TesselateTests.swift | #330 |
| `Sources/GISTools/Algorithms/TileCover.swift` | 343 | 95.92% | Covered | Algorithms/TileCoverTests.swift |  |
| `Sources/GISTools/Algorithms/Tin.swift` | 218 | 93.12% | Covered | Algorithms/TinTests.swift |  |
| `Sources/GISTools/Algorithms/TopologicalValidity.swift` | 408 | 73.28% | Partial | Algorithms/TopologicalValidityTests.swift |  |
| `Sources/GISTools/Algorithms/TransformCoordinates.swift` | 115 | 92.17% | Covered | Algorithms/TransformCoordinatesTests.swift |  |
| `Sources/GISTools/Algorithms/TransformRotate.swift` | 34 | 73.53% | Partial | Algorithms/TransformRotateTests.swift |  |
| `Sources/GISTools/Algorithms/TransformScale.swift` | 86 | 81.40% | Partial | Algorithms/TransformScaleTests.swift |  |
| `Sources/GISTools/Algorithms/TransformTranslate.swift` | 31 | 100.00% | Covered | Algorithms/TransformTranslateTests.swift |  |
| `Sources/GISTools/Algorithms/TriangleGrid.swift` | 153 | 100.00% | Covered | Algorithms/TriangleGridTests.swift |  |
| `Sources/GISTools/Algorithms/Truncate.swift` | 157 | 87.90% | Partial | Algorithms/TruncateTests.swift | #337 |
| `Sources/GISTools/Algorithms/UnaryUnion.swift` | 121 | 97.52% | Covered | Algorithms/UnaryUnionTests.swift |  |
| `Sources/GISTools/Algorithms/Union.swift` | 73 | 89.04% | Partial | Algorithms/UnionTests.swift |  |
| `Sources/GISTools/Algorithms/Validatable.swift` | 185 | 89.73% | Partial | Algorithms/ValidatableTests.swift |  |
| `Sources/GISTools/Algorithms/Voronoi.swift` | 377 | 97.35% | Covered | Algorithms/VoronoiTests.swift | #335 |
| `Sources/GISTools/Extensions/ArrayExtensions.swift` | 138 | 79.71% | Partial | Extensions/ArrayExtensionsTests.swift |  |
| `Sources/GISTools/Extensions/CLLocationDegreesExtensions.swift` | 7 | 100.00% | Covered | Extensions/CLLocationDegreesExtensionsTests.swift |  |
| `Sources/GISTools/Extensions/DataExtensions.swift` | 22 | 86.36% | Partial | — |  |
| `Sources/GISTools/Extensions/DoubleExtensions.swift` | 38 | 92.11% | Covered | Extensions/DoubleExtensionsTests.swift |  |
| `Sources/GISTools/Extensions/EquatableExtensions.swift` | 6 | 50.00% | Partial | — |  |
| `Sources/GISTools/Extensions/FeatureIdentifierExtensions.swift` | 14 | 100.00% | Covered | Extensions/FeatureIdentifierExtensionsTests.swift |  |
| `Sources/GISTools/Extensions/FixedWidthIntegerExtensions.swift` | 5 | 100.00% | Covered | — |  |
| `Sources/GISTools/Extensions/SetExtensions.swift` | 6 | 100.00% | Covered | — |  |
| `Sources/GISTools/Extensions/StringExtensions.swift` | 40 | 85.00% | Partial | Extensions/StringExtensionsTests.swift |  |
| `Sources/GISTools/GISTool.swift` | 3 | 100.00% | Covered | — |  |
| `Sources/GISTools/GeoJson/BoundingBox.swift` | 674 | 92.28% | Covered | GeoJson/BoundingBoxTests.swift | #338 |
| `Sources/GISTools/GeoJson/BoundingBoxRepresentable.swift` | 6 | 100.00% | Covered | — | #338 |
| `Sources/GISTools/GeoJson/Cartesian3D.swift` | 21 | 100.00% | Covered | GeoJson/Cartesian3DTests.swift |  |
| `Sources/GISTools/GeoJson/Coordinate3D.swift` | 402 | 91.29% | Covered | — | #338 |
| `Sources/GISTools/GeoJson/Feature.swift` | 313 | 86.26% | Partial | GeoJson/FeatureTests.swift |  |
| `Sources/GISTools/GeoJson/FeatureCollection.swift` | 235 | 91.49% | Covered | GeoJson/FeatureCollectionTests.swift |  |
| `Sources/GISTools/GeoJson/GeoJson.swift` | 140 | 85.00% | Partial | — |  |
| `Sources/GISTools/GeoJson/GeoJsonCodable.swift` | 182 | 89.01% | Partial | — |  |
| `Sources/GISTools/GeoJson/GeoJsonConvertible.swift` | 82 | 96.34% | Covered | — |  |
| `Sources/GISTools/GeoJson/GeoJsonDecoder.swift` | 275 | 82.18% | Partial | GeoJson/GeoJsonDecoderTests.swift |  |
| `Sources/GISTools/GeoJson/GeoJsonParser.swift` | 518 | 90.54% | Covered | GeoJson/GeoJsonParserTests.swift |  |
| `Sources/GISTools/GeoJson/GeoJsonReader.swift` | 103 | 93.20% | Covered | — |  |
| `Sources/GISTools/GeoJson/GeometryCollection.swift` | 176 | 81.25% | Partial | GeoJson/GeometryCollectionTests.swift |  |
| `Sources/GISTools/GeoJson/GeometryDispatch.swift` | 11 | 54.55% | Partial | — |  |
| `Sources/GISTools/GeoJson/Gzip.swift` | 112 | 99.11% | Covered | GeoJson/GzipTests.swift |  |
| `Sources/GISTools/GeoJson/JSONValue.swift` | 336 | 97.92% | Covered | GeoJson/JSONValueTests.swift |  |
| `Sources/GISTools/GeoJson/JsonCoercion.swift` | 269 | 91.82% | Covered | GeoJson/JsonCoercionTests.swift |  |
| `Sources/GISTools/GeoJson/LineSegment.swift` | 76 | 98.68% | Covered | GeoJson/LineSegmentTests.swift |  |
| `Sources/GISTools/GeoJson/LineString.swift` | 190 | 92.63% | Covered | GeoJson/LineStringTests.swift |  |
| `Sources/GISTools/GeoJson/MultiLineString.swift` | 208 | 78.85% | Partial | GeoJson/MultiLineStringTests.swift |  |
| `Sources/GISTools/GeoJson/MultiPoint.swift` | 183 | 86.89% | Partial | GeoJson/MultiPointTests.swift |  |
| `Sources/GISTools/GeoJson/MultiPolygon.swift` | 196 | 87.24% | Partial | GeoJson/MultiPolygonTests.swift |  |
| `Sources/GISTools/GeoJson/Point.swift` | 84 | 88.10% | Partial | GeoJson/PointTests.swift |  |
| `Sources/GISTools/GeoJson/Polygon.swift` | 172 | 93.60% | Covered | GeoJson/PolygonTests.swift |  |
| `Sources/GISTools/GeoJson/Polyline.swift` | 157 | 99.36% | Covered | GeoJson/PolylineTests.swift |  |
| `Sources/GISTools/GeoJson/Projectable.swift` | 5 | 100.00% | Covered | — |  |
| `Sources/GISTools/GeoJson/RTree.swift` | 437 | 99.77% | Covered | GeoJson/RTreeTests.swift | #338 |
| `Sources/GISTools/GeoJson/Ring.swift` | 125 | 96.80% | Covered | GeoJson/RingTests.swift |  |
| `Sources/GISTools/GeoJson/TWKBCoder.swift` | 509 | 96.86% | Covered | — |  |
| `Sources/GISTools/GeoJson/WKBCoder.swift` | 603 | 94.86% | Covered | — |  |
| `Sources/GISTools/GeoJson/WKTCoder.swift` | 532 | 90.79% | Covered | — |  |
| `Sources/GISTools/Graph/Edge.swift` | 24 | 83.33% | Partial | — |  |
| `Sources/GISTools/Graph/Graph+AStar.swift` | 97 | 100.00% | Covered | — |  |
| `Sources/GISTools/Graph/Graph+ArticulationPoints.swift` | 101 | 100.00% | Covered | — |  |
| `Sources/GISTools/Graph/Graph+BetweennessCentrality.swift` | 71 | 100.00% | Covered | — |  |
| `Sources/GISTools/Graph/Graph+Bidirectional.swift` | 240 | 98.33% | Covered | — |  |
| `Sources/GISTools/Graph/Graph+Bridges.swift` | 91 | 100.00% | Covered | — |  |
| `Sources/GISTools/Graph/Graph+Contraction.swift` | 609 | 97.21% | Covered | — |  |
| `Sources/GISTools/Graph/Graph+Convenience.swift` | 54 | 66.67% | Partial | — |  |
| `Sources/GISTools/Graph/Graph+Cycles.swift` | 183 | 96.72% | Covered | — |  |
| `Sources/GISTools/Graph/Graph+DeadEnds.swift` | 133 | 100.00% | Covered | — |  |
| `Sources/GISTools/Graph/Graph+Edges.swift` | 87 | 100.00% | Covered | — |  |
| `Sources/GISTools/Graph/Graph+Eulerian.swift` | 331 | 96.37% | Covered | — |  |
| `Sources/GISTools/Graph/Graph+KShortestPaths.swift` | 197 | 92.39% | Covered | — |  |
| `Sources/GISTools/Graph/Graph+LandmarkIndex.swift` | 273 | 98.53% | Covered | — |  |
| `Sources/GISTools/Graph/Graph+Merge.swift` | 392 | 97.45% | Covered | — |  |
| `Sources/GISTools/Graph/Graph+MinimumSpanningTree.swift` | 90 | 100.00% | Covered | — |  |
| `Sources/GISTools/Graph/Graph+MultiCriteriaPath.swift` | 64 | 100.00% | Covered | — |  |
| `Sources/GISTools/Graph/Graph+NodeOnEdge.swift` | 84 | 78.57% | Partial | — |  |
| `Sources/GISTools/Graph/Graph+Nodes.swift` | 55 | 100.00% | Covered | — |  |
| `Sources/GISTools/Graph/Graph+Partitioning.swift` | 248 | 98.79% | Covered | — |  |
| `Sources/GISTools/Graph/Graph+RoutingIndex.swift` | 110 | 78.18% | Partial | — |  |
| `Sources/GISTools/Graph/Graph+ShortestPath.swift` | 59 | 100.00% | Covered | — |  |
| `Sources/GISTools/Graph/Graph+StronglyConnectedComponents.swift` | 74 | 100.00% | Covered | — |  |
| `Sources/GISTools/Graph/Graph+Subgraph.swift` | 48 | 85.42% | Partial | — |  |
| `Sources/GISTools/Graph/Graph+Traversal.swift` | 157 | 99.36% | Covered | — |  |
| `Sources/GISTools/Graph/Graph+Tsp.swift` | 148 | 97.97% | Covered | — |  |
| `Sources/GISTools/Graph/Graph.swift` | 146 | 97.26% | Covered | — |  |
| `Sources/GISTools/Graph/MinHeap.swift` | 63 | 100.00% | Covered | — |  |
| `Sources/GISTools/Graph/Node.swift` | 14 | 71.43% | Partial | — |  |
| `Sources/GISTools/Graph/NodeBitSet.swift` | 28 | 96.43% | Covered | Graph/NodeBitSetTests.swift |  |
| `Sources/GISTools/Other/MapTile.swift` | 431 | 94.66% | Covered | Other/MapTileTests.swift |  |
| `Sources/GISTools/Projections/AlbersEqualAreaMath.swift` | 88 | 96.59% | Covered | — |  |
| `Sources/GISTools/Projections/ArrayProjection.swift` | 61 | 98.36% | Covered | Projections/ArrayProjectionTests.swift |  |
| `Sources/GISTools/Projections/AuthalicLatitude.swift` | 79 | 93.67% | Covered | — |  |
| `Sources/GISTools/Projections/CustomProjection.swift` | 44 | 81.82% | Partial | Projections/CustomProjectionTests.swift |  |
| `Sources/GISTools/Projections/Datum.swift` | 22 | 72.73% | Partial | Projections/DatumTests.swift |  |
| `Sources/GISTools/Projections/Definitions/Ch1903Lv03Definition.swift` | 111 | 42.34% | Low | Projections/ProjectionTests.swift (indirect) |  |
| `Sources/GISTools/Projections/Definitions/Ch1903PlusLv95Definition.swift` | 112 | 42.86% | Low | Projections/ProjectionTests.swift (indirect) |  |
| `Sources/GISTools/Projections/Definitions/DhdnGkDefinition.swift` | 135 | 42.96% | Low | Projections/ProjectionTests.swift (indirect) |  |
| `Sources/GISTools/Projections/Definitions/Epsg3005Definition.swift` | 96 | 40.62% | Low | Projections/ProjectionTests.swift (indirect) |  |
| `Sources/GISTools/Projections/Definitions/Epsg32662Definition.swift` | 45 | 86.67% | Partial | Projections/ProjectionTests.swift (indirect) |  |
| `Sources/GISTools/Projections/Definitions/Epsg3347Definition.swift` | 96 | 40.62% | Low | Projections/ProjectionTests.swift (indirect) |  |
| `Sources/GISTools/Projections/Definitions/Epsg3395Definition.swift` | 66 | 92.42% | Covered | Projections/ProjectionTests.swift (indirect) |  |
| `Sources/GISTools/Projections/Definitions/Epsg3857Definition.swift` | 44 | 100.00% | Covered | Projections/ProjectionTests.swift (indirect) |  |
| `Sources/GISTools/Projections/Definitions/Epsg3978Definition.swift` | 96 | 40.62% | Low | Projections/ProjectionTests.swift (indirect) |  |
| `Sources/GISTools/Projections/Definitions/Epsg4326Definition.swift` | 25 | 60.00% | Partial | Projections/ProjectionTests.swift (indirect) |  |
| `Sources/GISTools/Projections/Definitions/Epsg4978Definition.swift` | 83 | 100.00% | Covered | Projections/ProjectionTests.swift (indirect) |  |
| `Sources/GISTools/Projections/Definitions/Epsg5070Definition.swift` | 97 | 41.24% | Low | Projections/ProjectionTests.swift (indirect) |  |
| `Sources/GISTools/Projections/Definitions/Etrs89Definition.swift` | 32 | 81.25% | Partial | Projections/ProjectionTests.swift (indirect) |  |
| `Sources/GISTools/Projections/Definitions/Etrs89LaeaDefinition.swift` | 95 | 35.79% | Low | Projections/ProjectionTests.swift (indirect) |  |
| `Sources/GISTools/Projections/Definitions/Etrs89LccDefinition.swift` | 94 | 35.11% | Low | Projections/ProjectionTests.swift (indirect) |  |
| `Sources/GISTools/Projections/Definitions/Etrs89UtmDefinition.swift` | 123 | 41.46% | Low | Projections/ProjectionTests.swift (indirect) |  |
| `Sources/GISTools/Projections/Definitions/IrishGridTM65Definition.swift` | 51 | 94.12% | Covered | Projections/ProjectionTests.swift (indirect) |  |
| `Sources/GISTools/Projections/Definitions/IrishGridTM75Definition.swift` | 51 | 94.12% | Covered | Projections/ProjectionTests.swift (indirect) |  |
| `Sources/GISTools/Projections/Definitions/IrishTransverseMercatorDefinition.swift` | 42 | 92.86% | Covered | Projections/ProjectionTests.swift (indirect) |  |
| `Sources/GISTools/Projections/Definitions/Lambert93Definition.swift` | 94 | 35.11% | Low | Projections/ProjectionTests.swift (indirect) |  |
| `Sources/GISTools/Projections/Definitions/MgiGkDefinition.swift` | 165 | 48.48% | Low | Projections/ProjectionTests.swift (indirect) |  |
| `Sources/GISTools/Projections/Definitions/Nad27Definition.swift` | 53 | 35.85% | Low | Projections/ProjectionTests.swift (indirect) |  |
| `Sources/GISTools/Projections/Definitions/Nad83Definition.swift` | 42 | 78.57% | Partial | Projections/ProjectionTests.swift (indirect) |  |
| `Sources/GISTools/Projections/Definitions/Nad83UtmDefinition.swift` | 123 | 41.46% | Low | Projections/ProjectionTests.swift (indirect) |  |
| `Sources/GISTools/Projections/Definitions/NoSridDefinition.swift` | 30 | 20.00% | Low | Projections/ProjectionTests.swift (indirect) |  |
| `Sources/GISTools/Projections/Definitions/Osgb1936BngDefinition.swift` | 122 | 39.34% | Low | Projections/ProjectionTests.swift (indirect) |  |
| `Sources/GISTools/Projections/Definitions/Osgb1936Definition.swift` | 51 | 33.33% | Low | Projections/ProjectionTests.swift (indirect) |  |
| `Sources/GISTools/Projections/Definitions/ProjectionDefinition.swift` | 3 | 100.00% | Covered | Projections/ProjectionTests.swift (indirect) |  |
| `Sources/GISTools/Projections/Definitions/RdNewDefinition.swift` | 113 | 32.74% | Low | Projections/ProjectionTests.swift (indirect) |  |
| `Sources/GISTools/Projections/Definitions/UtmDefinition.swift` | 156 | 67.31% | Partial | Projections/UtmDefinitionTests.swift |  |
| `Sources/GISTools/Projections/HelmertTransformation.swift` | 258 | 56.59% | Partial | Projections/HelmertTransformationTests.swift |  |
| `Sources/GISTools/Projections/KarneyTransverseMercatorMath.swift` | 170 | 99.41% | Covered | — |  |
| `Sources/GISTools/Projections/LambertAzimuthalEqualAreaMath.swift` | 188 | 69.15% | Partial | — |  |
| `Sources/GISTools/Projections/LambertConformalConicMath.swift` | 127 | 95.28% | Covered | — |  |
| `Sources/GISTools/Projections/ObliqueStereographicMath.swift` | 97 | 96.91% | Covered | — |  |
| `Sources/GISTools/Projections/Projection.swift` | 269 | 90.33% | Covered | Projections/ProjectionTests.swift |  |
| `Sources/GISTools/Projections/ProjectionExtent.swift` | 6 | 100.00% | Covered | — |  |
| `Sources/GISTools/Projections/ProjectionRegistry.swift` | 131 | 100.00% | Covered | — |  |
| `Sources/GISTools/Projections/SwissObliqueMercatorMath.swift` | 87 | 100.00% | Covered | — |  |
| `Sources/GISTools/Projections/TransverseMercatorMath.swift` | 135 | 100.00% | Covered | — |  |
| `Sources/GISTools/Projections/UtmZoneSelection.swift` | 51 | 100.00% | Covered | Projections/UtmZoneSelectionTests.swift |  |
| `Sources/GISTools/Query/FeatureCollection+Query.swift` | 11 | 100.00% | Covered | — | #349 |
| `Sources/GISTools/Query/QueryParser.swift` | 1087 | 92.36% | Covered | Query/QueryParserTests.swift | #349 |

## Refresh

```bash
swift test --traits EnableGraphAPI --enable-code-coverage
python3 scripts/refresh_coverage_report.py
```

The CI gate runs the same data through
`python3 scripts/refresh_coverage_report.py --minimum 87.5 --check`.
Formatting is checked for Swift files changed by a pull request. The gate
compares violation counts against the base branch and fails when a PR adds
new violations; existing legacy formatting debt is tolerated. Locally:

```bash
swiftformat --lint --config .swiftformat <changed Swift files>
```

## Fixture inventory

**341 fixtures.** Every fixture has an explicit decision. No fixture
is unused: the files are loaded individually, by directory, or through the
generated-name patterns in `ConvexHullTests` / `TestData` helpers. Removing a
fixture would therefore remove real coverage; the improvements needed are test
assertions (tracked in the issues above), not fixture deletion.

| Fixture | Decision | Used by | Rationale |
| --- | --- | --- | --- |
| `BooleanDisjoint/LineString1.geojson.gz` | Keep | Algorithms/BooleanDisjointTests.swift | Turf/reference boolean fixtures; keep (predicate contract tests). |
| `BooleanDisjoint/LineString2.geojson.gz` | Keep | Algorithms/BooleanDisjointTests.swift | Turf/reference boolean fixtures; keep (predicate contract tests). |
| `BooleanDisjoint/LineString3.geojson.gz` | Keep | Algorithms/BooleanDisjointTests.swift | Turf/reference boolean fixtures; keep (predicate contract tests). |
| `BooleanDisjoint/LineString4.geojson.gz` | Keep | Algorithms/BooleanDisjointTests.swift | Turf/reference boolean fixtures; keep (predicate contract tests). |
| `BooleanDisjoint/MultiPoint1.geojson.gz` | Keep | Algorithms/BooleanDisjointTests.swift | Turf/reference boolean fixtures; keep (predicate contract tests). |
| `BooleanDisjoint/MultiPoint2.geojson.gz` | Keep | Algorithms/BooleanDisjointTests.swift | Turf/reference boolean fixtures; keep (predicate contract tests). |
| `BooleanDisjoint/MultiPoint3.geojson.gz` | Keep | Algorithms/BooleanDisjointTests.swift | Turf/reference boolean fixtures; keep (predicate contract tests). |
| `BooleanDisjoint/MultiPoint4.geojson.gz` | Keep | Algorithms/BooleanDisjointTests.swift | Turf/reference boolean fixtures; keep (predicate contract tests). |
| `BooleanDisjoint/MultiPoint5.geojson.gz` | Keep | Algorithms/BooleanDisjointTests.swift | Turf/reference boolean fixtures; keep (predicate contract tests). |
| `BooleanDisjoint/MultiPolygon1.geojson.gz` | Keep | Algorithms/BooleanDisjointTests.swift | Turf/reference boolean fixtures; keep (predicate contract tests). |
| `BooleanDisjoint/Point1.geojson.gz` | Keep | Algorithms/BooleanDisjointTests.swift | Turf/reference boolean fixtures; keep (predicate contract tests). |
| `BooleanDisjoint/Point2.geojson.gz` | Keep | Algorithms/BooleanDisjointTests.swift | Turf/reference boolean fixtures; keep (predicate contract tests). |
| `BooleanDisjoint/Point3.geojson.gz` | Keep | Algorithms/BooleanDisjointTests.swift | Turf/reference boolean fixtures; keep (predicate contract tests). |
| `BooleanDisjoint/Point4.geojson.gz` | Keep | Algorithms/BooleanDisjointTests.swift | Turf/reference boolean fixtures; keep (predicate contract tests). |
| `BooleanDisjoint/Polygon1.geojson.gz` | Keep | Algorithms/BooleanDisjointTests.swift | Turf/reference boolean fixtures; keep (predicate contract tests). |
| `BooleanDisjoint/Polygon2.geojson.gz` | Keep | Algorithms/BooleanDisjointTests.swift | Turf/reference boolean fixtures; keep (predicate contract tests). |
| `BooleanDisjoint/Polygon3.geojson.gz` | Keep | Algorithms/BooleanDisjointTests.swift | Turf/reference boolean fixtures; keep (predicate contract tests). |
| `BooleanOverlap/OverlapFalse1_1.geojson.gz` | Keep | Algorithms/BooleanOverlapTests.swift | Turf/reference boolean fixtures; keep. |
| `BooleanOverlap/OverlapFalse1_2.geojson.gz` | Keep | Algorithms/BooleanOverlapTests.swift | Turf/reference boolean fixtures; keep. |
| `BooleanOverlap/OverlapFalse2_1.geojson.gz` | Keep | Algorithms/BooleanOverlapTests.swift | Turf/reference boolean fixtures; keep. |
| `BooleanOverlap/OverlapFalse2_2.geojson.gz` | Keep | Algorithms/BooleanOverlapTests.swift | Turf/reference boolean fixtures; keep. |
| `BooleanOverlap/OverlapFalse3_1.geojson.gz` | Keep | Algorithms/BooleanOverlapTests.swift | Turf/reference boolean fixtures; keep. |
| `BooleanOverlap/OverlapFalse3_2.geojson.gz` | Keep | Algorithms/BooleanOverlapTests.swift | Turf/reference boolean fixtures; keep. |
| `BooleanOverlap/OverlapFalse4_1.geojson.gz` | Keep | Algorithms/BooleanOverlapTests.swift | Turf/reference boolean fixtures; keep. |
| `BooleanOverlap/OverlapFalse4_2.geojson.gz` | Keep | Algorithms/BooleanOverlapTests.swift | Turf/reference boolean fixtures; keep. |
| `BooleanOverlap/OverlapFalse6_1.geojson.gz` | Keep | Algorithms/BooleanOverlapTests.swift | Turf/reference boolean fixtures; keep. |
| `BooleanOverlap/OverlapFalse6_2.geojson.gz` | Keep | Algorithms/BooleanOverlapTests.swift | Turf/reference boolean fixtures; keep. |
| `BooleanOverlap/OverlapFalse7_1.geojson.gz` | Keep | Algorithms/BooleanOverlapTests.swift | Turf/reference boolean fixtures; keep. |
| `BooleanOverlap/OverlapFalse7_2.geojson.gz` | Keep | Algorithms/BooleanOverlapTests.swift | Turf/reference boolean fixtures; keep. |
| `BooleanOverlap/OverlapTrue1_1.geojson.gz` | Keep | Algorithms/BooleanOverlapTests.swift | Turf/reference boolean fixtures; keep. |
| `BooleanOverlap/OverlapTrue1_2.geojson.gz` | Keep | Algorithms/BooleanOverlapTests.swift | Turf/reference boolean fixtures; keep. |
| `BooleanOverlap/OverlapTrue2_1.geojson.gz` | Keep | Algorithms/BooleanOverlapTests.swift | Turf/reference boolean fixtures; keep. |
| `BooleanOverlap/OverlapTrue2_2.geojson.gz` | Keep | Algorithms/BooleanOverlapTests.swift | Turf/reference boolean fixtures; keep. |
| `BooleanOverlap/OverlapTrue3_1.geojson.gz` | Keep | Algorithms/BooleanOverlapTests.swift | Turf/reference boolean fixtures; keep. |
| `BooleanOverlap/OverlapTrue3_2.geojson.gz` | Keep | Algorithms/BooleanOverlapTests.swift | Turf/reference boolean fixtures; keep. |
| `BooleanOverlap/OverlapTrue4_1.geojson.gz` | Keep | Algorithms/BooleanOverlapTests.swift | Turf/reference boolean fixtures; keep. |
| `BooleanOverlap/OverlapTrue4_2.geojson.gz` | Keep | Algorithms/BooleanOverlapTests.swift | Turf/reference boolean fixtures; keep. |
| `BooleanOverlap/OverlapTrue5_1.geojson.gz` | Keep | Algorithms/BooleanOverlapTests.swift | Turf/reference boolean fixtures; keep. |
| `BooleanOverlap/OverlapTrue5_2.geojson.gz` | Keep | Algorithms/BooleanOverlapTests.swift | Turf/reference boolean fixtures; keep. |
| `BooleanParallel/LineStringFalse1_1.geojson.gz` | Keep | Algorithms/BooleanParallelTests.swift | Reference parallel-line fixtures; keep. |
| `BooleanParallel/LineStringFalse1_2.geojson.gz` | Keep | Algorithms/BooleanParallelTests.swift | Reference parallel-line fixtures; keep. |
| `BooleanParallel/LineStringFalse2_1.geojson.gz` | Keep | Algorithms/BooleanParallelTests.swift | Reference parallel-line fixtures; keep. |
| `BooleanParallel/LineStringFalse2_2.geojson.gz` | Keep | Algorithms/BooleanParallelTests.swift | Reference parallel-line fixtures; keep. |
| `BooleanParallel/LineStringTrue1_1.geojson.gz` | Keep | Algorithms/BooleanParallelTests.swift | Reference parallel-line fixtures; keep. |
| `BooleanParallel/LineStringTrue1_2.geojson.gz` | Keep | Algorithms/BooleanParallelTests.swift | Reference parallel-line fixtures; keep. |
| `BooleanParallel/LineStringTrue2_1.geojson.gz` | Keep | Algorithms/BooleanParallelTests.swift | Reference parallel-line fixtures; keep. |
| `BooleanParallel/LineStringTrue3_1.geojson.gz` | Keep | Algorithms/BooleanParallelTests.swift | Reference parallel-line fixtures; keep. |
| `BooleanParallel/LineStringTrue4_1.geojson.gz` | Keep | Algorithms/BooleanParallelTests.swift | Reference parallel-line fixtures; keep. |
| `BoundingBoxClip/LineString.geojson.gz` | Keep | Algorithms/BoundingBoxClipTests.swift | Clipping regression fixtures; keep, exact-area gaps in #341/#343. |
| `BoundingBoxClip/LineStringResult.geojson.gz` | Keep | Algorithms/BoundingBoxClipTests.swift | Clipping regression fixtures; keep, exact-area gaps in #341/#343. |
| `BoundingBoxClip/MultiLineString.geojson.gz` | Keep | Algorithms/BoundingBoxClipTests.swift | Clipping regression fixtures; keep, exact-area gaps in #341/#343. |
| `BoundingBoxClip/MultiLineStringResult.geojson.gz` | Keep | Algorithms/BoundingBoxClipTests.swift | Clipping regression fixtures; keep, exact-area gaps in #341/#343. |
| `BoundingBoxClip/MultiPolygon.geojson.gz` | Keep | Algorithms/BoundingBoxClipTests.swift | Clipping regression fixtures; keep, exact-area gaps in #341/#343. |
| `BoundingBoxClip/MultiPolygonResult.geojson.gz` | Keep | Algorithms/BoundingBoxClipTests.swift | Clipping regression fixtures; keep, exact-area gaps in #341/#343. |
| `BoundingBoxClip/PolygonCrossingHole.geojson.gz` | Keep | Algorithms/BoundingBoxClipTests.swift | Clipping regression fixtures; keep, exact-area gaps in #341/#343. |
| `BoundingBoxClip/PolygonCrossingHoleResult.geojson.gz` | Keep | Algorithms/BoundingBoxClipTests.swift | Clipping regression fixtures; keep, exact-area gaps in #341/#343. |
| `BoundingBoxClip/PolygonHoles.geojson.gz` | Keep | Algorithms/BoundingBoxClipTests.swift | Clipping regression fixtures; keep, exact-area gaps in #341/#343. |
| `BoundingBoxClip/PolygonHolesResult.geojson.gz` | Keep | Algorithms/BoundingBoxClipTests.swift | Clipping regression fixtures; keep, exact-area gaps in #341/#343. |
| `BoundingBoxClip/PolygonPointIntersection.geojson.gz` | Keep | Algorithms/BoundingBoxClipTests.swift | Clipping regression fixtures; keep, exact-area gaps in #341/#343. |
| `BoundingBoxClip/SingleLine.geojson.gz` | Keep | Algorithms/BoundingBoxClipTests.swift | Clipping regression fixtures; keep, exact-area gaps in #341/#343. |
| `BoundingBoxClip/SingleLineResult.geojson.gz` | Keep | Algorithms/BoundingBoxClipTests.swift | Clipping regression fixtures; keep, exact-area gaps in #341/#343. |
| `Buffer/FeatureCollectionPoints.geojson.gz` | Keep | Algorithms/BufferTests.swift | Buffer regression fixtures; keep, negative/degenerate gaps in #340. |
| `Buffer/FeatureCollectionPointsResult.geojson.gz` | Keep | Algorithms/BufferTests.swift | Buffer regression fixtures; keep, negative/degenerate gaps in #340. |
| `Buffer/GeometryCollectionPoints.geojson.gz` | Keep | Algorithms/BufferTests.swift | Buffer regression fixtures; keep, negative/degenerate gaps in #340. |
| `Buffer/GeometryCollectionPointsResult.geojson.gz` | Keep | Algorithms/BufferTests.swift | Buffer regression fixtures; keep, negative/degenerate gaps in #340. |
| `Buffer/LineFlatResult.geojson.gz` | Keep | Algorithms/BufferTests.swift | Buffer regression fixtures; keep, negative/degenerate gaps in #340. |
| `Buffer/LineRoundResult.geojson.gz` | Keep | Algorithms/BufferTests.swift | Buffer regression fixtures; keep, negative/degenerate gaps in #340. |
| `Buffer/LineString.geojson.gz` | Keep | Algorithms/BufferTests.swift | Buffer regression fixtures; keep, negative/degenerate gaps in #340. |
| `Buffer/LineStringResult.geojson.gz` | Keep | Algorithms/BufferTests.swift | Buffer regression fixtures; keep, negative/degenerate gaps in #340. |
| `Buffer/LineStringStripWidth.geojson.gz` | Keep | Algorithms/BufferTests.swift | Buffer regression fixtures; keep, negative/degenerate gaps in #340. |
| `Buffer/LineStringStripWidthResult.geojson.gz` | Keep | Algorithms/BufferTests.swift | Buffer regression fixtures; keep, negative/degenerate gaps in #340. |
| `Buffer/LongLineFlatResult.geojson.gz` | Keep | Algorithms/BufferTests.swift | Buffer regression fixtures; keep, negative/degenerate gaps in #340. |
| `Buffer/LongLineRoundResult.geojson.gz` | Keep | Algorithms/BufferTests.swift | Buffer regression fixtures; keep, negative/degenerate gaps in #340. |
| `Buffer/LongLineStringKinks.geojson.gz` | Keep | Algorithms/BufferTests.swift | Buffer regression fixtures; keep, negative/degenerate gaps in #340. |
| `Buffer/LongLineStringKinksResult.geojson.gz` | Keep | Algorithms/BufferTests.swift | Buffer regression fixtures; keep, negative/degenerate gaps in #340. |
| `Buffer/MultiLineFlatResult.geojson.gz` | Keep | Algorithms/BufferTests.swift | Buffer regression fixtures; keep, negative/degenerate gaps in #340. |
| `Buffer/MultiLineRoundResult.geojson.gz` | Keep | Algorithms/BufferTests.swift | Buffer regression fixtures; keep, negative/degenerate gaps in #340. |
| `Buffer/MultiLineString.geojson.gz` | Keep | Algorithms/BufferTests.swift | Buffer regression fixtures; keep, negative/degenerate gaps in #340. |
| `Buffer/MultiLineStringResult.geojson.gz` | Keep | Algorithms/BufferTests.swift | Buffer regression fixtures; keep, negative/degenerate gaps in #340. |
| `Buffer/MultiPoint.geojson.gz` | Keep | Algorithms/BufferTests.swift | Buffer regression fixtures; keep, negative/degenerate gaps in #340. |
| `Buffer/MultiPointResult.geojson.gz` | Keep | Algorithms/BufferTests.swift | Buffer regression fixtures; keep, negative/degenerate gaps in #340. |
| `Buffer/MultiPolygon.geojson.gz` | Keep | Algorithms/BufferTests.swift | Buffer regression fixtures; keep, negative/degenerate gaps in #340. |
| `Buffer/MultiPolygonResult.geojson.gz` | Keep | Algorithms/BufferTests.swift | Buffer regression fixtures; keep, negative/degenerate gaps in #340. |
| `Buffer/NegativeBuffer.geojson.gz` | Keep | Algorithms/BufferTests.swift | Buffer regression fixtures; keep, negative/degenerate gaps in #340. |
| `Buffer/NorthLatitudePoints.geojson.gz` | Keep | Algorithms/BufferTests.swift | Buffer regression fixtures; keep, negative/degenerate gaps in #340. |
| `Buffer/NorthLatitudePointsResult.geojson.gz` | Keep | Algorithms/BufferTests.swift | Buffer regression fixtures; keep, negative/degenerate gaps in #340. |
| `Buffer/NorthernPolygon.geojson.gz` | Keep | Algorithms/BufferTests.swift | Buffer regression fixtures; keep, negative/degenerate gaps in #340. |
| `Buffer/NorthernPolygonResult.geojson.gz` | Keep | Algorithms/BufferTests.swift | Buffer regression fixtures; keep, negative/degenerate gaps in #340. |
| `Buffer/Point.geojson.gz` | Keep | Algorithms/BufferTests.swift | Buffer regression fixtures; keep, negative/degenerate gaps in #340. |
| `Buffer/PointResult.geojson.gz` | Keep | Algorithms/BufferTests.swift | Buffer regression fixtures; keep, negative/degenerate gaps in #340. |
| `Buffer/PolygonCentroidEquator.geojson.gz` | Keep | Algorithms/BufferTests.swift | Buffer regression fixtures; keep, negative/degenerate gaps in #340. |
| `Buffer/PolygonCentroidEquatorResult.geojson.gz` | Keep | Algorithms/BufferTests.swift | Buffer regression fixtures; keep, negative/degenerate gaps in #340. |
| `Buffer/PolygonCentroidRadius.geojson.gz` | Keep | Algorithms/BufferTests.swift | Buffer regression fixtures; keep, negative/degenerate gaps in #340. |
| `Buffer/PolygonCentroidRadiusResult.geojson.gz` | Keep | Algorithms/BufferTests.swift | Buffer regression fixtures; keep, negative/degenerate gaps in #340. |
| `Buffer/PolygonExtremePoints.geojson.gz` | Keep | Algorithms/BufferTests.swift | Buffer regression fixtures; keep, negative/degenerate gaps in #340. |
| `Buffer/PolygonExtremePointsResult.geojson.gz` | Keep | Algorithms/BufferTests.swift | Buffer regression fixtures; keep, negative/degenerate gaps in #340. |
| `Buffer/PolygonWithHoleResult.geojson.gz` | Keep | Algorithms/BufferTests.swift | Buffer regression fixtures; keep, negative/degenerate gaps in #340. |
| `Buffer/PolygonWithHoles.geojson.gz` | Keep | Algorithms/BufferTests.swift | Buffer regression fixtures; keep, negative/degenerate gaps in #340. |
| `Buffer/PolygonWithHolesResult.geojson.gz` | Keep | Algorithms/BufferTests.swift | Buffer regression fixtures; keep, negative/degenerate gaps in #340. |
| `Buffer/RefMultiPointResult.geojson.gz` | Keep | Algorithms/BufferTests.swift | Buffer regression fixtures; keep, negative/degenerate gaps in #340. |
| `Buffer/RefMultiPolygonResult.geojson.gz` | Keep | Algorithms/BufferTests.swift | Buffer regression fixtures; keep, negative/degenerate gaps in #340. |
| `Buffer/RefPointResult.geojson.gz` | Keep | Algorithms/BufferTests.swift | Buffer regression fixtures; keep, negative/degenerate gaps in #340. |
| `Buffer/TouchingBufferPolygon.geojson.gz` | Keep | Algorithms/BufferTests.swift | Buffer regression fixtures; keep, negative/degenerate gaps in #340. |
| `Buffer/TouchingBufferPolygonResult.geojson.gz` | Keep | Algorithms/BufferTests.swift | Buffer regression fixtures; keep, negative/degenerate gaps in #340. |
| `Circle/CircleResult.geojson.gz` | Keep | Algorithms/CircleTests.swift | Reference circle fixture; keep. |
| `ConcaveHull/DonutShape.geojson.gz` | Keep | Algorithms/ConcaveHullTests.swift | Reference concave-hull fixtures; keep; antimeridian follow-up #336. |
| `ConcaveHull/LShapePoints.geojson.gz` | Keep | Algorithms/ConcaveHullTests.swift | Reference concave-hull fixtures; keep; antimeridian follow-up #336. |
| `ConcaveHull/LineWithNoise.geojson.gz` | Keep | Algorithms/ConcaveHullTests.swift | Reference concave-hull fixtures; keep; antimeridian follow-up #336. |
| `ConvexHull/CollinearPoints.geojson.gz` | Keep | Algorithms/ConvexHullTests.swift | Reference convex-hull input/result pairs; keep. |
| `ConvexHull/CollinearPointsResult.geojson.gz` | Keep | Algorithms/ConvexHullTests.swift | Reference convex-hull input/result pairs; keep. |
| `ConvexHull/RandomPoints.geojson.gz` | Keep | Algorithms/ConvexHullTests.swift | Reference convex-hull input/result pairs; keep. |
| `ConvexHull/RandomPointsResult.geojson.gz` | Keep | Algorithms/ConvexHullTests.swift | Reference convex-hull input/result pairs; keep. |
| `ConvexHull/SquarePoints.geojson.gz` | Keep | Algorithms/ConvexHullTests.swift | Reference convex-hull input/result pairs; keep. |
| `ConvexHull/SquarePointsResult.geojson.gz` | Keep | Algorithms/ConvexHullTests.swift | Reference convex-hull input/result pairs; keep. |
| `ConvexHull/ThreePoints.geojson.gz` | Keep | Algorithms/ConvexHullTests.swift | Reference convex-hull input/result pairs; keep. |
| `ConvexHull/ThreePointsResult.geojson.gz` | Keep | Algorithms/ConvexHullTests.swift | Reference convex-hull input/result pairs; keep. |
| `Flatten/FeatureCollection.geojson.gz` | Keep | Algorithms/FlattenTests.swift | Reference flatten fixtures; keep. |
| `Flatten/FeatureCollectionResult.geojson.gz` | Keep | Algorithms/FlattenTests.swift | Reference flatten fixtures; keep. |
| `Flatten/GeometryCollection.geojson.gz` | Keep | Algorithms/FlattenTests.swift | Reference flatten fixtures; keep. |
| `Flatten/GeometryCollectionResult.geojson.gz` | Keep | Algorithms/FlattenTests.swift | Reference flatten fixtures; keep. |
| `Flatten/GeometryObject.geojson.gz` | Keep | Algorithms/FlattenTests.swift | Reference flatten fixtures; keep. |
| `Flatten/GeometryObjectResult.geojson.gz` | Keep | Algorithms/FlattenTests.swift | Reference flatten fixtures; keep. |
| `Flatten/MultiLineString.geojson.gz` | Keep | Algorithms/FlattenTests.swift | Reference flatten fixtures; keep. |
| `Flatten/MultiLineStringResult.geojson.gz` | Keep | Algorithms/FlattenTests.swift | Reference flatten fixtures; keep. |
| `Flatten/MultiPoint.geojson.gz` | Keep | Algorithms/FlattenTests.swift | Reference flatten fixtures; keep. |
| `Flatten/MultiPointResult.geojson.gz` | Keep | Algorithms/FlattenTests.swift | Reference flatten fixtures; keep. |
| `Flatten/Polygon.geojson.gz` | Keep | Algorithms/FlattenTests.swift | Reference flatten fixtures; keep. |
| `Flatten/PolygonResult.geojson.gz` | Keep | Algorithms/FlattenTests.swift | Reference flatten fixtures; keep. |
| `Graph/RoadNetwork_Immenstadt.geojson.gz` | Keep | Graph/RealWorldRoutingTests.swift + GraphTestHelper.swift | Real-world OSM tile fixtures used by GraphTestHelper/RealWorldRoutingTests; keep. |
| `Graph/RoadNetwork_Immenstadt_2.geojson.gz` | Keep | Graph/RealWorldRoutingTests.swift + GraphTestHelper.swift | Real-world OSM tile fixtures used by GraphTestHelper/RealWorldRoutingTests; keep. |
| `Graph/RoadNetwork_Raploch.geojson.gz` | Keep | Graph/RealWorldRoutingTests.swift + GraphTestHelper.swift | Real-world OSM tile fixtures used by GraphTestHelper/RealWorldRoutingTests; keep. |
| `Graph/allgaeu_14_8647_5723.geojson.gz` | Keep | Graph/RealWorldRoutingTests.swift + GraphTestHelper.swift | Real-world OSM tile fixtures used by GraphTestHelper/RealWorldRoutingTests; keep. |
| `Graph/allgaeu_14_8647_5724.geojson.gz` | Keep | Graph/RealWorldRoutingTests.swift + GraphTestHelper.swift | Real-world OSM tile fixtures used by GraphTestHelper/RealWorldRoutingTests; keep. |
| `Graph/allgaeu_14_8647_5725.geojson.gz` | Keep | Graph/RealWorldRoutingTests.swift + GraphTestHelper.swift | Real-world OSM tile fixtures used by GraphTestHelper/RealWorldRoutingTests; keep. |
| `Graph/allgaeu_14_8648_5723.geojson.gz` | Keep | Graph/RealWorldRoutingTests.swift + GraphTestHelper.swift | Real-world OSM tile fixtures used by GraphTestHelper/RealWorldRoutingTests; keep. |
| `Graph/allgaeu_14_8648_5724.geojson.gz` | Keep | Graph/RealWorldRoutingTests.swift + GraphTestHelper.swift | Real-world OSM tile fixtures used by GraphTestHelper/RealWorldRoutingTests; keep. |
| `Graph/allgaeu_14_8648_5725.geojson.gz` | Keep | Graph/RealWorldRoutingTests.swift + GraphTestHelper.swift | Real-world OSM tile fixtures used by GraphTestHelper/RealWorldRoutingTests; keep. |
| `Graph/allgaeu_14_8649_5723.geojson.gz` | Keep | Graph/RealWorldRoutingTests.swift + GraphTestHelper.swift | Real-world OSM tile fixtures used by GraphTestHelper/RealWorldRoutingTests; keep. |
| `Graph/allgaeu_14_8649_5724.geojson.gz` | Keep | Graph/RealWorldRoutingTests.swift + GraphTestHelper.swift | Real-world OSM tile fixtures used by GraphTestHelper/RealWorldRoutingTests; keep. |
| `Graph/allgaeu_14_8649_5725.geojson.gz` | Keep | Graph/RealWorldRoutingTests.swift + GraphTestHelper.swift | Real-world OSM tile fixtures used by GraphTestHelper/RealWorldRoutingTests; keep. |
| `Graph/allgaeu_14_8650_5723.geojson.gz` | Keep | Graph/RealWorldRoutingTests.swift + GraphTestHelper.swift | Real-world OSM tile fixtures used by GraphTestHelper/RealWorldRoutingTests; keep. |
| `Graph/allgaeu_14_8650_5724.geojson.gz` | Keep | Graph/RealWorldRoutingTests.swift + GraphTestHelper.swift | Real-world OSM tile fixtures used by GraphTestHelper/RealWorldRoutingTests; keep. |
| `Graph/allgaeu_14_8650_5725.geojson.gz` | Keep | Graph/RealWorldRoutingTests.swift + GraphTestHelper.swift | Real-world OSM tile fixtures used by GraphTestHelper/RealWorldRoutingTests; keep. |
| `Graph/allgaeu_14_8651_5723.geojson.gz` | Keep | Graph/RealWorldRoutingTests.swift + GraphTestHelper.swift | Real-world OSM tile fixtures used by GraphTestHelper/RealWorldRoutingTests; keep. |
| `Graph/allgaeu_14_8651_5724.geojson.gz` | Keep | Graph/RealWorldRoutingTests.swift + GraphTestHelper.swift | Real-world OSM tile fixtures used by GraphTestHelper/RealWorldRoutingTests; keep. |
| `Graph/allgaeu_14_8651_5725.geojson.gz` | Keep | Graph/RealWorldRoutingTests.swift + GraphTestHelper.swift | Real-world OSM tile fixtures used by GraphTestHelper/RealWorldRoutingTests; keep. |
| `Graph/allgaeu_14_8652_5723.geojson.gz` | Keep | Graph/RealWorldRoutingTests.swift + GraphTestHelper.swift | Real-world OSM tile fixtures used by GraphTestHelper/RealWorldRoutingTests; keep. |
| `Graph/allgaeu_14_8652_5724.geojson.gz` | Keep | Graph/RealWorldRoutingTests.swift + GraphTestHelper.swift | Real-world OSM tile fixtures used by GraphTestHelper/RealWorldRoutingTests; keep. |
| `Graph/allgaeu_14_8652_5725.geojson.gz` | Keep | Graph/RealWorldRoutingTests.swift + GraphTestHelper.swift | Real-world OSM tile fixtures used by GraphTestHelper/RealWorldRoutingTests; keep. |
| `Graph/allgaeu_14_8653_5723.geojson.gz` | Keep | Graph/RealWorldRoutingTests.swift + GraphTestHelper.swift | Real-world OSM tile fixtures used by GraphTestHelper/RealWorldRoutingTests; keep. |
| `Graph/allgaeu_14_8653_5724.geojson.gz` | Keep | Graph/RealWorldRoutingTests.swift + GraphTestHelper.swift | Real-world OSM tile fixtures used by GraphTestHelper/RealWorldRoutingTests; keep. |
| `Graph/allgaeu_14_8653_5725.geojson.gz` | Keep | Graph/RealWorldRoutingTests.swift + GraphTestHelper.swift | Real-world OSM tile fixtures used by GraphTestHelper/RealWorldRoutingTests; keep. |
| `Graph/allgaeu_14_8654_5723.geojson.gz` | Keep | Graph/RealWorldRoutingTests.swift + GraphTestHelper.swift | Real-world OSM tile fixtures used by GraphTestHelper/RealWorldRoutingTests; keep. |
| `Graph/allgaeu_14_8654_5724.geojson.gz` | Keep | Graph/RealWorldRoutingTests.swift + GraphTestHelper.swift | Real-world OSM tile fixtures used by GraphTestHelper/RealWorldRoutingTests; keep. |
| `Graph/allgaeu_14_8654_5725.geojson.gz` | Keep | Graph/RealWorldRoutingTests.swift + GraphTestHelper.swift | Real-world OSM tile fixtures used by GraphTestHelper/RealWorldRoutingTests; keep. |
| `Graph/allgaeu_14_8655_5723.geojson.gz` | Keep | Graph/RealWorldRoutingTests.swift + GraphTestHelper.swift | Real-world OSM tile fixtures used by GraphTestHelper/RealWorldRoutingTests; keep. |
| `Graph/allgaeu_14_8655_5724.geojson.gz` | Keep | Graph/RealWorldRoutingTests.swift + GraphTestHelper.swift | Real-world OSM tile fixtures used by GraphTestHelper/RealWorldRoutingTests; keep. |
| `Graph/allgaeu_14_8655_5725.geojson.gz` | Keep | Graph/RealWorldRoutingTests.swift + GraphTestHelper.swift | Real-world OSM tile fixtures used by GraphTestHelper/RealWorldRoutingTests; keep. |
| `Graph/allgaeu_14_8656_5723.geojson.gz` | Keep | Graph/RealWorldRoutingTests.swift + GraphTestHelper.swift | Real-world OSM tile fixtures used by GraphTestHelper/RealWorldRoutingTests; keep. |
| `Graph/allgaeu_14_8656_5724.geojson.gz` | Keep | Graph/RealWorldRoutingTests.swift + GraphTestHelper.swift | Real-world OSM tile fixtures used by GraphTestHelper/RealWorldRoutingTests; keep. |
| `Graph/allgaeu_14_8656_5725.geojson.gz` | Keep | Graph/RealWorldRoutingTests.swift + GraphTestHelper.swift | Real-world OSM tile fixtures used by GraphTestHelper/RealWorldRoutingTests; keep. |
| `Graph/allgaeu_14_8657_5723.geojson.gz` | Keep | Graph/RealWorldRoutingTests.swift + GraphTestHelper.swift | Real-world OSM tile fixtures used by GraphTestHelper/RealWorldRoutingTests; keep. |
| `Graph/allgaeu_14_8657_5724.geojson.gz` | Keep | Graph/RealWorldRoutingTests.swift + GraphTestHelper.swift | Real-world OSM tile fixtures used by GraphTestHelper/RealWorldRoutingTests; keep. |
| `Graph/allgaeu_14_8657_5725.geojson.gz` | Keep | Graph/RealWorldRoutingTests.swift + GraphTestHelper.swift | Real-world OSM tile fixtures used by GraphTestHelper/RealWorldRoutingTests; keep. |
| `Graph/munich_14_8717_5684.geojson.gz` | Keep | Graph/RealWorldRoutingTests.swift + GraphTestHelper.swift | Real-world OSM tile fixtures used by GraphTestHelper/RealWorldRoutingTests; keep. |
| `Graph/munich_14_8717_5685.geojson.gz` | Keep | Graph/RealWorldRoutingTests.swift + GraphTestHelper.swift | Real-world OSM tile fixtures used by GraphTestHelper/RealWorldRoutingTests; keep. |
| `Graph/munich_14_8718_5684.geojson.gz` | Keep | Graph/RealWorldRoutingTests.swift + GraphTestHelper.swift | Real-world OSM tile fixtures used by GraphTestHelper/RealWorldRoutingTests; keep. |
| `Graph/munich_14_8718_5685.geojson.gz` | Keep | Graph/RealWorldRoutingTests.swift + GraphTestHelper.swift | Real-world OSM tile fixtures used by GraphTestHelper/RealWorldRoutingTests; keep. |
| `Graph/munich_14_8719_5684.geojson.gz` | Keep | Graph/RealWorldRoutingTests.swift + GraphTestHelper.swift | Real-world OSM tile fixtures used by GraphTestHelper/RealWorldRoutingTests; keep. |
| `Graph/munich_14_8719_5685.geojson.gz` | Keep | Graph/RealWorldRoutingTests.swift + GraphTestHelper.swift | Real-world OSM tile fixtures used by GraphTestHelper/RealWorldRoutingTests; keep. |
| `Graph/paris_14_8295_5632.geojson.gz` | Keep | Graph/RealWorldRoutingTests.swift + GraphTestHelper.swift | Real-world OSM tile fixtures used by GraphTestHelper/RealWorldRoutingTests; keep. |
| `Graph/paris_14_8295_5633.geojson.gz` | Keep | Graph/RealWorldRoutingTests.swift + GraphTestHelper.swift | Real-world OSM tile fixtures used by GraphTestHelper/RealWorldRoutingTests; keep. |
| `Graph/paris_14_8295_5634.geojson.gz` | Keep | Graph/RealWorldRoutingTests.swift + GraphTestHelper.swift | Real-world OSM tile fixtures used by GraphTestHelper/RealWorldRoutingTests; keep. |
| `Graph/paris_14_8295_5635.geojson.gz` | Keep | Graph/RealWorldRoutingTests.swift + GraphTestHelper.swift | Real-world OSM tile fixtures used by GraphTestHelper/RealWorldRoutingTests; keep. |
| `Graph/paris_14_8295_5636.geojson.gz` | Keep | Graph/RealWorldRoutingTests.swift + GraphTestHelper.swift | Real-world OSM tile fixtures used by GraphTestHelper/RealWorldRoutingTests; keep. |
| `Graph/paris_14_8295_5637.geojson.gz` | Keep | Graph/RealWorldRoutingTests.swift + GraphTestHelper.swift | Real-world OSM tile fixtures used by GraphTestHelper/RealWorldRoutingTests; keep. |
| `Graph/paris_14_8295_5638.geojson.gz` | Keep | Graph/RealWorldRoutingTests.swift + GraphTestHelper.swift | Real-world OSM tile fixtures used by GraphTestHelper/RealWorldRoutingTests; keep. |
| `Graph/paris_14_8295_5639.geojson.gz` | Keep | Graph/RealWorldRoutingTests.swift + GraphTestHelper.swift | Real-world OSM tile fixtures used by GraphTestHelper/RealWorldRoutingTests; keep. |
| `Graph/paris_14_8296_5632.geojson.gz` | Keep | Graph/RealWorldRoutingTests.swift + GraphTestHelper.swift | Real-world OSM tile fixtures used by GraphTestHelper/RealWorldRoutingTests; keep. |
| `Graph/paris_14_8296_5633.geojson.gz` | Keep | Graph/RealWorldRoutingTests.swift + GraphTestHelper.swift | Real-world OSM tile fixtures used by GraphTestHelper/RealWorldRoutingTests; keep. |
| `Graph/paris_14_8296_5634.geojson.gz` | Keep | Graph/RealWorldRoutingTests.swift + GraphTestHelper.swift | Real-world OSM tile fixtures used by GraphTestHelper/RealWorldRoutingTests; keep. |
| `Graph/paris_14_8296_5635.geojson.gz` | Keep | Graph/RealWorldRoutingTests.swift + GraphTestHelper.swift | Real-world OSM tile fixtures used by GraphTestHelper/RealWorldRoutingTests; keep. |
| `Graph/paris_14_8296_5636.geojson.gz` | Keep | Graph/RealWorldRoutingTests.swift + GraphTestHelper.swift | Real-world OSM tile fixtures used by GraphTestHelper/RealWorldRoutingTests; keep. |
| `Graph/paris_14_8296_5637.geojson.gz` | Keep | Graph/RealWorldRoutingTests.swift + GraphTestHelper.swift | Real-world OSM tile fixtures used by GraphTestHelper/RealWorldRoutingTests; keep. |
| `Graph/paris_14_8296_5638.geojson.gz` | Keep | Graph/RealWorldRoutingTests.swift + GraphTestHelper.swift | Real-world OSM tile fixtures used by GraphTestHelper/RealWorldRoutingTests; keep. |
| `Graph/paris_14_8296_5639.geojson.gz` | Keep | Graph/RealWorldRoutingTests.swift + GraphTestHelper.swift | Real-world OSM tile fixtures used by GraphTestHelper/RealWorldRoutingTests; keep. |
| `Graph/paris_14_8297_5632.geojson.gz` | Keep | Graph/RealWorldRoutingTests.swift + GraphTestHelper.swift | Real-world OSM tile fixtures used by GraphTestHelper/RealWorldRoutingTests; keep. |
| `Graph/paris_14_8297_5633.geojson.gz` | Keep | Graph/RealWorldRoutingTests.swift + GraphTestHelper.swift | Real-world OSM tile fixtures used by GraphTestHelper/RealWorldRoutingTests; keep. |
| `Graph/paris_14_8297_5634.geojson.gz` | Keep | Graph/RealWorldRoutingTests.swift + GraphTestHelper.swift | Real-world OSM tile fixtures used by GraphTestHelper/RealWorldRoutingTests; keep. |
| `Graph/paris_14_8297_5635.geojson.gz` | Keep | Graph/RealWorldRoutingTests.swift + GraphTestHelper.swift | Real-world OSM tile fixtures used by GraphTestHelper/RealWorldRoutingTests; keep. |
| `Graph/paris_14_8297_5636.geojson.gz` | Keep | Graph/RealWorldRoutingTests.swift + GraphTestHelper.swift | Real-world OSM tile fixtures used by GraphTestHelper/RealWorldRoutingTests; keep. |
| `Graph/paris_14_8297_5637.geojson.gz` | Keep | Graph/RealWorldRoutingTests.swift + GraphTestHelper.swift | Real-world OSM tile fixtures used by GraphTestHelper/RealWorldRoutingTests; keep. |
| `Graph/paris_14_8297_5638.geojson.gz` | Keep | Graph/RealWorldRoutingTests.swift + GraphTestHelper.swift | Real-world OSM tile fixtures used by GraphTestHelper/RealWorldRoutingTests; keep. |
| `Graph/paris_14_8297_5639.geojson.gz` | Keep | Graph/RealWorldRoutingTests.swift + GraphTestHelper.swift | Real-world OSM tile fixtures used by GraphTestHelper/RealWorldRoutingTests; keep. |
| `Graph/paris_14_8298_5632.geojson.gz` | Keep | Graph/RealWorldRoutingTests.swift + GraphTestHelper.swift | Real-world OSM tile fixtures used by GraphTestHelper/RealWorldRoutingTests; keep. |
| `Graph/paris_14_8298_5633.geojson.gz` | Keep | Graph/RealWorldRoutingTests.swift + GraphTestHelper.swift | Real-world OSM tile fixtures used by GraphTestHelper/RealWorldRoutingTests; keep. |
| `Graph/paris_14_8298_5634.geojson.gz` | Keep | Graph/RealWorldRoutingTests.swift + GraphTestHelper.swift | Real-world OSM tile fixtures used by GraphTestHelper/RealWorldRoutingTests; keep. |
| `Graph/paris_14_8298_5635.geojson.gz` | Keep | Graph/RealWorldRoutingTests.swift + GraphTestHelper.swift | Real-world OSM tile fixtures used by GraphTestHelper/RealWorldRoutingTests; keep. |
| `Graph/paris_14_8298_5636.geojson.gz` | Keep | Graph/RealWorldRoutingTests.swift + GraphTestHelper.swift | Real-world OSM tile fixtures used by GraphTestHelper/RealWorldRoutingTests; keep. |
| `Graph/paris_14_8298_5637.geojson.gz` | Keep | Graph/RealWorldRoutingTests.swift + GraphTestHelper.swift | Real-world OSM tile fixtures used by GraphTestHelper/RealWorldRoutingTests; keep. |
| `Graph/paris_14_8298_5638.geojson.gz` | Keep | Graph/RealWorldRoutingTests.swift + GraphTestHelper.swift | Real-world OSM tile fixtures used by GraphTestHelper/RealWorldRoutingTests; keep. |
| `Graph/paris_14_8298_5639.geojson.gz` | Keep | Graph/RealWorldRoutingTests.swift + GraphTestHelper.swift | Real-world OSM tile fixtures used by GraphTestHelper/RealWorldRoutingTests; keep. |
| `Graph/paris_14_8299_5632.geojson.gz` | Keep | Graph/RealWorldRoutingTests.swift + GraphTestHelper.swift | Real-world OSM tile fixtures used by GraphTestHelper/RealWorldRoutingTests; keep. |
| `Graph/paris_14_8299_5633.geojson.gz` | Keep | Graph/RealWorldRoutingTests.swift + GraphTestHelper.swift | Real-world OSM tile fixtures used by GraphTestHelper/RealWorldRoutingTests; keep. |
| `Graph/paris_14_8299_5634.geojson.gz` | Keep | Graph/RealWorldRoutingTests.swift + GraphTestHelper.swift | Real-world OSM tile fixtures used by GraphTestHelper/RealWorldRoutingTests; keep. |
| `Graph/paris_14_8299_5635.geojson.gz` | Keep | Graph/RealWorldRoutingTests.swift + GraphTestHelper.swift | Real-world OSM tile fixtures used by GraphTestHelper/RealWorldRoutingTests; keep. |
| `Graph/paris_14_8299_5636.geojson.gz` | Keep | Graph/RealWorldRoutingTests.swift + GraphTestHelper.swift | Real-world OSM tile fixtures used by GraphTestHelper/RealWorldRoutingTests; keep. |
| `Graph/paris_14_8299_5637.geojson.gz` | Keep | Graph/RealWorldRoutingTests.swift + GraphTestHelper.swift | Real-world OSM tile fixtures used by GraphTestHelper/RealWorldRoutingTests; keep. |
| `Graph/paris_14_8299_5638.geojson.gz` | Keep | Graph/RealWorldRoutingTests.swift + GraphTestHelper.swift | Real-world OSM tile fixtures used by GraphTestHelper/RealWorldRoutingTests; keep. |
| `Graph/paris_14_8299_5639.geojson.gz` | Keep | Graph/RealWorldRoutingTests.swift + GraphTestHelper.swift | Real-world OSM tile fixtures used by GraphTestHelper/RealWorldRoutingTests; keep. |
| `Graph/paris_14_8300_5632.geojson.gz` | Keep | Graph/RealWorldRoutingTests.swift + GraphTestHelper.swift | Real-world OSM tile fixtures used by GraphTestHelper/RealWorldRoutingTests; keep. |
| `Graph/paris_14_8300_5633.geojson.gz` | Keep | Graph/RealWorldRoutingTests.swift + GraphTestHelper.swift | Real-world OSM tile fixtures used by GraphTestHelper/RealWorldRoutingTests; keep. |
| `Graph/paris_14_8300_5634.geojson.gz` | Keep | Graph/RealWorldRoutingTests.swift + GraphTestHelper.swift | Real-world OSM tile fixtures used by GraphTestHelper/RealWorldRoutingTests; keep. |
| `Graph/paris_14_8300_5635.geojson.gz` | Keep | Graph/RealWorldRoutingTests.swift + GraphTestHelper.swift | Real-world OSM tile fixtures used by GraphTestHelper/RealWorldRoutingTests; keep. |
| `Graph/paris_14_8300_5636.geojson.gz` | Keep | Graph/RealWorldRoutingTests.swift + GraphTestHelper.swift | Real-world OSM tile fixtures used by GraphTestHelper/RealWorldRoutingTests; keep. |
| `Graph/paris_14_8300_5637.geojson.gz` | Keep | Graph/RealWorldRoutingTests.swift + GraphTestHelper.swift | Real-world OSM tile fixtures used by GraphTestHelper/RealWorldRoutingTests; keep. |
| `Graph/paris_14_8300_5638.geojson.gz` | Keep | Graph/RealWorldRoutingTests.swift + GraphTestHelper.swift | Real-world OSM tile fixtures used by GraphTestHelper/RealWorldRoutingTests; keep. |
| `Graph/paris_14_8300_5639.geojson.gz` | Keep | Graph/RealWorldRoutingTests.swift + GraphTestHelper.swift | Real-world OSM tile fixtures used by GraphTestHelper/RealWorldRoutingTests; keep. |
| `Graph/paris_14_8301_5632.geojson.gz` | Keep | Graph/RealWorldRoutingTests.swift + GraphTestHelper.swift | Real-world OSM tile fixtures used by GraphTestHelper/RealWorldRoutingTests; keep. |
| `Graph/paris_14_8301_5633.geojson.gz` | Keep | Graph/RealWorldRoutingTests.swift + GraphTestHelper.swift | Real-world OSM tile fixtures used by GraphTestHelper/RealWorldRoutingTests; keep. |
| `Graph/paris_14_8301_5634.geojson.gz` | Keep | Graph/RealWorldRoutingTests.swift + GraphTestHelper.swift | Real-world OSM tile fixtures used by GraphTestHelper/RealWorldRoutingTests; keep. |
| `Graph/paris_14_8301_5635.geojson.gz` | Keep | Graph/RealWorldRoutingTests.swift + GraphTestHelper.swift | Real-world OSM tile fixtures used by GraphTestHelper/RealWorldRoutingTests; keep. |
| `Graph/paris_14_8301_5636.geojson.gz` | Keep | Graph/RealWorldRoutingTests.swift + GraphTestHelper.swift | Real-world OSM tile fixtures used by GraphTestHelper/RealWorldRoutingTests; keep. |
| `Graph/paris_14_8301_5637.geojson.gz` | Keep | Graph/RealWorldRoutingTests.swift + GraphTestHelper.swift | Real-world OSM tile fixtures used by GraphTestHelper/RealWorldRoutingTests; keep. |
| `Graph/paris_14_8301_5638.geojson.gz` | Keep | Graph/RealWorldRoutingTests.swift + GraphTestHelper.swift | Real-world OSM tile fixtures used by GraphTestHelper/RealWorldRoutingTests; keep. |
| `Graph/paris_14_8301_5639.geojson.gz` | Keep | Graph/RealWorldRoutingTests.swift + GraphTestHelper.swift | Real-world OSM tile fixtures used by GraphTestHelper/RealWorldRoutingTests; keep. |
| `LineIntersection/LineIntersectionDouble1.geojson.gz` | Keep | Algorithms/LineIntersectionTests.swift | Reference line-intersection fixtures; keep. |
| `LineIntersection/LineIntersectionDouble2.geojson.gz` | Keep | Algorithms/LineIntersectionTests.swift | Reference line-intersection fixtures; keep. |
| `LineIntersection/LineIntersectionMultiLineStrings1.geojson.gz` | Keep | Algorithms/LineIntersectionTests.swift | Reference line-intersection fixtures; keep. |
| `LineIntersection/LineIntersectionMultiLineStrings2.geojson.gz` | Keep | Algorithms/LineIntersectionTests.swift | Reference line-intersection fixtures; keep. |
| `LineIntersection/LineIntersectionPolygonsWithHoles1.geojson.gz` | Keep | Algorithms/LineIntersectionTests.swift | Reference line-intersection fixtures; keep. |
| `LineIntersection/LineIntersectionPolygonsWithHoles2.geojson.gz` | Keep | Algorithms/LineIntersectionTests.swift | Reference line-intersection fixtures; keep. |
| `LineIntersection/LineIntersectionSameCoordinates1.geojson.gz` | Keep | Algorithms/LineIntersectionTests.swift | Reference line-intersection fixtures; keep. |
| `LineIntersection/LineIntersectionSameCoordinates2.geojson.gz` | Keep | Algorithms/LineIntersectionTests.swift | Reference line-intersection fixtures; keep. |
| `LineOverlap/LineOverlap1_1.geojson.gz` | Keep | Algorithms/LineOverlapTests.swift | Reference overlap fixtures; keep; extra coverage in #337. |
| `LineOverlap/LineOverlap1_2.geojson.gz` | Keep | Algorithms/LineOverlapTests.swift | Reference overlap fixtures; keep; extra coverage in #337. |
| `LineOverlap/LineOverlap2_1.geojson.gz` | Keep | Algorithms/LineOverlapTests.swift | Reference overlap fixtures; keep; extra coverage in #337. |
| `LineOverlap/LineOverlap2_2.geojson.gz` | Keep | Algorithms/LineOverlapTests.swift | Reference overlap fixtures; keep; extra coverage in #337. |
| `LineOverlap/LineOverlap3_1.geojson.gz` | Keep | Algorithms/LineOverlapTests.swift | Reference overlap fixtures; keep; extra coverage in #337. |
| `LineOverlap/LineOverlap3_2.geojson.gz` | Keep | Algorithms/LineOverlapTests.swift | Reference overlap fixtures; keep; extra coverage in #337. |
| `LineOverlap/NoOverlap1.geojson.gz` | Keep | Algorithms/LineOverlapTests.swift | Reference overlap fixtures; keep; extra coverage in #337. |
| `LineOverlap/NoOverlap2.geojson.gz` | Keep | Algorithms/LineOverlapTests.swift | Reference overlap fixtures; keep; extra coverage in #337. |
| `LineOverlap/PartlyOverlapping1Result.geojson.gz` | Keep | Algorithms/LineOverlapTests.swift | Reference overlap fixtures; keep; extra coverage in #337. |
| `LineOverlap/PartlyOverlapping1_1.geojson.gz` | Keep | Algorithms/LineOverlapTests.swift | Reference overlap fixtures; keep; extra coverage in #337. |
| `LineOverlap/PartlyOverlapping1_2.geojson.gz` | Keep | Algorithms/LineOverlapTests.swift | Reference overlap fixtures; keep; extra coverage in #337. |
| `LineOverlap/PartlyOverlapping2Result.geojson.gz` | Keep | Algorithms/LineOverlapTests.swift | Reference overlap fixtures; keep; extra coverage in #337. |
| `LineOverlap/PartlyOverlapping2_1.geojson.gz` | Keep | Algorithms/LineOverlapTests.swift | Reference overlap fixtures; keep; extra coverage in #337. |
| `LineOverlap/PartlyOverlapping2_2.geojson.gz` | Keep | Algorithms/LineOverlapTests.swift | Reference overlap fixtures; keep; extra coverage in #337. |
| `LineOverlap/Polygon1Result.geojson.gz` | Keep | Algorithms/LineOverlapTests.swift | Reference overlap fixtures; keep; extra coverage in #337. |
| `LineOverlap/Polygon1_1.geojson.gz` | Keep | Algorithms/LineOverlapTests.swift | Reference overlap fixtures; keep; extra coverage in #337. |
| `LineOverlap/Polygon1_2.geojson.gz` | Keep | Algorithms/LineOverlapTests.swift | Reference overlap fixtures; keep; extra coverage in #337. |
| `Mask/LShapeMask.geojson.gz` | Keep | Algorithms/MaskTests.swift | Mask regression fixtures; keep; hole/partial/seam gaps in #341. |
| `Mask/LShapeMaskResult.geojson.gz` | Keep | Algorithms/MaskTests.swift | Mask regression fixtures; keep; hole/partial/seam gaps in #341. |
| `Mask/SmallSquare.geojson.gz` | Keep | Algorithms/MaskTests.swift | Mask regression fixtures; keep; hole/partial/seam gaps in #341. |
| `Mask/SmallSquareResult.geojson.gz` | Keep | Algorithms/MaskTests.swift | Mask regression fixtures; keep; hole/partial/seam gaps in #341. |
| `Mask/TwoSquares.geojson.gz` | Keep | Algorithms/MaskTests.swift | Mask regression fixtures; keep; hole/partial/seam gaps in #341. |
| `Mask/TwoSquaresResult.geojson.gz` | Keep | Algorithms/MaskTests.swift | Mask regression fixtures; keep; hole/partial/seam gaps in #341. |
| `Overlay/DisjointSquaresA.geojson.gz` | Keep | Algorithms/OverlayTests.swift (shared overlay helpers) | Overlay regression fixtures; keep; exact-value gaps in #343. |
| `Overlay/DisjointSquaresB.geojson.gz` | Keep | Algorithms/OverlayTests.swift (shared overlay helpers) | Overlay regression fixtures; keep; exact-value gaps in #343. |
| `Overlay/DisjointSquaresDiffABResult.geojson.gz` | Keep | Algorithms/OverlayTests.swift (shared overlay helpers) | Overlay regression fixtures; keep; exact-value gaps in #343. |
| `Overlay/DisjointSquaresIntersectResult.geojson.gz` | Keep | Algorithms/OverlayTests.swift (shared overlay helpers) | Overlay regression fixtures; keep; exact-value gaps in #343. |
| `Overlay/DisjointSquaresSymDiffResult.geojson.gz` | Keep | Algorithms/OverlayTests.swift (shared overlay helpers) | Overlay regression fixtures; keep; exact-value gaps in #343. |
| `Overlay/FullyContainedA.geojson.gz` | Keep | Algorithms/OverlayTests.swift (shared overlay helpers) | Overlay regression fixtures; keep; exact-value gaps in #343. |
| `Overlay/FullyContainedB.geojson.gz` | Keep | Algorithms/OverlayTests.swift (shared overlay helpers) | Overlay regression fixtures; keep; exact-value gaps in #343. |
| `Overlay/FullyContainedDiffABResult.geojson.gz` | Keep | Algorithms/OverlayTests.swift (shared overlay helpers) | Overlay regression fixtures; keep; exact-value gaps in #343. |
| `Overlay/FullyContainedIntersectResult.geojson.gz` | Keep | Algorithms/OverlayTests.swift (shared overlay helpers) | Overlay regression fixtures; keep; exact-value gaps in #343. |
| `Overlay/FullyContainedSymDiffResult.geojson.gz` | Keep | Algorithms/OverlayTests.swift (shared overlay helpers) | Overlay regression fixtures; keep; exact-value gaps in #343. |
| `Overlay/HolePolygonIntersectA.geojson.gz` | Keep | Algorithms/OverlayTests.swift (shared overlay helpers) | Overlay regression fixtures; keep; exact-value gaps in #343. |
| `Overlay/HolePolygonIntersectB.geojson.gz` | Keep | Algorithms/OverlayTests.swift (shared overlay helpers) | Overlay regression fixtures; keep; exact-value gaps in #343. |
| `Overlay/HolePolygonIntersectDiffABResult.geojson.gz` | Keep | Algorithms/OverlayTests.swift (shared overlay helpers) | Overlay regression fixtures; keep; exact-value gaps in #343. |
| `Overlay/HolePolygonIntersectIntersectResult.geojson.gz` | Keep | Algorithms/OverlayTests.swift (shared overlay helpers) | Overlay regression fixtures; keep; exact-value gaps in #343. |
| `Overlay/HolePolygonIntersectSymDiffResult.geojson.gz` | Keep | Algorithms/OverlayTests.swift (shared overlay helpers) | Overlay regression fixtures; keep; exact-value gaps in #343. |
| `Overlay/IdenticalPolygonsA.geojson.gz` | Keep | Algorithms/OverlayTests.swift (shared overlay helpers) | Overlay regression fixtures; keep; exact-value gaps in #343. |
| `Overlay/IdenticalPolygonsB.geojson.gz` | Keep | Algorithms/OverlayTests.swift (shared overlay helpers) | Overlay regression fixtures; keep; exact-value gaps in #343. |
| `Overlay/IdenticalPolygonsDiffABResult.geojson.gz` | Keep | Algorithms/OverlayTests.swift (shared overlay helpers) | Overlay regression fixtures; keep; exact-value gaps in #343. |
| `Overlay/IdenticalPolygonsIntersectResult.geojson.gz` | Keep | Algorithms/OverlayTests.swift (shared overlay helpers) | Overlay regression fixtures; keep; exact-value gaps in #343. |
| `Overlay/IdenticalPolygonsSymDiffResult.geojson.gz` | Keep | Algorithms/OverlayTests.swift (shared overlay helpers) | Overlay regression fixtures; keep; exact-value gaps in #343. |
| `Overlay/LShapeOverlapA.geojson.gz` | Keep | Algorithms/OverlayTests.swift (shared overlay helpers) | Overlay regression fixtures; keep; exact-value gaps in #343. |
| `Overlay/LShapeOverlapB.geojson.gz` | Keep | Algorithms/OverlayTests.swift (shared overlay helpers) | Overlay regression fixtures; keep; exact-value gaps in #343. |
| `Overlay/LShapeOverlapDiffABResult.geojson.gz` | Keep | Algorithms/OverlayTests.swift (shared overlay helpers) | Overlay regression fixtures; keep; exact-value gaps in #343. |
| `Overlay/LShapeOverlapIntersectResult.geojson.gz` | Keep | Algorithms/OverlayTests.swift (shared overlay helpers) | Overlay regression fixtures; keep; exact-value gaps in #343. |
| `Overlay/LShapeOverlapSymDiffResult.geojson.gz` | Keep | Algorithms/OverlayTests.swift (shared overlay helpers) | Overlay regression fixtures; keep; exact-value gaps in #343. |
| `Overlay/OverlappingSquaresA.geojson.gz` | Keep | Algorithms/OverlayTests.swift (shared overlay helpers) | Overlay regression fixtures; keep; exact-value gaps in #343. |
| `Overlay/OverlappingSquaresB.geojson.gz` | Keep | Algorithms/OverlayTests.swift (shared overlay helpers) | Overlay regression fixtures; keep; exact-value gaps in #343. |
| `Overlay/OverlappingSquaresDiffABResult.geojson.gz` | Keep | Algorithms/OverlayTests.swift (shared overlay helpers) | Overlay regression fixtures; keep; exact-value gaps in #343. |
| `Overlay/OverlappingSquaresIntersectResult.geojson.gz` | Keep | Algorithms/OverlayTests.swift (shared overlay helpers) | Overlay regression fixtures; keep; exact-value gaps in #343. |
| `Overlay/OverlappingSquaresSymDiffResult.geojson.gz` | Keep | Algorithms/OverlayTests.swift (shared overlay helpers) | Overlay regression fixtures; keep; exact-value gaps in #343. |
| `ProjectionMatrix/matrix.csv` | Keep | Projections/ProjectionMatrixTests.swift (generated) | Machine-generated PROJ matrix (scripts/generate_projection_matrix.py); keep, regenerate rather than edit. |
| `Tesselate/ConcavePentagon.geojson.gz` | Keep | Algorithms/TesselateTests.swift | Reference tessellation fixture; keep; area/hole/antimeridian gaps in #330. |
| `Tesselate/LShape.geojson.gz` | Keep | Algorithms/TesselateTests.swift | Reference tessellation fixture; keep; area/hole/antimeridian gaps in #330. |
| `Tesselate/PolygonWithHole.geojson.gz` | Keep | Algorithms/TesselateTests.swift | Reference tessellation fixture; keep; area/hole/antimeridian gaps in #330. |
| `Tesselate/Square.geojson.gz` | Keep | Algorithms/TesselateTests.swift | Reference tessellation fixture; keep; area/hole/antimeridian gaps in #330. |
| `Tesselate/Triangle.geojson.gz` | Keep | Algorithms/TesselateTests.swift | Reference tessellation fixture; keep; area/hole/antimeridian gaps in #330. |
| `Union/ContainedPolygonInner.geojson.gz` | Keep | Algorithms/UnionTests.swift | Union regression fixtures; keep; tolerance gaps in #343. |
| `Union/ContainedPolygonOuter.geojson.gz` | Keep | Algorithms/UnionTests.swift | Union regression fixtures; keep; tolerance gaps in #343. |
| `Union/ContainedPolygonResult.geojson.gz` | Keep | Algorithms/UnionTests.swift | Union regression fixtures; keep; tolerance gaps in #343. |
| `Union/DisjointRectanglesInput1.geojson.gz` | Keep | Algorithms/UnionTests.swift | Union regression fixtures; keep; tolerance gaps in #343. |
| `Union/DisjointRectanglesInput2.geojson.gz` | Keep | Algorithms/UnionTests.swift | Union regression fixtures; keep; tolerance gaps in #343. |
| `Union/DisjointRectanglesResult.geojson.gz` | Keep | Algorithms/UnionTests.swift | Union regression fixtures; keep; tolerance gaps in #343. |
| `Union/LongLineFlatParts.geojson.gz` | Keep | Algorithms/UnionTests.swift | Union regression fixtures; keep; tolerance gaps in #343. |
| `Union/MaximumCallstackSizeExceeded2317.geojson.gz` | Keep | Algorithms/UnionTests.swift | Union regression fixtures; keep; tolerance gaps in #343. |
| `Union/NonConvexInput1.geojson.gz` | Keep | Algorithms/UnionTests.swift | Union regression fixtures; keep; tolerance gaps in #343. |
| `Union/NonConvexInput2.geojson.gz` | Keep | Algorithms/UnionTests.swift | Union regression fixtures; keep; tolerance gaps in #343. |
| `Union/NonConvexResult.geojson.gz` | Keep | Algorithms/UnionTests.swift | Union regression fixtures; keep; tolerance gaps in #343. |
| `Union/NotOverlapping.geojson.gz` | Keep | Algorithms/UnionTests.swift | Union regression fixtures; keep; tolerance gaps in #343. |
| `Union/NotOverlappingResult.geojson.gz` | Keep | Algorithms/UnionTests.swift | Union regression fixtures; keep; tolerance gaps in #343. |
| `Union/OverlappingRectanglesInput1.geojson.gz` | Keep | Algorithms/UnionTests.swift | Union regression fixtures; keep; tolerance gaps in #343. |
| `Union/OverlappingRectanglesInput2.geojson.gz` | Keep | Algorithms/UnionTests.swift | Union regression fixtures; keep; tolerance gaps in #343. |
| `Union/OverlappingRectanglesResult.geojson.gz` | Keep | Algorithms/UnionTests.swift | Union regression fixtures; keep; tolerance gaps in #343. |
| `Union/Pair0_1Result.geojson.gz` | Keep | Algorithms/UnionTests.swift | Union regression fixtures; keep; tolerance gaps in #343. |
| `Union/Pair0_4Result.geojson.gz` | Keep | Algorithms/UnionTests.swift | Union regression fixtures; keep; tolerance gaps in #343. |
| `Union/Pair1_2Result.geojson.gz` | Keep | Algorithms/UnionTests.swift | Union regression fixtures; keep; tolerance gaps in #343. |
| `Union/Pair1_4Result.geojson.gz` | Keep | Algorithms/UnionTests.swift | Union regression fixtures; keep; tolerance gaps in #343. |
| `Union/Pair1_5Result.geojson.gz` | Keep | Algorithms/UnionTests.swift | Union regression fixtures; keep; tolerance gaps in #343. |
| `Union/Pair2_3Result.geojson.gz` | Keep | Algorithms/UnionTests.swift | Union regression fixtures; keep; tolerance gaps in #343. |
| `Union/Pair2_5Result.geojson.gz` | Keep | Algorithms/UnionTests.swift | Union regression fixtures; keep; tolerance gaps in #343. |
| `Union/Pair2_6Result.geojson.gz` | Keep | Algorithms/UnionTests.swift | Union regression fixtures; keep; tolerance gaps in #343. |
| `Union/Pair3_6Result.geojson.gz` | Keep | Algorithms/UnionTests.swift | Union regression fixtures; keep; tolerance gaps in #343. |
| `Union/SharingEdgeInput1.geojson.gz` | Keep | Algorithms/UnionTests.swift | Union regression fixtures; keep; tolerance gaps in #343. |
| `Union/SharingEdgeInput2.geojson.gz` | Keep | Algorithms/UnionTests.swift | Union regression fixtures; keep; tolerance gaps in #343. |
| `Union/SharingEdgeResult.geojson.gz` | Keep | Algorithms/UnionTests.swift | Union regression fixtures; keep; tolerance gaps in #343. |
| `Union/ThreePolygonsInput1.geojson.gz` | Keep | Algorithms/UnionTests.swift | Union regression fixtures; keep; tolerance gaps in #343. |
| `Union/ThreePolygonsInput2.geojson.gz` | Keep | Algorithms/UnionTests.swift | Union regression fixtures; keep; tolerance gaps in #343. |
| `Union/ThreePolygonsInput3.geojson.gz` | Keep | Algorithms/UnionTests.swift | Union regression fixtures; keep; tolerance gaps in #343. |
| `Union/ThreePolygonsResult.geojson.gz` | Keep | Algorithms/UnionTests.swift | Union regression fixtures; keep; tolerance gaps in #343. |
| `Union/UnableToCompleteOutputRing1983_1.geojson.gz` | Keep | Algorithms/UnionTests.swift | Union regression fixtures; keep; tolerance gaps in #343. |
| `Union/UnableToCompleteOutputRing1983_2.geojson.gz` | Keep | Algorithms/UnionTests.swift | Union regression fixtures; keep; tolerance gaps in #343. |
| `Union/UnableToFindSegment2258_1.geojson.gz` | Keep | Algorithms/UnionTests.swift | Union regression fixtures; keep; tolerance gaps in #343. |
| `Union/UnableToFindSegment2258_2.geojson.gz` | Keep | Algorithms/UnionTests.swift | Union regression fixtures; keep; tolerance gaps in #343. |
| `Union/Union1.geojson.gz` | Keep | Algorithms/UnionTests.swift | Union regression fixtures; keep; tolerance gaps in #343. |
| `Union/Union1Result.geojson.gz` | Keep | Algorithms/UnionTests.swift | Union regression fixtures; keep; tolerance gaps in #343. |
| `Union/Union2.geojson.gz` | Keep | Algorithms/UnionTests.swift | Union regression fixtures; keep; tolerance gaps in #343. |
| `Union/Union2Result.geojson.gz` | Keep | Algorithms/UnionTests.swift | Union regression fixtures; keep; tolerance gaps in #343. |
| `Union/Union3.geojson.gz` | Keep | Algorithms/UnionTests.swift | Union regression fixtures; keep; tolerance gaps in #343. |
| `Union/Union3Result.geojson.gz` | Keep | Algorithms/UnionTests.swift | Union regression fixtures; keep; tolerance gaps in #343. |
| `Union/Union4.geojson.gz` | Keep | Algorithms/UnionTests.swift | Union regression fixtures; keep; tolerance gaps in #343. |
| `Union/Union4Result.geojson.gz` | Keep | Algorithms/UnionTests.swift | Union regression fixtures; keep; tolerance gaps in #343. |
| `Voronoi/FourPoints.geojson.gz` | Keep | Algorithms/VoronoiTests.swift | Reference Voronoi fixtures; keep; antimeridian/degenerate gaps in #335. |
| `Voronoi/FourPointsBbox.geojson.gz` | Keep | Algorithms/VoronoiTests.swift | Reference Voronoi fixtures; keep; antimeridian/degenerate gaps in #335. |
| `Voronoi/ThreePoints.geojson.gz` | Keep | Algorithms/VoronoiTests.swift | Reference Voronoi fixtures; keep; antimeridian/degenerate gaps in #335. |
| `Voronoi/ThreePointsBbox.geojson.gz` | Keep | Algorithms/VoronoiTests.swift | Reference Voronoi fixtures; keep; antimeridian/degenerate gaps in #335. |

## Weak-assertion inventory

The table lists test files with at least five non-value assertions
(`!= nil`, `.count`, `isNotEmpty`). These are not automatically defects: a
count is the right contract for feature/component counts, and optionality is
the right contract for failable constructors. The audit decision is to keep
them where the contract is structural and to replace them with exact
coordinates/areas/winding where they guard algorithm output. The latter work is
tracked per API in #337 (line/polygon construction) and #343 (overlay/spatial).

| Test file | `!= nil` | `.count` | `isNotEmpty` |
| --- | ---: | ---: | ---: |
| `Algorithms/MakeValidTests.swift` | 22 | 8 | 0 |
| `Graph/GraphMergeTests.swift` | 0 | 25 | 2 |
| `Algorithms/SharedPathsTests.swift` | 15 | 12 | 0 |
| `Query/QueryParserTests.swift` | 15 | 12 | 0 |
| `Extensions/ArrayExtensionsTests.swift` | 5 | 18 | 2 |
| `Algorithms/ClustersTests.swift` | 19 | 4 | 1 |
| `Algorithms/MaskTests.swift` | 11 | 12 | 0 |
| `Algorithms/TesselateTests.swift` | 0 | 21 | 1 |
| `GeoJson/FeatureCollectionTests.swift` | 1 | 20 | 0 |
| `Algorithms/TileCoverTests.swift` | 0 | 21 | 0 |
| `Algorithms/LineMergeTests.swift` | 0 | 21 | 0 |
| `Algorithms/RandomTests.swift` | 0 | 20 | 0 |
| `Algorithms/AntimeridianCuttingTests.swift` | 0 | 20 | 0 |
| `GeoJson/RTreeTests.swift` | 0 | 19 | 0 |
| `Algorithms/BezierSplineTests.swift` | 9 | 10 | 0 |
| `GeoJson/GeoJsonParserTests.swift` | 4 | 14 | 0 |
| `Algorithms/VoronoiTests.swift` | 3 | 15 | 0 |
| `Graph/KShortestPathsTests.swift` | 0 | 16 | 0 |
| `Graph/PartitioningTests.swift` | 0 | 16 | 0 |
| `Algorithms/SimplifyTests.swift` | 0 | 16 | 0 |
| `Graph/CycleTests.swift` | 0 | 15 | 0 |
| `Algorithms/IntersectionTests.swift` | 13 | 2 | 0 |
| `Algorithms/LineChunkTests.swift` | 0 | 15 | 0 |
| `Algorithms/MinkowskiSumTests.swift` | 15 | 0 | 0 |
| `Graph/DeadEndPruningTests.swift` | 0 | 12 | 2 |

## Regression links for recent fixes

Every bug fixed by the audit series has a regression test in the same PR:

| Issue | Regression coverage |
| --- | --- |
| #319 GeoJSON/WKB/WKT | `GeoJsonParserTests`, `WKBTests`, `WKTTests`, `TWKBTests`, `ReaderTests` |
| #320 predicates/validity | `Boolean*Tests`, `TopologicalValidityTests`, `KinksTests` |
| #321 overlay/buffer/clip/index | `Overlay*Tests`, `BufferTests`, `MaskTests`, `RTreeTests`, `UnionTests` |
| #322 line/polygon construction | `Line*Tests`, `PolygonizeTests`, `SimplifyTests`, `VoronoiTests` |
| #323 projections | `ProjectionTests` (registry, PROJ references, all-SRID round trips/batch) |
| #324 graph routing | `ShortestPathTests` (seeded Floyd–Warshall differential), `ContractionTests`, `MinimumSpanningTreeTests` |
| #325 core/tiles/clusters | `ClustersTests` (high latitude/seam), `MapTileTests` (zoom bounds), `DoubleExtensionsTests` |

## Remaining gaps

- #330 Tesselate hole/antimeridian, #331 Minkowski, #332 LineMerge, #333 Polygonize,
  #334 Simplify, #335 Voronoi, #336 constructors, #337 line/polygon coverage,
  #338 antimeridian operations, #339 boolean/prepared semantics, #340 buffer,
  #341 mask/clip, #342 decoder validation, #343 overlay/spatial coverage.
- #346 Eulerian/Chinese Postman parallel edges.
- #349 QueryParser nested groups and prefix `NOT`.
- #248 grid-shift datum accuracy remains a documented limitation.
