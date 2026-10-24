# API compatibility checks

Public API changes are checked on every pull request with:

```bash
swift package diagnose-api-breaking-changes "origin/${BASE_REF}" \
  --products GISTools
```

The baseline is the pull request's **base branch**, not a fixed release tag.
This catches accidental removals or signature changes before merge. Stacked
pull requests therefore compare against their stacked base branch.

## Running locally

```bash
git fetch origin main
swift package diagnose-api-breaking-changes origin/main --products GISTools
```

To compare against the previous release for a release audit:

```bash
git fetch --tags
swift package diagnose-api-breaking-changes v3.0.0-beta.4 --products GISTools
```

## Intentional breaking changes

For an intentional 3.0 API change, add the **`api-breaking`** label to the pull
request. The CI job still prints the complete diagnostics, but reports success
with a warning instead of failing.

Only maintainers should add this label. The label is an acknowledgement for
that pull request; no checked-in allowlist needs to be cleaned up afterwards.
Future pull requests compare against the updated base branch.

## CI notes

- The job runs only for `pull_request` events.
- It uses the minimum supported Swift version (`swift:6.1`).
- Full git history is fetched so the base branch can be built as the baseline.
