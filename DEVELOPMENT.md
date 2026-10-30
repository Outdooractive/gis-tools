# Development

Benchmark suites, baseline refreshes, coverage, formatting, documentation and
API compatibility checks are documented here so the README can stay focused
on using the package. See the [README](README.md) for installation and usage.

## Contents

- [Benchmarks](#benchmarks)
- [Benchmark baselines](#benchmark-baselines)
- [Development checks](#development-checks)
  - [Coverage](#coverage)
  - [Formatting](#formatting)
  - [Documentation](#documentation)
  - [API compatibility](#api-compatibility)

## Benchmarks

A separate release-mode executable covers loading, projection, spatial predicates, overlay, the R-tree, coders, buffer, simplify, hulls, line operations, tile cover, clipping, graph routing, the query DSL, clustering, memory layout and a small cross-module inlining suite.

```bash
# Run every suite and print a Markdown table
scripts/benchmarks.sh

# Run selected suites
swift run -c release --traits EnableGraphAPI Benchmarks predicates overlay graph

# Run the real-world graph benchmarks
swift run -c release --traits EnableGraphAPI Benchmarks realworld

# List available suites
swift run -c release Benchmarks
```

Each suite runs in its own process. Timing is the median of the executable's iterations; peak memory is `getrusage(RUSAGE_SELF).ru_maxrss`.

The `graph` and `realworld` suites require the `EnableGraphAPI` trait. The graph suite uses deterministic grids at approximately 10k, 100k and 1M edges. It measures construction, graph merging, Dijkstra, A*, bidirectional Dijkstra, contraction build time and contracted-graph queries, plus BFS/DFS and cycle detection at the smaller sizes.

The `realworld` suite loads the Allgäu, Munich and Paris graph fixtures (gzip), builds and merges directed and undirected graphs, and benchmarks hiking, cycling and car routes, contraction build/query, reusable routing-index queries, ALT landmark queries and per-dataset memory. Set `GISTOOLS_GRAPH_FIXTURES` to the fixture directory when it is not under `Tests/GISToolsTests/TestData/Graph`.

The Allgäu, Munich and Paris graph test fixtures are derived from
OpenStreetMap data © OpenStreetMap contributors, available under the
[Open Database License (ODbL)](https://www.openstreetmap.org/copyright).

### Benchmark baselines

Tracked baselines live in `Benchmarks/Baselines/` and are keyed by operating
system and CPU architecture, for example `linux-aarch64.json` or
`darwin-arm64.json`. Run the representative loading, projection, overlay,
R-tree, buffer, simplify, graph and memory suites and compare them with the
matching baseline:

```bash
python3 scripts/benchmark_compare.py
```

The command builds `Benchmarks` in release mode, prints current-versus-baseline
deltas for every suite, and exits non-zero when a benchmark time or peak RSS
regresses by more than the default 20%, or a finer-grained memory metric by more
than 50%. Use `--threshold 0.30` to change the time/RSS threshold,
`--metric-threshold 0.60` to change the memory metric threshold,
`--report-only` to keep the exit status successful, or pass suite names to
compare a subset. Benchmarks below 0.5 ms are reported without a regression
decision because the measurement noise is too large; suites without a matching
baseline are reported as such.

Refresh a baseline only after reviewing the performance change:

```bash
python3 scripts/benchmark_compare.py --update
git diff Benchmarks/Baselines/
```

Passing suite names with `--update` refreshes only those suites and preserves
the other entries. Commit the refreshed baseline with the change that
justifies it. Baselines are machine-specific; generate one on each
platform/architecture you intend to track. The manually triggered
**Benchmarks** workflow can run the comparison on a Linux ARM64 runner and on
macOS, but is not part of pull-request CI. The committed Linux baseline targets
the ARM64 runner used by that workflow. To create a baseline for another
platform, run the workflow with `update_baseline` enabled, download the uploaded
artifact, and commit it.

## Development checks

Coverage, formatting and documentation are gated in CI.

### Coverage

Refresh the per-file coverage report after running the test suite with coverage:

```bash
swift test --traits EnableGraphAPI --enable-code-coverage
python3 scripts/refresh_coverage_report.py
```

The CI coverage floor is **87.5%** weighted line coverage. To run the same gate locally:

```bash
python3 scripts/refresh_coverage_report.py --minimum 87.5 --check
```

### Formatting

Formatting uses the repository's `.swiftformat` configuration and the pinned
Swift version in `.swift-version`. CI compares the Swift files changed by a
pull request against the base branch and fails when the PR **adds** formatting
violations. Existing legacy debt is tolerated until those files are cleaned up.

Check changed files locally:

```bash
swiftformat --lint --config .swiftformat <changed Swift files>
```

To fix them:

```bash
swiftformat --config .swiftformat <changed Swift files>
```

### Documentation

Build the DocC catalog and fail on documentation warnings or broken links:

```bash
python3 scripts/check_documentation.py
```

### API compatibility

Public API changes are checked on every pull request with:

```bash
swift package diagnose-api-breaking-changes "origin/${BASE_REF}" \
  --products GISTools
```

The baseline is the pull request's **base branch**, not a fixed release tag.
This catches accidental removals or signature changes before merge. Stacked
pull requests therefore compare against their stacked base branch.

#### Running locally

```bash
# Compare against main
git fetch origin main
swift package diagnose-api-breaking-changes origin/main --products GISTools

# Compare against the previous release for a release audit
git fetch --tags
swift package diagnose-api-breaking-changes v3.0.0 --products GISTools
```

#### Intentional breaking changes

For an intentional 3.0 API change, add the **`api-breaking`** label to the pull
request. The CI job still prints the complete diagnostics, but reports success
with a warning instead of failing.

Only maintainers should add this label. The label is an acknowledgement for
that pull request; no checked-in allowlist needs to be cleaned up afterwards.
Future pull requests compare against the updated base branch.

#### CI notes

- The job runs only for `pull_request` events.
- It uses the same latest-stable Swift container as the other Linux jobs.
- Full git history is fetched so the base branch can be built as the baseline.
