# Release workflow:
#   1. Commit and push your changes to main as usual
#   2. Run `just release 1.2.0` to tag and publish the release
#      → creates immutable tag v1.2.0
#      → moves the floating major tag v1 to the same commit
#      → pushes both to GitHub
#   3. Users on `@v1` get the update automatically
#      Users on `@v1.2.0` stay pinned
#
#   Breaking changes only → bump major: `just release 2.0.0`
#   Hotfix without new version → `just retag` (moves v1 to HEAD)

default:
    @just --list

# Test Github action locally
[group('actions')]
test:
    act -j test-action

# Create a new release: just release 1.2.0
[group('release')]
release version:
    #!/usr/bin/env bash
    set -euo pipefail
    major="v$(echo '{{version}}' | cut -d. -f1)"
    git tag v{{version}}
    git tag -f "$major"
    git push origin v{{version}}
    git push -f origin "$major"
    echo "Released v{{version}} and moved $major to $(git rev-parse --short HEAD)"

# Move the major tag (v1, v2…) to HEAD without creating a new version
[group('release')]
retag:
    #!/usr/bin/env bash
    set -euo pipefail
    major=$(git tag --sort=-v:refname | grep -E '^v[0-9]+\.[0-9]+\.[0-9]+$' | head -1 | cut -d. -f1)
    git tag -f "$major"
    git push -f origin "$major"
    echo "Moved $major to $(git rev-parse --short HEAD)"

# List all release tags
[group('release')]
tags:
    git tag --sort=-v:refname | grep -E '^v[0-9]'
